# Testbench description
# 
# This testbench looks for testing the interleaving behaviour and throughput
# when all slave axi stream inputs runs at the same clock and throughput.
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
CAPTURE_SIZE = 60               # multiple of 1, 2, 3, 4, and 5
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

# get data period
def cycles_between_data(tb, ch_throuhput):
    throughput_in_bps = 1000000*ch_throuhput
    data_freq = throughput_in_bps/int(tb.dut.g_AXIS_TDATA_WIDTH)
    data_period_ns = 1000000000000/data_freq
    cycles_btw_data = int(data_period_ns/tb.AXIL_CLK_PERIOD)
    return cycles_btw_data

async def start_sending_data_ch0(tb, channel_data, capture_size):
    global in_init_time_ch0, in_last_time_ch0
    cycles_btw_data = cycles_between_data(tb, int(tb.dut.g_CH0_THROUGHPUT_MBPS))
    time_btw_data_ps = cycles_btw_data*tb.AXIL_CLK_PERIOD-tb.AXIL_CLK_PERIOD
    rand_delay = random.randint(0, 100)
    await Timer(time=rand_delay, units='ns')
    for i in range(capture_size):
        channel_0 = channel_data[i]
        await tb.axis_source_0.send(bytes(channel_0))
        await tb.axis_source_0.wait()
        await Timer(time_btw_data_ps, units='ps')
        if i == 0:
            in_init_time_ch0 = cocotb.utils.get_sim_time('ns')
    in_last_time_ch0 = cocotb.utils.get_sim_time('ns')

async def start_sending_data_ch1(tb, channel_data, capture_size):
    global in_init_time_ch1, in_last_time_ch1, cycles_btw_data
    cycles_btw_data = cycles_between_data(tb, int(tb.dut.g_CH1_THROUGHPUT_MBPS))
    time_btw_data_ps = cycles_btw_data*tb.AXIL_CLK_PERIOD-tb.AXIL_CLK_PERIOD
    rand_delay = random.randint(0, 100)
    await Timer(time=rand_delay, units='ns')
    for i in range(capture_size):
        channel_1 = channel_data[i]
        await tb.axis_source_1.send(bytes(channel_1))
        await tb.axis_source_1.wait()
        await Timer(time_btw_data_ps, units='ps')
        if i == 0:
            in_init_time_ch1 = cocotb.utils.get_sim_time('ns')
    in_last_time_ch1 = cocotb.utils.get_sim_time('ns')

async def start_sending_data_ch2(tb, channel_data, capture_size):
    global in_init_time_ch2, in_last_time_ch2
    cycles_btw_data = cycles_between_data(tb, int(tb.dut.g_CH2_THROUGHPUT_MBPS))
    time_btw_data_ps = cycles_btw_data*tb.AXIL_CLK_PERIOD-tb.AXIL_CLK_PERIOD
    rand_delay = random.randint(0, 100)
    await Timer(time=rand_delay, units='ns')
    for i in range(capture_size):
        channel_2 = channel_data[i]
        await tb.axis_source_2.send(bytes(channel_2))
        await tb.axis_source_2.wait()
        await Timer(time=time_btw_data_ps, units='ps')
        if i == 0:
            in_init_time_ch2 = cocotb.utils.get_sim_time('ns')
    in_last_time_ch2 = cocotb.utils.get_sim_time('ns')

async def start_sending_data_ch3(tb, channel_data, capture_size):
    global in_init_time_ch3, in_last_time_ch3
    cycles_btw_data = cycles_between_data(tb, int(tb.dut.g_CH3_THROUGHPUT_MBPS))
    time_btw_data_ps = cycles_btw_data*tb.AXIL_CLK_PERIOD-tb.AXIL_CLK_PERIOD
    rand_delay = random.randint(0, 100)
    await Timer(time=rand_delay, units='ns')
    for i in range(capture_size):
        channel_3 = channel_data[i]
        await tb.axis_source_3.send(bytes(channel_3))
        await tb.axis_source_3.wait()
        await Timer(time=time_btw_data_ps, units='ps')
        if i == 0:
            in_init_time_ch3 = cocotb.utils.get_sim_time('ns')
    in_last_time_ch3 = cocotb.utils.get_sim_time('ns')

async def start_sending_data_ch4(tb, channel_data, capture_size):
    global in_init_time_ch4, in_last_time_ch4
    cycles_btw_data = cycles_between_data(tb, int(tb.dut.g_CH4_THROUGHPUT_MBPS))
    time_btw_data_ps = cycles_btw_data*tb.AXIL_CLK_PERIOD-tb.AXIL_CLK_PERIOD
    rand_delay = random.randint(0, 100)
    await Timer(time=rand_delay, units='ns')
    for i in range(capture_size):
        channel_4 = channel_data[i]
        await tb.axis_source_4.send(bytes(channel_4))
        await tb.axis_source_4.wait()
        await Timer(time=time_btw_data_ps, units='ps')
        if i == 0:
            in_init_time_ch4 = cocotb.utils.get_sim_time('ns')
    in_last_time_ch4 = cocotb.utils.get_sim_time('ns')

