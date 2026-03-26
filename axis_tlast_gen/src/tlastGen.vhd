library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity tlastGen is
  generic (
    g_AXIS_TDATA_WIDTH : integer := 32
  );
  port (
    axis_aclk    : in std_logic;
    axis_aresetn : in std_logic;
    -- AXIS SLAVE
    s_axis_tdata  : in std_logic_vector(g_AXIS_TDATA_WIDTH - 1 downto 0);
    s_axis_tvalid : in std_logic;
    s_axis_tready : out std_logic;
    s_axis_tkeep  : in std_logic_vector (g_AXIS_TDATA_WIDTH/8 -1 downto 0);
    s_axis_tlast  : in std_logic; --! @end    
    -- AXIS MASTER
    m_axis_tdata  : out std_logic_vector(g_AXIS_TDATA_WIDTH - 1 downto 0);
    m_axis_tvalid : out std_logic;
    m_axis_tready : in std_logic;
    m_axis_tlast  : out std_logic;
    m_axis_tkeep  : out std_logic_vector (g_AXIS_TDATA_WIDTH/8 -1 downto 0);  --! @end  
    --
    rstn             : in std_logic;
    ena              : in std_logic;
    tlast_gen_busy_o : out std_logic;
    --
    transferLen : in std_logic_vector(32 - 1 downto 0);
    packetsNum  : in std_logic_vector(32 - 1 downto 0);
    data_swap   : in std_logic_vector(32 - 1 downto 0); -- Input port for data swap control
    tlast_mode  : in std_logic_vector(32 - 1 downto 0); -- Input port for tlast generation mode control
    data_mask   : in std_logic_vector(32 - 1 downto 0) -- Input port for data mask control
    );
  end entity;
  
  architecture rtl of tlastGen is
    
    constant c_bytes_data_width : integer := g_AXIS_TDATA_WIDTH / 8;
    constant c_tkeep_ones : std_logic_vector(g_AXIS_TDATA_WIDTH/8 - 1 downto 0) := (others => '1');
    
    --
  signal s_bytes_remaining_to_transfer : integer := 0;
  signal s0_m_axis_tkeep_mask  : std_logic_vector(g_AXIS_TDATA_WIDTH/8 - 1 downto 0) := (others => '1'); -- masking signal active
  signal s_m_axis_tkeep_mask  : std_logic_vector(g_AXIS_TDATA_WIDTH/8 - 1 downto 0) := (others => '1'); -- masking signal deactivated
  --
  signal s_m_axis_tdata  : std_logic_vector(g_AXIS_TDATA_WIDTH - 1 downto 0) := (others => '0');
  signal s_m_axis_tdata_word_swap  : std_logic_vector(g_AXIS_TDATA_WIDTH - 1 downto 0) := (others => '0');
  signal s_m_axis_tdata_byte_swap  : std_logic_vector(g_AXIS_TDATA_WIDTH - 1 downto 0) := (others => '0');
  signal s_m_axis_tdata_byte_word_swap  : std_logic_vector(g_AXIS_TDATA_WIDTH - 1 downto 0) := (others => '0');
  signal s_m_axis_tkeep_byte_swap  : std_logic_vector(g_AXIS_TDATA_WIDTH/8 - 1 downto 0) := (others => '0');
  signal s_m_axis_tkeep_word_swap  : std_logic_vector(g_AXIS_TDATA_WIDTH/8 - 1 downto 0) := (others => '0');
  signal s_m_axis_tkeep_byte_word_swap  : std_logic_vector(g_AXIS_TDATA_WIDTH/8 - 1 downto 0) := (others => '0');
  signal s_m_axis_tkeep  : std_logic_vector(g_AXIS_TDATA_WIDTH/8 - 1 downto 0) := (others => '0');
  signal s_m_axis_tvalid : std_logic                                      := '0';
  signal s_m_axis_tready : std_logic                                      := '0';
  signal s_m_axis_tlast  : std_logic                                      := '0';
  signal r0_s_axis_tlast  : std_logic                                      := '0';
  --
  signal aux_tready : std_logic := '0';
  --
  signal r0_rstn        : std_logic                         := '0';
  signal r0_ena         : std_logic                         := '0';
  signal r0_transferLen : std_logic_vector(32 - 1 downto 0) := (others => '0');
  signal r0_packetsNum  : std_logic_vector(32 - 1 downto 0) := x"00000001";
  --
  signal r0_counter         : integer := 0;
  signal r0_counter_packets : integer := 0;
  --
  type fsm_states_type is (IDLE, RUNNING, RUNNING_LOOP);
  signal fsm_state                           : fsm_states_type;
  attribute enum_encoding                    : string;
  attribute enum_encoding of fsm_states_type : type is "one_hot";
  --
  
  -- Count the number of bits set to 1 in a std_logic_vector
  function f_tkeep_ones (
    tkeep    : in std_logic_vector )
    return integer is
      variable counter : integer := 0;
    begin
      for i in 0 to tkeep'length-1 loop
        if tkeep(i) = '1' then
          counter := counter + 1;
        end if;
      end loop;
        return counter;
        
      end function f_tkeep_ones;
      
    begin
    
    -- Calculate the number of bytes remaining to transfer based on transferLen and the current counter and generate tkeep mask
    s_bytes_remaining_to_transfer <= to_integer(unsigned(r0_transferLen)) - r0_counter;
    s0_m_axis_tkeep_mask <= c_tkeep_ones when s_bytes_remaining_to_transfer >= c_bytes_data_width else
      std_logic_vector(shift_right(unsigned(c_tkeep_ones), c_bytes_data_width - s_bytes_remaining_to_transfer));
    s_m_axis_tkeep_mask <= s0_m_axis_tkeep_mask when to_integer(unsigned(data_mask)) = 1 else
      s_axis_tkeep;


      r0 : process (axis_aclk)
      begin
        if rising_edge(axis_aclk) then
          if axis_aresetn = '0' then
            r0_rstn        <= '0';
            r0_ena         <= '0';
            r0_transferLen <= (others => '0');
            r0_packetsNum  <= (others => '0');
          else
            r0_rstn        <= rstn;
            r0_ena         <= ena;
            r0_transferLen <= transferLen; -- std_logic_vector(shift_right(unsigned(transferLen), nshift_c));
            r0_packetsNum  <= packetsNum;
          end if;
        end if;
      end process;
      
      -- FSM
