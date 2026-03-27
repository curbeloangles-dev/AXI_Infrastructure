from cocotb_test.simulator import run
import pytest
import os
import glob

dir = os.path.dirname(os.path.abspath(__file__))
sources_list = glob.glob(dir+"/../src/*.vhd")

@pytest.mark.skipif(os.getenv("SIM") == "questa", reason="")
def test_tlast_lite_ghdl():
    run(
        vhdl_sources=[os.path.join(dir,file)
            for file in sources_list],      # sources
        toplevel="tlastgen_top",            # top level HDL
        module="tlastgen_lite_tb",        # name of cocotb test module
        toplevel_lang="vhdl",
        compile_args=["--ieee=synopsys","--std=08"],
        sim_args=["--wave=wave.ghw"]
    )

@pytest.mark.parametrize("parameters", [ 
                            {"g_AXIS_TDATA_WIDTH": "16"},
                            {"g_AXIS_TDATA_WIDTH": "32"},
                            {"g_AXIS_TDATA_WIDTH": "64"},
                            {"g_AXIS_TDATA_WIDTH": "128"},
                            {"g_AXIS_TDATA_WIDTH": "256"},
                            ]) 
@pytest.mark.skipif(os.getenv("SIM") != "ghdl", reason="")
def test_tlast_full_ghdl(parameters):
    run(
        vhdl_sources=[os.path.join(dir,file)
            for file in sources_list],      # sources
        toplevel="tlastgen_top",            # top level HDL
        module="tlastgen_full_tb",          # name of cocotb test module
        toplevel_lang="vhdl",
        parameters=parameters,
        extra_env=parameters, 
        compile_args=["--ieee=synopsys","--std=08"],
        sim_build="sim_build/" + "_".join(("{}={}".format(*i) for i in parameters.items())),
        sim_args=["--wave=wave.ghw"]
    )