# Libraries
# =============================================================================
import cocotb
import logging
import itertools
from cocotb.triggers         import  Timer, RisingEdge
from cocotb.clock            import  Clock
from cocotbext.axi import AxiStreamFrame, AxiLiteBus, AxiLiteMaster, AxiStreamBus, AxiStreamSource, AxiStreamSink
import random

# Constants
#==============================================================================
CLK_PERIOD = 10     # ns
BASEADDRESS = 0x40000000
CONTROL_REG = 0x4
TRANSFER_LENGTH_REG = 0x8
PACKET_LENGTH_REG = 0xC
DATA_SWAP_REG = 0x10
TLAST_GEN_MODE_REG = 0x14
DATA_MASK_REG = 0x18

Enable_reg = 0x3
tlast_gen_disable = 0
tlast_gen_enable = 1
tlast_gen_gen_and_passthrough = 2

num_transfers_total = 1
num_frames = 10

#==============================================================================

class Frame:
    def __init__(self, tdata, tkeep, tid, tuser, tdest):
        self.tdata = tdata
        self.tkeep = tkeep
        self.tid = tid
        self.tuser = tuser
        self.tdest = tdest

class TB(object):
    def __init__(self, dut):
        self.dut = dut

        self.data_width = int(self.dut.g_AXIS_TDATA_WIDTH)//8

        log = logging.getLogger("cocotb.tb")
        #Set clock
        axis_clk_100MHz = Clock(self.dut.axi_aclk, CLK_PERIOD, units='ns')
        axil_clk_100MHz = Clock(self.dut.axis_aclk, CLK_PERIOD, units='ns')
        cocotb.start_soon(axis_clk_100MHz.start(start_high=False))
        cocotb.start_soon(axil_clk_100MHz.start(start_high=False))

        self.axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(self.dut, "s_axi"), self.dut.axi_aclk, self.dut.axi_aresetn, reset_active_level=False)
        self.axis_source = AxiStreamSource(AxiStreamBus.from_prefix(self.dut, "s_axis"), self.dut.axis_aclk, self.dut.axis_aresetn, reset_active_level=False)
        self.axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(self.dut, "m_axis"), self.dut.axis_aclk, self.dut.axis_aresetn, reset_active_level=False)


    async def reset(self):
        self.dut.axis_aresetn.setimmediatevalue(1)
        self.dut.axi_aresetn.setimmediatevalue(1)
        await RisingEdge(self.dut.axis_aclk)
        await RisingEdge(self.dut.axi_aclk)
        self.dut.axis_aresetn.value = 0
        self.dut.axi_aresetn.value = 0
        await RisingEdge(self.dut.axis_aclk)
        await RisingEdge(self.dut.axi_aclk)
        self.dut.axis_aresetn.value = 1
        self.dut.axi_aresetn.value = 1
        await RisingEdge(self.dut.axis_aclk)
        await RisingEdge(self.dut.axi_aclk)

    def insert_idle_list(self, cycle_list = None):
        if type(cycle_list) is not list:
            print ("Cycle List needs to be a list")
        self.axis_source.set_pause_generator(itertools.cycle(cycle_list))

    def insert_backpressure_list(self, cycle_list = None):
        if type(cycle_list) is not list:
            print ("Cycle List needs to be a list")
        self.axis_sink.set_pause_generator(itertools.cycle(cycle_list))

    def compare(self, a, b):
        assert len(a) == len(b)
        self.dut._log.info("Input len %d" % (len(a)))
        self.dut._log.info("Expected input len %d" % (len(b)))
        for i in range(len(a)):
            assert a[i] == b[i]

    def strip_invalid_bytes(self, tdata, tkeep):
        """Remove bytes from tdata where tkeep=0"""
        return [d for d, k in zip(tdata, tkeep) if k == 1]



#==============================================================================
@cocotb.coroutine
async def receive_data(stream_sink, capture_size):
    """
    Read AXI-Stream frames from sink and return a list of dictionaries
    with full fields (tdata, tkeep, tid, tuser, tdest).
    """
    output = []
    #Reading
    for _ in range(capture_size):
        rframe = await stream_sink.recv(compact=False) # Disable compact mode to get full fields
        # These values are lists of repeated values (see cocotb-axi documentation), so we take the first element
        frame_info = Frame(
            tdata = rframe.tdata,
            tkeep = rframe.tkeep if hasattr(rframe, 'tkeep') else None,     # Check if tkeep exists
            tid = rframe.tid if hasattr(rframe, 'tid') else [0],       # Check if tid exists, default to [0]
            tuser = rframe.tuser if hasattr(rframe, 'tuser') else [0], # Check if tuser exists, default to [0]
            tdest = rframe.tdest if hasattr(rframe, 'tdest') else [0], # Check if tdest exists, default to [0]
        )

        output.append(frame_info)
        # await RisingEdge(tb.dut.axis_aclk)
        await Timer(CLK_PERIOD, "ns")  # Wait for the clock period.

    return output   

