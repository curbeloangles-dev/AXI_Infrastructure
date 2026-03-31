from    cocotb_test.simulator import run
import  pytest
import  os
import  glob

dir = os.path.dirname(os.path.abspath(__file__))
interleaving_regs_pkg_src = glob.glob(dir + "/../src/axis_interleaving_regs_pkg.vhd")
interleaving_regs_src = glob.glob(dir + "/../src/axis_interleaving_regs.vhd")
interleaving_src = glob.glob(dir + "/../src/axis_interleaving.vhd")
interleaving_top_src = glob.glob(dir + "/../src/axis_interleaving_top.vhd")
axis_fifo = glob.glob(dir + "/../node_modules/@quside/axi_stream_fifo/axi_stream_fifo/src/*.vhd")
async_fifo = glob.glob(dir + "/../node_modules/@quside/axi_stream_fifo/axi_stream_fifo/src/async_fifo.vhd")
gray_cdc = glob.glob(dir + "/../node_modules/@quside/gray_cdc/gray_cdc/src/*.vhd")
bit_cdc = glob.glob(dir + "/../node_modules/@quside/bit_cdc/bit_cdc/src/*.vhd")
glbl_src = glob.glob(dir + "/glbl.v")

# testbench for registers
@pytest.mark.skipif(os.getenv("SIM") == "ghdl", reason="")
@pytest.mark.parametrize("parameters", [ 
                            {"g_AXIS_TDATA_WIDTH": "32",  "g_CHANNELS_USED" : "2"},
                            {"g_AXIS_TDATA_WIDTH": "64",  "g_CHANNELS_USED" : "3"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_CHANNELS_USED" : "4"},
                            {"g_AXIS_TDATA_WIDTH": "256", "g_CHANNELS_USED" : "5"},
                            ]) 
def test_registers(parameters):
    run(
        verilog_sources=[os.path.join(dir, file) for file in glbl_src],     # verilog sources
        vhdl_sources=[os.path.join(dir,file) for file in gray_cdc]          # vhdl sources
        +
            [os.path.join(dir,file) for file in bit_cdc]
        +
            [os.path.join(dir,file) for file in async_fifo]
        +
            [os.path.join(dir,file) for file in axis_fifo]
        +
            [os.path.join(dir,file) for file in interleaving_regs_pkg_src]
        +
            [os.path.join(dir,file) for file in interleaving_regs_src]
        +
            [os.path.join(dir,file) for file in interleaving_src]
        +
            [os.path.join(dir,file) for file in interleaving_top_src],
        toplevel="axis_interleaving_top",                                   # top level HDL
        module="tb_registers",                                              # name of cocotb test module
        parameters=parameters,
        extra_env=parameters, 
        sim_args=["-t", "1ps", "axis_interleaving_top.glbl"],
        force_compile=True
    )

# testbench for blocking threshold generic
@pytest.mark.skipif(os.getenv("SIM") == "ghdl", reason="")
@pytest.mark.parametrize("parameters", [ 
                            {"g_AXIS_TDATA_WIDTH": "32",  "g_BLOCKING_THRESHOLD" : "1", "g_CHANNELS_USED" : "2"},
                            {"g_AXIS_TDATA_WIDTH": "32",  "g_BLOCKING_THRESHOLD" : "2", "g_CHANNELS_USED" : "2"},
                            {"g_AXIS_TDATA_WIDTH": "32",  "g_BLOCKING_THRESHOLD" : "1", "g_CHANNELS_USED" : "3"},
                            {"g_AXIS_TDATA_WIDTH": "32",  "g_BLOCKING_THRESHOLD" : "2", "g_CHANNELS_USED" : "3"},
                            {"g_AXIS_TDATA_WIDTH": "32",  "g_BLOCKING_THRESHOLD" : "3", "g_CHANNELS_USED" : "3"},
                            {"g_AXIS_TDATA_WIDTH": "64",  "g_BLOCKING_THRESHOLD" : "1", "g_CHANNELS_USED" : "4"},
                            {"g_AXIS_TDATA_WIDTH": "64",  "g_BLOCKING_THRESHOLD" : "2", "g_CHANNELS_USED" : "4"},
                            {"g_AXIS_TDATA_WIDTH": "64",  "g_BLOCKING_THRESHOLD" : "3", "g_CHANNELS_USED" : "4"},
                            {"g_AXIS_TDATA_WIDTH": "64",  "g_BLOCKING_THRESHOLD" : "4", "g_CHANNELS_USED" : "4"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "1", "g_CHANNELS_USED" : "5"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "2", "g_CHANNELS_USED" : "5"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "3", "g_CHANNELS_USED" : "5"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "4", "g_CHANNELS_USED" : "5"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "5", "g_CHANNELS_USED" : "5"},
                            ]) 
def test_blocking_threshold(parameters):
    run(
        verilog_sources=[os.path.join(dir, file) for file in glbl_src],     # verilog sources
        vhdl_sources=[os.path.join(dir,file) for file in gray_cdc]          # vhdl sources
        +
            [os.path.join(dir,file) for file in bit_cdc]
        +
            [os.path.join(dir,file) for file in async_fifo]
        +
            [os.path.join(dir,file) for file in axis_fifo]
        +
            [os.path.join(dir,file) for file in interleaving_regs_pkg_src]
        +
            [os.path.join(dir,file) for file in interleaving_regs_src]
        +
            [os.path.join(dir,file) for file in interleaving_src]
        +
            [os.path.join(dir,file) for file in interleaving_top_src],
        toplevel="axis_interleaving_top",                                   # top level HDL
        module="tb_blocking_threshold",                                     # name of cocotb test module
        parameters=parameters,
        extra_env=parameters, 
        sim_args=["-t", "1ps", "axis_interleaving_top.glbl"],
        force_compile=True
    )

# testbench for channel status input
@pytest.mark.skipif(os.getenv("SIM") == "ghdl", reason="")
@pytest.mark.parametrize("parameters", [ 
                            {"g_AXIS_TDATA_WIDTH": "32",  "g_BLOCKING_THRESHOLD" : "3", "g_CHANNELS_USED" : "3"},
                            {"g_AXIS_TDATA_WIDTH": "64",  "g_BLOCKING_THRESHOLD" : "4", "g_CHANNELS_USED" : "4"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "5", "g_CHANNELS_USED" : "5"},
                            ]) 
def test_channel_status_input(parameters):
    run(
        verilog_sources=[os.path.join(dir, file) for file in glbl_src],     # verilog sources
        vhdl_sources=[os.path.join(dir,file) for file in gray_cdc]          # vhdl sources
        +
            [os.path.join(dir,file) for file in bit_cdc]
        +
            [os.path.join(dir,file) for file in async_fifo]
        +
            [os.path.join(dir,file) for file in axis_fifo]
        +
            [os.path.join(dir,file) for file in interleaving_regs_pkg_src]
        +
            [os.path.join(dir,file) for file in interleaving_regs_src]
        +
            [os.path.join(dir,file) for file in interleaving_src]
        +
            [os.path.join(dir,file) for file in interleaving_top_src],
        toplevel="axis_interleaving_top",                                   # top level HDL
        module="tb_channel_status_input",                                   # name of cocotb test module
        parameters=parameters,
        extra_env=parameters, 
        sim_args=["-t", "1ps", "axis_interleaving_top.glbl"],
        force_compile=True
    )

# testbench for data arriving in different edges
@pytest.mark.skipif(os.getenv("SIM") == "ghdl", reason="")
@pytest.mark.parametrize("parameters", [ 
                            {"g_AXIS_TDATA_WIDTH": "32",  "g_BLOCKING_THRESHOLD" : "2", "g_CHANNELS_USED" : "2"},
                            {"g_AXIS_TDATA_WIDTH": "64",  "g_BLOCKING_THRESHOLD" : "3", "g_CHANNELS_USED" : "3"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "4", "g_CHANNELS_USED" : "4"},
                            {"g_AXIS_TDATA_WIDTH": "256", "g_BLOCKING_THRESHOLD" : "5", "g_CHANNELS_USED" : "5"},
                            ]) 
def test_data_different_edges(parameters):
    run(
        verilog_sources=[os.path.join(dir, file) for file in glbl_src],     # verilog sources
        vhdl_sources=[os.path.join(dir,file) for file in gray_cdc]          # vhdl sources
        +
            [os.path.join(dir,file) for file in bit_cdc]
        +
            [os.path.join(dir,file) for file in async_fifo]
        +
            [os.path.join(dir,file) for file in axis_fifo]
        +
            [os.path.join(dir,file) for file in interleaving_regs_pkg_src]
        +
            [os.path.join(dir,file) for file in interleaving_regs_src]
        +
            [os.path.join(dir,file) for file in interleaving_src]
        +
            [os.path.join(dir,file) for file in interleaving_top_src],
        toplevel="axis_interleaving_top",                                   # top level HDL
        module="tb_data_different_edges",                                   # name of cocotb test module
        parameters=parameters,
        extra_env=parameters, 
        sim_args=["-t", "1ps", "axis_interleaving_top.glbl"],
        force_compile=True
    )

# testbench to calculate core throughput
@pytest.mark.skipif(os.getenv("SIM") == "ghdl", reason="")
@pytest.mark.parametrize("parameters", [ 
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "5", "g_CHANNELS_USED" : "5", "g_CH0_THROUGHPUT_MBPS" : "800",  "g_CH1_THROUGHPUT_MBPS" : "800",  "g_CH2_THROUGHPUT_MBPS" : "800",  "g_CH3_THROUGHPUT_MBPS" : "800",  "g_CH4_THROUGHPUT_MBPS" : "800",  "g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ" : "100", "g_AXIS_OUTPUT_FREQUENCY_MHZ" : "200", "g_INTERLEAVING_FREQUENCY_MHZ" : "500"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "5", "g_CHANNELS_USED" : "5", "g_CH0_THROUGHPUT_MBPS" : "1000", "g_CH1_THROUGHPUT_MBPS" : "1000", "g_CH2_THROUGHPUT_MBPS" : "1000", "g_CH3_THROUGHPUT_MBPS" : "1000", "g_CH4_THROUGHPUT_MBPS" : "1000", "g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ" : "100", "g_AXIS_OUTPUT_FREQUENCY_MHZ" : "200", "g_INTERLEAVING_FREQUENCY_MHZ" : "500"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "3", "g_CHANNELS_USED" : "3", "g_CH0_THROUGHPUT_MBPS" : "800",  "g_CH1_THROUGHPUT_MBPS" : "800",  "g_CH2_THROUGHPUT_MBPS" : "800",  "g_CH3_THROUGHPUT_MBPS" : "800",  "g_CH4_THROUGHPUT_MBPS" : "800",  "g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ" : "100", "g_AXIS_OUTPUT_FREQUENCY_MHZ" : "100", "g_INTERLEAVING_FREQUENCY_MHZ" : "350"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "3", "g_CHANNELS_USED" : "3", "g_CH0_THROUGHPUT_MBPS" : "1000", "g_CH1_THROUGHPUT_MBPS" : "1000", "g_CH2_THROUGHPUT_MBPS" : "1000", "g_CH3_THROUGHPUT_MBPS" : "1000", "g_CH4_THROUGHPUT_MBPS" : "1000", "g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ" : "100", "g_AXIS_OUTPUT_FREQUENCY_MHZ" : "100", "g_INTERLEAVING_FREQUENCY_MHZ" : "350"},
                            ]) 
