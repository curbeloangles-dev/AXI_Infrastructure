-- -----------------------------------------------------------------------------
-- 'axil_regs' Register Component
-- Revision: 72
-- -----------------------------------------------------------------------------
-- Generated on 2021-11-04 at 12:22 (UTC) by airhdl version 2021.10.1-71
-- -----------------------------------------------------------------------------
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
-- -----------------------------------------------------------------------------

library ieee;
use 	ieee.std_logic_1164.all;
use 	ieee.numeric_std.all;

entity axil_regs is
  	generic (
		g_axi_addr_width  	: integer   := 32;  	--! width of the AXI address bus
		g_axi_data_width  	: integer   := 32;  	--! width of the AXI data bus
		g_total_registers 	: integer   := 64;  	--! Total amount of registers. It has to be even
		g_external_bresp	: boolean	:= false	--! When false bresp is asserted after writing a register. When true bresp comes from an external source
	);
	port (
		--
		-- Clock and Reset
		axi_aclk    		: in  std_logic;
		axi_aresetn 		: in  std_logic;
		--! @virtualbus Axilite bus
		-- AXI Write Address Channel
		s_axi_awaddr  		: in  std_logic_vector(g_axi_addr_width - 1 downto 0);
		s_axi_awprot  		: in  std_logic_vector(2 downto 0);
		s_axi_awvalid 		: in  std_logic;
		s_axi_awready 		: out std_logic;
		-- AXI Write Data Channel
		s_axi_wdata  		: in  std_logic_vector(g_axi_data_width - 1 downto 0);
		s_axi_wstrb  		: in  std_logic_vector(3 downto 0);
		s_axi_wvalid 		: in  std_logic;
		s_axi_wready 		: out std_logic;
		-- AXI Read Address Channel
		s_axi_araddr  		: in  std_logic_vector(g_axi_addr_width - 1 downto 0);
		s_axi_arprot  		: in  std_logic_vector(2 downto 0);
		s_axi_arvalid 		: in  std_logic;
		s_axi_arready 		: out std_logic;
		-- AXI Read Data Channel
		s_axi_rdata  		: out std_logic_vector(g_axi_data_width - 1 downto 0);
		s_axi_rresp  		: out std_logic_vector(1 downto 0);
		s_axi_rvalid 		: out std_logic;
		s_axi_rready 		: in  std_logic;
		-- AXI Write Response Channel
		s_axi_bresp  		: out std_logic_vector(1 downto 0);
		s_axi_bvalid 		: out std_logic;
		s_axi_bready 		: in  std_logic; --! @end

		--
		-- Strobes
		register_value		: out std_logic_vector(g_axi_data_width - 1 downto 0);		--! Last data written
		read_irq 			: out std_logic_vector(g_total_registers/2 - 1 downto 0);	--! Read irq bus
		write_irq 			: out std_logic_vector(g_total_registers/2 - 1 downto 0); 	--! Write irq bus

		--
		-- External bresponse
		external_bresp		: in  std_logic_vector(1 downto 0);							--! bresp from an external source
		external_bresp_vld 	: in  std_logic												--! bresp valid from an external source
	);
end axil_regs;

