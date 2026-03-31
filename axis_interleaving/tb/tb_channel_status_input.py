# Testbench description
# 
# This testbench looks for testing the interleaving behaviour when the channel
# status input changes from stage to another.
#
# =============================================================================
# Libraries
# =============================================================================
import  random
import  logging
import  cocotb
from    cocotb.triggers         import RisingEdge, Timer
from    cocotb.clock            import Clock
from    cocotbext.axi           import AxiStreamBus
from    cocotbext.axi           import AxiStreamSource
from    cocotbext.axi           import AxiStreamSink
from    cocotbext.axi           import AxiLiteBus, AxiLiteMaster


#==============================================================================
# Constants
#==============================================================================
CAPTURE_SIZE = 60           # multiple of 1, 2, 3, 4, and 5


#==============================================================================
# AXIS Interleaving Register Map
#==============================================================================
# Offsets
VERSION_OFFSET = 0x0
USER_CONTROL_OFFSET = 0x4
CHANNEL_STATUS_OFFSET = 0x8

# Useful values
DISABLE_USER_CONTROL = 0
ENABLE_USER_CONTROL = 1
ENABLE_CHANNEL_0 = 1
ENABLE_CHANNEL_1 = 2
ENABLE_CHANNEL_2 = 4
ENABLE_CHANNEL_3 = 8
ENABLE_CHANNEL_4 = 16
ENABLE_CHANNEL_0_AND_2 = 5
ENABLE_ALL_CHANNELS = 31


#==============================================================================
# Function definitions
#==============================================================================
# Generate initial data
def get_init_data(dut):
    width = int(dut.g_AXIS_TDATA_WIDTH)
    
    all_data_channel0 = []
    all_data_channel1 = []
    all_data_channel2 = []
    all_data_channel3 = []
    all_data_channel4 = []
    for i in range(CAPTURE_SIZE):
        # random integer data
        int_channel0 = random.randint(0, 2**width-1)
        int_channel1 = random.randint(0, 2**width-1)
        int_channel2 = random.randint(0, 2**width-1)
        int_channel3 = random.randint(0, 2**width-1)
        int_channel4 = random.randint(0, 2**width-1)
        # data conversion to bytes
        channel0 = int_channel0.to_bytes(int(width/8), 'big')
        channel1 = int_channel1.to_bytes(int(width/8), 'big')
        channel2 = int_channel2.to_bytes(int(width/8), 'big')
        channel3 = int_channel3.to_bytes(int(width/8), 'big')
        channel4 = int_channel4.to_bytes(int(width/8), 'big')
        # append data
        all_data_channel0.append(channel0)
        all_data_channel1.append(channel1)
        all_data_channel2.append(channel2)
        all_data_channel3.append(channel3)
        all_data_channel4.append(channel4)        

    return {'channel_0' : all_data_channel0, 'channel_1' : all_data_channel1, 'channel_2' : all_data_channel2, 'channel_3' : all_data_channel3, 'channel_4' : all_data_channel4}

# Get expected output
def get_expected_output(data, output_iterations):
    expected_output = []
    for i in range(CAPTURE_SIZE):
        for j in range(output_iterations):
            all_data_channel = data['channel_' + str(j)]
            expected_output.append(all_data_channel[i])
    
    return expected_output


