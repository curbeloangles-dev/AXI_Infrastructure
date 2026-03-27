
import cocotb
import itertools
import random
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock
from cocotbext.axi import AxiStreamFrame, AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiLiteBus, AxiLiteMaster

###############################
###############################

c_CLK_PERIOD = 10
packetsCount  = 2

CONTROL_REG         = 0x4
TRANSFER_LENGTH_REG = 0x8
PACKET_LENGTH_REG   = 0xC

Enable_reg = 0x3

print_debug = 0

# ==============================================================================
class Frame:
    def __init__(self, tdata, tkeep):
        self.tdata = tdata
        self.tkeep = tkeep

# ==============================================================================
class TB(object):
    def __init__(self, dut):
        self.dut = dut
        self.data_width = int(self.dut.g_AXIS_TDATA_WIDTH) // 8

        axis_clk = Clock(dut.axis_aclk, c_CLK_PERIOD, units='ns')
        axi_clk  = Clock(dut.axi_aclk,  c_CLK_PERIOD, units='ns')
        cocotb.start_soon(axis_clk.start(start_high=False))
        cocotb.start_soon(axi_clk.start(start_high=False))

        self.axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"),   dut.axi_aclk,  dut.axi_aresetn,  reset_active_level=False)
        self.axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.axis_aclk, dut.axis_aresetn, reset_active_level=False)
        self.axis_sink   = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"),   dut.axis_aclk, dut.axis_aresetn, reset_active_level=False)

    async def reset(self):
        self.dut.axis_aresetn.setimmediatevalue(1)
        self.dut.axi_aresetn.setimmediatevalue(1)
        await RisingEdge(self.dut.axis_aclk)
        await RisingEdge(self.dut.axi_aclk)
        self.dut.axis_aresetn.value = 0
        self.dut.axi_aresetn.value  = 0
        await RisingEdge(self.dut.axis_aclk)
        await RisingEdge(self.dut.axi_aclk)
        self.dut.axis_aresetn.value = 1
        self.dut.axi_aresetn.value  = 1
        await RisingEdge(self.dut.axis_aclk)
        await RisingEdge(self.dut.axi_aclk)

    def insert_idle_list(self, cycle_list=None):
        if type(cycle_list) is not list:
            print("Cycle List needs to be a list")
        self.axis_source.set_pause_generator(itertools.cycle(cycle_list))

    def insert_backpressure_list(self, cycle_list=None):
        if type(cycle_list) is not list:
            print("Cycle List needs to be a list")
        self.axis_sink.set_pause_generator(itertools.cycle(cycle_list))

    def compare(self, a, b):
        assert len(a) == len(b)
        for i in range(len(a)):
            assert a[i] == b[i]

    def strip_invalid_bytes(self, tdata, tkeep):
        return [d for d, k in zip(tdata, tkeep) if k == 1]


# ==============================================================================
@cocotb.coroutine
async def receive_data(stream_sink, capture_size):
    """
    Read AXI-Stream frames from sink and return a list of Frame objects.
    """
    output = []
    for _ in range(capture_size):
        rframe = await stream_sink.recv(compact=False)
        frame_info = Frame(
            tdata=rframe.tdata,
            tkeep=rframe.tkeep if hasattr(rframe, 'tkeep') else None,
        )
        output.append(frame_info)
        await Timer(c_CLK_PERIOD, "ns")
    return output


@cocotb.coroutine
async def send_data(stream_source, data_list):
    """
    Send AXI-Stream frames defined inside data_list (AxiStreamFrame objects).
    """
    for data in data_list:
        frame = AxiStreamFrame(data.tdata)
        if hasattr(data, "tkeep") and data.tkeep is not None:
            frame.tkeep = data.tkeep
        await stream_source.send(frame)


def generate_frames(data_width, transfer_bytes, num_frames):
    """Generate num_frames AxiStreamFrame objects with transfer_bytes valid bytes each."""
    stream_frames = []
    for _ in range(num_frames):
        frame_data  = []
        frame_tkeep = []
        tkeep_count = 0
        while tkeep_count < transfer_bytes:
            bytes_remaining = transfer_bytes - tkeep_count
            if bytes_remaining > data_width:
                bytes_remaining = data_width
            tdata_chunk = [random.randint(0, 255) for _ in range(data_width)]
            frame_data.extend(tdata_chunk)
            tkeep_mask  = [1] * bytes_remaining + [0] * (data_width - bytes_remaining)
            tkeep_chunk = [random.randint(0, 1) & mask for mask in tkeep_mask[:bytes_remaining]] + [0] * (data_width - bytes_remaining)
            frame_tkeep.extend(tkeep_chunk)
            tkeep_count += sum(tkeep_chunk)
        stream_frames.append(AxiStreamFrame(frame_data, tkeep=frame_tkeep))
    return stream_frames


