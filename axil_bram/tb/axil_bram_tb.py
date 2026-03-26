import  cocotb
from    cocotb.triggers         import Timer
from    cocotb.clock            import Clock
from    cocotb_bus.drivers.amba import  AXI4LiteMaster

# Constants
c_BASEADDRESS = 0x40100000
c_MEM_OFFSET = 0x00000000
c_CLK_PERIOD = 10           #ns

# ==============================================================================
def check(act, exp):
    # Check
    assert act == exp, "Expected and actual data are not the same"

# ==============================================================================
@cocotb.test(skip = False, stage = 1)
def axil_bram(dut):
    # Setting up clocks
    axi_aclk_100MHz = Clock(dut.axi_aclk, c_CLK_PERIOD, units='ns')
    cocotb.fork(axi_aclk_100MHz.start(start_high=False))

    axil_m = AXI4LiteMaster(dut, "s_axi", dut.axi_aclk)
    # Reset axi bus
    dut.axi_aresetn <= 0
    yield Timer(20*c_CLK_PERIOD, units='ns')
    dut.axi_aresetn <= 1
    yield Timer(20*c_CLK_PERIOD, units='ns')

    # AXI-Lite write bram
    for bram_reg in range(dut.g_data_depth.value):
        dut._log.info("AXI-Lite: Writing 0x%02X at address 0x%02X" % (bram_reg, c_BASEADDRESS+c_MEM_OFFSET+(bram_reg*4)))
        yield axil_m.write(c_BASEADDRESS+c_MEM_OFFSET+(bram_reg*4), bram_reg)

    # AXI-Lite read bram 
    for bram_reg in range(dut.g_data_depth.value):
        dut._log.info("AXI-Lite: Reading address 0x%02X" % (c_BASEADDRESS+c_MEM_OFFSET+(bram_reg*4)))
        s_value_read = yield axil_m.read(c_BASEADDRESS+c_MEM_OFFSET+(bram_reg*4))
        dut._log.info("BRAM REG %i = %i" % (int(bram_reg),int(s_value_read)))
        check(s_value_read, int(bram_reg))
