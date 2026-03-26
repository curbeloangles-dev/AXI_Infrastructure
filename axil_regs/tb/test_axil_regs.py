from cocotb_test.simulator import run
import pytest
import os
import glob

dir = os.path.dirname(os.path.abspath(__file__))
sources_list = glob.glob(dir+"/../src/*.vhd")

@pytest.mark.skipif(os.getenv("SIM") != "ghdl", reason="")
def test_axil_regs_tb_ghdl():
    run(
        vhdl_sources=[os.path.join(dir,file)
            for file in sources_list],       # sources
        toplevel="axil_regs",            # top level HDL
        module="axil_regs_tb",        # name of cocotb test module
        toplevel_lang="vhdl",
        compile_args=["--ieee=synopsys","--std=08"]
    )