#==============================================================================
# TB class defintion
#==============================================================================
class TB(object):
    def __init__(self, dut):
        self.dut = dut

        log = logging.getLogger("cocotb.tb")

        # set inmediate value for reset
        self.dut.s0_axis_aresetn.setimmediatevalue(0)
        self.dut.s1_axis_aresetn.setimmediatevalue(0)
        self.dut.s2_axis_aresetn.setimmediatevalue(0)
        self.dut.s3_axis_aresetn.setimmediatevalue(0)
        self.dut.s4_axis_aresetn.setimmediatevalue(0)
        self.dut.m_axis_aresetn.setimmediatevalue(0)
        self.dut.axi_aresetn.setimmediatevalue(0)
        self.dut.interleaving_aresetn.setimmediatevalue(0)

        # Set and run axi stream and lite clock
        self.S_AXIS_CLK_PERIOD = int(1000000/int(dut.g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ))
        self.S_AXIS_CLK_PERIOD = 10 * int(round(self.S_AXIS_CLK_PERIOD/10))  # in case the last digit is not odd
        s0_axis_clk = Clock(self.dut.s0_axis_aclk, self.S_AXIS_CLK_PERIOD, units='ps')
        cocotb.start_soon(s0_axis_clk.start(start_high=False))
        s1_axis_clk = Clock(self.dut.s1_axis_aclk, self.S_AXIS_CLK_PERIOD, units='ps')
        cocotb.start_soon(s1_axis_clk.start(start_high=False))
        s2_axis_clk = Clock(self.dut.s2_axis_aclk, self.S_AXIS_CLK_PERIOD, units='ps')
        cocotb.start_soon(s2_axis_clk.start(start_high=False))
        s3_axis_clk = Clock(self.dut.s3_axis_aclk, self.S_AXIS_CLK_PERIOD, units='ps')
        cocotb.start_soon(s3_axis_clk.start(start_high=False))
        s4_axis_clk = Clock(self.dut.s4_axis_aclk, self.S_AXIS_CLK_PERIOD, units='ps')
        cocotb.start_soon(s4_axis_clk.start(start_high=False))

        M_AXIS_CLK_PERIOD = int(1000000/int(dut.g_AXIS_OUTPUT_FREQUENCY_MHZ))
        M_AXIS_CLK_PERIOD = 10 * int(round(M_AXIS_CLK_PERIOD/10))  # in case the last digit is not odd
        m_axis_clk = Clock(self.dut.m_axis_aclk, M_AXIS_CLK_PERIOD, units='ps')
        cocotb.start_soon(m_axis_clk.start(start_high=False))
        
        self.AXIL_CLK_PERIOD = 10000
        axil_clk = Clock(self.dut.axi_aclk, self.AXIL_CLK_PERIOD, units='ps')
        cocotb.start_soon(axil_clk.start(start_high=False))

        INTERLEAVING_CLK_PERIOD = int(1000000/int(dut.g_INTERLEAVING_FREQUENCY_MHZ))
        INTERLEAVING_CLK_PERIOD = 10 * int(round(INTERLEAVING_CLK_PERIOD/10))  # in case the last digit is not odd
        interleaving_clk = Clock(self.dut.interleaving_aclk, INTERLEAVING_CLK_PERIOD, units='ps')
        cocotb.start_soon(interleaving_clk.start(start_high=False))
    
        # AXI stream drivers
        self.axis_source_0 = AxiStreamSource(AxiStreamBus.from_prefix(self.dut, "s0_axis"), self.dut.s0_axis_aclk, self.dut.s0_axis_aresetn, reset_active_level=False, byte_size = 8)
        self.axis_source_1 = AxiStreamSource(AxiStreamBus.from_prefix(self.dut, "s1_axis"), self.dut.s1_axis_aclk, self.dut.s1_axis_aresetn, reset_active_level=False, byte_size = 8)
        self.axis_source_2 = AxiStreamSource(AxiStreamBus.from_prefix(self.dut, "s2_axis"), self.dut.s2_axis_aclk, self.dut.s2_axis_aresetn, reset_active_level=False, byte_size = 8)
        self.axis_source_3 = AxiStreamSource(AxiStreamBus.from_prefix(self.dut, "s3_axis"), self.dut.s3_axis_aclk, self.dut.s3_axis_aresetn, reset_active_level=False, byte_size = 8)
        self.axis_source_4 = AxiStreamSource(AxiStreamBus.from_prefix(self.dut, "s4_axis"), self.dut.s4_axis_aclk, self.dut.s4_axis_aresetn, reset_active_level=False, byte_size = 8)
        self.axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(self.dut, "m_axis"), self.dut.m_axis_aclk, self.dut.m_axis_aresetn, reset_active_level=False, byte_size = 8)

        # AXI lite master driver
        self.axi_lite_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"), dut.axi_aclk, dut.axi_aresetn, reset_active_level=False)

    async def s0_axis_reset(self):        
        await RisingEdge(self.dut.s0_axis_aclk)
        self.dut.s0_axis_aresetn.value = 0
        await RisingEdge(self.dut.s0_axis_aclk)
        self.dut.s0_axis_aresetn.value = 1

    async def s1_axis_reset(self):        
        await RisingEdge(self.dut.s1_axis_aclk)
        self.dut.s1_axis_aresetn.value = 0
        await RisingEdge(self.dut.s1_axis_aclk)
        self.dut.s1_axis_aresetn.value = 1

    async def s2_axis_reset(self):        
        await RisingEdge(self.dut.s2_axis_aclk)
        self.dut.s2_axis_aresetn.value = 0
        await RisingEdge(self.dut.s2_axis_aclk)
        self.dut.s2_axis_aresetn.value = 1

    async def s3_axis_reset(self):        
        await RisingEdge(self.dut.s3_axis_aclk)
        self.dut.s3_axis_aresetn.value = 0
        await RisingEdge(self.dut.s3_axis_aclk)
        self.dut.s3_axis_aresetn.value = 1

    async def s4_axis_reset(self):        
        await RisingEdge(self.dut.s4_axis_aclk)
        self.dut.s4_axis_aresetn.value = 0
        await RisingEdge(self.dut.s4_axis_aclk)
        self.dut.s4_axis_aresetn.value = 1

    async def m_axis_reset(self):        
        await RisingEdge(self.dut.m_axis_aclk)
        self.dut.m_axis_aresetn.value = 0
        await RisingEdge(self.dut.m_axis_aclk)
        self.dut.m_axis_aresetn.value = 1

    async def axi_reset(self):        
        await RisingEdge(self.dut.axi_aclk)
        self.dut.axi_aresetn.value = 0
        await RisingEdge(self.dut.axi_aclk)
        self.dut.axi_aresetn.value = 1

    async def interleaving_reset(self):
        await RisingEdge(self.dut.interleaving_aclk)
        self.dut.interleaving_aresetn.value = 0
        await RisingEdge(self.dut.interleaving_aclk)
        self.dut.interleaving_aresetn.value = 1

    async def waiting_time_to_meet_throughput(self):
        packet_input_freq = int(1000000*int(self.dut.g_CH0_THROUGHPUT_MBPS)/int(self.dut.g_AXIS_TDATA_WIDTH))
        axis_input_freq = 1000000*int(self.dut.g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ)
        cycles_between_packets = int(round(axis_input_freq/packet_input_freq))
        axis_cycles_in_ns = int(round(self.S_AXIS_CLK_PERIOD/1000))
        await Timer(cycles_between_packets*axis_cycles_in_ns, units='ns')

    async def set_channel_status_inputs(self, value):
        await RisingEdge(self.dut.axi_aclk)
        self.dut.channel_status = value

    def compare(self, a, b):
        assert len(a) == len(b)
        self.dut._log.info("Input len %d" % (len(a)))
        self.dut._log.info("Expected input len %d" % (len(b)))
        for i in range(len(a)):
            assert a[i].hex() == b[i].hex()