def test_m_axis_throughput(parameters):
    run(
        verilog_sources=[os.path.join(dir, file) for file in glbl_src],     # verilog sources
        vhdl_sources=[os.path.join(dir,file) for file in gray_cdc]          # vhdl sources
        +
            [os.path.join(dir,file) for file in bit_cdc]
        +
            [os.path.join(dir,file) for file in async_fifo]
        +
            [os.path.join(dir,file) for file in axis_fifo]
        +
            [os.path.join(dir,file) for file in interleaving_regs_pkg_src]
        +
            [os.path.join(dir,file) for file in interleaving_regs_src]
        +
            [os.path.join(dir,file) for file in interleaving_src]
        +
            [os.path.join(dir,file) for file in interleaving_top_src],
        toplevel="axis_interleaving_top",                                    # top level HDL
        module="tb_m_axis_throughput",                                       # name of cocotb test module
        parameters=parameters,
        extra_env=parameters, 
        sim_args=["-t", "1ps", "axis_interleaving_top.glbl"],
        force_compile=True
    )

# testbench for data arriving at different throughputs
@pytest.mark.skipif(os.getenv("SIM") == "ghdl", reason="")
@pytest.mark.parametrize("parameters", [ 
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "1", "g_CHANNELS_USED" : "2", "g_CH0_THROUGHPUT_MBPS" : "800",  "g_CH1_THROUGHPUT_MBPS" : "80",  "g_CH2_THROUGHPUT_MBPS" : "800",  "g_CH3_THROUGHPUT_MBPS" : "80",  "g_CH4_THROUGHPUT_MBPS" : "800",  "g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ" : "100", "g_AXIS_OUTPUT_FREQUENCY_MHZ" : "100", "g_INTERLEAVING_FREQUENCY_MHZ" : "200"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "1", "g_CHANNELS_USED" : "2", "g_CH0_THROUGHPUT_MBPS" : "1000", "g_CH1_THROUGHPUT_MBPS" : "200", "g_CH2_THROUGHPUT_MBPS" : "1000", "g_CH3_THROUGHPUT_MBPS" : "200", "g_CH4_THROUGHPUT_MBPS" : "1000", "g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ" : "100", "g_AXIS_OUTPUT_FREQUENCY_MHZ" : "100", "g_INTERLEAVING_FREQUENCY_MHZ" : "200"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "3", "g_CHANNELS_USED" : "3", "g_CH0_THROUGHPUT_MBPS" : "800",  "g_CH1_THROUGHPUT_MBPS" : "80",  "g_CH2_THROUGHPUT_MBPS" : "800",  "g_CH3_THROUGHPUT_MBPS" : "80",  "g_CH4_THROUGHPUT_MBPS" : "800",  "g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ" : "100", "g_AXIS_OUTPUT_FREQUENCY_MHZ" : "100", "g_INTERLEAVING_FREQUENCY_MHZ" : "350"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "3", "g_CHANNELS_USED" : "3", "g_CH0_THROUGHPUT_MBPS" : "1000", "g_CH1_THROUGHPUT_MBPS" : "100", "g_CH2_THROUGHPUT_MBPS" : "1000", "g_CH3_THROUGHPUT_MBPS" : "100", "g_CH4_THROUGHPUT_MBPS" : "1000", "g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ" : "100", "g_AXIS_OUTPUT_FREQUENCY_MHZ" : "100", "g_INTERLEAVING_FREQUENCY_MHZ" : "350"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "1", "g_CHANNELS_USED" : "2", "g_CH0_THROUGHPUT_MBPS" : "800",  "g_CH1_THROUGHPUT_MBPS" : "80",  "g_CH2_THROUGHPUT_MBPS" : "800",  "g_CH3_THROUGHPUT_MBPS" : "80",  "g_CH4_THROUGHPUT_MBPS" : "800",  "g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ" : "100", "g_AXIS_OUTPUT_FREQUENCY_MHZ" : "100", "g_INTERLEAVING_FREQUENCY_MHZ" : "500"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "1", "g_CHANNELS_USED" : "2", "g_CH0_THROUGHPUT_MBPS" : "1000", "g_CH1_THROUGHPUT_MBPS" : "200", "g_CH2_THROUGHPUT_MBPS" : "1000", "g_CH3_THROUGHPUT_MBPS" : "200", "g_CH4_THROUGHPUT_MBPS" : "1000", "g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ" : "100", "g_AXIS_OUTPUT_FREQUENCY_MHZ" : "100", "g_INTERLEAVING_FREQUENCY_MHZ" : "500"},
                            ]) 
