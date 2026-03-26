library ieee;
use 	ieee.std_logic_1164.all;
use 	ieee.numeric_std.all;
use 	ieee.math_real.all;

entity bram is
	generic (
		g_bram_depth 	: positive 	:= 30;
		g_data_width 	: positive 	:= 32
	);
	port (
		clk_in    		: in  std_logic;
		resetn_in 		: in  std_logic;
		wen_in    		: in  std_logic_vector(g_data_width / 8 - 1 downto 0);
		ren_in    		: in  std_logic;
		wdata_in  		: in  std_logic_vector(g_data_width - 1 downto 0);
		rdata_out 		: out std_logic_vector(g_data_width - 1 downto 0);
		addr_in   		: in  std_logic_vector(integer(ceil(log2(real(g_bram_depth)))) - 1 downto 0)
	);
end entity bram;

architecture rtl of bram is

	type mem is array(g_bram_depth - 1 downto 0) of std_logic_vector(g_data_width - 1 downto 0);

	signal ram_block	: mem;
	signal s_addr    	: std_logic_vector(integer(ceil(log2(real(g_bram_depth)))) - 1 downto 0) := (others => '0');
	signal r0_addr    	: std_logic_vector(integer(ceil(log2(real(g_bram_depth)))) - 1 downto 0) := (others => '0');
	signal r0_ren    	: std_logic:= '0';
	signal r0_wen     	: std_logic:= '0';
  
begin

	s_addr <= 	addr_in when wen_in(0) = '1' or r0_wen = '1' else
				addr_in when ren_in = '1' and r0_ren = '0' else
				r0_addr;

	sync_enable: process (clk_in)
		begin
			if rising_edge(clk_in) then
				if resetn_in = '0' then
					r0_ren 	<= '0';
					r0_wen 	<= '0';
				else
					r0_ren 	<= ren_in;
					r0_wen 	<= wen_in(0);
					r0_addr	<= s_addr;
				end if;
			end if;
		end process sync_enable;

	bram_proc: process (clk_in)
		begin
			if rising_edge(clk_in) then
				if resetn_in = '0' then
					rdata_out 	<= (others => '0');
				else
					if wen_in(0) = '1' then
						ram_block(to_integer(unsigned(s_addr))) <= wdata_in;
					else
						rdata_out 								<= ram_block(to_integer(unsigned(s_addr)));
					end if;
				end if;
			end if;
		end process bram_proc;

end architecture rtl;
