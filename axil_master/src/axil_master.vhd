library ieee;
use 	ieee.std_logic_1164.all;

entity axil_master is
	generic (
		g_axi_addr_width    :   integer :=  32;
        g_axi_data_width    :   integer :=  32
	);
	port (
		-- Generic Interface
		-- signals for axi write/read transactions
		addr          	: in  std_logic_vector (g_axi_addr_width - 1 downto 0);	--! Address to be written or read
		done		  	: out std_logic;										--! Indicates when an AXI transaction is done
		-- write axi transaction signals
		write_vld     	: in  std_logic;										--! Trigger to start the AXI writing transaction		
		dataIn        	: in  std_logic_vector (g_axi_data_width - 1 downto 0);	--! Data to write	
		write_result	: out std_logic_vector(1 downto 0);						--! Transaction result. bresp extension signal
		-- read axi transaction signals
		read_vld      	: in  std_logic;										--! Trigger to start the AXI reading transaction	
		dataOut_vld   	: out std_logic;										--! Indicates when the data read is available
		dataOut       	: out std_logic_vector (g_axi_data_width - 1 downto 0);	--! Data read
		
		-- AXI Clock and Reset
		m_axi_aclk    	: in  std_logic;
        m_axi_aresetn 	: in  std_logic;
		-- AXI Write Address Channel
        m_axi_awaddr  	: out std_logic_vector(g_axi_addr_width - 1 downto 0);
        m_axi_awvalid 	: out std_logic;
        m_axi_awready 	: in  std_logic;
        -- AXI Write Data Channel
        m_axi_wdata  	: out std_logic_vector(g_axi_data_width - 1 downto 0);
        m_axi_wstrb  	: out std_logic_vector(3 downto 0);
        m_axi_wvalid 	: out std_logic;
        m_axi_wready 	: in  std_logic;        
        -- AXI Read Address Channel
        m_axi_araddr  	: out std_logic_vector(g_axi_addr_width - 1 downto 0);
        m_axi_arvalid 	: out std_logic;
        m_axi_arready 	: in  std_logic;
        -- AXI Read Data Channel
        m_axi_rdata  	: in  std_logic_vector(g_axi_data_width - 1 downto 0);
        m_axi_rresp  	: in  std_logic_vector(1 downto 0);
        m_axi_rvalid 	: in  std_logic;
        m_axi_rready 	: out std_logic;
        -- AXI Write Response Channel
        m_axi_bresp  	: in  std_logic_vector(1 downto 0);
        m_axi_bvalid 	: in  std_logic;
        m_axi_bready 	: out std_logic
	);
end entity;

architecture rtl of axil_master is

	type axi_rd_states is (IDLE, WAIT_ARREADY, WAIT_VLD);
	signal state_read 			: axi_rd_states					  					:= IDLE;

	type axi_wr_states is (IDLE, WRITE, WAIT_READY);
	signal state_write       	: axi_wr_states                   					:= IDLE;

	signal r0_addr          	: std_logic_vector (g_axi_addr_width - 1 downto 0) 	:= (others => '0');
	signal r0_data          	: std_logic_vector (g_axi_data_width - 1 downto 0) 	:= (others => '0');
	signal r0_axi_awaddr  		: std_logic_vector (g_axi_addr_width - 1 downto 0) 	:= (others => '0');
	signal r0_axi_awvalid 		: std_logic                      					:= '0';
	signal r0_axi_wdata   		: std_logic_vector (g_axi_data_width - 1 downto 0) 	:= (others => '0');
	signal r0_axi_wvalid  		: std_logic                      					:= '0';
	signal r0_axi_bready  		: std_logic                      					:= '0';
	signal r0_axi_bvalid  		: std_logic                      					:= '0';
	signal r0_done_wr			: std_logic											:= '0';
	signal r0_done_rd			: std_logic											:= '0';
	signal r0_bresp				: std_logic_vector(1 downto 0)						:= (others => '0');

