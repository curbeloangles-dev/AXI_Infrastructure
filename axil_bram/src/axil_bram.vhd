library ieee;
use 	ieee.std_logic_1164.all;
use 	ieee.numeric_std.all;
use 	ieee.math_real.all;

use 	work.axi_bram_regs_pkg.all;

--!  | OFFSET | LABEL                       |  R/W  | SC  | DESCRIPTION           | RESET VALUE |
--!  | :----: | --------------------------- | :---: | --- | --------------------- | ----------- |
--!  |  0x0 - 4*data_depth   | **mem_regs**        |       |     |                |             |
--!  |        | _[31:0] word_            |   W/R   | NO  | memory word            | 0x0         |

entity axil_bram is
	generic (
		g_AXI_ADDR_WIDTH	: integer  	:= 32; 	--! width of the AXI address bus
		g_data_depth     	: positive	:= 512  --! Memory depth in words (32 bit)
	);
	port (
		-- Clock and Reset
		axi_aclk    		: in  std_logic;
		axi_aresetn 		: in  std_logic;
		-- AXI Write Address Channel
		--! @virtualbus Axilite bus
		s_axi_awaddr  		: in  std_logic_vector(g_AXI_ADDR_WIDTH - 1 downto 0);
		s_axi_awprot  		: in  std_logic_vector(2 downto 0);
		s_axi_awvalid 		: in  std_logic;
		s_axi_awready 		: out std_logic;
		-- AXI Write Data Channel
		s_axi_wdata  		: in  std_logic_vector(31 downto 0);
		s_axi_wstrb  		: in  std_logic_vector(3 downto 0);
		s_axi_wvalid 		: in  std_logic;
		s_axi_wready		: out std_logic;
		-- AXI Read Address Channel
		s_axi_araddr  		: in  std_logic_vector(g_AXI_ADDR_WIDTH - 1 downto 0);
		s_axi_arprot  		: in  std_logic_vector(2 downto 0);
		s_axi_arvalid 		: in  std_logic;
		s_axi_arready 		: out std_logic;
		-- AXI Read Data Channel
		s_axi_rdata  		: out std_logic_vector(31 downto 0);
		s_axi_rresp  		: out std_logic_vector(1 downto 0);
		s_axi_rvalid 		: out std_logic;
		s_axi_rready 		: in  std_logic;
		-- AXI Write Response Channel
		s_axi_bresp  		: out std_logic_vector(1 downto 0);
		s_axi_bvalid 		: out std_logic;
		s_axi_bready 		: in  std_logic --! @end
	);
end entity axil_bram;

architecture rtl of axil_bram is

	constant c_data_width 	: integer  		:= 32;
	constant c_depth_bits 	: integer 		:= integer(ceil(log2(real(g_data_depth))));

	signal s_user2regs 		: user2regs_t;
	signal s_regs2user 		: regs2user_t;

begin

	axi_bram_regs_inst : entity work.axi_bram_regs
		generic map (
			AXI_ADDR_WIDTH 	=> g_AXI_ADDR_WIDTH,
			g_regs_depth   	=> 4*g_data_depth
		)
		port map (
			axi_aclk      	=> axi_aclk,
			axi_aresetn   	=> axi_aresetn,
			s_axi_awaddr  	=> s_axi_awaddr,
			s_axi_awprot  	=> s_axi_awprot,
			s_axi_awvalid 	=> s_axi_awvalid,
			s_axi_awready 	=> s_axi_awready,
			s_axi_wdata   	=> s_axi_wdata,
			s_axi_wstrb  	=> s_axi_wstrb,
			s_axi_wvalid  	=> s_axi_wvalid,
			s_axi_wready  	=> s_axi_wready,
			s_axi_araddr  	=> s_axi_araddr,
			s_axi_arprot  	=> s_axi_arprot,
			s_axi_arvalid 	=> s_axi_arvalid,
			s_axi_arready 	=> s_axi_arready,
			s_axi_rdata   	=> s_axi_rdata,
			s_axi_rresp   	=> s_axi_rresp,
			s_axi_rvalid  	=> s_axi_rvalid,
			s_axi_rready  	=> s_axi_rready,
			s_axi_bresp   	=> s_axi_bresp,
			s_axi_bvalid  	=> s_axi_bvalid,
			s_axi_bready  	=> s_axi_bready,
			user2regs     	=> s_user2regs,
			regs2user     	=> s_regs2user
		);

  	bram_inst : entity work.bram
		generic map (
			g_bram_depth 	=> g_data_depth,
			g_data_width 	=> c_data_width
		)
		port map (
			clk_in    		=> axi_aclk,
			resetn_in 		=> axi_aresetn,
			wen_in    		=> s_regs2user.register_map_wen,
			ren_in    		=> s_regs2user.register_map_ren,
			wdata_in  		=> s_regs2user.register_map_wdata,
			addr_in   		=> s_regs2user.register_map_addr (c_depth_bits - 1 downto 0),
			rdata_out		=> s_user2regs.register_map_rdata
		);

end architecture rtl;