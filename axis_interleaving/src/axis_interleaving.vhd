library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

entity axis_interleaving is 
    generic (
		g_AXIS_TDATA_WIDTH		: natural range 0 to 256	:= 32;
        g_BLOCKING_THRESHOLD	: natural range 1 to 5 		:= 3;
        g_CHANNELS_USED			: natural range 1 to 5 		:= 3;
		g_CHANNEL_STATUS_WIDTH	: natural range 1 to 5		:= 5
    );
    port (
		-- interleaving clock and reset
        interleaving_aclk       : in  std_logic;
        interleaving_aresetn    : in  std_logic;
        -- axi stream channel 0
        s_axis_0_tvalid 		: in  std_logic;
        s_axis_0_tdata			: in  std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
		s_axis_0_tready 		: out std_logic;
        -- axi stream channel 1
        s_axis_1_tvalid 		: in  std_logic;
        s_axis_1_tdata  		: in  std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
		s_axis_1_tready 		: out std_logic;
        -- axi stream channel 2
        s_axis_2_tvalid 		: in  std_logic;
        s_axis_2_tdata  		: in  std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
		s_axis_2_tready 		: out std_logic;
        -- axi stream channel 3
        s_axis_3_tvalid 		: in  std_logic;
        s_axis_3_tdata  		: in  std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
		s_axis_3_tready 		: out std_logic;
        -- axi stream channel 4
        s_axis_4_tvalid 		: in  std_logic;
        s_axis_4_tdata			: in  std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
		s_axis_4_tready 		: out std_logic;
        -- axi stream output	
        m_axis_tvalid   		: out std_logic;
        m_axis_tdata    		: out std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
		m_axis_tready 			: in  std_logic;
		m_demanding_data		: in  std_logic;
		-- register inputs
		user_control_from_reg   : in  std_logic;
		channel_status_from_reg : in  std_logic_vector(4 downto 0);
		-- logic inptus
		channel_status_from_rtl : in  std_logic_vector(4 downto 0)
    );
end entity;

architecture rtl of axis_interleaving is 

	-- constants
	constant c_NO_TVALID				: std_logic_vector(g_CHANNEL_STATUS_WIDTH-1 downto 0)	:= (others => '0');

	-- fsm
	attribute enum_encoding                    			: string;
	--
	type fsm_master_states_type is (IDLE, OUTPUT_DATA);
	signal fsm_master_state 							: fsm_master_states_type;
  	attribute enum_encoding of fsm_master_states_type	: type is "one_hot";
	--
	type fsm_slave_states_type is (IDLE, LATCH_DATA);
	signal fsm_slave_state 								: fsm_slave_states_type;
  	attribute enum_encoding of fsm_slave_states_type	: type is "one_hot";

	-- custom type declaration
	type array_tdata is array(g_CHANNEL_STATUS_WIDTH-1 downto 0) of std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);

	-- signals
	signal s_array_tvalid				: std_logic_vector(g_CHANNEL_STATUS_WIDTH-1 downto 0);
	signal s_array_data					: array_tdata;
	
	-- registers
	signal r_array_tvalid				: std_logic_vector(g_CHANNEL_STATUS_WIDTH-1 downto 0);
	signal r_array_tready				: std_logic_vector(g_CHANNEL_STATUS_WIDTH-1 downto 0);
	signal r_array_tdata				: array_tdata;
	signal r_channel_index				: natural range 0 to 4;
	signal r_axis_tvalid				: std_logic;
	signal r_axis_tdata					: std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
	signal r_channel_status				: std_logic_vector(4 downto 0);
	signal r_array_tdata_ack			: std_logic_vector(4 downto 0);
	signal r_m_axis_tready				: std_logic;
	
	-- functions
	function find_amount_of_channels_nok(channel_status_from_logic : std_logic_vector) return natural is
		variable v_nok_ctr	: natural	:= 0;
		begin
			for v_ctr in 0 to g_CHANNELS_USED-1 loop
				if channel_status_from_logic(g_CHANNELS_USED-1 downto 0)(v_ctr) = '0' then
					v_nok_ctr	:= v_nok_ctr + 1;
				end if;
			end loop;
			return v_nok_ctr;
		end function;