begin

	----------------------------------------------------------------------------
    -- Write-transaction FSM
    --
	process(m_axi_aclk, m_axi_aresetn)
	begin
		if m_axi_aresetn='0' then
			state_write     	<= IDLE;
			r0_axi_awaddr		<= (others => '0');
			r0_axi_awvalid 		<= '0';
			r0_axi_wdata   		<= (others => '0');
			r0_axi_wvalid  		<= '0';
			r0_axi_bready 		<= '0';
			r0_axi_bvalid		<= '0';
			r0_done_wr			<= '0';
			r0_bresp			<= (others => '0');
		elsif rising_edge(m_axi_aclk) then
			case state_write is
				when IDLE =>			
					r0_done_wr				<= '0';		
					if write_vld = '1' then
						r0_addr 			<= addr;
						r0_data 			<= dataIn;
						state_write    		<= WRITE;
					end if;

				when WRITE =>
					r0_axi_awaddr  			<= r0_addr;
					r0_axi_wdata   			<= r0_data;
					r0_axi_awvalid 			<= '1';
					r0_axi_wvalid  			<= '1';
					r0_axi_bvalid  			<= '1';
					r0_axi_bready 			<= '1';
					state_write        		<= WAIT_READY;

				when WAIT_READY =>
					if m_axi_awready ='1' then
						r0_axi_awvalid 		<= '0';
					end if;

					if m_axi_wready ='1' then
						r0_axi_wvalid 		<= '0';
					end if;

					if m_axi_bvalid ='1' then
						r0_axi_bvalid 		<= '0';
						r0_bresp			<= m_axi_bresp;
					end if;

					if r0_axi_awvalid ='0' and r0_axi_wvalid ='0' and r0_axi_bvalid = '0' then
						r0_axi_bready 		<= '0';
					   	r0_done_wr			<= '1';
						state_write 		<= IDLE;
					end if;

			end case;
		end if;
	end process;

	m_axi_awaddr  	<= r0_axi_awaddr;
	m_axi_awvalid 	<= r0_axi_awvalid;
	m_axi_wdata   	<= r0_axi_wdata;
	m_axi_wvalid  	<= r0_axi_wvalid;
	m_axi_bready 	<= r0_axi_bready;
	m_axi_wstrb		<= (others => '1');
	

	----------------------------------------------------------------------------
    -- Read-transaction FSM
    --
	process(m_axi_aclk, m_axi_aresetn)
	begin
		if m_axi_aresetn ='0' then
			dataOut     	<= (others => '0');
			dataOut_vld    	<= '0';
			r0_done_rd		<= '0';
			m_axi_araddr  	<= (others => '0');
			m_axi_arvalid 	<= '0';
			m_axi_rready  	<= '0';
			state_read    	<= IDLE;
		elsif rising_edge(m_axi_aclk) then
			case state_read is
				when IDLE =>					
					dataOut_vld 		<= '0';
					r0_done_rd			<= '0';
					if read_vld = '1' then
						m_axi_araddr  	<= addr;
						m_axi_arvalid 	<= '1';						
						state_read    	<= WAIT_ARREADY;
					else
						m_axi_arvalid 	<= '0';
						m_axi_rready  	<= '0';						
					end if;

				when WAIT_ARREADY =>
					if m_axi_arready = '1' then
						m_axi_arvalid	<= '0';
						m_axi_rready  	<= '1';
						state_read    	<= WAIT_VLD;
					end if;

				when WAIT_VLD =>
					if m_axi_rvalid = '1' then
						dataOut       	<= m_axi_rdata;
						dataOut_vld 	<= '1';
						r0_done_rd		<= '1';
						m_axi_rready  	<= '0';
						state_read      <= IDLE;
					end if;

			end case;
		end if;
	end process;

	-- Output
	done			<= r0_done_wr or r0_done_rd;
	write_result	<= r0_bresp;

end architecture;