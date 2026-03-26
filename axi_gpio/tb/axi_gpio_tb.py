import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.result import TestFailure
from cocotb.clock import Clock
from cocotb_bus.drivers.amba import AXI4LiteMaster

# Constants
c_BASEADDRESS = 0x40000000
c_VERSION_OFFSET = 0x00000000
c_GPO_OFFSET = 0x00000004
c_GPI_OFFSET = 0x00000008
c_VERSION_VALUE = 0x00000001


c_CLK_PERIOD = 10 #ns
# ==============================================================================
def check(dut, act, exp):
    # Check
    if act != exp:
        raise TestFailure("Read = 0x%08X, Expected = 0x%08X" % (int(act), exp))

    dut._log.info("Correct!")
# ==============================================================================
@cocotb.test(skip = False, stage = 1)
def ad5592r_alive(dut):
    # Setting up clocks
    axi_aclk_100MHz = Clock(dut.axi_aclk, c_CLK_PERIOD, units='ns')
    cocotb.fork(axi_aclk_100MHz.start(start_high=False))

    # Setting init values
    dut.axi_aresetn <= 0
    dut.gpi <= 0
    # AXI-Lite Master object
    axil_m = AXI4LiteMaster(dut, "s_axi", dut.axi_aclk)
    # Wait one cycle and deactivate resets
    yield Timer(c_CLK_PERIOD, units='ns')
    dut.axi_aresetn <= 1

    # AXI-Lite read VERSION
    dut._log.info("AXI-Lite: Reading address 0x%02X" % (c_BASEADDRESS+c_VERSION_OFFSET))
    s_value_read = yield axil_m.read(c_BASEADDRESS+c_VERSION_OFFSET)
    # Check
    check(dut, s_value_read, c_VERSION_VALUE)

    # AXI-Lite write GPO
    gpo_value = 2147483649
    dut._log.info("AXI-Lite: Writing 0x%02X at address 0x%02X" % (gpo_value, c_BASEADDRESS+c_GPO_OFFSET))
    yield axil_m.write(c_BASEADDRESS+c_GPO_OFFSET, gpo_value)
    # Check GPO
    if int(dut.gpo) == gpo_value:
        dut._log.info("GPO: %i = GPO_REG: %i" % (int(dut.gpo), gpo_value))
    else:
        raise TestFailure("GPO: %i != GPO_REG: %i" % (int(dut.gpo), gpo_value))

    # Write GPI
    yield RisingEdge(dut.axi_aclk)
    gpi_value = 2147483649
    dut.gpi <= gpi_value
    yield Timer(5*c_CLK_PERIOD, units='ns')
    # AXI-Lite read GPI
    dut._log.info("AXI-Lite: Reading address 0x%02X" % (c_BASEADDRESS+c_GPI_OFFSET))
    s_value_read = yield axil_m.read(c_BASEADDRESS+c_GPI_OFFSET)
    # Check GPI
    if s_value_read == gpi_value:
        dut._log.info("GPI: %i = GPI_REG: %i" % (gpi_value, s_value_read))
    else:
        raise TestFailure("GPI: %i != GPI_REG: %i" % (gpi_value, s_value_read))