@cocotb.coroutine
async def send_data(stream_source, data_list):
    """
    Send AXI-Stream frames defined inside object data_list (class Frame)
    AXI parameters (tdata, tkeep, tid, tuser, tdest) are sent if defined inside data_list
    """
    for data in data_list:
        frame = AxiStreamFrame(data.tdata)

        # Assign only when the field is defined (not None)
        if hasattr(data, "tkeep") and data.tkeep is not None:
            frame.tkeep = data.tkeep

        if hasattr(data, "tid") and data.tid is not None:
            frame.tid = data.tid

        if hasattr(data, "tuser") and data.tuser is not None:
            frame.tuser = data.tuser

        if hasattr(data, "tdest") and data.tdest is not None:
            frame.tdest = data.tdest

        await stream_source.send(frame)    

#==============================================================================

@cocotb.test(skip = False, stage = 1, timeout_time=1, timeout_unit='ms')
async def axis_tlast_back_pressure(dut):
    tb = TB(dut)
    await tb.reset()

    # Adjust sink back pressure here. 
    # This list is repeated during the current simulation
    num_clocks_down = 50
    num_clocks_up = 3
    num_clocks = 100
    t_ready_clocks = []
    for z in range(num_clocks_up):
        t_ready_clocks.append(0)
    for k in range(num_clocks_down):
        t_ready_clocks.append(1)
        
    tb.insert_backpressure_list(t_ready_clocks)
   
    #################### WRITE AXI-LITE ##############################  
    # Set enable, packet & byte registers
    # tlastGen Transfer in bytes
    tlast_gen_transfer_bytes = random.randint(1,512)
    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4,'little'))
    # number of packets
    packet_lenght = num_frames
    await tb.axil_master.write(PACKET_LENGTH_REG, (packet_lenght).to_bytes(4,'little'))
    #Enable tlastGen
    await tb.axil_master.write(CONTROL_REG, bytearray([Enable_reg]))

    ##################### W/R AXI-STREAM ############################## 
    for num_transfers in range(0,num_transfers_total):
        # Expected output
        stream_frames = [] # List to store AxiStreamFrame objects
        for i in range(num_frames):
            frame_data = []
            frame_tkeep = []
            tkeep_count = 0
            bytes_remaining = 0
            while tkeep_count < (int(tlast_gen_transfer_bytes)):
                if int(tlast_gen_transfer_bytes) - tkeep_count < tb.data_width:
                    bytes_remaining = int(tlast_gen_transfer_bytes) - tkeep_count
                else:
                    bytes_remaining = tb.data_width
                tdata_chunk = [random.randint(0, 255) for _ in range(tb.data_width)]
                frame_data.extend(tdata_chunk)
                tkeep_mask = [1]*bytes_remaining + [0]*(tb.data_width - bytes_remaining)
                tkeep_chunk = [random.randint(0,1) & mask for mask in tkeep_mask[:bytes_remaining]] + [0]*(tb.data_width - bytes_remaining)
                frame_tkeep.extend(tkeep_chunk)
                #count the number of ones in tkeep
                tkeep_count += sum(tkeep_chunk)
        
                
            stream_frame = AxiStreamFrame(frame_data,
                                          tkeep=frame_tkeep)
            stream_frames.append(stream_frame)

        cocotb.start_soon(send_data(tb.axis_source, stream_frames)) # write on channel 1
        recv_task = cocotb.start_soon(receive_data(tb.axis_sink, num_frames)) # read on channel 0
        dut_output = await recv_task.join()

        for i in range(num_frames):
            tdata_expected = tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep)
            tdata_received = tb.strip_invalid_bytes(dut_output[i].tdata, dut_output[i].tkeep)
            tb.compare(tdata_received, tdata_expected)

        await Timer(100 * CLK_PERIOD, "ns")  # Wait for the clock period.