# ==============================================================================
@cocotb.coroutine
async def check_busy_signal(dut):
    await RisingEdge(dut.axi_aclk)
    while True:
        await RisingEdge(dut.axi_aclk)

        # IDLE State coded as 00 = 0
        if int(dut.tlastgen_inst.fsm_state.value) != 0:
            assert dut.tlastgen_inst.tlast_gen_busy_o.value == 1

        # RUNNING RUNNING_LOOP State coded other than 00
        else:
            assert dut.tlastgen_inst.tlast_gen_busy_o.value == 0


@cocotb.test(skip=False, stage=1, timeout_time=1, timeout_unit='ms')
async def tlastGen_test(dut):
    tb = TB(dut)
    await tb.reset()

    num_clocks = 100
    t_valid_clocks = [random.choice(range(2)) for _ in range(num_clocks)]
    tb.insert_idle_list(t_valid_clocks)

    tlast_gen_transfer_bytes = random.randint(1, 512)
    num_frames = 1

    s_value_read = await tb.axil_master.read(0x0, 4)
    dut._log.info("AXI-Lite: Reading address 0x%02X. Value: 0x%02X" % (0x0, int.from_bytes(s_value_read, 'little')))

    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4, 'little'))
    await tb.axil_master.write(PACKET_LENGTH_REG,   (num_frames).to_bytes(4, 'little'))
    await tb.axil_master.write(CONTROL_REG,          bytearray([Enable_reg]))

    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(100 * c_CLK_PERIOD, units='ns')


@cocotb.test(skip=False, stage=1, timeout_time=1, timeout_unit='ms')
async def tlastGen_packets(dut):
    tb = TB(dut)
    await tb.reset()

    num_clocks = 100
    t_valid_clocks = [random.choice(range(2)) for _ in range(num_clocks)]
    tb.insert_idle_list(t_valid_clocks)

    tlast_gen_transfer_bytes = random.randint(1, 512)
    num_frames = 4

    s_value_read = await tb.axil_master.read(0x0, 4)
    dut._log.info("AXI-Lite: Reading address 0x%02X. Value: 0x%02X" % (0x0, int.from_bytes(s_value_read, 'little')))

    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4, 'little'))
    await tb.axil_master.write(PACKET_LENGTH_REG,   (num_frames).to_bytes(4, 'little'))
    await tb.axil_master.write(CONTROL_REG,          bytearray([Enable_reg]))

    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(100 * c_CLK_PERIOD, units='ns')


@cocotb.test(skip=False, stage=1, timeout_time=1, timeout_unit='ms')
async def tlastGen_continuous(dut):
    tb = TB(dut)
    await tb.reset()

    num_clocks = 100
    t_valid_clocks = [random.choice(range(2)) for _ in range(num_clocks)]
    tb.insert_idle_list(t_valid_clocks)

    tlast_gen_transfer_bytes = random.randint(1, 512)
    num_frames  = packetsCount
    packet_num  = 0  # 0 = loop mode

    s_value_read = await tb.axil_master.read(0x0, 4)
    dut._log.info("AXI-Lite: Reading address 0x%02X. Value: 0x%02X" % (0x0, int.from_bytes(s_value_read, 'little')))

    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4, 'little'))
    await tb.axil_master.write(PACKET_LENGTH_REG,   (packet_num).to_bytes(4, 'little'))
    await tb.axil_master.write(CONTROL_REG,          bytearray([Enable_reg]))

    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(100 * c_CLK_PERIOD, units='ns')


