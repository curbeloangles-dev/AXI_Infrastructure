import  cocotb
from    cocotb.triggers         import Timer
from    cocotb.clock            import Clock
from    cocotbext.axi import AxiLiteBus, AxiLiteMaster

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
async def axil_bram(dut):
    # Setting up clocks
    axi_aclk_100MHz = Clock(dut.axi_aclk, c_CLK_PERIOD, units='ns')
    cocotb.start_soon(axi_aclk_100MHz.start(start_high=False))

    # Reset axi bus
    dut.axi_aresetn.value = 0
    axil_m = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"), dut.axi_aclk, dut.axi_aresetn, reset_active_level=False)
    await Timer(20*c_CLK_PERIOD, units='ns')
    dut.axi_aresetn.value = 1
    await Timer(20*c_CLK_PERIOD, units='ns')

    # AXI-Lite write bram
    for bram_reg in range(dut.g_data_depth.value):
        dut._log.info("AXI-Lite: Writing 0x%02X at address 0x%02X" % (bram_reg, c_BASEADDRESS+c_MEM_OFFSET+(bram_reg*4)))
        await axil_m.write(c_BASEADDRESS+c_MEM_OFFSET+(bram_reg*4), bram_reg.to_bytes(4, 'little'))

    # AXI-Lite read bram
    for bram_reg in range(dut.g_data_depth.value):
        dut._log.info("AXI-Lite: Reading address 0x%02X" % (c_BASEADDRESS+c_MEM_OFFSET+(bram_reg*4)))
        s_value_read = await axil_m.read(address=c_BASEADDRESS+c_MEM_OFFSET+(bram_reg*4), length=4)
        dut._log.info("BRAM REG %i = %i" % (int(bram_reg), int.from_bytes(s_value_read, 'little')))
        check(int.from_bytes(s_value_read, 'little'), int(bram_reg))