#==============================================================================
# Testbenches
#==============================================================================
@cocotb.test(skip = False, stage = 1)
async def all_channel_status_ok(dut):
    """
        Data arrives to the inputs in the same rising edge.
        User control is disabled by default.
        All channel status inputs are set OK.
        Output is compare with the expected output.

        Note: This test doesnt support different throughputs at the inputs
    """

    # init dut
    tb = TB(dut)

    # reset
    await tb.axi_reset()
    await tb.s0_axis_reset()
    await tb.s1_axis_reset()
    await tb.s2_axis_reset()
    await tb.s3_axis_reset()
    await tb.s4_axis_reset()
    await tb.m_axis_reset()
    await tb.interleaving_reset()

    # set all channel status to OK
    await tb.set_channel_status_inputs(ENABLE_ALL_CHANNELS)

    # init data
    data = get_init_data(dut)
    channel_0 = data['channel_0']
    channel_1 = data['channel_1']
    channel_2 = data['channel_2']
    channel_3 = data['channel_3']
    channel_4 = data['channel_4']

    # one iteration with no user control
    # send streaming data to slave ports and read streaming data from master port
    output = []
    for j in range(CAPTURE_SIZE):
        start_trigger = cocotb.start_soon(tb.waiting_time_to_meet_throughput())        
        sdata_0 = channel_0[j]
        sdata_1 = channel_1[j]
        sdata_2 = channel_2[j]
        sdata_3 = channel_3[j]
        sdata_4 = channel_4[j]
        await tb.axis_source_0.send(bytes(sdata_0))
        await tb.axis_source_1.send(bytes(sdata_1))
        await tb.axis_source_2.send(bytes(sdata_2))
        await tb.axis_source_3.send(bytes(sdata_3))
        await tb.axis_source_4.send(bytes(sdata_4))

        for k in range(int(dut.g_CHANNELS_USED)):
            rdata = await tb.axis_sink.read() 
            output.append(bytes(rdata))

        await start_trigger
        start_trigger.kill()

    # compare
    expected_output = get_expected_output(data, int(dut.g_CHANNELS_USED))
    tb.compare(output, expected_output)
    await Timer(15*tb.AXIL_CLK_PERIOD, units='ps')
    

