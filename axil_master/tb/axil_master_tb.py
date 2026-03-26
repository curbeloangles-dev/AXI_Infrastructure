# Libraries
# =============================================================================
import  cocotb
from    cocotb.triggers         import  Timer, RisingEdge
from    cocotb.result           import  TestFailure
from    cocotb.clock            import  Clock

# Constants
#==============================================================================
CLK_PERIOD = 10     # ns

c_AXI_OKAY = 0
c_AXI_ERROR = 3

DATA = [0x2A01C, 0x3FB21, 0xA001E]
ADDR = [0x400B0010, 0x400A00B0, 0x40035080]

# Functions
#==============================================================================
def check(dut, actual_value, expected_value):
    if int(actual_value) != int(expected_value):
        dut._log.info("Incorrect!")
        raise TestFailure("Read = 0x%08x, Expected = 0x%08x" % (int(actual_value), int(expected_value)))
    dut._log.info("Correct! Read = 0x%08x, Expected = 0x%08x" % (int(actual_value), int(expected_value))) 

# Test 1: Writing test
#==============================================================================
@cocotb.test(skip = False, stage = 1)
def axil_master_wr(dut):

    # Set clock
    axil_clk_100MHz = Clock(dut.m_axi_aclk, CLK_PERIOD, units='ns')
    cocotb.fork(axil_clk_100MHz.start(start_high=False))

    # Set initial values      
    dut.addr            <= 0
    dut.write_vld       <= 0
    dut.dataIn          <= 0       
    dut.read_vld        <= 0  
    dut.m_axi_awready 	<= 1  
    dut.m_axi_wready 	<= 1
    dut.m_axi_bresp  	<= c_AXI_OKAY  
    dut.m_axi_bvalid 	<= 0
    
    # Reset axi bus
    dut.m_axi_aresetn <= 0
    yield Timer(10*CLK_PERIOD, units='ns')
    dut.m_axi_aresetn <= 1
    yield Timer(10*CLK_PERIOD, units='ns')

    # Write AXI
    for i in range(len(DATA)):
        dut._log.info("Writing data 0x%08x at address 0x%08x" % (DATA[i], ADDR[i])) 
        yield RisingEdge(dut.m_axi_aclk)       
        dut.write_vld       <= 1
        dut.dataIn          <= DATA[i]   
        dut.addr            <= ADDR[i]
        yield RisingEdge(dut.m_axi_aclk)
        dut.write_vld       <= 0
        yield RisingEdge(dut.m_axi_wvalid)
        data_send = dut.m_axi_wdata
        yield Timer(1, units='us')
        yield RisingEdge(dut.m_axi_aclk)
        dut.m_axi_bvalid 	<= 1
        yield RisingEdge(dut.m_axi_aclk)
        dut.m_axi_bvalid 	<= 0
        check(dut, data_send, DATA[i])

    yield Timer(20, units='us')


# Test 2: Reading test
#==============================================================================
@cocotb.test(skip = False, stage = 2)
def axil_master_rd(dut):

    # Set clock
    axil_clk_100MHz = Clock(dut.m_axi_aclk, CLK_PERIOD, units='ns')
    cocotb.fork(axil_clk_100MHz.start(start_high=False))

    # Set initial values      
    dut.addr            <= 0
    dut.write_vld       <= 0
    dut.dataIn          <= 0       
    dut.read_vld        <= 0  
    dut.m_axi_arready 	<= 1  
    dut.m_axi_rvalid 	<= 0
    dut.m_axi_rdata 	<= 0 
    
    # Reset axi bus
    dut.m_axi_aresetn <= 0
    yield Timer(10*CLK_PERIOD, units='ns')
    dut.m_axi_aresetn <= 1
    yield Timer(10*CLK_PERIOD, units='ns')

    # Read AXI
    for i in range(len(ADDR)):
        dut._log.info("Reading address 0x%08x" % (ADDR[i])) 
        yield RisingEdge(dut.m_axi_aclk)       
        dut.read_vld        <= 1
        dut.addr            <= ADDR[i]
        dut.m_axi_rvalid 	<= 1
        dut.m_axi_rdata 	<= DATA[i]
        yield RisingEdge(dut.m_axi_aclk)
        dut.read_vld        <= 0
        while(dut.m_axi_rready.value == 0):
            yield RisingEdge(dut.m_axi_aclk)
        dut.m_axi_rvalid 	<= 0
        while(dut.dataOut_vld.value == 1):
            yield RisingEdge(dut.m_axi_aclk)
        yield RisingEdge(dut.m_axi_aclk)
        check(dut, dut.dataOut, DATA[i])
        yield Timer(5*CLK_PERIOD, units='ns')

    yield Timer(50*CLK_PERIOD, units='ns')



# Test 2: Writing test with an error response
#==============================================================================
@cocotb.test(skip = False, stage = 3)
def axil_master_resp_error(dut):

    # Set clock
    axil_clk_100MHz = Clock(dut.m_axi_aclk, CLK_PERIOD, units='ns')
    cocotb.fork(axil_clk_100MHz.start(start_high=False))

    # Set initial values      
    dut.addr            <= 0
    dut.write_vld       <= 0
    dut.dataIn          <= 0       
    dut.read_vld        <= 0  
    dut.m_axi_awready 	<= 1  
    dut.m_axi_wready 	<= 1
    dut.m_axi_bresp  	<= c_AXI_ERROR  
    dut.m_axi_bvalid 	<= 0
    
    # Reset axi bus
    dut.m_axi_aresetn <= 0
    yield Timer(10*CLK_PERIOD, units='ns')
    dut.m_axi_aresetn <= 1
    yield Timer(10*CLK_PERIOD, units='ns')

    # Write AXI
    dut._log.info("Writing data 0x%08x at address 0x%08x" % (DATA[0], ADDR[0])) 
    yield RisingEdge(dut.m_axi_aclk)       
    dut.write_vld       <= 1
    dut.dataIn          <= DATA[0]   
    dut.addr            <= ADDR[0]
    yield RisingEdge(dut.m_axi_aclk)
    dut.write_vld       <= 0
    yield Timer(1, units='us')
    yield RisingEdge(dut.m_axi_aclk)
    dut.m_axi_bvalid 	<= 1
    yield RisingEdge(dut.m_axi_aclk)
    dut.m_axi_bvalid 	<= 0
    yield RisingEdge(dut.done)
    response = int(dut.write_result)
    check(dut, response, c_AXI_ERROR)

    yield Timer(20, units='us')