@cocotb.test(skip=False, stage=1, timeout_time=1, timeout_unit='ms')
async def tlastGen_continuous_tready0(dut):
    tb = TB(dut)
    await tb.reset()

    # Source starvation (random tvalid)
    num_clocks = 100
    t_valid_clocks = [random.choice(range(2)) for _ in range(num_clocks)]
    tb.insert_idle_list(t_valid_clocks)

    # No sink backpressure (tready always asserted)

    tlast_gen_transfer_bytes = random.randint(1, 512)
    num_frames = packetsCount
    packet_num = 0  # loop mode

    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4, 'little'))
    await tb.axil_master.write(PACKET_LENGTH_REG,   (packet_num).to_bytes(4, 'little'))
    await tb.axil_master.write(CONTROL_REG,          bytearray([Enable_reg]))

    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(100 * c_CLK_PERIOD, units='ns')


@cocotb.test(skip=False, stage=1, timeout_time=1, timeout_unit='ms')
async def tlastGen_continuous_tready1(dut):
    tb = TB(dut)
    await tb.reset()

    # Source starvation
    num_clocks = 100
    t_valid_clocks = [random.choice(range(2)) for _ in range(num_clocks)]
    tb.insert_idle_list(t_valid_clocks)

    # Sink backpressure: 1 cycle down, 2 cycles up
    num_clocks_down = 1
    num_clocks_up   = 2
    t_ready_clocks  = [1] * num_clocks_down + [0] * num_clocks_up
    tb.insert_backpressure_list(t_ready_clocks)

    tlast_gen_transfer_bytes = random.randint(1, 512)
    num_frames = packetsCount
    packet_num = 0  # loop mode

    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4, 'little'))
    await tb.axil_master.write(PACKET_LENGTH_REG,   (packet_num).to_bytes(4, 'little'))
    await tb.axil_master.write(CONTROL_REG,          bytearray([Enable_reg]))

    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(100 * c_CLK_PERIOD, units='ns')


@cocotb.test(skip=False, stage=1, timeout_time=1, timeout_unit='ms')
async def tlastGen_start_stop(dut):
    tb = TB(dut)
    await tb.reset()

    num_clocks = 100
    t_valid_clocks = [random.choice(range(2)) for _ in range(num_clocks)]
    tb.insert_idle_list(t_valid_clocks)

    tlast_gen_transfer_bytes = random.randint(1, 512)
    num_frames = 1

    s_value_read = await tb.axil_master.read(0x0, 4)
    dut._log.info("AXI-Lite: Reading address 0x%02X. Value: 0x%02X" % (0x0, int.from_bytes(s_value_read, 'little')))

    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4, 'little'))
    await tb.axil_master.write(PACKET_LENGTH_REG,   (num_frames).to_bytes(4, 'little'))
    await tb.axil_master.write(CONTROL_REG,          bytearray([Enable_reg]))

    # First transfer
    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(20 * c_CLK_PERIOD, units='ns')

    # Second transfer (restart)
    await tb.axil_master.write(CONTROL_REG, bytearray([Enable_reg]))

    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(100 * c_CLK_PERIOD, units='ns')


@cocotb.test(skip=False, stage=1, timeout_time=1, timeout_unit='ms')
async def tlastGen_start_stop_tready0(dut):
    tb = TB(dut)
    await tb.reset()

    num_clocks = 100
    t_valid_clocks = [random.choice(range(2)) for _ in range(num_clocks)]
    tb.insert_idle_list(t_valid_clocks)
    # No sink backpressure

    tlast_gen_transfer_bytes = random.randint(1, 512)
    num_frames = 1

    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4, 'little'))
    await tb.axil_master.write(PACKET_LENGTH_REG,   (num_frames).to_bytes(4, 'little'))
    await tb.axil_master.write(CONTROL_REG,          bytearray([Enable_reg]))

    # First transfer
    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(20 * c_CLK_PERIOD, units='ns')

    # Second transfer (restart)
    await tb.axil_master.write(CONTROL_REG, bytearray([Enable_reg]))

    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(100 * c_CLK_PERIOD, units='ns')


