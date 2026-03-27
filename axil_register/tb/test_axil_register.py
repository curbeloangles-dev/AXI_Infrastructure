from cocotb_test.simulator import run
import pytest
import os
import glob

dir = os.path.dirname(os.path.abspath(__file__))
sources_list = glob.glob(dir+"/../src/*.vhd")
sources_list += glob.glob(dir+"/*.vhd")

@pytest.mark.skipif(os.getenv("SIM") != "ghdl", reason="")
def test_axil_register_tb_ghdl():
    run(
        vhdl_sources=[os.path.join(dir,file)
            for file in sources_list],          # sources
        toplevel="axil_register_top_tb",         # top level HDL
        module="axil_register_tb",              # name of cocotb test module
        toplevel_lang="vhdl",
        compile_args=["--ieee=synopsys","--std=08"]
    )