#==============================================================================
@cocotb.test(skip = False, stage = 2)
async def channel_one_status_ok(dut):
    """
        Data arrives to the inputs in the same rising edge.
        
        Block 1:
            User control is disabled by default.
            All channel status inputs are set OK.
            Output is compare with the expected output.

        Block 2:
            Channel status of channel one only is set to OK.
            Output is compare with the expected output.
            
        Block 3:
            All channel status inputs are set OK.
            Output is compare with the expected output.

        Note: This test doesnt support different throughputs at the inputs
    """

    # init dut
    tb = TB(dut)

    # reset
    await tb.axi_reset()
    await tb.s0_axis_reset()
    await tb.s1_axis_reset()
    await tb.s2_axis_reset()
    await tb.s3_axis_reset()
    await tb.s4_axis_reset()
    await tb.m_axis_reset()
    await tb.interleaving_reset()

    # set all channel status to OK
    await tb.set_channel_status_inputs(ENABLE_ALL_CHANNELS)

    # init data
    data = get_init_data(dut)
    channel_0 = data['channel_0']
    channel_1 = data['channel_1']
    channel_2 = data['channel_2']
    channel_3 = data['channel_3']
    channel_4 = data['channel_4']

    ## BLOCK 1
    # one iteration with no user control
    # send streaming data to slave ports and read streaming data from master port
    output = []
    for j in range(CAPTURE_SIZE):
        start_trigger = cocotb.start_soon(tb.waiting_time_to_meet_throughput())  
        sdata_0 = channel_0[j]
        sdata_1 = channel_1[j]
        sdata_2 = channel_2[j]
        sdata_3 = channel_3[j]
        sdata_4 = channel_4[j]
        await tb.axis_source_0.send(bytes(sdata_0))
        await tb.axis_source_1.send(bytes(sdata_1))
        await tb.axis_source_2.send(bytes(sdata_2))
        await tb.axis_source_3.send(bytes(sdata_3))
        await tb.axis_source_4.send(bytes(sdata_4))
        await tb.axis_source_0.wait()
        await tb.axis_source_1.wait()
        await tb.axis_source_2.wait()
        await tb.axis_source_3.wait()
        await tb.axis_source_4.wait()

        for k in range(int(dut.g_CHANNELS_USED)):
            rdata = await tb.axis_sink.read() 
            output.append(bytes(rdata))

        await start_trigger
        start_trigger.kill()

    # compare
    expected_output = get_expected_output(data, int(dut.g_CHANNELS_USED))
    tb.compare(output, expected_output)
    await Timer(15*tb.AXIL_CLK_PERIOD, units='ps')
    
    ## BLOCK 2
    # channel status 0: NOK; channel status 1: OK; channel status 2: NOK; channel status 3: NOK; channel status 4: NOK 
    await tb.set_channel_status_inputs(ENABLE_CHANNEL_1)
    
    # send streaming data to slave ports and read streaming data from master port
    output = []
    expected_output = []
    for j in range(CAPTURE_SIZE):
        start_trigger = cocotb.start_soon(tb.waiting_time_to_meet_throughput())    
        sdata_0 = channel_0[j]
        sdata_1 = channel_1[j]
        sdata_2 = channel_2[j]
        sdata_3 = channel_3[j]
        sdata_4 = channel_4[j]
        await tb.axis_source_0.send(bytes(sdata_0))
        await tb.axis_source_1.send(bytes(sdata_1))
        await tb.axis_source_2.send(bytes(sdata_2))
        await tb.axis_source_3.send(bytes(sdata_3))
        await tb.axis_source_4.send(bytes(sdata_4))
        await tb.axis_source_0.wait()
        await tb.axis_source_1.wait()
        await tb.axis_source_2.wait()
        await tb.axis_source_3.wait()
        await tb.axis_source_4.wait()

        rdata = await tb.axis_sink.read() 
        output.append(bytes(rdata))
        expected_output.append(sdata_1)

        await start_trigger
        start_trigger.kill()

    # compare
    tb.compare(output, expected_output)
    await Timer(15*tb.AXIL_CLK_PERIOD, units='ps')

    ## BLOCK 3
    # set all channel status to OK
    await tb.set_channel_status_inputs(ENABLE_ALL_CHANNELS)

    # one iteration with no user control
    # send streaming data to slave ports and read streaming data from master port
    output = []
    for j in range(CAPTURE_SIZE):
        start_trigger = cocotb.start_soon(tb.waiting_time_to_meet_throughput())    
        sdata_0 = channel_0[j]
        sdata_1 = channel_1[j]
        sdata_2 = channel_2[j]
        sdata_3 = channel_3[j]
        sdata_4 = channel_4[j]
        await tb.axis_source_0.send(bytes(sdata_0))
        await tb.axis_source_1.send(bytes(sdata_1))
        await tb.axis_source_2.send(bytes(sdata_2))
        await tb.axis_source_3.send(bytes(sdata_3))
        await tb.axis_source_4.send(bytes(sdata_4))
        await tb.axis_source_0.wait()
        await tb.axis_source_1.wait()
        await tb.axis_source_2.wait()
        await tb.axis_source_3.wait()
        await tb.axis_source_4.wait()

        for k in range(int(dut.g_CHANNELS_USED)):
            rdata = await tb.axis_sink.read() 
            output.append(bytes(rdata))

        await start_trigger
        start_trigger.kill()

    # compare
    expected_output = get_expected_output(data, int(dut.g_CHANNELS_USED))
    tb.compare(output, expected_output)
    await Timer(15*tb.AXIL_CLK_PERIOD, units='ps')


