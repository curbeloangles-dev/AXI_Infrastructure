library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
  generic (
    g_axis_data_width : integer := 32;--! Axi-Stream data width
    g_counter_width   : integer := 32 --! Counter width
  );
  port (
    clk           : in std_logic;
    resetn        : in std_logic;
    start_in      : in std_logic;
    up_down_in    : in std_logic; -- 1: Up, 0: Down
    step_in       : in std_logic_vector(g_counter_width - 1 downto 0);
    m_axis_tdata  : out std_logic_vector(g_axis_data_width - 1 downto 0);
    m_axis_tvalid : out std_logic;
    m_axis_tready : in std_logic
  );
end counter;

architecture Behavioral of counter is
  signal r0_count  : unsigned(g_counter_width - 1 downto 0);
  signal r0_tvalid : std_logic;

begin

  process (clk)
  begin
    if rising_edge(clk) then
      if resetn = '0' then
        r0_count  <= (others => '0');
        r0_tvalid <= '0';
      elsif start_in = '1' then
        if r0_tvalid = '0' or m_axis_tready = '1' then
          if up_down_in = '1' then
            r0_count <= r0_count + unsigned(step_in);
          else
            r0_count <= r0_count - unsigned(step_in);
          end if;
          r0_tvalid <= '1';
        end if;
      end if;
    end if;
  end process;

  m_axis_tvalid                                              <= r0_tvalid;
  m_axis_tdata(g_counter_width - 1 downto 0)                 <= std_logic_vector(r0_count);
  m_axis_tdata(g_axis_data_width - 1 downto g_counter_width) <= (others => '0');

end Behavioral;
