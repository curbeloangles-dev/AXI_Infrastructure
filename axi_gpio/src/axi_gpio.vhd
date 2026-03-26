--!## Register space
--!### Overview
--!
--!| OFFSET | LABEL       | DESCRIPTION       |
--!| ------ | ----------- | ----------------- |
--!| 0x0    | **Version** | Core version info |
--!| 0x4    | **GPO**     | GPO Ports values  |
--!| 0x8    | **GPI**     | GPI Ports values  |
--!
--!### Registers
--!| OFFSET | LABEL            |  R/W  | SC  | DESCRIPTION  | RESET VALUE |
--!| :----: | ---------------- | :---: | --- | ------------ | ----------- |
--!|  0x0   | **Version**      |       |     |              |             |
--!|        | _[31:0] Version_ |   R   | NO  | Version info | 0x1         |
--!|  0x4   | **GPO**          |       |     |              |             |
--!|        | _[31:0] GPO_     |  R/W  | NO  | Write GPO values. Each bit corresponds to a single port in the same order as the module interface    | 0x0         |
--!|  0x8   | **GPI**          |       |     |              |             |
--!|        | _[31:0] GPI_     |   R   | NO  | Read GPI values. Each bit corresponds to a single port in the same order as the module interface    | 0x0         |
--!
--! Standard library.
library ieee;
--! Logic elements.
use ieee.std_logic_1164.all;
--! arithmetic functions.
use ieee.numeric_std.all;
--! Modules
use work.axi_gpio_regs_pkg.all;
--! @details implementation of axi_gpio
--! @ingroup axi_gpio

entity axi_gpio is
  generic (
    g_GPO_WIDTH       : integer range 1 to 32         := 32; --! Configuration of the number of GPO Ports. Range allowed: [1,32]
    g_GPI_WIDTH       : integer range 1 to 32         := 32;--! Configuration of the number of GPI Ports. Range allowed: [1,32]
    g_AXI_ADDR_WIDTH  : integer                       := 32; --! Width of the AXI address bus
    g_DEFAULT_GPO_VAL : std_logic_vector(31 downto 0) := "00000000000000000000000000000000"--! Default GPO after reset
  );
  port (
    -- GPIO
    gpo : out std_logic_vector(g_GPO_WIDTH - 1 downto 0); --! GPO ports
    gpi : in std_logic_vector(g_GPI_WIDTH - 1 downto 0); --! GPI ports
    -- AXI Lite
    axi_aclk      : in std_logic;--! AXI4-Lite clock (used as core clock)
    axi_aresetn   : in std_logic;--! AXI4-Lite aresetn
    s_axi_awaddr  : in std_logic_vector(g_AXI_ADDR_WIDTH - 1 downto 0);
    s_axi_awprot  : in std_logic_vector(2 downto 0);
    s_axi_awvalid : in std_logic;
    s_axi_awready : out std_logic;
    s_axi_wdata   : in std_logic_vector(31 downto 0);
    s_axi_wstrb   : in std_logic_vector(3 downto 0);
    s_axi_wvalid  : in std_logic;
    s_axi_wready  : out std_logic;
    s_axi_araddr  : in std_logic_vector(g_AXI_ADDR_WIDTH - 1 downto 0);
    s_axi_arprot  : in std_logic_vector(2 downto 0);
    s_axi_arvalid : in std_logic;
    s_axi_arready : out std_logic;
    s_axi_rdata   : out std_logic_vector(31 downto 0);
    s_axi_rresp   : out std_logic_vector(1 downto 0);
    s_axi_rvalid  : out std_logic;
    s_axi_rready  : in std_logic;
    s_axi_bresp   : out std_logic_vector(1 downto 0);
    s_axi_bvalid  : out std_logic;
    s_axi_bready  : in std_logic
  );
end axi_gpio;

architecture rtl of axi_gpio is
  -- signals
  signal s_user2regs : user2regs_t;
  signal s_regs2user : regs2user_t;
begin
  -- AXI-Lite
  axi_gpio_regs_i : entity work.axi_gpio_regs
    generic map(
      AXI_ADDR_WIDTH    => g_AXI_ADDR_WIDTH,
      g_DEFAULT_GPO_VAL => g_DEFAULT_GPO_VAL
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
  s_user2regs.version_value                       <= VERSION_VALUE_RESET;
  gpo                                             <= s_regs2user.gpo_value(g_GPO_WIDTH - 1 downto 0);
  s_user2regs.gpi_value(g_GPI_WIDTH - 1 downto 0) <= gpi;
  s_user2regs.gpi_value(31 downto g_GPI_WIDTH)    <= (others => '0');

end rtl;