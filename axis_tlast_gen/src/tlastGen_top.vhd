--!Configurable tlast generator. It has two modes of operation: 
--!* Packet mode: Configuring the packetsNum register with values >= 1 the module will generate as many tlast as packets have been configured with the number of bytes set in transferLen per packet
--!
--!* Continuous mode: Configuring the packetsNum register to 0 sets the module in continuous mode generating infinite tlast every X bytes depending on the transferLen configuration.
--!  
--!  Any tlast signal input in the module is propagated to the output. If the module is in continuous mode and bypass mode, we can rely on the tlast signal from the input.
--!  The module also supports data swapping (word and byte swapping) configurable through the AXI-Lite interface.
--!  The core mask the tkeep signal based on the transfer length to ensure that the number of bytes requested are the number of bytes transferred
--!  If a transfer length of 0 is set, the module doesn't generate tlast signals.
--!  The bytes in tkeep are masked in the way that when there are less bytes remaining to transfer than the data width, only the lower bytes are kept. Any high byte above the remaining bytes to transfer is masked to 0.
--!  Data mask can be disabled through the AXI-Lite interface. When working with input data streams that already have the correct tkeep for the transfer length, data mask can be disabled to propagate the input tkeep to the output.
--!  This module can be used for input streaming data swapping with Tlast passthrough and data swapping.
--!  
--!  
--! ## Register space
--! 
--! ### Overview
--! 
--! | OFFSET | LABEL                         | DESCRIPTION                                                                        |
--! | ------ | ----------------------------- | ---------------------------------------------------------------------------------- |
--! | 0x0    | **tlastGen Version**          | Core version info                                                                  |
--! | 0x4    | **tlastGen Control**          | Control of module operation, start/stop of CDF calculation and data request        |
--! | 0x8    | **tlastGen Transfer**         | Configuration of the number  of  samples  used  to  calculate the running  average |
--! | 0xC    | **tlastGen Packets Number**   | Configuration of the comparator voltage (DAC) step size                            |
--! ### Registers
--! | OFFSET | LABEL               |  R/W  | SC  | DESCRIPTION                                                                                                   | RESET VALUE |
--! | :----: | ------------------- | :---: | --- | ------------------------------------------------------------------------------------------------------------- | ----------- |
--! |  0x0   | **tlastGen Version** |       |     |                                                                                                             |             |
--! |        | _[31:0] Version_    |   R   | NO  | Version info                                                                                                  | 0x1         |
--! |  0x4   | **tlastGen Control** |       |     |                                                                                                             |             |
--! |        | _[0] resetn_        |  R/W  | NO  | Reset signal, active at low level                                                                             | 0x0         |
--! |        | _[1] enable_        |  R/W  | YES  | Enable signal. When 1 it indicates that the module is runnning, otherwise it is idle. Enable working as tigger | 0x0         |
--! |        | _[31:3] Reserved_   |       |     | Reserved                                                                                                      |             |
--! |  0x8   | **tlastGen Transfer**    |       |     |                                                                                                         |             |
--! |        | _[31:0] Value_      |  R/W  | NO  | Write Transfer length value in bytes. If set to 0, the module doesn't generate tlast signals. But can rely on input tlast signals depending on mode.                                                                          | 0x0         |
--! |  0xC   | **tlastGen Packets Number**    |       |     |                                                                                                         |             |
--! |        | _[31:0] Value_      |  R/W  | NO  | Write number of packets to be generated. By default, it is set to 1, generating a single packet (tlast is only active once). If set to 0 the module goes into continuous packet generation                                                                         | 0x1         |
--! |  0x10  | **Data_swap** |   |  |                                                                                       |          |
--! |        | _[31:0] Data_swap_ |   R/W  |   NO  | Data swap configuration.                                                                                           | 0x0      |
--! |        |                    |       |       | '0' -> No swapping                                                                                           |       |
--! |        |                    |       |       | '1' -> Word swapping (32-bit)                                                                            |             |
--! |        |                    |       |       | '2' -> Byte swapping (8-bit)                                                                            |             |
--! |        |                    |       |       | '3' -> Word and Byte swapping (32-bit and 8-bit)                                                            |             |
--! | 0x14   | **tlast generation mode** |       |     |                                                                                                             |             |
--! |        | _[31:0] tlast_gen_mode_       |  R/W  | NO  | Tlast generation mode.                                                                            | 0x1         |
--! |        |                    |       |       | '0' -> tlast generation disabled. Tlast passthrough                                                       |             |
--! |        |                    |       |       | '1' -> tlast generation enabled.                                                                          |             |
--! |        |                    |       |       | '2' -> tlast generation and passthrough enabled                                                           |             |
--! | 0x18   | **data mask** |       |     |                                                                                                             |             |
--! |        | _[31:0] data_mask_       |  R/W  | NO  | Mask tkeep signal to adjust the data captured to number of bytes configured.                          | 0x0         |
--! |        |                    |       |       | '0' -> data mask disabled. s_tkeep = m_tkeep                                                              |             |
--! |        |                    |       |       | '1' -> data mask enabled. Mask is calculated to adjusto bytes output. Only low bytes will be used when masking.  |             |


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tlastGen_regs_pkg.all;

