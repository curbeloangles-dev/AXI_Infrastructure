from    cocotb_test.simulator   import run
import  pytest
import  os
import  glob

dir = os.path.dirname(__file__)
bram = glob.glob("../src/*.vhd")

@pytest.mark.skipif(os.getenv("SIM") != "ghdl", reason="")
def test_axi_master_tb_ghdl():
    run(
        vhdl_sources=[os.path.join(dir, file) for file in bram],                    # sources     
        toplevel="axil_master",                                                     # top level HDL
        module="axil_master_tb",                                                    # name of cocotb test module
        toplevel_lang="vhdl",
        compile_args=["--std=08", "-frelaxed-rules", "--ieee=synopsys", "--no-vital-checks"],
        sim_args=["--wave=wave.ghw", "--ieee-asserts=disable", "--max-stack-alloc=0"]
    )