#==============================================================================
@cocotb.test(skip = False, stage = 3)
async def channels_zero_and_two_ok(dut):
    """
        Data arrives to the inputs in the same rising edge.
        
        Block 1:
            User control is disabled by default.
            All channel status inputs are set OK.
            Output is compare with the expected output.

        Block 2:
            Channel status of channel zero and two are set to OK.
            Output is compare with the expected output.
            
        Block 3:
            All channel status inputs are set OK.
            Output is compare with the expected output.

        Note: This test doesnt support different throughputs at the inputs
    """

    # init dut
    tb = TB(dut)

    # reset
    await tb.axi_reset()
    await tb.s0_axis_reset()
    await tb.s1_axis_reset()
    await tb.s2_axis_reset()
    await tb.s3_axis_reset()
    await tb.s4_axis_reset()
    await tb.m_axis_reset()
    await tb.interleaving_reset()
    
    # set all channel status to OK
    await tb.set_channel_status_inputs(ENABLE_ALL_CHANNELS)

    # init data
    data = get_init_data(dut)
    channel_0 = data['channel_0']
    channel_1 = data['channel_1']
    channel_2 = data['channel_2']
    channel_3 = data['channel_3']
    channel_4 = data['channel_4']

    ## BLOCK 1
    # one iteration with no user control
    # send streaming data to slave ports and read streaming data from master port
    output = []
    for j in range(CAPTURE_SIZE):
        start_trigger = cocotb.start_soon(tb.waiting_time_to_meet_throughput())    
        sdata_0 = channel_0[j]
        sdata_1 = channel_1[j]
        sdata_2 = channel_2[j]
        sdata_3 = channel_3[j]
        sdata_4 = channel_4[j]
        await tb.axis_source_0.send(bytes(sdata_0))
        await tb.axis_source_1.send(bytes(sdata_1))
        await tb.axis_source_2.send(bytes(sdata_2))
        await tb.axis_source_3.send(bytes(sdata_3))
        await tb.axis_source_4.send(bytes(sdata_4))
        await tb.axis_source_0.wait()
        await tb.axis_source_1.wait()
        await tb.axis_source_2.wait()
        await tb.axis_source_3.wait()
        await tb.axis_source_4.wait()

        for k in range(int(dut.g_CHANNELS_USED)):
            rdata = await tb.axis_sink.read() 
            output.append(bytes(rdata))

        await start_trigger
        start_trigger.kill()

    # compare
    expected_output = get_expected_output(data, int(dut.g_CHANNELS_USED))
    tb.compare(output, expected_output)
    await Timer(15*tb.AXIL_CLK_PERIOD, units='ps')
    
    ## BLOCK 2
    # channel status 0: OK; channel status 1: NOK; channel status 2: OK; channel status 3: NOK; channel status 4: NOK 
    await tb.set_channel_status_inputs(ENABLE_CHANNEL_0_AND_2)

    # send streaming data to slave ports and read streaming data from master port
    output = []
    expected_output = []
    for j in range(CAPTURE_SIZE):
        start_trigger = cocotb.start_soon(tb.waiting_time_to_meet_throughput())  
        sdata_0 = channel_0[j]
        sdata_1 = channel_1[j]
        sdata_2 = channel_2[j]
        sdata_3 = channel_3[j]
        sdata_4 = channel_4[j]
        await tb.axis_source_0.send(bytes(sdata_0))
        await tb.axis_source_1.send(bytes(sdata_1))
        await tb.axis_source_2.send(bytes(sdata_2))
        await tb.axis_source_3.send(bytes(sdata_3))
        await tb.axis_source_4.send(bytes(sdata_4))
        await tb.axis_source_0.wait()
        await tb.axis_source_1.wait()
        await tb.axis_source_2.wait()
        await tb.axis_source_3.wait()
        await tb.axis_source_4.wait()

        rdata = await tb.axis_sink.read() 
        output.append(bytes(rdata))
        expected_output.append(sdata_0)

        rdata = await tb.axis_sink.read() 
        output.append(bytes(rdata))
        expected_output.append(sdata_2)

        await start_trigger
        start_trigger.kill()

    # compare
    tb.compare(output, expected_output)
    await Timer(15*tb.AXIL_CLK_PERIOD, units='ps')

    ## BLOCK 3
    # set all channel status to OK
    await tb.set_channel_status_inputs(ENABLE_ALL_CHANNELS)

    # one iteration with no user control
    # send streaming data to slave ports and read streaming data from master port
    output = []
    for j in range(CAPTURE_SIZE):
        start_trigger = cocotb.start_soon(tb.waiting_time_to_meet_throughput())  
        sdata_0 = channel_0[j]
        sdata_1 = channel_1[j]
        sdata_2 = channel_2[j]
        sdata_3 = channel_3[j]
        sdata_4 = channel_4[j]
        await tb.axis_source_0.send(bytes(sdata_0))
        await tb.axis_source_1.send(bytes(sdata_1))
        await tb.axis_source_2.send(bytes(sdata_2))
        await tb.axis_source_3.send(bytes(sdata_3))
        await tb.axis_source_4.send(bytes(sdata_4))
        await tb.axis_source_0.wait()
        await tb.axis_source_1.wait()
        await tb.axis_source_2.wait()
        await tb.axis_source_3.wait()
        await tb.axis_source_4.wait()

        for k in range(int(dut.g_CHANNELS_USED)):
            rdata = await tb.axis_sink.read() 
            output.append(bytes(rdata))

        await start_trigger
        start_trigger.kill()

    # compare
    expected_output = get_expected_output(data, int(dut.g_CHANNELS_USED))
    tb.compare(output, expected_output)
    await Timer(15*tb.AXIL_CLK_PERIOD, units='ps')


