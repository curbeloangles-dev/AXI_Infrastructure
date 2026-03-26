
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axil_register is
  generic
  (
    AXI_DATA_WIDTH  : integer := 32;           --! Bus width
    AXI_ADDR_WIDTH  : integer := 32;           --! Bus address width
    STRB_WIDTH  : integer := AXI_DATA_WIDTH/8; --! Strobe width
    AW_REG_TYPE : integer := 1;            --! Address write channel reg
    W_REG_TYPE  : integer := 1;            --! Write channel reg
    B_REG_TYPE  : integer := 1;            --! Bresp channel reg
    AR_REG_TYPE : integer := 1;            --! Address read channel reg
    R_REG_TYPE  : integer := 1             --! Read channel reg
  );
  port
  (
    S_ACLK         : in std_logic;
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
    s_axil_rready  : in std_logic;
    m_axil_awaddr  : out std_logic_vector (AXI_ADDR_WIDTH - 1 downto 0);
    m_axil_awprot  : out std_logic_vector (2 downto 0);
    m_axil_awvalid : out std_logic;
    m_axil_awready : in std_logic;
    m_axil_wdata   : out std_logic_vector (AXI_DATA_WIDTH - 1 downto 0);
    m_axil_wstrb   : out std_logic_vector (STRB_WIDTH - 1 downto 0);
    m_axil_wvalid  : out std_logic;
    m_axil_wready  : in std_logic;
    m_axil_bresp   : in std_logic_vector (1 downto 0);
    m_axil_bvalid  : in std_logic;
    m_axil_bready  : out std_logic;
    m_axil_araddr  : out std_logic_vector (AXI_ADDR_WIDTH - 1 downto 0);
    m_axil_arprot  : out std_logic_vector (2 downto 0);
    m_axil_arvalid : out std_logic;
    m_axil_arready : in std_logic;
    m_axil_rdata   : in std_logic_vector (AXI_DATA_WIDTH - 1 downto 0);
    m_axil_rresp   : in std_logic_vector (1 downto 0);
    m_axil_rvalid  : in std_logic;
    m_axil_rready  : out std_logic
  );
end axil_register;

architecture rtl of axil_register is

begin

  axil_register_wr_inst : entity work.axil_register_wr
    generic
    map (
    DATA_WIDTH  => AXI_DATA_WIDTH,
    ADDR_WIDTH  => AXI_ADDR_WIDTH,
    STRB_WIDTH  => STRB_WIDTH,
    AW_REG_TYPE => AW_REG_TYPE,
    W_REG_TYPE  => W_REG_TYPE,
    B_REG_TYPE  => B_REG_TYPE
    )
    port map
    (
      clk            => S_ACLK,
      rstn           => axi_aresetn,
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
      m_axil_bready  => m_axil_bready
    );

  axil_register_rd_inst : entity work.axil_register_rd
    generic
    map (
    DATA_WIDTH  => AXI_DATA_WIDTH,
    ADDR_WIDTH  => AXI_ADDR_WIDTH,
    STRB_WIDTH  => STRB_WIDTH,
    AR_REG_TYPE => AR_REG_TYPE,
    R_REG_TYPE  => R_REG_TYPE
    )
    port
    map (
    clk            => S_ACLK,
    rstn           => axi_aresetn,
    s_axil_araddr  => s_axil_araddr,
    s_axil_arprot  => s_axil_arprot,
    s_axil_arvalid => s_axil_arvalid,
    s_axil_arready => s_axil_arready,
    s_axil_rdata   => s_axil_rdata,
    s_axil_rresp   => s_axil_rresp,
    s_axil_rvalid  => s_axil_rvalid,
    s_axil_rready  => s_axil_rready,
    m_axil_araddr  => m_axil_araddr,
    m_axil_arprot  => m_axil_arprot,
    m_axil_arvalid => m_axil_arvalid,
    m_axil_arready => m_axil_arready,
    m_axil_rdata   => m_axil_rdata,
    m_axil_rresp   => m_axil_rresp,
    m_axil_rvalid  => m_axil_rvalid,
    m_axil_rready  => m_axil_rready
    );

end architecture;