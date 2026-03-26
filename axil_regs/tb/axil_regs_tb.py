import  cocotb
from    cocotb.triggers         import Timer, RisingEdge
from    cocotb.result           import TestFailure
from    cocotb.clock            import Clock
from    cocotb_bus.drivers.amba import AXI4LiteMaster, BinaryValue

# Constants
c_BASEADDRESS = 0x40000000
c_TOTAL_REGS = 64
c_CLK_PERIOD = 10 #ns

# ==============================================================================
async def gen_external_bvalid(dut):
    """
        Emulates external bvalid signal behavior
    """
    while True:
        # wait
        await Timer(1, units = 'us')
        # assert bvalid
        await RisingEdge(dut.axi_aclk)
        dut.external_bresp_vld.value = BinaryValue('1')  
        # deassert bvalid
        await RisingEdge(dut.axi_aclk)
        dut.external_bresp_vld.value = BinaryValue('0')   


def check(dut, act, exp):
    # Check
    if act != exp:
        raise TestFailure("Read = 0x%08X, Expected = 0x%08X" % (int(act), exp))
    dut._log.info("Correct!")

# ==============================================================================
@cocotb.test(skip = False, stage = 1)
def axil_regs_tb(dut):

    # Setting up clocks
    axi_aclk_100MHz = Clock(dut.axi_aclk, c_CLK_PERIOD, units='ns')
    cocotb.fork(axi_aclk_100MHz.start(start_high=False))

    # Set initial values
    # AXI Slave
    dut.s_axi_awaddr        <= 0
    dut.s_axi_awprot        <= 0
    dut.s_axi_awvalid       <= 0
    # AXI Write Data Channel 
    dut.s_axi_wdata         <= 0
    dut.s_axi_wstrb         <= 0
    dut.s_axi_wvalid        <= 0
    # AXI Read Address Channel
    dut.s_axi_araddr        <= 0
    dut.s_axi_arprot        <= 0
    dut.s_axi_arvalid       <= 0
    # AXI Read Data Channel
    dut.s_axi_rready        <= 1
    # AXI Write Response Channel
    dut.s_axi_bready        <= 1

    # Start bvalid generation
    dut.external_bresp_vld.value = BinaryValue('0')  
    dut.external_bresp.value = BinaryValue('00')  
    cocotb.start_soon(gen_external_bvalid(dut))   

    axil_m = AXI4LiteMaster(dut, "s_axi", dut.axi_aclk)

    # Reset axi bus
    dut.axi_aresetn <= 0
    yield Timer(20*c_CLK_PERIOD, units='ns')
    dut.axi_aresetn <= 1
    yield Timer(20*c_CLK_PERIOD, units='ns')

    # AXI-Lite write
    for i in range(c_TOTAL_REGS):
        dut._log.info("AXI-Lite: Writing 0x%02X at address 0x%02X" % (i, c_BASEADDRESS+(i*4)))
        yield axil_m.write(c_BASEADDRESS+(i*4), i)

    # AXI-Lite read
    for i in range(c_TOTAL_REGS):
        dut._log.info("AXI-Lite: Reading address 0x%02X" % (c_BASEADDRESS+(i*4)))
        s_value_read = yield axil_m.read(c_BASEADDRESS+(i*4))
        dut._log.info("REG [%i] = %i" % (int(i), int(s_value_read)))
        check(dut, s_value_read, int(i))