@cocotb.test(skip = False, stage = 1, timeout_time=1, timeout_unit='ms')
async def axis_tlast_back_pressure_bypassmode(dut):
    tb = TB(dut)
    await tb.reset()

    # Adjust sink back pressure here. 
    # This list is repeated during the current simulation
    num_clocks_down = 50
    num_clocks_up = 3
    num_clocks = 100
    t_ready_clocks = []
    for z in range(num_clocks_up):
        t_ready_clocks.append(0)
    for k in range(num_clocks_down):
        t_ready_clocks.append(1)
        
    tb.insert_backpressure_list(t_ready_clocks)
   
    #################### WRITE AXI-LITE ##############################  
    # Set enable, packet & byte registers
    # tlastGen Transfer in bytes
    tlast_gen_transfer_bytes = random.randint(1,512)
    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4,'little'))
    # Enable bypass mode
    await tb.axil_master.write(TLAST_GEN_MODE_REG, (tlast_gen_disable).to_bytes(4,'little'))
    # number of packets
    packet_length = 0 # Set to 0 to enable loop mode
    await tb.axil_master.write(PACKET_LENGTH_REG, (packet_length).to_bytes(4,'little'))
    #Enable tlastGen
    await tb.axil_master.write(CONTROL_REG, bytearray([Enable_reg]))

    ##################### W/R AXI-STREAM ############################## 
    for num_transfers in range(0,num_transfers_total):
        # Expected output
        stream_frames = [] # List to store AxiStreamFrame objects
        for i in range(num_frames):
            frame_data = []
            frame_tkeep = []
            tkeep_count = 0
            bytes_remaining = 0
            while tkeep_count < (int(tlast_gen_transfer_bytes)):
                if int(tlast_gen_transfer_bytes) - tkeep_count < tb.data_width:
                    bytes_remaining = int(tlast_gen_transfer_bytes) - tkeep_count
                else:
                    bytes_remaining = tb.data_width
                tdata_chunk = [random.randint(0, 255) for _ in range(tb.data_width)]
                frame_data.extend(tdata_chunk)
                tkeep_mask = [1]*bytes_remaining + [0]*(tb.data_width - bytes_remaining)
                tkeep_chunk = [random.randint(0,1) & mask for mask in tkeep_mask[:bytes_remaining]] + [0]*(tb.data_width - bytes_remaining)
                frame_tkeep.extend(tkeep_chunk)
                #count the number of ones in tkeep
                tkeep_count += sum(tkeep_chunk)
        
                
            stream_frame = AxiStreamFrame(frame_data,
                                          tkeep=frame_tkeep)
            stream_frames.append(stream_frame)

        cocotb.start_soon(send_data(tb.axis_source, stream_frames)) # write on channel 1
        recv_task = cocotb.start_soon(receive_data(tb.axis_sink, num_frames)) # read on channel 0
        dut_output = await recv_task.join()

        for i in range(num_frames):
            tdata_expected = tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep)
            tdata_received = tb.strip_invalid_bytes(dut_output[i].tdata, dut_output[i].tkeep)
            tb.compare(tdata_received, tdata_expected)

        await Timer(100 * CLK_PERIOD, "ns")  # Wait for the clock period.

#===========================================================================

@cocotb.test(skip = False, stage = 1, timeout_time=1, timeout_unit='ms')
async def axis_tlast_starvation(dut):
    tb = TB(dut)
    await tb.reset()

    # Adjust source starvation here. 
    # This list is repeated during the current simulation
    num_clocks = 100
    t_valid_clocks = []
    for z in range(num_clocks):
        t_valid_clocks.append(random.choice(range(2)))
        
    tb.insert_idle_list(t_valid_clocks)
   
    #################### WRITE AXI-LITE ##############################  
    # Set enable, packet & byte registers
    # tlastGen Transfer in bytes
    tlast_gen_transfer_bytes = random.randint(1,512)
    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4,'little'))
    # number of packets
    packet_lenght = num_frames
    await tb.axil_master.write(PACKET_LENGTH_REG, (packet_lenght).to_bytes(4,'little'))
    #Enable tlastGen
    await tb.axil_master.write(CONTROL_REG, bytearray([Enable_reg]))

    ##################### W/R AXI-STREAM ############################## 
    for num_transfers in range(0,num_transfers_total):
        # Expected output
        stream_frames = [] # List to store AxiStreamFrame objects
        for i in range(num_frames):
            frame_data = []
            frame_tkeep = []
            tkeep_count = 0
            bytes_remaining = 0
            while tkeep_count < (int(tlast_gen_transfer_bytes)):
                if int(tlast_gen_transfer_bytes) - tkeep_count < tb.data_width:
                    bytes_remaining = int(tlast_gen_transfer_bytes) - tkeep_count
                else:
                    bytes_remaining = tb.data_width
                tdata_chunk = [random.randint(0, 255) for _ in range(tb.data_width)]
                frame_data.extend(tdata_chunk)
                tkeep_mask = [1]*bytes_remaining + [0]*(tb.data_width - bytes_remaining)
                tkeep_chunk = [random.randint(0,1) & mask for mask in tkeep_mask[:bytes_remaining]] + [0]*(tb.data_width - bytes_remaining)
                frame_tkeep.extend(tkeep_chunk)
                #count the number of ones in tkeep
                tkeep_count += sum(tkeep_chunk)
        
                
            stream_frame = AxiStreamFrame(frame_data,
                                          tkeep=frame_tkeep)
            stream_frames.append(stream_frame)

        cocotb.start_soon(send_data(tb.axis_source, stream_frames)) # write on channel 1
        recv_task = cocotb.start_soon(receive_data(tb.axis_sink, num_frames)) # read on channel 0
        dut_output = await recv_task.join()

        for i in range(num_frames):
            tdata_expected = tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep)
            tdata_received = tb.strip_invalid_bytes(dut_output[i].tdata, dut_output[i].tkeep)
            tb.compare(tdata_received, tdata_expected)

        await Timer(100 * CLK_PERIOD, "ns")  # Wait for the clock period.