@cocotb.test(skip = False, stage = 4)
async def all_channel_status_ok_tready(dut):
    """
        Data arrives to the inputs in the same rising edge.
        User control is disabled by default.
        All channel status inputs are set OK.
        Tready starts low, then high, then low, and ends high
        Output is compare with the expected output.

        Note: This test doesnt support different throughputs at the inputs
    """

    # init dut
    tb = TB(dut)

    # reset
    await tb.axi_reset()
    await tb.s0_axis_reset()
    await tb.s1_axis_reset()
    await tb.s2_axis_reset()
    await tb.s3_axis_reset()
    await tb.s4_axis_reset()
    await tb.m_axis_reset()
    await tb.interleaving_reset()

    # set all channel status to OK
    await tb.set_channel_status_inputs(ENABLE_ALL_CHANNELS)

    # init data
    data = get_init_data(dut)
    channel_0 = data['channel_0']
    channel_1 = data['channel_1']
    channel_2 = data['channel_2']
    channel_3 = data['channel_3']
    channel_4 = data['channel_4']

    # send streaming data to slave ports and read streaming data from master port
    tb.axis_sink.set_pause_generator([1])    
    for j in range(20):
        start_trigger = cocotb.start_soon(tb.waiting_time_to_meet_throughput())        
        sdata_0 = channel_0[j]
        sdata_1 = channel_1[j]
        sdata_2 = channel_2[j]
        sdata_3 = channel_3[j]
        sdata_4 = channel_4[j]
        await tb.axis_source_0.send(bytes(sdata_0))
        await tb.axis_source_1.send(bytes(sdata_1))
        await tb.axis_source_2.send(bytes(sdata_2))
        await tb.axis_source_3.send(bytes(sdata_3))
        await tb.axis_source_4.send(bytes(sdata_4))

        await start_trigger
        start_trigger.kill()

    await Timer(5*tb.AXIL_CLK_PERIOD, units='ps')
    
    # one iteration with no user control
    # send streaming data to slave ports and read streaming data from master port
    tb.axis_sink.set_pause_generator([0])
    await Timer(tb.AXIL_CLK_PERIOD, units='ps')
    output = []
    for j in range(10):
        start_trigger = cocotb.start_soon(tb.waiting_time_to_meet_throughput())        
        sdata_0 = channel_0[j]
        sdata_1 = channel_1[j]
        sdata_2 = channel_2[j]
        sdata_3 = channel_3[j]
        sdata_4 = channel_4[j]
        await tb.axis_source_0.send(bytes(sdata_0))
        await tb.axis_source_1.send(bytes(sdata_1))
        await tb.axis_source_2.send(bytes(sdata_2))
        await tb.axis_source_3.send(bytes(sdata_3))
        await tb.axis_source_4.send(bytes(sdata_4))

        for k in range(int(dut.g_CHANNELS_USED)):
            rdata = await tb.axis_sink.read() 
            output.append(bytes(rdata))

        await start_trigger
        start_trigger.kill()

    await Timer(5*tb.AXIL_CLK_PERIOD, units='ps')

    # send streaming data to slave ports and read streaming data from master port
    tb.axis_sink.set_pause_generator([1])    
    for j in range(10):
        start_trigger = cocotb.start_soon(tb.waiting_time_to_meet_throughput())        
        sdata_0 = channel_0[j]
        sdata_1 = channel_1[j]
        sdata_2 = channel_2[j]
        sdata_3 = channel_3[j]
        sdata_4 = channel_4[j]
        await tb.axis_source_0.send(bytes(sdata_0))
        await tb.axis_source_1.send(bytes(sdata_1))
        await tb.axis_source_2.send(bytes(sdata_2))
        await tb.axis_source_3.send(bytes(sdata_3))
        await tb.axis_source_4.send(bytes(sdata_4))

        await start_trigger
        start_trigger.kill()

    await Timer(5*tb.AXIL_CLK_PERIOD, units='ps')

    # send streaming data to slave ports and read streaming data from master port
    tb.axis_sink.set_pause_generator([0])
    await Timer(tb.AXIL_CLK_PERIOD, units='ps')
    for j in range(20):
        start_trigger = cocotb.start_soon(tb.waiting_time_to_meet_throughput())        
        sdata_0 = channel_0[j]
        sdata_1 = channel_1[j]
        sdata_2 = channel_2[j]
        sdata_3 = channel_3[j]
        sdata_4 = channel_4[j]
        await tb.axis_source_0.send(bytes(sdata_0))
        await tb.axis_source_1.send(bytes(sdata_1))
        await tb.axis_source_2.send(bytes(sdata_2))
        await tb.axis_source_3.send(bytes(sdata_3))
        await tb.axis_source_4.send(bytes(sdata_4))

        for k in range(int(dut.g_CHANNELS_USED)):
            rdata = await tb.axis_sink.read() 
            output.append(bytes(rdata))

        await start_trigger
        start_trigger.kill()

    # remove data received while tready was at low level
    expected_output = get_expected_output(data, int(dut.g_CHANNELS_USED))
    expected_output_first_tready_assert = expected_output[:10*int(dut.g_CHANNELS_USED)]
    expected_output_second_tready_assert = expected_output[:20*int(dut.g_CHANNELS_USED)]
    expected_output =  expected_output_first_tready_assert + expected_output_second_tready_assert

    # compare
    tb.compare(output, expected_output)
    await Timer(15*tb.AXIL_CLK_PERIOD, units='ps')