async def start_receiving_data_output(tb, capture_size, channels_used):
    global out_init_time, out_last_time, output
    output = []
    for i in range(capture_size):
        for j in range(channels_used):
            rdata = await tb.axis_sink.read() 
            output.append(bytes(rdata))
            tb.dut._log.info("Output number %d" % len(output))
            tb.dut._log.info("Data read is %s%s%s%s" % (hex(rdata[3]), hex(rdata[2])[2:], hex(rdata[1])[2:], hex(rdata[0])[2:]))
            if i == 0:
                out_init_time = cocotb.utils.get_sim_time('ns')
    out_last_time = cocotb.utils.get_sim_time('ns')


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
async def throughput(dut):
    """
        Data arrives to the inputs in different and random rising edges.
        User control is disabled by default.
        All channel status inputs are set OK.
        Throughput is calculated.
        Throughput obtained is compared with the expected.
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
    cocotb.start_soon(start_sending_data_ch0(tb, channel_0, CAPTURE_SIZE))
    cocotb.start_soon(start_sending_data_ch1(tb, channel_1, CAPTURE_SIZE))
    cocotb.start_soon(start_sending_data_ch2(tb, channel_2, CAPTURE_SIZE))
    cocotb.start_soon(start_sending_data_ch3(tb, channel_3, CAPTURE_SIZE))
    cocotb.start_soon(start_sending_data_ch4(tb, channel_4, CAPTURE_SIZE))
    receiving_data_output = cocotb.start_soon(start_receiving_data_output(tb, CAPTURE_SIZE, int(dut.g_CHANNELS_USED)))
    await receiving_data_output
    await Timer(15*tb.AXIL_CLK_PERIOD, units='ns')
    
    ## Test results
    cocotb.log.info("\n#######################################")
    cocotb.log.info("Test Results")
    cocotb.log.info("Channels in used: %d" % (dut.g_CHANNELS_USED))

    # bits
    cocotb.log.info("Total of bits:")
    cocotb.log.info("\tInput bits (channel 0): %i" % ((len(channel_0)*int(dut.g_AXIS_TDATA_WIDTH))))
    cocotb.log.info("\tInput bits (channel 1): %i" % ((len(channel_1)*int(dut.g_AXIS_TDATA_WIDTH))))
    cocotb.log.info("\tInput bits (channel 2): %i" % ((len(channel_2)*int(dut.g_AXIS_TDATA_WIDTH))))
    cocotb.log.info("\tInput bits (channel 3): %i" % ((len(channel_3)*int(dut.g_AXIS_TDATA_WIDTH))))
    cocotb.log.info("\tInput bits (channel 4): %i" % ((len(channel_4)*int(dut.g_AXIS_TDATA_WIDTH))))
    cocotb.log.info("\tOutput bits: %i" % ((len(output)*int(dut.g_AXIS_TDATA_WIDTH))))  

    # throughputs
    cocotb.log.info("Throughputs:")
    # check input throughput for channel 0
    in_throughput_0 = (len(channel_0)*int(dut.g_AXIS_TDATA_WIDTH))/((in_last_time_ch0-in_init_time_ch0)*10**-9)/10**6
    cocotb.log.info("\tInput Throughput (channel 0): %f Mbps" % (in_throughput_0))

    in_throughput_1 = 0
    if int(tb.dut.g_CHANNELS_USED) > 1:
        # check input throughput for channel 1
        in_throughput_1 = (len(channel_1)*int(dut.g_AXIS_TDATA_WIDTH))/((in_last_time_ch1-in_init_time_ch1)*10**-9)/10**6
        cocotb.log.info("\tInput Throughput (channel 1): %f Mbps" % (in_throughput_1))

    in_throughput_2 = 0
    if int(tb.dut.g_CHANNELS_USED) > 2:
        # check input throughput for channel 2
        in_throughput_2 = (len(channel_2)*int(dut.g_AXIS_TDATA_WIDTH))/((in_last_time_ch2-in_init_time_ch2)*10**-9)/10**6
        cocotb.log.info("\tInput Throughput (channel 2): %f Mbps" % (in_throughput_2))

    in_throughput_3 = 0
    if int(tb.dut.g_CHANNELS_USED) > 3:
        # check input throughput for channel 3
        in_throughput_3 = (len(channel_3)*int(dut.g_AXIS_TDATA_WIDTH))/((in_last_time_ch3-in_init_time_ch3)*10**-9)/10**6
        cocotb.log.info("\tInput Throughput (channel 3): %f Mbps" % (in_throughput_3))

    in_throughput_4 = 0
    if int(tb.dut.g_CHANNELS_USED) > 4:
        # check input throughput for channel 4
        in_throughput_4 = (len(channel_4)*int(dut.g_AXIS_TDATA_WIDTH))/((in_last_time_ch4-in_init_time_ch4)*10**-9)/10**6
        cocotb.log.info("\tInput Throughput (channel 4): %f Mbps" % (in_throughput_4))

    # check output throughput
    out_throughput = (len(output)*int(dut.g_AXIS_TDATA_WIDTH))/((out_last_time-out_init_time)*10**-9)/10**6
    cocotb.log.info("\tOutput Throughput: %f Mbps" % (out_throughput))

    throughput_acc = 0
    throughputs = [in_throughput_0, in_throughput_1, in_throughput_2, in_throughput_3, in_throughput_4]
    for i in range(int(dut.g_CHANNELS_USED)):
        throughput_acc = throughput_acc + throughputs[i]

    lower_limit = 0.95*(throughput_acc)
    higher_limit = 1.05*(throughput_acc)
    assert lower_limit <= out_throughput <= higher_limit, "Output throughput (%f Mbps) is out of bound (%f Mbps and %f Mbps)" % (out_throughput, lower_limit, higher_limit)