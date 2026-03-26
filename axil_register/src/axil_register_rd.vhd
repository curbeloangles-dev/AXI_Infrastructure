
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axil_register_rd is
  generic
  (
    DATA_WIDTH  : integer := 32;
    ADDR_WIDTH  : integer := 32;
    STRB_WIDTH  : integer := DATA_WIDTH/8;
    AR_REG_TYPE : integer := 1; --! address read channel register type
    R_REG_TYPE  : integer := 1  --! read channel register type
  );
  port
  (
    clk  : in std_logic;
    rstn : in std_logic;
    --! axil slave interface
    s_axil_araddr  : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
    s_axil_arprot  : in std_logic_vector (2 downto 0);
    s_axil_arvalid : in std_logic;
    s_axil_arready : out std_logic;
    s_axil_rdata   : out std_logic_vector (DATA_WIDTH - 1 downto 0);
    s_axil_rresp   : out std_logic_vector (1 downto 0);
    s_axil_rvalid  : out std_logic;
    s_axil_rready  : in std_logic;
    --! axil master interface
    m_axil_araddr  : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
    m_axil_arprot  : out std_logic_vector (2 downto 0);
    m_axil_arvalid : out std_logic;
    m_axil_arready : in std_logic;
    m_axil_rdata   : in std_logic_vector (DATA_WIDTH - 1 downto 0);
    m_axil_rresp   : in std_logic_vector (1 downto 0);
    m_axil_rvalid  : in std_logic;
    m_axil_rready  : out std_logic
  );
end axil_register_rd;

architecture rtl of axil_register_rd is

  signal s_axil_arready_reg                      : std_logic                                 := '0';
  signal m_axil_araddr_reg                       : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
  signal m_axil_arprot_reg                       : std_logic_vector(2 downto 0)              := (others => '0');
  signal m_axil_arvalid_reg, m_axil_arvalid_next : std_logic                                 := '0';

  signal store_axil_ar_input_to_output : std_logic := '0';
  signal s_axil_arready_early          : std_logic := '0';

  signal m_axil_rready_reg                     : std_logic                                 := '0';
  signal s_axil_rdata_reg                      : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
  signal s_axil_rresp_reg                      : std_logic_vector(1 downto 0)              := (others => '0');
  signal s_axil_rvalid_reg, s_axil_rvalid_next : std_logic                                 := '0';

  signal store_axil_r_input_to_output : std_logic := '0';
  signal m_axil_rready_early          : std_logic := '0';

begin

  ar_channel : if AR_REG_TYPE = 1 generate
    --! Simple register
    s_axil_arready <= s_axil_arready_reg;
    m_axil_araddr  <= m_axil_araddr_reg;
    m_axil_arprot  <= m_axil_arprot_reg;
    m_axil_arvalid <= m_axil_arvalid_reg;

    -- enable ready input next cycle if output buffer will be empty
    s_axil_arready_early <= not m_axil_arvalid_next;

    process (all)
    begin
      -- transfer sink ready state to source
      m_axil_arvalid_next <= m_axil_arvalid_reg;

      store_axil_ar_input_to_output <= '0';

      if (s_axil_arready_reg) then
        m_axil_arvalid_next           <= s_axil_arvalid;
        store_axil_ar_input_to_output <= '1';
      elsif (m_axil_arready) then
        m_axil_arvalid_next <= '0';
      end if;
    end process;

    process (clk)
    begin
      if rising_edge(clk) then
        if rstn = '0' then
          s_axil_arready_reg <= '0';
          m_axil_arvalid_reg <= '0';
        else
          s_axil_arready_reg <= s_axil_arready_early;
          m_axil_arvalid_reg <= m_axil_arvalid_next;
        end if;
        -- datapath
        if (store_axil_ar_input_to_output) then
          m_axil_araddr_reg <= s_axil_araddr;
          m_axil_arprot_reg <= s_axil_arprot;
        end if;
      end if;
    end process;

  end generate;

  ar_channel_bypass : if AR_REG_TYPE = 0 generate
    -- bypass AR channel
    m_axil_araddr  <= s_axil_araddr;
    m_axil_arprot  <= s_axil_arprot;
    m_axil_arvalid <= s_axil_arvalid;
    s_axil_arready <= m_axil_arready;
  end generate;

  r_channel : if R_REG_TYPE = 1 generate
    -- simple register
    m_axil_rready <= m_axil_rready_reg;
    s_axil_rdata  <= s_axil_rdata_reg;
    s_axil_rresp  <= s_axil_rresp_reg;
    s_axil_rvalid <= s_axil_rvalid_reg;

    -- enable ready input next cycle if output buffer will be empty
    m_axil_rready_early <= not s_axil_rvalid_next;

    process (all)
    begin
      -- transfer sink ready state to source
      s_axil_rvalid_next <= s_axil_rvalid_reg;

      store_axil_r_input_to_output <= '0';

      if (m_axil_rready_reg) then
        s_axil_rvalid_next           <= m_axil_rvalid;
        store_axil_r_input_to_output <= '1';
      elsif (s_axil_rready) then
        s_axil_rvalid_next <= '0';
      end if;
    end process;

    process (clk)
    begin
      if rising_edge(clk) then
        if rstn = '0' then
          m_axil_rready_reg <= '0';
          s_axil_rvalid_reg <= '0';
        else
          m_axil_rready_reg <= m_axil_rready_early;
          s_axil_rvalid_reg <= s_axil_rvalid_next;
        end if;
        -- datapath
        if (store_axil_r_input_to_output) then
          s_axil_rdata_reg <= m_axil_rdata;
          s_axil_rresp_reg <= m_axil_rresp;
        end if;
      end if;
    end process;
  end generate;

  r_channel_bypass : if R_REG_TYPE = 0 generate
    -- bypass R channel
    s_axil_rdata  <= m_axil_rdata;
    s_axil_rresp  <= m_axil_rresp;
    s_axil_rvalid <= m_axil_rvalid;
    m_axil_rready <= s_axil_rready;
  end generate;

end architecture;