entity tlastGen_top is
  generic (
    g_AXI_ADDR_WIDTH   : integer := 5; --! AXI-Lite address width
    g_AXIS_TDATA_WIDTH : integer := 32 --! AXI-Strea tdata width
  );
  port (
    axis_aclk        : in std_logic; --! AXI4-Stream clock
    axis_aresetn     : in std_logic; --! AXI4-Stream resetn
    axi_aclk         : in std_logic; --! AXI4-Lite clock
    axi_aresetn      : in std_logic; --! AXI4-Lite resetn
    tlast_gen_busy_o : out std_logic; --! tlast generator busy signal
    --! @virtualbus S_AXIS AXI-Stream Slave Bus
    s_axis_tdata  : in std_logic_vector(g_AXIS_TDATA_WIDTH - 1 downto 0);
    s_axis_tvalid : in std_logic;
    s_axis_tready : out std_logic;
    s_axis_tkeep  : in std_logic_vector (g_AXIS_TDATA_WIDTH/8 -1 downto 0) :=(others => '1');
    s_axis_tlast  : in std_logic; --! @end
    --! @virtualbus M_AXIS AXI-Stream Master Bus
    m_axis_tdata  : out std_logic_vector(g_AXIS_TDATA_WIDTH - 1 downto 0);
    m_axis_tvalid : out std_logic;
    m_axis_tready : in std_logic;
    m_axis_tlast  : out std_logic;
    m_axis_tkeep  : out std_logic_vector (g_AXIS_TDATA_WIDTH/8 -1 downto 0); --! @end    
    --! @virtualbus AXI_lite AXI-Lite Slave Bus
    s_axi_awaddr  : in std_logic_vector(g_AXI_ADDR_WIDTH - 1 downto 0);
    s_axi_awprot  : in std_logic_vector(2 downto 0);
    s_axi_awvalid : in std_logic;
    s_axi_awready : out std_logic;
    s_axi_wdata   : in std_logic_vector(31 downto 0);
    s_axi_wstrb   : in std_logic_vector(3 downto 0);
    s_axi_wvalid  : in std_logic;
    s_axi_wready  : out std_logic;
    s_axi_araddr  : in std_logic_vector(g_axi_addr_width - 1 downto 0);
    s_axi_arprot  : in std_logic_vector(2 downto 0);
    s_axi_arvalid : in std_logic;
    s_axi_arready : out std_logic;
    s_axi_rdata   : out std_logic_vector(31 downto 0);
    s_axi_rresp   : out std_logic_vector(1 downto 0);
    s_axi_rvalid  : out std_logic;
    s_axi_rready  : in std_logic;
    s_axi_bresp   : out std_logic_vector(1 downto 0);
    s_axi_bvalid  : out std_logic;
    s_axi_bready  : in std_logic --! @end
  );
end tlastGen_top;

architecture rtl of tlastGen_top is
  -- AXI regs
  signal s_user2regs : user2regs_t;
  signal s_regs2user : regs2user_t;
  --
  signal s_rstn        : std_logic;
  signal s_ena         : std_logic;
  signal s_transferLen : std_logic_vector(32 - 1 downto 0);
  signal s_packetsNum  : std_logic_vector(32 - 1 downto 0);
  signal s_data_swap   : std_logic_vector(32 - 1 downto 0);
  signal s_tlast_mode  : std_logic_vector(32 - 1 downto 0);
  signal s_data_mask   : std_logic_vector(32 - 1 downto 0);
  --
begin

  tlastGen_regs_inst : entity work.tlastGen_regs
    generic map(
      AXI_ADDR_WIDTH => g_AXI_ADDR_WIDTH
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
  --
  s_user2regs.version_value <= VERSION_VALUE_RESET;
  --
  s_rstn <= s_regs2user.control_rstn(0);
  s_ena  <= s_regs2user.control_enable(0);
  --
  s_transferLen <= s_regs2user.transferlen_value;
  s_packetsNum  <= s_regs2user.packetsnum_value;
  s_data_swap   <= s_regs2user.data_swap_value;
  s_tlast_mode  <= s_regs2user.tlast_gen_mode_value;
  s_data_mask   <= s_regs2user.data_mask_value;
  --
  tlastGen_inst : entity work.tlastGen
  generic map(
    g_AXIS_TDATA_WIDTH  => g_AXIS_TDATA_WIDTH
  )
  port map(
    axis_aclk        => axis_aclk,
    axis_aresetn     => axis_aresetn,
    s_axis_tdata     => s_axis_tdata,
    s_axis_tvalid    => s_axis_tvalid,
    s_axis_tready    => s_axis_tready,
    s_axis_tkeep     => s_axis_tkeep,
    s_axis_tlast     => s_axis_tlast,
    m_axis_tdata     => m_axis_tdata,
    m_axis_tvalid    => m_axis_tvalid,
    m_axis_tready    => m_axis_tready,
    m_axis_tlast     => m_axis_tlast,
    m_axis_tkeep     => m_axis_tkeep,
    rstn             => s_rstn,
    ena              => s_ena,
    transferLen      => s_transferLen,
    packetsNum       => s_packetsNum,
    data_swap        => s_data_swap,
    tlast_mode       => s_tlast_mode,
    tlast_gen_busy_o => tlast_gen_busy_o,
    data_mask        => s_data_mask
  );
end rtl;