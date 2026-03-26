# Libraries
# =============================================================================
from cocotb_test.simulator import run
import os
import cocotb
import logging
import random
from cocotb.triggers         import  Timer, RisingEdge
from cocotb.result           import  TestFailure
from cocotb.clock            import  Clock
from cocotbext.axi import AxiStreamBus
from cocotbext.axi import AxiStreamSink
from cocotbext.axi import AxiLiteBus, AxiLiteMaster

# Constants
#==============================================================================
CLK_PERIOD = 10     # ns

#==============================================================================
# Register Map

# ADDR 0X0 :
#    --------------------------------------------------
#    |spare(29) | up_down (1) | resetn(1) | start (1) |
#    --------------------------------------------------
#    up_down = 1 -> Count up
#    up_down = 0 -> Count down

# ADDR 0X4 :
#    ---------------
#    |step_size(32)|
#    ---------------

def generate_config(size,order,init_value):
    step = random.randint(1,size - 1)
    result_size = random.randint(10,100)
    expected_capture = []
    for i in range(result_size):
        if order == 1:
            expected_capture.append((int(init_value) + step*i)%size)
        else:
            expected_capture.append((int(init_value) - step*i)%size)
    expected_capture = expected_capture[1:]
    return expected_capture,step


class TB(object):
    def __init__(self, dut):
        self.dut = dut
        log = logging.getLogger("cocotb.tb")
        self.g_axil_addr_width = int(dut.g_axil_addr_width.value)
        self.g_axis_data_width = int(dut.g_axis_data_width)

        # Set clock
        axis_clk_100MHz = Clock(self.dut.axi_aclk, CLK_PERIOD, units='ns')
        cocotb.start_soon(axis_clk_100MHz.start(start_high=True))

        # Set 0 all ready inputs
        dut.m_axis_tready.value = 0

        self.axil_m = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"), dut.axi_aclk, dut.axi_aresetn, reset_active_level=False)
        self.axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.axi_aclk, dut.axi_aresetn, reset_active_level=False, byte_size = 8)

    def check(self, actual_value, expected_value):
        if int(actual_value) != int(expected_value):
            self.dut._log.info("Incorrect!")
            raise TestFailure("Read = 0x%08x, Expected = 0x%08x" % (int(actual_value), int(expected_value)))
        self.dut._log.info("Correct! Read = 0x%08x, Expected = 0x%08x" % (int(actual_value), int(expected_value))) 
    
    async def set_step(self,step):
        await self.axil_m.write(0x04, step.to_bytes(4, byteorder='little'))
        await RisingEdge(self.dut.axi_aclk)
    
    async def set_control_reg(self,up_down,resetn,start):
        config_byte = (up_down << 2) | (resetn << 1) | start
        await self.axil_m.write(0x00, bytes([config_byte]))
        await RisingEdge(self.dut.axi_aclk)

#==============================================================================

@cocotb.test(skip=(os.getenv("TEST_NAME") not in ["reset_tb", "test_all"]), stage=1)
async def reset_tb(dut):
    tb = TB(dut)
    dut.axi_aresetn.value = 0
    await Timer(5*CLK_PERIOD, units='ns')
    dut.axi_aresetn.value = 1
    await tb.set_control_reg(1,0,0)

    await Timer(15*CLK_PERIOD, units='ns')

@cocotb.test(skip=(os.getenv("TEST_NAME") not in ["counter_down_tb", "test_all"]), stage=2)
async def counter_down_tb(dut):
    order = 0
    expected_capture,step = generate_config(pow(2,int(dut.g_counter_width)),order,0) # Generate random configuration
    capture = [0] * len(expected_capture)
    tb = TB(dut)
    dut.axi_aresetn.value = 0
    await Timer(5*CLK_PERIOD, units='ns')
    dut.axi_aresetn.value = 1
    await tb.set_control_reg(order,0,0) #apply reset to the counter
    await tb.set_step(step)
    await tb.set_control_reg(order,1,1)

    for i in range (len(expected_capture)):
        capture[i] = dut.m_axis_tdata
        tb.check(capture[i],expected_capture[i])
        await RisingEdge(tb.dut.axi_aclk)
    await Timer(15*CLK_PERIOD, units='ns')


@cocotb.test(skip=(os.getenv("TEST_NAME") not in ["counter_up_tb", "test_all"]), stage=3)
async def counter_up_tb(dut):
    
    order = 1
    expected_capture,step = generate_config(pow(2,int(dut.g_counter_width)),order,0) # Generate random configuration
    capture = [0] * len(expected_capture)
    tb = TB(dut)
    dut.axi_aresetn.value = 0
    await Timer(5*CLK_PERIOD, units='ns')
    dut.axi_aresetn.value = 1
    await tb.set_control_reg(order,0,0) #apply reset to the counter
    await tb.set_step(step)
    await tb.set_control_reg(order,1,1)

    for i in range (len(expected_capture)):
        capture[i] = dut.m_axis_tdata
        tb.check(capture[i],expected_capture[i])
        await RisingEdge(tb.dut.axi_aclk)
    await Timer(15*CLK_PERIOD, units='ns')

@cocotb.test(skip=(os.getenv("TEST_NAME") not in ["counter_start_and_stop_tb", "test_all"]), stage=3)
async def counter_start_and_stop(dut):
    tb = TB(dut)
    dut.axi_aresetn.value = 0
    await Timer(5*CLK_PERIOD, units='ns')
    dut.axi_aresetn.value = 1
    await tb.set_control_reg(1,0,0) #apply reset to the counter
    for i in range(random.randint(2,10)):
        order = random.randint(0,1) #Random order
        expected_capture,step = generate_config(pow(2,int(dut.g_counter_width)),order,dut.m_axis_tdata) # Generate random configuration
        capture = [0] * len(expected_capture)
        await tb.set_step(step)
        await tb.set_control_reg(order,1,1)
        dut._log.info("--------COUNT STARTED--------")

        for i in range (len(expected_capture)):
            capture[i] = dut.m_axis_tdata
            tb.check(capture[i],expected_capture[i])
            await RisingEdge(tb.dut.axi_aclk)
        await tb.set_control_reg(order,1,0)
        dut._log.info("--------COUNT STOPPED--------")

        await Timer(5*CLK_PERIOD, units='ns')
        
    await Timer(15*CLK_PERIOD, units='ns')