@cocotb.test(skip = False, stage = 1, timeout_time=1, timeout_unit='ms')
async def axis_tlast_starvation_bypassmode(dut):
    tb = TB(dut)
    await tb.reset()

    # Adjust source starvation here. 
    # This list is repeated during the current simulation
    num_clocks = 100
    t_valid_clocks = []
    for z in range(num_clocks):
        t_valid_clocks.append(random.choice(range(2)))
        
    tb.insert_idle_list(t_valid_clocks)
   
    #################### WRITE AXI-LITE ##############################  
    # Set enable, packet & byte registers
    # tlastGen Transfer in bytes
    tlast_gen_transfer_bytes = random.randint(1,512)
    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4,'little'))
    # Enable bypass mode
    await tb.axil_master.write(TLAST_GEN_MODE_REG, (tlast_gen_disable).to_bytes(4,'little'))
    # number of packets
    packet_length = 0 # Set to 0 to enable loop mode
    await tb.axil_master.write(PACKET_LENGTH_REG, (packet_length).to_bytes(4,'little'))
    #Enable tlastGen
    await tb.axil_master.write(CONTROL_REG, bytearray([Enable_reg]))

    ##################### W/R AXI-STREAM ############################## 
    for num_transfers in range(0,num_transfers_total):
        # Expected output
        stream_frames = [] # List to store AxiStreamFrame objects
        for i in range(num_frames):
            frame_data = []
            frame_tkeep = []
            tkeep_count = 0
            bytes_remaining = 0
            while tkeep_count < (int(tlast_gen_transfer_bytes)):
                if int(tlast_gen_transfer_bytes) - tkeep_count < tb.data_width:
                    bytes_remaining = int(tlast_gen_transfer_bytes) - tkeep_count
                else:
                    bytes_remaining = tb.data_width
                tdata_chunk = [random.randint(0, 255) for _ in range(tb.data_width)]
                frame_data.extend(tdata_chunk)
                tkeep_mask = [1]*bytes_remaining + [0]*(tb.data_width - bytes_remaining)
                tkeep_chunk = [random.randint(0,1) & mask for mask in tkeep_mask[:bytes_remaining]] + [0]*(tb.data_width - bytes_remaining)
                frame_tkeep.extend(tkeep_chunk)
                #count the number of ones in tkeep
                tkeep_count += sum(tkeep_chunk)
        
                
            stream_frame = AxiStreamFrame(frame_data,
                                          tkeep=frame_tkeep)
            stream_frames.append(stream_frame)

        cocotb.start_soon(send_data(tb.axis_source, stream_frames)) # write on channel 1
        recv_task = cocotb.start_soon(receive_data(tb.axis_sink, num_frames)) # read on channel 0
        dut_output = await recv_task.join()

        for i in range(num_frames):
            tdata_expected = tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep)
            tdata_received = tb.strip_invalid_bytes(dut_output[i].tdata, dut_output[i].tkeep)
            tb.compare(tdata_received, tdata_expected)

        await Timer(100 * CLK_PERIOD, "ns")  # Wait for the clock period.        

#===========================================================================

