
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axil_register_pkg.all;

entity axil_register_top is
  generic
  (
    AXI_DATA_WIDTH : integer := 32;               --! Bus width
    AXI_ADDR_WIDTH : integer := 32;               --! Bus address width
    STRB_WIDTH     : integer := AXI_DATA_WIDTH/8; --! Strobe width
    NUM_REGS       : integer := 1                 --! Number of full axi registers
  );
  port
  (
    s_aclk         : in std_logic;
    axi_aresetn    : in std_logic;
    --! @virtualbus Axilite @dir in
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
    --! @virtualbus Axilite @dir out
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
end axil_register_top;

architecture rtl of axil_register_top is

  signal reg_s_axil_awaddr  : typea_nslavesxaddrstd (NUM_REGS downto 0)(AXI_ADDR_WIDTH - 1 downto 0) := (others => (others => '0'));
  signal reg_s_axil_awprot  : typea_nslavesxprotstd (NUM_REGS downto 0)(2 downto 0)                  := (others => (others => '0'));
  signal reg_s_axil_awvalid : std_logic_vector (NUM_REGS downto 0)                                   := (others => '0');
  signal reg_s_axil_awready : std_logic_vector (NUM_REGS downto 0)                                   := (others => '0');
  signal reg_s_axil_wdata   : typea_nslavesxdatastd (NUM_REGS downto 0)(AXI_DATA_WIDTH - 1 downto 0) := (others => (others => '0'));
  signal reg_s_axil_wstrb   : typea_nslavesxwstrbstd (NUM_REGS downto 0)(STRB_WIDTH - 1 downto 0)    := (others => (others => '0'));
  signal reg_s_axil_wvalid  : std_logic_vector (NUM_REGS downto 0)                                   := (others => '0');
  signal reg_s_axil_wready  : std_logic_vector (NUM_REGS downto 0)                                   := (others => '0');
  signal reg_s_axil_bresp   : typea_nslavesxrespstd (NUM_REGS downto 0)(1 downto 0)                  := (others => (others => '0'));
  signal reg_s_axil_bvalid  : std_logic_vector (NUM_REGS downto 0)                                   := (others => '0');
  signal reg_s_axil_bready  : std_logic_vector (NUM_REGS downto 0)                                   := (others => '0');
  signal reg_s_axil_araddr  : typea_nslavesxaddrstd (NUM_REGS downto 0)(AXI_ADDR_WIDTH - 1 downto 0) := (others => (others => '0'));
  signal reg_s_axil_arprot  : typea_nslavesxprotstd (NUM_REGS downto 0)(2 downto 0)                  := (others => (others => '0'));
  signal reg_s_axil_arvalid : std_logic_vector (NUM_REGS downto 0)                                   := (others => '0');
  signal reg_s_axil_arready : std_logic_vector (NUM_REGS downto 0)                                   := (others => '0');
  signal reg_s_axil_rdata   : typea_nslavesxdatastd (NUM_REGS downto 0)(AXI_DATA_WIDTH - 1 downto 0) := (others => (others => '0'));
  signal reg_s_axil_rresp   : typea_nslavesxrespstd (NUM_REGS downto 0)(1 downto 0)                  := (others => (others => '0'));
  signal reg_s_axil_rvalid  : std_logic_vector (NUM_REGS downto 0)                                   := (others => '0');
  signal reg_s_axil_rready  : std_logic_vector (NUM_REGS downto 0)                                   := (others => '0');

begin

  axil_reg_one : if NUM_REGS < 2 generate
    axil_register_top_inst : entity work.axil_register
      generic
      map (
      AXI_DATA_WIDTH => AXI_DATA_WIDTH,
      AXI_ADDR_WIDTH => AXI_ADDR_WIDTH,
      STRB_WIDTH     => STRB_WIDTH,
      AW_REG_TYPE    => NUM_REGS,
      W_REG_TYPE     => NUM_REGS,
      B_REG_TYPE     => NUM_REGS,
      AR_REG_TYPE    => NUM_REGS,
      R_REG_TYPE     => NUM_REGS
      )
      port map
      (
        S_ACLK         => s_aclk,
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
  end generate;

  axil_reg_plus : if NUM_REGS > 1 generate

    reg_s_axil_awaddr(0)  <= s_axil_awaddr;
    reg_s_axil_awprot(0)  <= s_axil_awprot;
    reg_s_axil_awvalid(0) <= s_axil_awvalid;
    s_axil_awready        <= reg_s_axil_awready(0);
    reg_s_axil_wdata(0)   <= s_axil_wdata;
    reg_s_axil_wstrb(0)   <= s_axil_wstrb;
    reg_s_axil_wvalid(0)  <= s_axil_wvalid;
    s_axil_wready         <= reg_s_axil_wready(0);
    s_axil_bresp          <= reg_s_axil_bresp(0);
    s_axil_bvalid         <= reg_s_axil_bvalid(0);
    reg_s_axil_bready(0)  <= s_axil_bready;
    reg_s_axil_araddr(0)  <= s_axil_araddr;
    reg_s_axil_arprot(0)  <= s_axil_arprot;
    reg_s_axil_arvalid(0) <= s_axil_arvalid;
    s_axil_arready        <= reg_s_axil_arready(0);
    s_axil_rdata          <= reg_s_axil_rdata(0);
    s_axil_rresp          <= reg_s_axil_rresp(0);
    s_axil_rvalid         <= reg_s_axil_rvalid(0);
    reg_s_axil_rready(0)  <= s_axil_rready;

    axil_reg_loop_plus : for i in 0 to NUM_REGS - 1 generate

      axil_register_top_inst : entity work.axil_register
        generic
        map (
        AXI_DATA_WIDTH => AXI_DATA_WIDTH,
        AXI_ADDR_WIDTH => AXI_ADDR_WIDTH,
        STRB_WIDTH     => STRB_WIDTH,
        AW_REG_TYPE    => 1,
        W_REG_TYPE     => 1,
        B_REG_TYPE     => 1,
        AR_REG_TYPE    => 1,
        R_REG_TYPE     => 1
        )
        port
        map
        (
        S_ACLK      => s_aclk,
        axi_aresetn => axi_aresetn,
        -- Slave interfaces
        s_axil_awaddr  => reg_s_axil_awaddr(i),
        s_axil_awprot  => reg_s_axil_awprot(i),
        s_axil_awvalid => reg_s_axil_awvalid(i),
        s_axil_awready => reg_s_axil_awready(i),
        s_axil_wdata   => reg_s_axil_wdata(i),
        s_axil_wstrb   => reg_s_axil_wstrb(i),
        s_axil_wvalid  => reg_s_axil_wvalid(i),
        s_axil_wready  => reg_s_axil_wready(i),
        s_axil_bresp   => reg_s_axil_bresp(i),
        s_axil_bvalid  => reg_s_axil_bvalid(i),
        s_axil_bready  => reg_s_axil_bready(i),
        s_axil_araddr  => reg_s_axil_araddr(i),
        s_axil_arprot  => reg_s_axil_arprot(i),
        s_axil_arvalid => reg_s_axil_arvalid(i),
        s_axil_arready => reg_s_axil_arready(i),
        s_axil_rdata   => reg_s_axil_rdata(i),
        s_axil_rresp   => reg_s_axil_rresp(i),
        s_axil_rvalid  => reg_s_axil_rvalid(i),
        s_axil_rready  => reg_s_axil_rready(i),
        --! Master interfaces
        m_axil_awaddr  => reg_s_axil_awaddr(i + 1),
        m_axil_awprot  => reg_s_axil_awprot(i + 1),
        m_axil_awvalid => reg_s_axil_awvalid(i + 1),
        m_axil_awready => reg_s_axil_awready(i + 1),
        m_axil_wdata   => reg_s_axil_wdata(i + 1),
        m_axil_wstrb   => reg_s_axil_wstrb(i + 1),
        m_axil_wvalid  => reg_s_axil_wvalid(i + 1),
        m_axil_wready  => reg_s_axil_wready(i + 1),
        m_axil_bresp   => reg_s_axil_bresp(i + 1),
        m_axil_bvalid  => reg_s_axil_bvalid(i + 1),
        m_axil_bready  => reg_s_axil_bready(i + 1),
        m_axil_araddr  => reg_s_axil_araddr(i + 1),
        m_axil_arprot  => reg_s_axil_arprot(i + 1),
        m_axil_arvalid => reg_s_axil_arvalid(i + 1),
        m_axil_arready => reg_s_axil_arready(i + 1),
        m_axil_rdata   => reg_s_axil_rdata(i + 1),
        m_axil_rresp   => reg_s_axil_rresp(i + 1),
        m_axil_rvalid  => reg_s_axil_rvalid(i + 1),
        m_axil_rready  => reg_s_axil_rready(i + 1)
        );

    end generate;

    m_axil_awaddr                <= reg_s_axil_awaddr(NUM_REGS);
    m_axil_awprot                <= reg_s_axil_awprot(NUM_REGS);
    m_axil_awvalid               <= reg_s_axil_awvalid(NUM_REGS);
    reg_s_axil_awready(NUM_REGS) <= m_axil_awready;
    m_axil_wdata                 <= reg_s_axil_wdata(NUM_REGS);
    m_axil_wstrb                 <= reg_s_axil_wstrb(NUM_REGS);
    m_axil_wvalid                <= reg_s_axil_wvalid(NUM_REGS);
    reg_s_axil_wready(NUM_REGS)  <= m_axil_wready;
    reg_s_axil_bresp(NUM_REGS)   <= m_axil_bresp;
    reg_s_axil_bvalid(NUM_REGS)  <= m_axil_bvalid;
    m_axil_bready                <= reg_s_axil_bready(NUM_REGS);
    m_axil_araddr                <= reg_s_axil_araddr(NUM_REGS);
    m_axil_arprot                <= reg_s_axil_arprot(NUM_REGS);
    m_axil_arvalid               <= reg_s_axil_arvalid(NUM_REGS);
    reg_s_axil_arready(NUM_REGS) <= m_axil_arready;
    reg_s_axil_rdata(NUM_REGS)   <= m_axil_rdata;
    reg_s_axil_rresp(NUM_REGS)   <= m_axil_rresp;
    reg_s_axil_rvalid(NUM_REGS)  <= m_axil_rvalid;
    m_axil_rready                <= reg_s_axil_rready(NUM_REGS);

  end generate;

end architecture;