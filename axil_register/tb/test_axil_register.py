from cocotb_test.simulator import run
import pytest
import os
import glob

dir = os.path.dirname(os.path.abspath(__file__))
sources_list = glob.glob(dir+"/../src/*.vhd")
sources_list += glob.glob(dir+"/*.vhd")

@pytest.mark.skipif(os.getenv("SIM") != "ghdl", reason="")
@pytest.mark.parametrize("parameters", [
                                        {"AXI_DATA_WIDTH":"32","AXI_ADDR_WIDTH":"32", "REG_TYPE": "0"},
                                        {"AXI_DATA_WIDTH":"32","AXI_ADDR_WIDTH":"32", "REG_TYPE": "1"},
                            ])
def test_axil_register_tb_ghdl(parameters):
    run(
        vhdl_sources=[os.path.join(dir,file)
            for file in sources_list],          # sources
        toplevel="axil_register_top",           # top level HDL
        module="axil_register_tb",              # name of cocotb test module
        toplevel_lang="vhdl",
        compile_args=["--ieee=synopsys","--std=08"],
        parameters=parameters,
        extra_env=parameters 
    )