architecture rtl of axil_regs is

	-- Constants
	constant c_AXI_DIR_BITS 	: positive                     := 12;
	constant AXI_OKAY       	: std_logic_vector(1 downto 0) := "00";
	constant AXI_DECERR     	: std_logic_vector(1 downto 0) := "11";

	-- FSM signals
	type read_states is (IDLE, READ_REGISTER, READ_RESPONSE, DONE);
	signal s_read_state 		: read_states;

	type write_states is (IDLE, ADDR_FIRST, DATA_FIRST, UPDATE_REGISTER, WAIT_EXTERNAL_BRESP, DONE);
	signal s_write_state  		: write_states;

	-- AXI registered signals
	signal s_axi_awready_r    	: std_logic;
	signal s_axi_wready_r     	: std_logic;
	signal s_axi_awaddr_reg_r 	: unsigned(s_axi_awaddr'range);
	signal s_axi_bvalid_r     	: std_logic;
	signal s_axi_bresp_r      	: std_logic_vector(s_axi_bresp'range);
	signal s_axi_arready_r    	: std_logic;
	signal s_axi_araddr_reg_r 	: unsigned(g_axi_addr_width - 1 downto 0);
	signal s_axi_rvalid_r     	: std_logic;
	signal s_axi_rresp_r      	: std_logic_vector(s_axi_rresp'range);
	signal s_axi_wdata_reg_r  	: std_logic_vector(s_axi_wdata'range);
	signal s_axi_wstrb_reg_r  	: std_logic_vector(s_axi_wstrb'range);
	signal s_axi_rdata_r      	: std_logic_vector(s_axi_rdata'range);

	-- Register Map
	type register_array is array(0 to g_total_registers - 1) of std_logic_vector(g_axi_data_width - 1 downto 0); 
	signal register_map			: register_array;

	-- Registered IRQs
	signal s_read_irq_r			: std_logic_vector(g_total_registers/2 - 1 downto 0);
	signal s_write_irq_r		: std_logic_vector(g_total_registers/2 - 1 downto 0);

	-- Registered internal signals
	signal s_last_data_written_r: std_logic_vector(g_axi_data_width - 1 downto 0);

begin

	----------------------------------------------------------------------------
	-- Read-transaction FSM
	--
	read_fsm : process (axi_aclk, axi_aresetn) is
		variable v_rdata_r      : std_logic_vector(g_axi_data_width - 1 downto 0);
		variable v_rresp_r      : std_logic_vector(s_axi_rresp'range);
		-- combinatorial helper variables
		variable v_addr_hit 	: boolean;
		variable v_mem_addr 	: unsigned(g_axi_addr_width - 1 downto 0);
	begin
		if axi_aresetn = '0' then
			s_read_state        <= IDLE;
			v_rdata_r          	:= (others => '0');
			v_rresp_r          	:= (others => '0');
			s_axi_arready_r    	<= '0';
			s_axi_rvalid_r     	<= '0';
			s_axi_rresp_r      	<= (others => '0');
			s_axi_araddr_reg_r 	<= (others => '0');
			s_axi_rdata_r      	<= (others => '0');
			--
			s_read_irq_r   		<= (others => '0');

		elsif rising_edge(axi_aclk) then
			-- Default values:
			s_axi_arready_r   	<= '0';
			--
			s_read_irq_r   		<= (others => '0');

			case s_read_state is

				-- Wait for the start of a read transaction, which is
				-- initiated by the assertion of ARVALID
				when IDLE =>
					if s_axi_arvalid = '1' then
						s_axi_araddr_reg_r 	<= unsigned(s_axi_araddr); -- save the read address
						s_axi_arready_r    	<= '1';                    -- acknowledge the read-address
						s_read_state 		<= READ_REGISTER;
					end if;

				-- Read from the actual storage element
				when READ_REGISTER =>
					-- defaults:
					v_addr_hit 				:= false;
					v_rdata_r  				:= (others => '0');
					
					-- read the register
					for i in 0 to g_total_registers - 1 loop
						if s_axi_araddr_reg_r(c_AXI_DIR_BITS - 1 downto 2) = to_unsigned(i, c_AXI_DIR_BITS - 2) then
							v_addr_hit     		:= true;
							v_rdata_r			:= register_map(i);
							s_read_state    	<= READ_RESPONSE;
							-- generate the irq
							if i < g_total_registers/2 then
								s_read_irq_r(i)	<= '1';
							end if;
						end if;
					end loop;

					--
					if v_addr_hit then
						v_rresp_r 			:= AXI_OKAY;
					else
						v_rresp_r 			:= AXI_DECERR;
						-- pragma translate_off
						report "ARADDR decode error" severity warning;
						-- pragma translate_on
						s_read_state 		<= READ_RESPONSE;
					end if;

				-- Generate read response
				when READ_RESPONSE =>
					s_axi_rvalid_r 			<= '1';
					s_axi_rresp_r  			<= v_rresp_r;
					s_axi_rdata_r  			<= v_rdata_r;
					--
					s_read_state 			<= DONE;

					-- Write transaction completed, wait for master RREADY to proceed
				when DONE =>
					if s_axi_rready = '1' then
						s_axi_rvalid_r 		<= '0';
						s_axi_rdata_r  		<= (others => '0');
						s_read_state 		<= IDLE;
					end if;

			end case;
		end if;
	end process;

	----------------------------------------------------------------------------
	-- Write-transaction FSM
	--
	write_fsm : process (axi_aclk, axi_aresetn) is
		variable v_addr_hit 	: boolean;
		variable v_irq_assert	: boolean;
		variable v_mem_addr 	: unsigned(g_axi_addr_width - 1 downto 0);
	begin
		if axi_aresetn = '0' then
			s_write_state 			<= IDLE;
			s_axi_awready_r    		<= '0';
			s_axi_wready_r     		<= '0';
			s_axi_awaddr_reg_r 		<= (others => '0');
			s_axi_wdata_reg_r  		<= (others => '0');
			s_axi_wstrb_reg_r  		<= (others => '0');
			s_axi_bvalid_r     		<= '0';
			s_axi_bresp_r      		<= (others => '0');
			--
			register_map			<= (others => (others => '0'));
			s_write_irq_r   		<= (others => '0');
			s_last_data_written_r	<= (others => '0');

		elsif rising_edge(axi_aclk) then
			-- Default values:
			s_axi_awready_r    		<= '0';
			s_axi_wready_r     		<= '0';
			--
			s_write_irq_r   		<= (others => '0');

			case s_write_state is

				-- Wait for the start of a write transaction, which may be
				-- initiated by either of the following conditions:
				--   * assertion of both AWVALID and WVALID
				--   * assertion of AWVALID
				--   * assertion of WVALID
				when IDLE =>
					if s_axi_awvalid = '1' and s_axi_wvalid = '1' then
						s_axi_awaddr_reg_r 	<= unsigned(s_axi_awaddr); -- save the write-address
						s_axi_awready_r    	<= '1';                    -- acknowledge the write-address
						s_axi_wdata_reg_r  	<= s_axi_wdata;            -- save the write-data
						s_axi_wstrb_reg_r  	<= s_axi_wstrb;            -- save the write-strobe
						s_axi_wready_r     	<= '1';                    -- acknowledge the write-data
						s_write_state 		<= UPDATE_REGISTER;
					elsif s_axi_awvalid = '1' then
						s_axi_awaddr_reg_r 	<= unsigned(s_axi_awaddr); -- save the write-address
						s_axi_awready_r    	<= '1';                    -- acknowledge the write-address
						s_write_state 		<= ADDR_FIRST;
					elsif s_axi_wvalid = '1' then
						s_axi_wdata_reg_r 	<= s_axi_wdata; -- save the write-data
						s_axi_wstrb_reg_r 	<= s_axi_wstrb; -- save the write-strobe
						s_axi_wready_r    	<= '1';         -- acknowledge the write-data
						s_write_state 		<= DATA_FIRST;
					end if;

				-- Address-first write transaction: wait for the write-data
				when ADDR_FIRST =>
					if s_axi_wvalid = '1' then
						s_axi_wdata_reg_r 	<= s_axi_wdata; -- save the write-data
						s_axi_wstrb_reg_r 	<= s_axi_wstrb; -- save the write-strobe
						s_axi_wready_r    	<= '1';         -- acknowledge the write-data
						s_write_state 		<= UPDATE_REGISTER;
					end if;

				-- Data-first write transaction: wait for the write-address
				when DATA_FIRST =>
					if s_axi_awvalid = '1' then
						s_axi_awaddr_reg_r 	<= unsigned(s_axi_awaddr); -- save the write-address
						s_axi_awready_r    	<= '1';                    -- acknowledge the write-address
						s_write_state 		<= UPDATE_REGISTER;
					end if;

				-- Update the actual storage element
				when UPDATE_REGISTER =>
					v_addr_hit 				:= false;
					v_irq_assert			:= false;
					
					-- write the register
					for i in 0 to g_total_registers - 1 loop
						if s_axi_awaddr_reg_r(c_AXI_DIR_BITS - 1 downto 2) = to_unsigned(i, c_AXI_DIR_BITS - 2) then
							v_addr_hit 				:= true;
							register_map(i) 		<= s_axi_wdata_reg_r;
							s_last_data_written_r	<= s_axi_wdata_reg_r;
							-- generate the irq
							if i >= g_total_registers/2 then
								v_irq_assert		:= true;
								s_write_irq_r(i - g_total_registers/2)	<= '1';
							end if;
						end if;
					end loop;
					
					-- generate bresp
					if g_external_bresp = true and v_irq_assert = true then  
						s_write_state		<= WAIT_EXTERNAL_BRESP;
					else
						s_axi_bvalid_r 		<= '1';
						s_write_state 		<= DONE;
						if not v_addr_hit then
							s_axi_bresp_r 	<= AXI_DECERR;
							-- pragma translate_off
							report "AWADDR decode error" severity warning;
							-- pragma translate_on
						else 
							s_axi_bresp_r  	<= AXI_OKAY;
						end if;
					end if;

				-- Wait for an external bresp
				when WAIT_EXTERNAL_BRESP =>
					if external_bresp_vld = '1' then 
						s_axi_bresp_r		<= external_bresp;
						s_axi_bvalid_r 		<= '1';
						s_write_state 		<= DONE;
					end if;

				-- Write transaction completed, wait for master BREADY to proceed
				when DONE =>
					if s_axi_bready = '1' then
						s_axi_bvalid_r 		<= '0';
						s_write_state 		<= IDLE;
					end if;

			end case;
		end if;
	end process;

	----------------------------------------------------------------------------
	-- Outputs
	--
	s_axi_awready 	<= s_axi_awready_r;
	s_axi_wready  	<= s_axi_wready_r;
	s_axi_bvalid  	<= s_axi_bvalid_r;
	s_axi_bresp   	<= s_axi_bresp_r;
	s_axi_arready 	<= s_axi_arready_r;
	s_axi_rvalid  	<= s_axi_rvalid_r;
	s_axi_rresp   	<= s_axi_rresp_r;
	s_axi_rdata   	<= s_axi_rdata_r;

	register_value	<= s_last_data_written_r;
	read_irq 		<= s_read_irq_r;
	write_irq 		<= s_write_irq_r;

end architecture rtl;