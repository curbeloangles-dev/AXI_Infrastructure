
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.freq_counter_regs_pkg.all;

entity freq_counter_axi is
  generic (
    g_clk_in_hz    : positive := 100000000; --! Input clock of module in Hz
    AXI_ADDR_WIDTH : integer  := 32;        --! AXI-lite addr width
    g_core_number  : integer  := 1          --! AXI-lite addr width
  );
  port (
    input_in : in std_logic_vector(7 downto 0); --! support for 8 inputs
    --! @virtualbus AXI_lite  axi_lite bus
    axi_aclk    : in std_logic;
    axi_aresetn : in std_logic;
    -- AXI Write Address Channel
    s_axi_awaddr  : in std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
    s_axi_awprot  : in std_logic_vector(2 downto 0);
    s_axi_awvalid : in std_logic;
    s_axi_awready : out std_logic;
    -- AXI Write Data Channel
    s_axi_wdata  : in std_logic_vector(31 downto 0);
    s_axi_wstrb  : in std_logic_vector(3 downto 0);
    s_axi_wvalid : in std_logic;
    s_axi_wready : out std_logic;
    -- AXI Read Address Channel
    s_axi_araddr  : in std_logic_vector(AXI_ADDR_WIDTH - 1 downto 0);
    s_axi_arprot  : in std_logic_vector(2 downto 0);
    s_axi_arvalid : in std_logic;
    s_axi_arready : out std_logic;
    -- AXI Read Data Channel
    s_axi_rdata  : out std_logic_vector(31 downto 0);
    s_axi_rresp  : out std_logic_vector(1 downto 0);
    s_axi_rvalid : out std_logic;
    s_axi_rready : in std_logic;
    -- AXI Write Response Channel
    s_axi_bresp  : out std_logic_vector(1 downto 0);
    s_axi_bvalid : out std_logic;
    s_axi_bready : in std_logic --! @end

  );
end entity;

architecture rtl of freq_counter_axi is

  signal s_regs2user : regs2user_t;
  signal s_user2regs : user2regs_t;
  signal s_input_in  : std_logic := '0';

begin

  freq_counter_regs_inst : entity work.freq_counter_regs
    generic map(
      AXI_ADDR_WIDTH => AXI_ADDR_WIDTH
    )
    port map(
      axi_aclk      => axi_aclk,
      axi_aresetn   => axi_aresetn,
      s_axi_awaddr  => s_axi_awaddr,
      s_axi_awprot  => s_axi_awprot,
      s_axi_awvalid => s_axi_awvalid,
      s_axi_awready => s_axi_awready,
      s_axi_wdata   => s_axi_wdata,
      s_axi_wstrb   => s_axi_wstrb,
      s_axi_wvalid  => s_axi_wvalid,
      s_axi_wready  => s_axi_wready,
      s_axi_araddr  => s_axi_araddr,
      s_axi_arprot  => s_axi_arprot,
      s_axi_arvalid => s_axi_arvalid,
      s_axi_arready => s_axi_arready,
      s_axi_rdata   => s_axi_rdata,
      s_axi_rresp   => s_axi_rresp,
      s_axi_rvalid  => s_axi_rvalid,
      s_axi_rready  => s_axi_rready,
      s_axi_bresp   => s_axi_bresp,
      s_axi_bvalid  => s_axi_bvalid,
      s_axi_bready  => s_axi_bready,
      user2regs     => s_user2regs,
      regs2user     => s_regs2user
    );

  s_user2regs.version_value <= std_logic_vector(to_unsigned(g_core_number,s_user2regs.version_value'length));
  s_input_in                <= input_in(to_integer(unsigned(s_regs2user.control_input_sel)));

  freq_counter_inst : entity work.freq_counter
    generic map(
      g_clk_in_hz => g_clk_in_hz
    )
    port map(
      clk_in   => axi_aclk,
      reset_n  => axi_aresetn,
      input_in => s_input_in,
      start_in => s_regs2user.control_start(0),
      busy_out => s_user2regs.status_busy(0),
      freq_out => s_user2regs.frequency_value
    );

end architecture;