
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axil_register_top_tb is
  generic
  (
    AXI_DATA_WIDTH : integer := 32;               --! Bus width
    AXI_ADDR_WIDTH : integer := 32;               --! Bus address width
    STRB_WIDTH     : integer := AXI_DATA_WIDTH/8; --! Strobe width
    REG_TYPE       : integer := 1                 --! axil regs
  );
  port
  (
    s_aclk         : in std_logic;
    axi_aresetn    : in std_logic;
    s_axil_awaddr  : in std_logic_vector (AXI_ADDR_WIDTH - 1 downto 0);
    s_axil_awprot  : in std_logic_vector (2 downto 0);
    s_axil_awvalid : in std_logic;
    s_axil_awready : out std_logic;
    s_axil_wdata   : in std_logic_vector (AXI_DATA_WIDTH - 1 downto 0);
    s_axil_wstrb   : in std_logic_vector (STRB_WIDTH - 1 downto 0);
    s_axil_wvalid  : in std_logic;
    s_axil_wready  : out std_logic;
    s_axil_bresp   : out std_logic_vector (1 downto 0);
    s_axil_bvalid  : out std_logic;
    s_axil_bready  : in std_logic;
    s_axil_araddr  : in std_logic_vector (AXI_ADDR_WIDTH - 1 downto 0);
    s_axil_arprot  : in std_logic_vector (2 downto 0);
    s_axil_arvalid : in std_logic;
    s_axil_arready : out std_logic;
    s_axil_rdata   : out std_logic_vector (AXI_DATA_WIDTH - 1 downto 0);
    s_axil_rresp   : out std_logic_vector (1 downto 0);
    s_axil_rvalid  : out std_logic;
    s_axil_rready  : in std_logic
  );
end axil_register_top_tb;

architecture rtl of axil_register_top_tb is

  constant g_clk_in_hz : positive := 10000;

  signal input_in  : std_logic_vector(7 downto 0);
  signal s_clk_div : std_logic_vector(1 downto 0);

  signal m_axil_awaddr : std_logic_vector (AXI_ADDR_WIDTH - 1 downto 0);
  signal m_axil_awprot : std_logic_vector (2 downto 0);
  signal m_axil_awvalid : std_logic;
  signal m_axil_awready : std_logic;
  signal m_axil_wdata : std_logic_vector (AXI_DATA_WIDTH - 1 downto 0);
  signal m_axil_wstrb : std_logic_vector (STRB_WIDTH - 1 downto 0);
  signal m_axil_wvalid : std_logic;
  signal m_axil_wready : std_logic;
  signal m_axil_bresp : std_logic_vector (1 downto 0);
  signal m_axil_bvalid : std_logic;
  signal m_axil_bready : std_logic;
  signal m_axil_araddr : std_logic_vector (AXI_ADDR_WIDTH - 1 downto 0);
  signal m_axil_arprot : std_logic_vector (2 downto 0);
  signal m_axil_arvalid : std_logic;
  signal m_axil_arready : std_logic;
  signal m_axil_rdata : std_logic_vector (AXI_DATA_WIDTH - 1 downto 0);
  signal m_axil_rresp : std_logic_vector (1 downto 0);
  signal m_axil_rvalid : std_logic;
  signal m_axil_rready : std_logic;

begin

  process (s_aclk)
  begin
    if rising_edge(s_aclk) then
      if axi_aresetn = '0' then
        input_in  <= (others => '0');
        s_clk_div <= (others => '0');
      else
        s_clk_div <= std_logic_vector(unsigned(s_clk_div) + 1);
        if s_clk_div = "11" then
          input_in <= not input_in;
        end if;
      end if;
    end if;
  end process;

  axil_register_inst : entity work.axil_register_top
    generic
    map (
    AXI_DATA_WIDTH => AXI_DATA_WIDTH,
    AXI_ADDR_WIDTH => AXI_ADDR_WIDTH,
    STRB_WIDTH     => STRB_WIDTH,
    NUM_REGS    => REG_TYPE
    )
    port map
    (
      S_ACLK         => S_ACLK,
      axi_aresetn    => axi_aresetn,
      s_axil_awaddr  => s_axil_awaddr,
      s_axil_awprot  => s_axil_awprot,
      s_axil_awvalid => s_axil_awvalid,
      s_axil_awready => s_axil_awready,
      s_axil_wdata   => s_axil_wdata,
      s_axil_wstrb   => s_axil_wstrb,
      s_axil_wvalid  => s_axil_wvalid,
      s_axil_wready  => s_axil_wready,
      s_axil_bresp   => s_axil_bresp,
      s_axil_bvalid  => s_axil_bvalid,
      s_axil_bready  => s_axil_bready,
      s_axil_araddr  => s_axil_araddr,
      s_axil_arprot  => s_axil_arprot,
      s_axil_arvalid => s_axil_arvalid,
      s_axil_arready => s_axil_arready,
      s_axil_rdata   => s_axil_rdata,
      s_axil_rresp   => s_axil_rresp,
      s_axil_rvalid  => s_axil_rvalid,
      s_axil_rready  => s_axil_rready,
      m_axil_awaddr  => m_axil_awaddr,
      m_axil_awprot  => m_axil_awprot,
      m_axil_awvalid => m_axil_awvalid,
      m_axil_awready => m_axil_awready,
      m_axil_wdata   => m_axil_wdata,
      m_axil_wstrb   => m_axil_wstrb,
      m_axil_wvalid  => m_axil_wvalid,
      m_axil_wready  => m_axil_wready,
      m_axil_bresp   => m_axil_bresp,
      m_axil_bvalid  => m_axil_bvalid,
      m_axil_bready  => m_axil_bready,
      m_axil_araddr  => m_axil_araddr,
      m_axil_arprot  => m_axil_arprot,
      m_axil_arvalid => m_axil_arvalid,
      m_axil_arready => m_axil_arready,
      m_axil_rdata   => m_axil_rdata,
      m_axil_rresp   => m_axil_rresp,
      m_axil_rvalid  => m_axil_rvalid,
      m_axil_rready  => m_axil_rready
    );

  freq_counter_axi_inst : entity work.freq_counter_axi
    generic
    map (
    g_clk_in_hz    => g_clk_in_hz,
    AXI_ADDR_WIDTH => AXI_ADDR_WIDTH,
    g_core_number  => 1
    )
    port
    map (
    input_in      => input_in,
    axi_aclk      => S_ACLK,
    axi_aresetn   => axi_aresetn,
    s_axi_awaddr  => m_axil_awaddr,
    s_axi_awprot  => m_axil_awprot,
    s_axi_awvalid => m_axil_awvalid,
    s_axi_awready => m_axil_awready,
    s_axi_wdata   => m_axil_wdata,
    s_axi_wstrb   => m_axil_wstrb,
    s_axi_wvalid  => m_axil_wvalid,
    s_axi_wready  => m_axil_wready,
    s_axi_araddr  => m_axil_araddr,
    s_axi_arprot  => m_axil_arprot,
    s_axi_arvalid => m_axil_arvalid,
    s_axi_arready => m_axil_arready,
    s_axi_rdata   => m_axil_rdata,
    s_axi_rresp   => m_axil_rresp,
    s_axi_rvalid  => m_axil_rvalid,
    s_axi_rready  => m_axil_rready,
    s_axi_bresp   => m_axil_bresp,
    s_axi_bvalid  => m_axil_bvalid,
    s_axi_bready  => m_axil_bready
    );

end architecture;