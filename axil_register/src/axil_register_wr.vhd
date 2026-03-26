
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axil_register_wr is
  generic
  (
    DATA_WIDTH  : integer := 32;
    ADDR_WIDTH  : integer := 32;
    STRB_WIDTH  : integer := DATA_WIDTH/8;
    AW_REG_TYPE : integer := 1;
    W_REG_TYPE  : integer := 1;
    B_REG_TYPE  : integer := 1
  );
  port
  (
    clk            : in std_logic;
    rstn           : in std_logic;
    s_axil_awaddr  : in std_logic_vector (ADDR_WIDTH - 1 downto 0);
    s_axil_awprot  : in std_logic_vector (2 downto 0);
    s_axil_awvalid : in std_logic;
    s_axil_awready : out std_logic;
    s_axil_wdata   : in std_logic_vector (DATA_WIDTH - 1 downto 0);
    s_axil_wstrb   : in std_logic_vector (STRB_WIDTH - 1 downto 0);
    s_axil_wvalid  : in std_logic;
    s_axil_wready  : out std_logic;
    s_axil_bresp   : out std_logic_vector (1 downto 0);
    s_axil_bvalid  : out std_logic;
    s_axil_bready  : in std_logic;
    m_axil_awaddr  : out std_logic_vector (ADDR_WIDTH - 1 downto 0);
    m_axil_awprot  : out std_logic_vector (2 downto 0);
    m_axil_awvalid : out std_logic;
    m_axil_awready : in std_logic;
    m_axil_wdata   : out std_logic_vector (DATA_WIDTH - 1 downto 0);
    m_axil_wstrb   : out std_logic_vector (STRB_WIDTH - 1 downto 0);
    m_axil_wvalid  : out std_logic;
    m_axil_wready  : in std_logic;
    m_axil_bresp   : in std_logic_vector (1 downto 0);
    m_axil_bvalid  : in std_logic;
    m_axil_bready  : out std_logic
  );
end axil_register_wr;

architecture rtl of axil_register_wr is

  -- datapath registers
  signal s_axil_awready_reg : std_logic := '0';

  signal m_axil_awaddr_reg   : std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
  signal m_axil_awprot_reg   : std_logic_vector(2 downto 0)               := (others => '0');
  signal m_axil_awvalid_reg  : std_logic                                  := '0';
  signal m_axil_awvalid_next : std_logic                                  := '0';

  -- datapath control
  signal store_axil_aw_input_to_output : std_logic := '0';
  signal s_axil_awready_early          : std_logic := '0';

  -- datapath registers
  signal s_axil_wready_reg : std_logic := '0';

  signal m_axil_wdata_reg   : std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
  signal m_axil_wstrb_reg   : std_logic_vector(STRB_WIDTH - 1 downto 0)  := (others => '0');
  signal m_axil_wvalid_reg  : std_logic                                  := '0';
  signal m_axil_wvalid_next : std_logic                                  := '0';

  -- datapath control
  signal store_axil_w_input_to_output : std_logic := '0';
  signal s_axil_wready_early          : std_logic := '0';

  -- datapath registers
  signal m_axil_bready_reg : std_logic := '0';

  signal s_axil_bresp_reg   : std_logic_vector(1 downto 0) := (others => '0');
  signal s_axil_bvalid_reg  : std_logic                    := '0';
  signal s_axil_bvalid_next : std_logic                    := '0';

  -- datapath control
  signal store_axil_b_input_to_output : std_logic := '0';
  signal m_axil_bready_early          : std_logic := '0';