begin 

	-- inputs
	-- axi stream
	s_array_tvalid	<= s_axis_4_tvalid & s_axis_3_tvalid & s_axis_2_tvalid & s_axis_1_tvalid & s_axis_0_tvalid;	
	s_array_data(0)	<= s_axis_0_tdata;
	s_array_data(1)	<= s_axis_1_tdata;
	s_array_data(2)	<= s_axis_2_tdata;
	s_array_data(3)	<= s_axis_3_tdata;
	s_array_data(4)	<= s_axis_4_tdata;

	-- user control handler
	user_ctrl_p	: process(interleaving_aclk)
	begin
		if rising_edge(interleaving_aclk) then
			if interleaving_aresetn = '0' then 
				r_channel_status		<=	(others => '0');
			else
				if user_control_from_reg = '1' then
					r_channel_status	<= channel_status_from_reg;
				else
					r_channel_status	<= channel_status_from_rtl;
				end if;
			end if;
		end if;
	end process;

	---------------------------------------------------------------------------------------------------
	-- slave axi stream fsm
	---------------------------------------------------------------------------------------------------
	s_axis_fsm	: process(interleaving_aclk)
	begin
		if rising_edge(interleaving_aclk) then
			if interleaving_aresetn = '0' then
				r_array_tready			<= (others => '0');
				r_array_tvalid			<= (others => '0');
				r_array_tdata			<= (others => (others => '0'));
			else
				-- default values
				r_array_tready			<= (others => '1');	
				r_array_tvalid			<= (others => '0');
				r_array_tdata			<= (others => (others => '0'));

				case fsm_slave_state is
					when IDLE =>						
						if m_demanding_data = '1' then							
							fsm_slave_state		<= LATCH_DATA;
						else
							fsm_slave_state		<= IDLE;
						end if;

					when LATCH_DATA =>		
						if m_demanding_data = '0' then 		
							fsm_slave_state		<= IDLE;
						else
							fsm_slave_state		<= LATCH_DATA;	

							-- channel 0
							if s_array_tvalid(0) = '1' and r_channel_status(0) = '1' then 
								-- latch data
								r_array_tvalid(0)	<= s_array_tvalid(0);
								r_array_tdata(0)	<= s_array_data(0);
							elsif r_array_tdata_ack(0) = '1' then
								-- clear data
								r_array_tvalid(0)	<= '0';
								r_array_tdata(0)	<= (others => '0');
							else
								-- keep data
								r_array_tvalid(0)	<= r_array_tvalid(0);
								r_array_tdata(0)	<= r_array_tdata(0); 
							end if;

							-- channel 1
							if s_array_tvalid(1) = '1' and r_channel_status(1) = '1' then 
								-- latch data
								r_array_tvalid(1)	<= s_array_tvalid(1);
								r_array_tdata(1)	<= s_array_data(1);
							elsif r_array_tdata_ack(1) = '1' then
								-- clear data
								r_array_tvalid(1)	<= '0';
								r_array_tdata(1)	<= (others => '0');
							else
								-- keep data
								r_array_tvalid(1)	<= r_array_tvalid(1);
								r_array_tdata(1)	<= r_array_tdata(1); 
							end if;

							-- channel 2
							if s_array_tvalid(2) = '1' and r_channel_status(2) = '1' then 
								-- latch data
								r_array_tvalid(2)	<= s_array_tvalid(2);
								r_array_tdata(2)	<= s_array_data(2);
							elsif r_array_tdata_ack(2) = '1' then
								-- clear data
								r_array_tvalid(2)	<= '0';
								r_array_tdata(2)	<= (others => '0');
							else
								-- keep data
								r_array_tvalid(2)	<= r_array_tvalid(2);
								r_array_tdata(2)	<= r_array_tdata(2); 
							end if;

							-- channel 3
							if s_array_tvalid(3) = '1' and r_channel_status(3) = '1' then 
								-- latch data
								r_array_tvalid(3)	<= s_array_tvalid(3);
								r_array_tdata(3)	<= s_array_data(3);
							elsif r_array_tdata_ack(3) = '1' then
								-- clear data
								r_array_tvalid(3)	<= '0';
								r_array_tdata(3)	<= (others => '0');
							else
								-- keep data
								r_array_tvalid(3)	<= r_array_tvalid(3);
								r_array_tdata(3)	<= r_array_tdata(3); 
							end if;

							-- channel 4
							if s_array_tvalid(4) = '1' and r_channel_status(4) = '1' then 
								-- latch data
								r_array_tvalid(4)	<= s_array_tvalid(4);
								r_array_tdata(4)	<= s_array_data(4);
							elsif r_array_tdata_ack(4) = '1' then
								-- clear data
								r_array_tvalid(4)	<= '0';
								r_array_tdata(4)	<= (others => '0');
							else
								-- keep data
								r_array_tvalid(4)	<= r_array_tvalid(4);
								r_array_tdata(4)	<= r_array_tdata(4); 
							end if;
						end if;

					when OTHERS => 
						fsm_slave_state <= IDLE;

				end case;
			end if;
		end if;
	end process;

	---------------------------------------------------------------------------------------------------
	-- master axi stream fsm
	---------------------------------------------------------------------------------------------------
	m_axis_fsm	: process(interleaving_aclk)
		variable v_amount_of_channels_nok	: natural	:= 0;
	begin
		if rising_edge(interleaving_aclk) then
			if interleaving_aresetn = '0' then
				r_channel_index				<= 0;
				r_m_axis_tready				<= '0';
				r_axis_tvalid				<= '0';
				r_axis_tdata				<= (others => '0');
				r_array_tdata_ack			<= (others => '0');
			else				
				-- default values
				r_channel_index				<= 0;	
				r_m_axis_tready				<= m_axis_tready;
				r_axis_tvalid				<= '0';
				r_axis_tdata				<= (others => '0');
				r_array_tdata_ack			<= (others => '0');

				case fsm_master_state is
					when IDLE =>
						if m_demanding_data = '1' then 							
							fsm_master_state	<= OUTPUT_DATA;
						else
							fsm_master_state	<= IDLE;
						end if;								

					when OUTPUT_DATA =>
						if m_demanding_data = '0' then
							fsm_master_state	<= IDLE;
						elsif m_axis_tready = '1' then
							fsm_master_state	<= OUTPUT_DATA;

							-- check threshold
							v_amount_of_channels_nok	:= find_amount_of_channels_nok(channel_status_from_rtl);
							if v_amount_of_channels_nok >= g_BLOCKING_THRESHOLD and user_control_from_reg = '0' then
								r_channel_index			<= 0;	
								r_axis_tvalid			<= '0';
								r_axis_tdata			<= (others => '0');
							else
								-- index
								if r_array_tvalid(g_CHANNELS_USED-1 downto 0) /= c_NO_TVALID(g_CHANNELS_USED-1 downto 0) then		
									if r_channel_index < g_CHANNELS_USED-1 then
										r_channel_index	<= r_channel_index + 1;
									else
										r_channel_index	<= 0;						
									end if;
								end if;
		
								-- tvalid and tdata outputs
								if r_array_tvalid(0) = '1' and r_channel_index = 0 then 
									if r_channel_status(0) = '1' then
										r_axis_tvalid		<= r_array_tvalid(0);
										r_axis_tdata		<= r_array_tdata(0);
										r_array_tdata_ack(0)<= '1';
									end if;
								elsif r_array_tvalid(1) = '1' and r_channel_index = 1 then   
									if r_channel_status(1) = '1' then
										r_axis_tvalid		<= r_array_tvalid(1);
										r_axis_tdata		<= r_array_tdata(1);
										r_array_tdata_ack(1)<= '1';
									end if;
								elsif r_array_tvalid(2) = '1' and r_channel_index = 2 then   
									if r_channel_status(2) = '1' then
										r_axis_tvalid		<= r_array_tvalid(2);
										r_axis_tdata		<= r_array_tdata(2);
										r_array_tdata_ack(2)<= '1';
									end if;
								elsif r_array_tvalid(3) = '1' and r_channel_index = 3 then   
									if r_channel_status(3) = '1' then
										r_axis_tvalid		<= r_array_tvalid(3);
										r_axis_tdata		<= r_array_tdata(3);
										r_array_tdata_ack(3)<= '1';
									end if;
								elsif r_array_tvalid(4) = '1' and r_channel_index = 4 then   
									if r_channel_status(4) = '1' then
										r_axis_tvalid		<= r_array_tvalid(4);
										r_axis_tdata		<= r_array_tdata(4);
										r_array_tdata_ack(4)<= '1';
									end if;
								else
									r_axis_tvalid		<= '0';
									r_axis_tdata		<= (others => '0');
								end if;																
							end if;		
						end if;
					
					when OTHERS =>
						fsm_master_state	<= IDLE;

				end case;
			end if;
		end if;
	end process;

	-- outputs
	-- slave
	s_axis_0_tready		<= r_array_tready(0);
	s_axis_1_tready		<= r_array_tready(1);
	s_axis_2_tready		<= r_array_tready(2);
	s_axis_3_tready		<= r_array_tready(3);
	s_axis_4_tready		<= r_array_tready(4);
	-- master	
	m_axis_tvalid		<= r_axis_tvalid;
	m_axis_tdata		<= r_axis_tdata;

end architecture;