@cocotb.test(skip = False, stage = 1, timeout_time=1, timeout_unit='ms')
async def axis_tlast_tready_on(dut):
    tb = TB(dut)
    await tb.reset()

    dut.m_axis_tready.value = 1
    await Timer(20*CLK_PERIOD, units='ns')
   
    #################### WRITE AXI-LITE ##############################  
    # Set enable, packet & byte registers
    # tlastGen Transfer in bytes
    tlast_gen_transfer_bytes = random.randint(1,512)
    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4,'little'))
    # number of packets
    packet_lenght = num_frames
    await tb.axil_master.write(PACKET_LENGTH_REG, (packet_lenght).to_bytes(4,'little'))
    #Enable tlastGen
    await tb.axil_master.write(CONTROL_REG, bytearray([Enable_reg]))

    ##################### W/R AXI-STREAM ############################## 
    for num_transfers in range(0,num_transfers_total):
        # Expected output
        stream_frames = [] # List to store AxiStreamFrame objects
        for i in range(num_frames):
            frame_data = []
            frame_tkeep = []
            tkeep_count = 0
            bytes_remaining = 0
            while tkeep_count < (int(tlast_gen_transfer_bytes)):
                if int(tlast_gen_transfer_bytes) - tkeep_count < tb.data_width:
                    bytes_remaining = int(tlast_gen_transfer_bytes) - tkeep_count
                else:
                    bytes_remaining = tb.data_width
                tdata_chunk = [random.randint(0, 255) for _ in range(tb.data_width)]
                frame_data.extend(tdata_chunk)
                tkeep_mask = [1]*bytes_remaining + [0]*(tb.data_width - bytes_remaining)
                tkeep_chunk = [random.randint(0,1) & mask for mask in tkeep_mask[:bytes_remaining]] + [0]*(tb.data_width - bytes_remaining)
                frame_tkeep.extend(tkeep_chunk)
                #count the number of ones in tkeep
                tkeep_count += sum(tkeep_chunk)
        
                
            stream_frame = AxiStreamFrame(frame_data,
                                          tkeep=frame_tkeep)
            stream_frames.append(stream_frame)

        cocotb.start_soon(send_data(tb.axis_source, stream_frames)) # write on channel 1
        recv_task = cocotb.start_soon(receive_data(tb.axis_sink, num_frames)) # read on channel 0
        dut_output = await recv_task.join()

        for i in range(num_frames):
            tdata_expected = tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep)
            tdata_received = tb.strip_invalid_bytes(dut_output[i].tdata, dut_output[i].tkeep)
            tb.compare(tdata_received, tdata_expected)

        await Timer(100 * CLK_PERIOD, "ns")  # Wait for the clock period.


@cocotb.test(skip = False, stage = 1, timeout_time=1, timeout_unit='ms')
async def axis_tlast_tready_on_bypassmode(dut):
    tb = TB(dut)
    await tb.reset()

    dut.m_axis_tready.value = 1
    await Timer(20*CLK_PERIOD, units='ns')
   
    #################### WRITE AXI-LITE ##############################  
    # Set enable, packet & byte registers
    # tlastGen Transfer in bytes
    tlast_gen_transfer_bytes = random.randint(1,512)
    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4,'little'))
    # Enable bypass mode
    await tb.axil_master.write(TLAST_GEN_MODE_REG, (tlast_gen_disable).to_bytes(4,'little'))
    # number of packets
    packet_lenght = 0 # Set to 0 to enable loop mode
    await tb.axil_master.write(PACKET_LENGTH_REG, (packet_lenght).to_bytes(4,'little'))
    #Enable tlastGen
    await tb.axil_master.write(CONTROL_REG, bytearray([Enable_reg]))

    ##################### W/R AXI-STREAM ############################## 
    for num_transfers in range(0,num_transfers_total):
        # Expected output
        stream_frames = [] # List to store AxiStreamFrame objects
        for i in range(num_frames):
            frame_data = []
            frame_tkeep = []
            tkeep_count = 0
            bytes_remaining = 0
            while tkeep_count < (int(tlast_gen_transfer_bytes)):
                if int(tlast_gen_transfer_bytes) - tkeep_count < tb.data_width:
                    bytes_remaining = int(tlast_gen_transfer_bytes) - tkeep_count
                else:
                    bytes_remaining = tb.data_width
                tdata_chunk = [random.randint(0, 255) for _ in range(tb.data_width)]
                frame_data.extend(tdata_chunk)
                tkeep_mask = [1]*bytes_remaining + [0]*(tb.data_width - bytes_remaining)
                tkeep_chunk = [random.randint(0,1) & mask for mask in tkeep_mask[:bytes_remaining]] + [0]*(tb.data_width - bytes_remaining)
                frame_tkeep.extend(tkeep_chunk)
                #count the number of ones in tkeep
                tkeep_count += sum(tkeep_chunk)
        
                
            stream_frame = AxiStreamFrame(frame_data,
                                          tkeep=frame_tkeep)
            stream_frames.append(stream_frame)

        cocotb.start_soon(send_data(tb.axis_source, stream_frames)) # write on channel 1
        recv_task = cocotb.start_soon(receive_data(tb.axis_sink, num_frames)) # read on channel 0
        dut_output = await recv_task.join()

        for i in range(num_frames):
            tdata_expected = tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep)
            tdata_received = tb.strip_invalid_bytes(dut_output[i].tdata, dut_output[i].tkeep)
            tb.compare(tdata_received, tdata_expected)

        await Timer(100 * CLK_PERIOD, "ns")  # Wait for the clock period.                

