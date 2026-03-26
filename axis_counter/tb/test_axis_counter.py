from cocotb_test.simulator import run
import pytest
import os
import glob

dir = os.path.dirname(os.path.abspath(__file__))
sources_list = glob.glob(dir+"/../src/*.vhd")

#GHDL
@pytest.mark.skipif(os.getenv("SIM") != "ghdl", reason="")
@pytest.mark.parametrize("parameters", [ 
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "32"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "31"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "30"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "29"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "28"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "27"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "26"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "25"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "24"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "23"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "22"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "21"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "20"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "19"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "18"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "17"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "16"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "15"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "14"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "13"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "12"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "11"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "10"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "9"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "8"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "7"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "6"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "5"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "4"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "3"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "2"},
                            {"g_axil_addr_width": "32", "g_axis_data_width" : "32", "g_counter_width" : "1"}
                           
                            ]) 
def test_axis_counter_ghdl(parameters):
    run(
        vhdl_sources=[os.path.join(dir,file)
            for file in sources_list],         # sources
        toplevel="axis_counter",            # top level HDL
        module="axis_counter_tb",                  # name of cocotb test module
        toplevel_lang="vhdl",
        parameters=parameters,
        extra_env=parameters,
        compile_args=["--ieee=synopsys","--std=08"],
        sim_build="sim_build/" + "_".join(("{}_{}".format(*i) for i in parameters.items())),
        sim_args=["--wave=wave.ghw"]
    )