library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.axis_counter_regs_pkg.all;
--! - **Name:** axis_counter 
--!
--! - **Human Name:** Axis Counter Top
--!
--! - **One-line Description:** This module is the top module for the axis_counter. It instantiates the counter with AXI interfaces.  
--!
--! - **One-paragraph Description:** It receives the input configuration and control from the AXI-Lite interface. 
--!   The counter is executed and the count is sent to the AXI-Stream interface. 
--!   The count can:
--!   - Count up and down
--!   - Change the step of the count
--!   
--!
--! ### Features
--! 
--! **Generic accepted values**
--!    - g_axil_addr_width     : 32
--!    - g_axis_data_width     : 32
--!    - g_counter_width       : 32
--! **Latency**
--!
--! **Running mode**
--! 
--! 
--! **Corner cases**
--!   
--!   
--! 
--! ### Future improvements
--!
--! ### Register space
--! **Overview**
--! 
--! | Offset | Name                       | Description | Type |
--! | ------ | -------------------------- | ----------- | ---- |
--! | `0x0`  | control                    |             | REG  |
--! | `0x4`  | step_size                  |             | REG  |
--! 
--! **Registers**
--! 
--! | Offset | Name                       | Description                 | Type | Access | Attributes | Reset        |
--! | ------ | -------------------------- | --------------------------- | ---- | ------ | ---------- | ------------ |
--! | `0x0`  | control                    |                             | REG  | R/W    |            | `0x6`        |
--! |        | [2] up_down                | 1=Up - 0=Down               |      |        |            | `0x1`        |
--! |        | [1] resetn                 |                             |      |        |            | '0x1`        |
--! |        | [0] start                  |                             |      |        |            | '0x0`        |
--! | `0x4`  | step_size                  |                             | REG  | R/W    |            | `0x1`        |
--! |        | [31:0] step_size           |                             |      |        |            | `0x1`        |
entity axis_counter is
  generic (
    g_axil_addr_width : integer := 32;--! AXI-lite addr width
    g_axis_data_width : integer := 32;--! Axi-Stream data width
    g_counter_width   : integer := 32--! Counter size
  );
  port (
    --Clock and Reset
    axi_aclk    : in std_logic;
    axi_aresetn : in std_logic;
    --! @virtualbus S_AXIL AXI-Lite Slave Bus
    -- AXI Write Address Channel
    s_axi_awaddr  : in std_logic_vector(g_axil_addr_width - 1 downto 0);
    s_axi_awprot  : in std_logic_vector(2 downto 0);
    s_axi_awvalid : in std_logic;
    s_axi_awready : out std_logic;
    -- AXI Write Data Channel
    s_axi_wdata  : in std_logic_vector(31 downto 0);
    s_axi_wstrb  : in std_logic_vector(3 downto 0);
    s_axi_wvalid : in std_logic;
    s_axi_wready : out std_logic;
    -- AXI Read Address Channel
    s_axi_araddr  : in std_logic_vector(g_axil_addr_width - 1 downto 0);
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
    s_axi_bready : in std_logic;
    --! @virtualbus M_AXIS @dir out AXI-Stream Master Bus
    m_axis_tdata  : out std_logic_vector(g_axis_data_width - 1 downto 0);
    m_axis_tvalid : out std_logic;
    m_axis_tready : in std_logic
  );
end axis_counter;

architecture Structural of axis_counter is
  -- Señales internas
  signal regs_out : user2regs_t;
  signal regs_in  : regs2user_t;

begin

  -- Instancia del módulo AXI-Lite
  axi_counter_inst : entity work.axis_counter_regs
    generic map(
      g_axi_addr_width => g_axil_addr_width -- width of the AXI address word, in bits
    )
    port map
    (
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
      user2regs     => regs_out,
      regs2user     => regs_in
    );

  -- Instancia del contador
  counter_inst : entity work.counter
    generic map(
      g_axis_data_width => g_axis_data_width, -- width of the AXIS data width and counter size, in bits
      g_counter_width   => g_counter_width
    )
    port map
    (
      clk           => axi_aclk,
      resetn        => regs_in.control_resetn(0) and axi_aresetn,
      start_in      => regs_in.control_start(0),
      up_down_in    => regs_in.control_up_down(0),
      step_in       => regs_in.step_size_step_size(g_counter_width - 1 downto 0),
      m_axis_tdata  => m_axis_tdata,
      m_axis_tvalid => m_axis_tvalid,
      m_axis_tready => m_axis_tready
    );

end Structural;