#===========================================================================

@cocotb.test(skip = False, stage = 1, timeout_time=1, timeout_unit='ms')
async def axis_tlast_tready_tvalid_random(dut):
    tb = TB(dut)
    await tb.reset()

    # Adjust sink back pressure here. 
    # This list is repeated during the current simulation
    num_clocks = 100
    t_valid_clocks = []
    t_ready_clocks = []
    for z in range(num_clocks):
        t_valid_clocks.append(random.choice(range(2)))
        t_ready_clocks.append(random.choice(range(2)))
    
    tb.insert_backpressure_list(t_ready_clocks)
    tb.insert_idle_list(t_valid_clocks)
   
    #################### WRITE AXI-LITE ##############################  
    # Set enable, packet & byte registers
    # tlastGen Transfer in bytes
    tlast_gen_transfer_bytes = random.randint(1,512)
    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4,'little'))
    # number of packets
    packet_lenght = num_frames
    await tb.axil_master.write(PACKET_LENGTH_REG, (packet_lenght).to_bytes(4,'little'))
    #Enable tlastGen
    await tb.axil_master.write(CONTROL_REG, bytearray([Enable_reg]))

    ##################### W/R AXI-STREAM ############################## 
    for num_transfers in range(0,num_transfers_total):
        # Expected output
        stream_frames = [] # List to store AxiStreamFrame objects
        for i in range(num_frames):
            frame_data = []
            frame_tkeep = []
            tkeep_count = 0
            bytes_remaining = 0
            while tkeep_count < (int(tlast_gen_transfer_bytes)):
                if int(tlast_gen_transfer_bytes) - tkeep_count < tb.data_width:
                    bytes_remaining = int(tlast_gen_transfer_bytes) - tkeep_count
                else:
                    bytes_remaining = tb.data_width
                tdata_chunk = [random.randint(0, 255) for _ in range(tb.data_width)]
                frame_data.extend(tdata_chunk)
                tkeep_mask = [1]*bytes_remaining + [0]*(tb.data_width - bytes_remaining)
                tkeep_chunk = [random.randint(0,1) & mask for mask in tkeep_mask[:bytes_remaining]] + [0]*(tb.data_width - bytes_remaining)
                frame_tkeep.extend(tkeep_chunk)
                #count the number of ones in tkeep
                tkeep_count += sum(tkeep_chunk)
        
                
            stream_frame = AxiStreamFrame(frame_data,
                                          tkeep=frame_tkeep)
            stream_frames.append(stream_frame)

        cocotb.start_soon(send_data(tb.axis_source, stream_frames)) # write on channel 1
        recv_task = cocotb.start_soon(receive_data(tb.axis_sink, num_frames)) # read on channel 0
        dut_output = await recv_task.join()

        for i in range(num_frames):
            tdata_expected = tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep)
            tdata_received = tb.strip_invalid_bytes(dut_output[i].tdata, dut_output[i].tkeep)
            tb.compare(tdata_received, tdata_expected)

        await Timer(100 * CLK_PERIOD, "ns")  # Wait for the clock period.