fsm_process : process (axis_aclk)
  variable v_counter_tkeep : integer := 0;
  begin
    if rising_edge(axis_aclk) then
      if axis_aresetn = '0' or r0_rstn = '0' then
        fsm_state          <= IDLE;
        r0_counter         <= 0;
        r0_counter_packets <= 0;
        s_m_axis_tdata     <= (others => '0');
        s_m_axis_tvalid    <= '0';
        s_m_axis_tlast     <= '0';
        r0_s_axis_tlast <= '0'; --! Reset the tlast signal from the input stream.
      else
        case fsm_state is
            -- IDLE State (wait until start)
          when IDLE =>
            s_m_axis_tvalid    <= '0';
            s_m_axis_tdata     <= (others => '0');
            r0_counter         <= 0;
            r0_counter_packets <= 0;
            if r0_ena = '1' then
              if r0_packetsNum = x"00000000" then
                fsm_state <= RUNNING_LOOP;
              else
                fsm_state <= RUNNING;
              end if;
            else
              fsm_state      <= IDLE;
              s_m_axis_tlast <= '0';
              r0_s_axis_tlast <= '0'; --! Reset the tlast signal from the input stream.
            end if;
            -- RUNNING State (finite number of packets)
          when RUNNING =>
            if r0_counter_packets < to_integer(unsigned(r0_packetsNum)) then
              if s_m_axis_tready = '1' then
                if s_axis_tvalid = '1' then
                  r0_s_axis_tlast <= s_axis_tlast;
                  s_m_axis_tdata  <= s_axis_tdata;
                  s_m_axis_tvalid <= '1';
                  v_counter_tkeep := f_tkeep_ones(s_axis_tkeep);
                  if to_integer(unsigned(r0_transferLen)) = 0 then
                    s_m_axis_tkeep  <= s_axis_tkeep;
                    fsm_state <= RUNNING;
                  elsif r0_counter + v_counter_tkeep >= to_integer(unsigned(r0_transferLen)) then --! If the number of bytes in the packet is greater than the transfer length, then we need to generate a tlast signal.
                    r0_counter_packets <= r0_counter_packets + 1;
                    r0_counter         <= 0;
                    s_m_axis_tlast     <= '1';
                    s_m_axis_tkeep  <= s_m_axis_tkeep_mask; -- Apply tkeep mask to the last transfer
                  else
                    r0_counter     <= r0_counter + v_counter_tkeep;
                    s_m_axis_tlast <= '0';
                    s_m_axis_tkeep  <= s_axis_tkeep;
                  end if;
                else
                  s_m_axis_tvalid <= '0';
                end if;
              end if;
            elsif m_axis_tready = '1' then
              s_m_axis_tvalid <= '0';
              fsm_state       <= IDLE;
              s_m_axis_tlast  <= '0';
              r0_s_axis_tlast <= '0'; --! Reset the tlast signal from the input stream.
            end if;
            -- RUNNING LOOP State (infinite number of packets)
          when RUNNING_LOOP =>
            if r0_packetsNum = x"00000000" then
              if s_m_axis_tready = '1' then
                if s_axis_tvalid = '1' then
                  r0_s_axis_tlast <= s_axis_tlast;
                  s_m_axis_tdata  <= s_axis_tdata;
                  s_m_axis_tvalid <= '1';
                  v_counter_tkeep := f_tkeep_ones(s_axis_tkeep);
                  if to_integer(unsigned(r0_transferLen)) = 0 then
                    fsm_state <= RUNNING_LOOP;
                    s_m_axis_tkeep  <= s_axis_tkeep;
                  elsif r0_counter + v_counter_tkeep >= to_integer(unsigned(r0_transferLen)) then
                    r0_counter     <= 0;
                    s_m_axis_tlast <= '1';
                    s_m_axis_tkeep  <= s_m_axis_tkeep_mask; -- Apply tkeep mask to the last transfer
                  else
                    r0_counter     <= r0_counter + v_counter_tkeep;
                    s_m_axis_tlast <= '0';
                    s_m_axis_tkeep  <= s_axis_tkeep;
                  end if;
                else
                  s_m_axis_tvalid <= '0';
                end if;
              end if;
            elsif m_axis_tready = '1' then
              s_m_axis_tvalid <= '0';
              fsm_state       <= IDLE;
              s_m_axis_tlast  <= '0';
              r0_s_axis_tlast <= '0'; --! Reset the tlast signal from the input stream.
            end if;
          when others =>
            fsm_state      <= IDLE;
            s_m_axis_tlast <= '0';
            r0_s_axis_tlast <= '0'; --! Reset the tlast signal from the input stream.
        end case;
      end if;
    end if;
  end process;

  -- Data swap logic
  -- Depending on the value of data_swap, the data is swapped accordingly.
  m_axis_tdata  <= s_m_axis_tdata when  to_integer(unsigned(data_swap)) = 0 else
                  s_m_axis_tdata_word_swap when  to_integer(unsigned(data_swap)) = 1 else
                  s_m_axis_tdata_byte_swap when  to_integer(unsigned(data_swap)) = 2 else
                  s_m_axis_tdata_byte_word_swap when to_integer(unsigned(data_swap)) = 3 else
                  s_m_axis_tdata; -- Default case (no swap)

  m_axis_tkeep  <= s_m_axis_tkeep when  to_integer(unsigned(data_swap)) = 0 else
                  s_m_axis_tkeep_word_swap when  to_integer(unsigned(data_swap)) = 1 else
                  s_m_axis_tkeep_byte_swap when  to_integer(unsigned(data_swap)) = 2 else
                  s_m_axis_tkeep_byte_word_swap when to_integer(unsigned(data_swap)) = 3 else
                  s_m_axis_tkeep; -- Default case (no swap)
                  
  -- Word swap logic
  word_swap : for i in 0 to g_AXIS_TDATA_WIDTH/32 - 1 generate
    s_m_axis_tdata_word_swap((i + 1) * 32 - 1 downto i * 32) <= s_m_axis_tdata(g_AXIS_TDATA_WIDTH - i * 32 - 1 downto g_AXIS_TDATA_WIDTH - (i + 1) * 32);
    s_m_axis_tkeep_word_swap((i + 1) * 4 - 1 downto i * 4) <= s_m_axis_tkeep(g_AXIS_TDATA_WIDTH/8 - i * 4 - 1 downto g_AXIS_TDATA_WIDTH/8 - (i + 1) * 4);
  end generate;
  -- Byte swap logic
  byte_swap : for i in 0 to g_AXIS_TDATA_WIDTH/8 - 1 generate
    s_m_axis_tdata_byte_swap((i + 1) * 8 - 1 downto i * 8) <= s_m_axis_tdata(g_AXIS_TDATA_WIDTH - i * 8 - 1 downto g_AXIS_TDATA_WIDTH - (i + 1)* 8);
    s_m_axis_tkeep_byte_swap((i + 1) * 1 - 1 downto i * 1) <= s_m_axis_tkeep(g_AXIS_TDATA_WIDTH/8 - i * 1 - 1 downto g_AXIS_TDATA_WIDTH/8 - (i + 1)* 1);
  end generate;
  -- Use byte_swap output to create byte and word swap
  byte_word_swap : for i in 0 to g_AXIS_TDATA_WIDTH/32 - 1 generate
    s_m_axis_tdata_byte_word_swap((i + 1) * 32 - 1 downto i * 32) <= s_m_axis_tdata_byte_swap(g_AXIS_TDATA_WIDTH - i * 32 - 1 downto g_AXIS_TDATA_WIDTH - (i + 1) * 32);
    s_m_axis_tkeep_byte_word_swap((i + 1) * 4 - 1 downto i * 4) <= s_m_axis_tkeep_byte_swap(g_AXIS_TDATA_WIDTH/8 - i * 4 - 1 downto g_AXIS_TDATA_WIDTH/8 - (i + 1) * 4);
  end generate;

  m_axis_tvalid <= s_m_axis_tvalid;
  m_axis_tlast <= r0_s_axis_tlast when to_integer(unsigned(tlast_mode)) = 0 else --! Input stream tlast when tlast_mode = 0. Generation disabled.
                  s_m_axis_tlast when to_integer(unsigned(tlast_mode)) = 1 else  --! Generated tlast when tlast_mode = 1. Generation enabled.
                  s_m_axis_tlast or r0_s_axis_tlast when to_integer(unsigned(tlast_mode)) = 2 else --! Generated or input stream tlast when tlast_mode = 2. Either can trigger tlast.
                  s_m_axis_tlast; -- Default case (generated tlast)

  s_m_axis_tready <= '1' when m_axis_tready = '1' and aux_tready = '1' else
    '1' when s_m_axis_tvalid = '0' and aux_tready = '1' else
    '0';
  s_axis_tready <= s_m_axis_tready when (not(fsm_state = IDLE)) else
    '0';

  aux_tready <= '1' when r0_counter_packets < to_integer(unsigned(r0_packetsNum)) else
    '1' when r0_packetsNum = x"00000000" else
    '0';

  tlast_gen_busy_o <= '1' when (fsm_state = RUNNING or fsm_state = RUNNING_LOOP) else
    '0';

end architecture;