begin

  -- AW channel
  aw_channel : if AW_REG_TYPE = 1 generate
    -- Simple register
    s_axil_awready <= s_axil_awready_reg;
    m_axil_awaddr  <= m_axil_awaddr_reg;
    m_axil_awprot  <= m_axil_awprot_reg;
    m_axil_awvalid <= m_axil_awvalid_reg;

    -- enable ready input next cycle if output buffer will be empty
    s_axil_awready_early <= not m_axil_awvalid_next;

    process (all)
    begin
      -- transfer sink ready state to source
      m_axil_awvalid_next <= m_axil_awvalid_reg;

      store_axil_aw_input_to_output <= '0';

      if (s_axil_awready_reg) then
        m_axil_awvalid_next           <= s_axil_awvalid;
        store_axil_aw_input_to_output <= '1';
      elsif (m_axil_awready) then
        m_axil_awvalid_next <= '0';
      end if;
    end process;

    process (clk)
    begin
      if rising_edge(clk) then
        if rstn = '0' then
          s_axil_awready_reg <= '0';
          m_axil_awvalid_reg <= '0';

        else
          s_axil_awready_reg <= s_axil_awready_early;
          m_axil_awvalid_reg <= m_axil_awvalid_next;
        end if;
        -- datapath
        if (store_axil_aw_input_to_output) then
          m_axil_awaddr_reg <= s_axil_awaddr;
          m_axil_awprot_reg <= s_axil_awprot;
        end if;
      end if;
    end process;
  end generate;
  aw_channel_bypass : if AW_REG_TYPE = 0 generate
    -- bypass AW channel
    m_axil_awaddr  <= s_axil_awaddr;
    m_axil_awprot  <= s_axil_awprot;
    m_axil_awvalid <= s_axil_awvalid;
    s_axil_awready <= m_axil_awready;
  end generate;

  w_channel : if W_REG_TYPE = 1 generate
    s_axil_wready <= s_axil_wready_reg;

    m_axil_wdata  <= m_axil_wdata_reg;
    m_axil_wstrb  <= m_axil_wstrb_reg;
    m_axil_wvalid <= m_axil_wvalid_reg;

    -- enable ready input next cycle if output buffer will be empty
    s_axil_wready_early <= not m_axil_wvalid_next;

    process (all)
    begin
      m_axil_wvalid_next <= m_axil_wvalid_reg;

      store_axil_w_input_to_output <= '0';

      if (s_axil_wready_reg) then
        m_axil_wvalid_next           <= s_axil_wvalid;
        store_axil_w_input_to_output <= '1';
      elsif (m_axil_wready) then
        m_axil_wvalid_next <= '0';
      end if;
    end process;

    process (clk)
    begin
      if rising_edge(clk) then
        if rstn = '0' then
          s_axil_wready_reg <= '0';
          m_axil_wvalid_reg <= '0';
        else
          s_axil_wready_reg <= s_axil_wready_early;
          m_axil_wvalid_reg <= m_axil_wvalid_next;
        end if;
        -- datapath
        if (store_axil_w_input_to_output) then
          m_axil_wdata_reg <= s_axil_wdata;
          m_axil_wstrb_reg <= s_axil_wstrb;
        end if;
      end if;

    end process;

  end generate;

  w_channel_bypass : if W_REG_TYPE = 0 generate
    -- bypass W channel
    m_axil_wdata  <= s_axil_wdata;
    m_axil_wstrb  <= s_axil_wstrb;
    m_axil_wvalid <= s_axil_wvalid;
    s_axil_wready <= m_axil_wready;
  end generate;

  -- B channel
  b_channel : if B_REG_TYPE = 1 generate
    m_axil_bready <= m_axil_bready_reg;
    s_axil_bresp  <= s_axil_bresp_reg;
    s_axil_bvalid <= s_axil_bvalid_reg;

    -- enable ready input next cycle if output buffer will be empty
    m_axil_bready_early <= not s_axil_bvalid_next;

    process (all)
    begin
      -- transfer sink ready state to source
      s_axil_bvalid_next <= s_axil_bvalid_reg;

      store_axil_b_input_to_output <= '0';

      if (m_axil_bready_reg) then
        s_axil_bvalid_next           <= m_axil_bvalid;
        store_axil_b_input_to_output <= '1';
      elsif (s_axil_bready) then
        s_axil_bvalid_next <= '0';
      end if;
    end process;

    process (clk)
    begin
      if rising_edge(clk) then
        if rstn = '0' then
          m_axil_bready_reg <= '0';
          s_axil_bvalid_reg <= '0';
        else
          m_axil_bready_reg <= m_axil_bready_early;
          s_axil_bvalid_reg <= s_axil_bvalid_next;
        end if;
        -- datapath
        if (store_axil_b_input_to_output) then
          s_axil_bresp_reg <= m_axil_bresp;
        end if;
      end if;
    end process;
end generate;

    b_channel_bypass : if B_REG_TYPE = 0 generate
        -- bypass B channel
        s_axil_bresp  <= m_axil_bresp;
        s_axil_bvalid <= m_axil_bvalid;
        m_axil_bready <= s_axil_bready;
    end generate;


end architecture;