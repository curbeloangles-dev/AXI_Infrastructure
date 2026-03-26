
# Libraries
# =============================================================================
import cocotb
from cocotb.triggers         import  Timer, RisingEdge
from cocotb.clock            import  Clock
from cocotbext.axi import AxiLiteBus, AxiLiteMaster

######################################################

c_CLK_PERIOD = 10
c_VERSION_VALUE = 0x1

@cocotb.test(skip = False, stage = 1)
async def axil_register_test(dut):
    c_CORE_BASE_ADDR = 0x00000000

    saxi_aclk_100MHz = Clock(dut.S_ACLK, c_CLK_PERIOD, units='ns')
    cocotb.start_soon(saxi_aclk_100MHz.start(start_high=True))
    
    # AXI-Lite Master object
    axil_m = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axil"), dut.S_ACLK, dut.axi_aresetn, reset_active_level=False)

    # Reset core
    dut.axi_aresetn.value = 0 
    await Timer(5*c_CLK_PERIOD, units='ns')
    dut.axi_aresetn.value = 1
    await Timer(5*c_CLK_PERIOD, units='ns') 
    await RisingEdge(dut.S_ACLK)

    # AXI-Lite read VERSION
    dut._log.info("AXI-Lite: Reading")
    base_addr = c_CORE_BASE_ADDR
    dut._log.info("AXI-Lite: Reading address 0x%02X" % (base_addr))
    s_value_read = await axil_m.read(address = 0x0 + base_addr, length = 4)
    core_number = 1
    assert int.from_bytes(s_value_read.data, 'little') == core_number # Check the version. Each version core correspond to the core number.
    await Timer(5*c_CLK_PERIOD, units='ns')
    await RisingEdge(dut.S_ACLK)
    # dut._log.info("AXI-Lite: Reading address 0x%02X" % (0x0) + ". Value: 0x%02X" % (s_value_read))

    await Timer(5*c_CLK_PERIOD, units='ns')
    await RisingEdge(dut.S_ACLK)  

    # Axi write-read regs
    base_addr = c_CORE_BASE_ADDR
    s_value_read = await axil_m.read(address = base_addr+0x8,length = 4)
    assert int.from_bytes(s_value_read, 'little') == 0x0
    await axil_m.write(base_addr+0x4, bytearray([0x1]))
    busy = 1
    while busy == 1:
        busy = await axil_m.read(address = base_addr+0x8,length = 4)
        busy = (int.from_bytes(busy, 'little'))
        dut._log.info("AXI-Lite-> Busy signal: 0x%02X" % busy)
        await Timer(50*c_CLK_PERIOD, units='ns')
        await RisingEdge(dut.S_ACLK)
    await Timer(50*c_CLK_PERIOD, units='ns')  
    freq = await axil_m.read(address = base_addr+0xc,length = 4)

    dut._log.info("AXI-Lite-> s_value_read: 0x%08X" % int.from_bytes(freq, 'little'))
    assert int.from_bytes(freq, 'little') == 1250