@cocotb.test(skip=False, stage=1, timeout_time=1, timeout_unit='ms')
async def tlastGen_start_stop_tready1(dut):
    tb = TB(dut)
    await tb.reset()

    num_clocks = 100
    t_valid_clocks = [random.choice(range(2)) for _ in range(num_clocks)]
    tb.insert_idle_list(t_valid_clocks)

    # Sink backpressure: 1 cycle down, 2 cycles up
    num_clocks_down = 1
    num_clocks_up   = 2
    t_ready_clocks  = [1] * num_clocks_down + [0] * num_clocks_up
    tb.insert_backpressure_list(t_ready_clocks)

    tlast_gen_transfer_bytes = random.randint(1, 512)
    num_frames = 1

    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4, 'little'))
    await tb.axil_master.write(PACKET_LENGTH_REG,   (num_frames).to_bytes(4, 'little'))
    await tb.axil_master.write(CONTROL_REG,          bytearray([Enable_reg]))

    # First transfer
    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(20 * c_CLK_PERIOD, units='ns')

    # Second transfer (restart)
    await tb.axil_master.write(CONTROL_REG, bytearray([Enable_reg]))

    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(100 * c_CLK_PERIOD, units='ns')


@cocotb.test(skip=False, stage=1, timeout_time=1, timeout_unit='ms')
async def tlastGen_start_stop_tready1_tvalid1(dut):
    tb = TB(dut)
    await tb.reset()

    # No source starvation (tvalid always asserted)

    # Sink backpressure: 2 cycles down, 2 cycles up
    num_clocks_down = 2
    num_clocks_up   = 2
    t_ready_clocks  = [1] * num_clocks_down + [0] * num_clocks_up
    tb.insert_backpressure_list(t_ready_clocks)

    tlast_gen_transfer_bytes = random.randint(1, 512)
    num_frames = 1

    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4, 'little'))
    await tb.axil_master.write(PACKET_LENGTH_REG,   (num_frames).to_bytes(4, 'little'))
    await tb.axil_master.write(CONTROL_REG,          bytearray([Enable_reg]))

    # First transfer
    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(20 * c_CLK_PERIOD, units='ns')

    # Second transfer (restart)
    await tb.axil_master.write(CONTROL_REG, bytearray([Enable_reg]))

    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(100 * c_CLK_PERIOD, units='ns')


@cocotb.test(skip=False, stage=1, timeout_time=1, timeout_unit='ms')
async def tlastGen_start_stop_single_data(dut):
    tb = TB(dut)
    await tb.reset()

    # No source starvation, no backpressure

    tlast_gen_transfer_bytes = tb.data_width  # Single beat
    num_frames = 1

    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4, 'little'))
    await tb.axil_master.write(PACKET_LENGTH_REG,   (num_frames).to_bytes(4, 'little'))
    await tb.axil_master.write(CONTROL_REG,          bytearray([Enable_reg]))

    # First transfer
    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(20 * c_CLK_PERIOD, units='ns')

    # Second transfer (restart)
    await tb.axil_master.write(CONTROL_REG, bytearray([Enable_reg]))

    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(100 * c_CLK_PERIOD, units='ns')


@cocotb.test(skip=False, stage=1, timeout_time=1, timeout_unit='ms')
async def tlastGen_busy_output_test(dut):
    tb = TB(dut)
    await tb.reset()

    num_clocks = 100
    t_valid_clocks = [random.choice(range(2)) for _ in range(num_clocks)]
    tb.insert_idle_list(t_valid_clocks)

    cocotb.start_soon(check_busy_signal(dut))

    tlast_gen_transfer_bytes = random.randint(1, 512)
    num_frames = 4

    s_value_read = await tb.axil_master.read(0x0, 4)
    dut._log.info("AXI-Lite: Reading address 0x%02X. Value: 0x%02X" % (0x0, int.from_bytes(s_value_read, 'little')))

    await tb.axil_master.write(TRANSFER_LENGTH_REG, (tlast_gen_transfer_bytes).to_bytes(4, 'little'))
    await tb.axil_master.write(PACKET_LENGTH_REG,   (num_frames).to_bytes(4, 'little'))
    await tb.axil_master.write(CONTROL_REG,          bytearray([Enable_reg]))

    stream_frames = generate_frames(tb.data_width, tlast_gen_transfer_bytes, num_frames)
    cocotb.start_soon(send_data(tb.axis_source, stream_frames))
    recv_task  = cocotb.start_soon(receive_data(tb.axis_sink, num_frames))
    dut_output = await recv_task.join()

    for i in range(num_frames):
        tb.compare(
            tb.strip_invalid_bytes(dut_output[i].tdata,   dut_output[i].tkeep),
            tb.strip_invalid_bytes(stream_frames[i].tdata, stream_frames[i].tkeep),
        )

    await Timer(100 * c_CLK_PERIOD, units='ns')