@cocotb.test(skip = False, stage = 1, timeout_time=1, timeout_unit='ms')
async def axis_tlast_tready_tvalid_random_bypassmode(dut):
    tb = TB(dut)
    await tb.reset()

    # Adjust sink back pressure here. 
    # This list is repeated during the current simulation
    num_clocks = 100
    t_valid_clocks = []
    t_ready_clocks = []
    for z in range(num_clocks):
        t_valid_clocks.append(random.choice(range(2)))
        t_ready_clocks.append(random.choice(range(2)))
    
    tb.insert_backpressure_list(t_ready_clocks)
    tb.insert_idle_list(t_valid_clocks)
   
    #################### WRITE AXI-LITE ##############################  
    # Set enable, packet & byte registers
    # tlastGen Transfer in bytes
    tlast_gen_transfer_bytes = random.randint(1,512)
    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4,'little'))
    # Enable bypass mode
    await tb.axil_master.write(TLAST_GEN_MODE_REG, (tlast_gen_disable).to_bytes(4,'little'))
    # number of packets
    packet_length = 0 # Set to 0 to enable loop mode
    await tb.axil_master.write(PACKET_LENGTH_REG, (packet_length).to_bytes(4,'little'))
    #Enable tlastGen
    await tb.axil_master.write(CONTROL_REG, bytearray([Enable_reg]))

    ##################### W/R AXI-STREAM ############################## 
    for num_transfers in range(0,num_transfers_total):
        # Expected output
        stream_frames = [] # List to store AxiStreamFrame objects
        for i in range(num_frames):
            frame_data = []
            frame_tkeep = []
            tkeep_count = 0
            bytes_remaining = 0
            while tkeep_count < (int(tlast_gen_transfer_bytes)):
                if int(tlast_gen_transfer_bytes) - tkeep_count < tb.data_width:
                    bytes_remaining = int(tlast_gen_transfer_bytes) - tkeep_count
                else:
                    bytes_remaining = tb.data_width
                tdata_chunk = [random.randint(0, 255) for _ in range(tb.data_width)]
                frame_data.extend(tdata_chunk)
                tkeep_mask = [1]*bytes_remaining + [0]*(tb.data_width - bytes_remaining)
                tkeep_chunk = [random.randint(0,1) & mask for mask in tkeep_mask[:bytes_remaining]] + [0]*(tb.data_width - bytes_remaining)
                frame_tkeep.extend(tkeep_chunk)
                #count the number of ones in tkeep
                tkeep_count += sum(tkeep_chunk)
        
                
            stream_frame = AxiStreamFrame(frame_data,
                                          tkeep=frame_tkeep)
            stream_frames.append(stream_frame)

        cocotb.start_soon(send_data(tb.axis_source, stream_frames)) # write on channel 1
        recv_task = cocotb.start_soon(receive_data(tb.axis_sink, num_frames)) # read on channel 0
        dut_output = await recv_task.join()

        for i in range(num_frames):
            tdata_expected = tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep)
            tdata_received = tb.strip_invalid_bytes(dut_output[i].tdata, dut_output[i].tkeep)
            tb.compare(tdata_received, tdata_expected)

        await Timer(100 * CLK_PERIOD, "ns")  # Wait for the clock period.             


@cocotb.test(skip = False, stage = 1, timeout_time=1, timeout_unit='ms')
async def axis_tlast_tready_tvalid_random_swap_words(dut):
    if (int(dut.g_AXIS_TDATA_WIDTH) < 32):
        dut._log.info("Test skipped due to insufficient data width for byte swap.")
        return    
    tb = TB(dut)
    await tb.reset()

    # Adjust sink back pressure here. 
    # This list is repeated during the current simulation
    num_clocks = 100
    t_valid_clocks = []
    t_ready_clocks = []
    for z in range(num_clocks):
        t_valid_clocks.append(random.choice(range(2)))
        t_ready_clocks.append(random.choice(range(2)))
    
    tb.insert_backpressure_list(t_ready_clocks)
    tb.insert_idle_list(t_valid_clocks)
   
    #################### WRITE AXI-LITE ##############################  
    # Set enable, packet & byte registers
    # tlastGen Transfer in bytes
    tlast_gen_transfer_bytes = random.randint(1, tb.data_width)
    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4,'little'))
    # number of packets
    packet_length = num_frames
    await tb.axil_master.write(PACKET_LENGTH_REG, (packet_length).to_bytes(4,'little'))
    # word swap configuration
    data_swap = 1
    await tb.axil_master.write(DATA_SWAP_REG, (data_swap).to_bytes(4,'little'))
    #Enable tlastGen
    await tb.axil_master.write(CONTROL_REG, bytearray([Enable_reg]))
    # Data mask disabled
    await tb.axil_master.write(DATA_MASK_REG, (0).to_bytes(4,'little'))

    ##################### W/R AXI-STREAM ############################## 
    for num_transfers in range(0,num_transfers_total):
        # Expected output
        stream_frames = [] # List to store AxiStreamFrame objects
        for i in range(num_frames):
            frame_data = []
            frame_tkeep = []
            tkeep_count = 0
            while tkeep_count < (int(tlast_gen_transfer_bytes)):
                tdata_chunk = [random.randint(0, 255) for _ in range(tb.data_width)]
                frame_data.extend(tdata_chunk)
                tkeep_chunk = [1 for _ in range(tb.data_width)]
                frame_tkeep.extend(tkeep_chunk)
                #count the number of ones in tkeep
                tkeep_count += sum(tkeep_chunk)
                print(f"tkeep_count: {tkeep_count}")
        
                
            stream_frame = AxiStreamFrame(frame_data,
                                          tkeep=frame_tkeep)
            stream_frames.append(stream_frame)

        cocotb.start_soon(send_data(tb.axis_source, stream_frames)) # write on channel 1
        recv_task = cocotb.start_soon(receive_data(tb.axis_sink, num_frames)) # read on channel 0
        dut_output = await recv_task.join()

        for i in range(num_frames):
            tdata_expected = tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep)
            # Split tdata into 32-bit words, swap each word's byte order (endianness), then flatten back
            swapped_tdata = []
            for j in range(len(tdata_expected), 0, -4):
                swapped_tdata.extend(tdata_expected[j-4:j])
            tdata_received = tb.strip_invalid_bytes(dut_output[i].tdata, dut_output[i].tkeep)
            print(f"tdata_expected: {tdata_expected}")
            print(f"swapped_tdata: {swapped_tdata}")
            print(f"Received: {tdata_received}")
            tb.compare(tdata_received, swapped_tdata)

        await Timer(100 * CLK_PERIOD, "ns")  # Wait for the clock period.