def test_s_axis_throughputs(parameters):
    run(
        verilog_sources=[os.path.join(dir, file) for file in glbl_src],     # verilog sources
        vhdl_sources=[os.path.join(dir,file) for file in gray_cdc]          # vhdl sources
        +
            [os.path.join(dir,file) for file in bit_cdc]
        +
            [os.path.join(dir,file) for file in async_fifo]
        +
            [os.path.join(dir,file) for file in axis_fifo]
        +
            [os.path.join(dir,file) for file in interleaving_regs_pkg_src]
        +
            [os.path.join(dir,file) for file in interleaving_regs_src]
        +
            [os.path.join(dir,file) for file in interleaving_src]
        +
            [os.path.join(dir,file) for file in interleaving_top_src],
        toplevel="axis_interleaving_top",                                   # top level HDL
        module="tb_s_axis_throughputs",                                     # name of cocotb test module
        parameters=parameters,
        extra_env=parameters, 
        sim_args=["-t", "1ps", "axis_interleaving_top.glbl"],
        force_compile=True
    )

# testbench for data arriving at different throughputs and different frequencies
@pytest.mark.skipif(os.getenv("SIM") == "ghdl", reason="")
@pytest.mark.parametrize("parameters", [ 
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "1", "g_CHANNELS_USED" : "2", "g_CH0_THROUGHPUT_MBPS" : "800",  "g_CH1_THROUGHPUT_MBPS" : "80",  "g_CH2_THROUGHPUT_MBPS" : "800",  "g_CH3_THROUGHPUT_MBPS" : "80",  "g_CH4_THROUGHPUT_MBPS" : "800",  "g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ" : "100", "g_AXIS_OUTPUT_FREQUENCY_MHZ" : "100", "g_INTERLEAVING_FREQUENCY_MHZ" : "200"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "1", "g_CHANNELS_USED" : "2", "g_CH0_THROUGHPUT_MBPS" : "1000", "g_CH1_THROUGHPUT_MBPS" : "200", "g_CH2_THROUGHPUT_MBPS" : "1000", "g_CH3_THROUGHPUT_MBPS" : "200", "g_CH4_THROUGHPUT_MBPS" : "1000", "g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ" : "100", "g_AXIS_OUTPUT_FREQUENCY_MHZ" : "100", "g_INTERLEAVING_FREQUENCY_MHZ" : "200"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "3", "g_CHANNELS_USED" : "3", "g_CH0_THROUGHPUT_MBPS" : "800",  "g_CH1_THROUGHPUT_MBPS" : "80",  "g_CH2_THROUGHPUT_MBPS" : "800",  "g_CH3_THROUGHPUT_MBPS" : "80",  "g_CH4_THROUGHPUT_MBPS" : "800",  "g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ" : "100", "g_AXIS_OUTPUT_FREQUENCY_MHZ" : "100", "g_INTERLEAVING_FREQUENCY_MHZ" : "350"},
                            {"g_AXIS_TDATA_WIDTH": "128", "g_BLOCKING_THRESHOLD" : "3", "g_CHANNELS_USED" : "3", "g_CH0_THROUGHPUT_MBPS" : "1000", "g_CH1_THROUGHPUT_MBPS" : "100", "g_CH2_THROUGHPUT_MBPS" : "1000", "g_CH3_THROUGHPUT_MBPS" : "100", "g_CH4_THROUGHPUT_MBPS" : "1000", "g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ" : "100", "g_AXIS_OUTPUT_FREQUENCY_MHZ" : "100", "g_INTERLEAVING_FREQUENCY_MHZ" : "350"},
                            ]) 
def test_s_axis_different_clks(parameters):
    run(
        verilog_sources=[os.path.join(dir, file) for file in glbl_src],     # verilog sources
        vhdl_sources=[os.path.join(dir,file) for file in gray_cdc]          # vhdl sources
        +
            [os.path.join(dir,file) for file in bit_cdc]
        +
            [os.path.join(dir,file) for file in async_fifo]
        +
            [os.path.join(dir,file) for file in axis_fifo]
        +
            [os.path.join(dir,file) for file in interleaving_regs_pkg_src]
        +
            [os.path.join(dir,file) for file in interleaving_regs_src]
        +
            [os.path.join(dir,file) for file in interleaving_src]
        +
            [os.path.join(dir,file) for file in interleaving_top_src],
        toplevel="axis_interleaving_top",                                   # top level HDL
        module="tb_s_axis_different_clks",                                  # name of cocotb test module
        parameters=parameters,
        extra_env=parameters, 
        sim_args=["-t", "1ps", "axis_interleaving_top.glbl"],
        force_compile=True
    )