
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity freq_counter is
  generic (
    g_clk_in_hz : positive := 100000000 --! module clock frequency
  );
  port (
    clk_in   : in std_logic;
    reset_n  : in std_logic;
    input_in : in std_logic;
    start_in : in std_logic;
    busy_out : out std_logic;
    freq_out : out std_logic_vector(31 downto 0)
  );
end freq_counter;

architecture rtl of freq_counter is

  signal r0_input, r1_input, r2_input : std_logic := '0'; --! remove metastability
  signal s_flag                       : std_logic := '0'; --! detect clock edge.
  signal s_input                      : std_logic := '0'; --! filtered input signal
  signal s_busy                       : std_logic := '0';
  signal counter                      : integer   := g_clk_in_hz;
  signal freq_counter                 : integer   := 0;

begin

  input_proc : process (clk_in)
  begin
    if rising_edge(clk_in) then
      if reset_n = '0' then
        r0_input <= '0';
        r1_input <= '0';
        r2_input <= '0';
        s_flag   <= '0';
      else
        r0_input <= input_in;
        r1_input <= r0_input;
        r2_input <= r1_input;
        s_flag   <= r2_input;
      end if;
    end if;
  end process;

  rising_flag : process (clk_in)
  begin
    if rising_edge(clk_in) then
      if reset_n = '0' then
        s_input <= '0';
      else
        if s_flag = '0' and r2_input = '1' then
          s_input <= '1';
        else
          s_input <= '0';
        end if;
      end if;
    end if;
  end process;

  process (clk_in)
  begin
    if rising_edge(clk_in) then
      if reset_n = '0' then
        counter <= g_clk_in_hz;
        s_busy  <= '0';
      else
        if counter < g_clk_in_hz then
          counter <= counter + 1;
          s_busy  <= '1';
        elsif start_in = '1' then
          counter <= 0;
        else
          s_busy <= '0';
        end if;
      end if;
    end if;
  end process;

  freq_counter_proc : process (clk_in)
  begin
    if rising_edge(clk_in) then
      if reset_n = '0' or start_in = '1' then
        freq_counter <= 0;
      else
        if s_input = '1' and s_busy = '1' then
          freq_counter <= freq_counter + 1;
        end if;
      end if;
    end if;
  end process;

  busy_out <= s_busy;
  freq_out <= std_logic_vector(to_unsigned(freq_counter, freq_out'length));

end rtl;