@cocotb.test(skip = False, stage = 1, timeout_time=1, timeout_unit='ms')
async def axis_tlast_tready_tvalid_random_swap_bytes(dut):
    if (int(dut.g_AXIS_TDATA_WIDTH) < 32):
        dut._log.info("Test skipped due to insufficient data width for byte swap.")
        return
    tb = TB(dut)
    await tb.reset()

    # Adjust sink back pressure here. 
    # This list is repeated during the current simulation
    num_clocks = 100
    t_valid_clocks = []
    t_ready_clocks = []
    for z in range(num_clocks):
        t_valid_clocks.append(random.choice(range(2)))
        t_ready_clocks.append(random.choice(range(2)))
    
    tb.insert_backpressure_list(t_ready_clocks)
    tb.insert_idle_list(t_valid_clocks)
   
    #################### WRITE AXI-LITE ##############################  
    # Set enable, packet & byte registers
    # tlastGen Transfer in bytes
    tlast_gen_transfer_bytes = random.randint(1, tb.data_width)
    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4,'little'))
    # number of packets
    packet_length = num_frames
    await tb.axil_master.write(PACKET_LENGTH_REG, (packet_length).to_bytes(4,'little'))
    # byte swap configuration
    data_swap = 2
    await tb.axil_master.write(DATA_SWAP_REG, (data_swap).to_bytes(4,'little'))
    #Enable tlastGen
    await tb.axil_master.write(CONTROL_REG, bytearray([Enable_reg]))
    # Data mask disabled
    await tb.axil_master.write(DATA_MASK_REG, (0).to_bytes(4,'little'))

    ##################### W/R AXI-STREAM ############################## 
    for num_transfers in range(0,num_transfers_total):
        # Expected output
        stream_frames = [] # List to store AxiStreamFrame objects
        for i in range(num_frames):
            frame_data = []
            frame_tkeep = []
            tkeep_count = 0
            while tkeep_count < (int(tlast_gen_transfer_bytes)):
                tdata_chunk = [random.randint(0, 255) for _ in range(tb.data_width)]
                frame_data.extend(tdata_chunk)
                tkeep_chunk = [1 for _ in range(tb.data_width)]
                frame_tkeep.extend(tkeep_chunk)
                #count the number of ones in tkeep
                tkeep_count += sum(tkeep_chunk)
        
                
            stream_frame = AxiStreamFrame(frame_data,
                                          tkeep=frame_tkeep)
            stream_frames.append(stream_frame)

        cocotb.start_soon(send_data(tb.axis_source, stream_frames)) # write on channel 1
        recv_task = cocotb.start_soon(receive_data(tb.axis_sink, num_frames)) # read on channel 0
        dut_output = await recv_task.join()

        for i in range(num_frames):
            tdata_expected = tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep)
            # Split tdata into 8-bit words, swap each byte order (endianness), then flatten back
            swapped_tdata = []
            for j in range(len(tdata_expected), 0, -1):
                swapped_tdata.extend(tdata_expected[j-1:j])
            tdata_received = tb.strip_invalid_bytes(dut_output[i].tdata, dut_output[i].tkeep)
            print(f"tdata_expected: {tdata_expected}")
            print(f"swapped_tdata: {swapped_tdata}")
            print(f"Received: {tdata_received}")
            tb.compare(tdata_received, swapped_tdata)

        await Timer(100 * CLK_PERIOD, "ns")  # Wait for the clock period.