
# Entity: axil_register_top 
- **File**: axil_register_top.vhd

## Diagram
![Diagram](axil_register_top.svg "Diagram")
## Generics

| Generic name   | Type    | Value            | Description                  |
| -------------- | ------- | ---------------- | ---------------------------- |
| AXI_DATA_WIDTH | integer | 32               | Bus width                    |
| AXI_ADDR_WIDTH | integer | 32               | Bus address width            |
| STRB_WIDTH     | integer | AXI_DATA_WIDTH/8 | Strobe width                 |
| NUM_REGS       | integer | 1                | Number of full axi registers |

## Ports

| Port name   | Direction | Type        | Description |
| ----------- | --------- | ----------- | ----------- |
| s_aclk      | in        | std_logic   |             |
| axi_aresetn | in        | std_logic   |             |
| Axilite     | in        | Virtual bus |             |
| Axilite     | out       | Virtual bus |             |

### Virtual Buses

#### Axilite

| Port name      | Direction | Type                                           | Description |
| -------------- | --------- | ---------------------------------------------- | ----------- |
| s_axil_awaddr  | in        | std_logic_vector (AXI_ADDR_WIDTH - 1 downto 0) |             |
| s_axil_awprot  | in        | std_logic_vector (2 downto 0)                  |             |
| s_axil_awvalid | in        | std_logic                                      |             |
| s_axil_awready | out       | std_logic                                      |             |
| s_axil_wdata   | in        | std_logic_vector (AXI_DATA_WIDTH - 1 downto 0) |             |
| s_axil_wstrb   | in        | std_logic_vector (STRB_WIDTH - 1 downto 0)     |             |
| s_axil_wvalid  | in        | std_logic                                      |             |
| s_axil_wready  | out       | std_logic                                      |             |
| s_axil_bresp   | out       | std_logic_vector (1 downto 0)                  |             |
| s_axil_bvalid  | out       | std_logic                                      |             |
| s_axil_bready  | in        | std_logic                                      |             |
| s_axil_araddr  | in        | std_logic_vector (AXI_ADDR_WIDTH - 1 downto 0) |             |
| s_axil_arprot  | in        | std_logic_vector (2 downto 0)                  |             |
| s_axil_arvalid | in        | std_logic                                      |             |
| s_axil_arready | out       | std_logic                                      |             |
| s_axil_rdata   | out       | std_logic_vector (AXI_DATA_WIDTH - 1 downto 0) |             |
| s_axil_rresp   | out       | std_logic_vector (1 downto 0)                  |             |
| s_axil_rvalid  | out       | std_logic                                      |             |
| s_axil_rready  | in        | std_logic                                      |             |
#### Axilite

| Port name      | Direction | Type                                           | Description |
| -------------- | --------- | ---------------------------------------------- | ----------- |
| m_axil_awaddr  | out       | std_logic_vector (AXI_ADDR_WIDTH - 1 downto 0) |             |
| m_axil_awprot  | out       | std_logic_vector (2 downto 0)                  |             |
| m_axil_awvalid | out       | std_logic                                      |             |
| m_axil_awready | in        | std_logic                                      |             |
| m_axil_wdata   | out       | std_logic_vector (AXI_DATA_WIDTH - 1 downto 0) |             |
| m_axil_wstrb   | out       | std_logic_vector (STRB_WIDTH - 1 downto 0)     |             |
| m_axil_wvalid  | out       | std_logic                                      |             |
| m_axil_wready  | in        | std_logic                                      |             |
| m_axil_bresp   | in        | std_logic_vector (1 downto 0)                  |             |
| m_axil_bvalid  | in        | std_logic                                      |             |
| m_axil_bready  | out       | std_logic                                      |             |
| m_axil_araddr  | out       | std_logic_vector (AXI_ADDR_WIDTH - 1 downto 0) |             |
| m_axil_arprot  | out       | std_logic_vector (2 downto 0)                  |             |
| m_axil_arvalid | out       | std_logic                                      |             |
| m_axil_arready | in        | std_logic                                      |             |
| m_axil_rdata   | in        | std_logic_vector (AXI_DATA_WIDTH - 1 downto 0) |             |
| m_axil_rresp   | in        | std_logic_vector (1 downto 0)                  |             |
| m_axil_rvalid  | in        | std_logic                                      |             |
| m_axil_rready  | out       | std_logic                                      |             |

## Signals

| Name               | Type                                                                   | Description |
| ------------------ | ---------------------------------------------------------------------- | ----------- |
| reg_s_axil_awaddr  | typea_nslavesxaddrstd (NUM_REGS downto 0)(AXI_ADDR_WIDTH - 1 downto 0) |             |
| reg_s_axil_awprot  | typea_nslavesxprotstd (NUM_REGS downto 0)(2 downto 0)                  |             |
| reg_s_axil_awvalid | std_logic_vector (NUM_REGS downto 0)                                   |             |
| reg_s_axil_awready | std_logic_vector (NUM_REGS downto 0)                                   |             |
| reg_s_axil_wdata   | typea_nslavesxdatastd (NUM_REGS downto 0)(AXI_DATA_WIDTH - 1 downto 0) |             |
| reg_s_axil_wstrb   | typea_nslavesxwstrbstd (NUM_REGS downto 0)(STRB_WIDTH - 1 downto 0)    |             |
| reg_s_axil_wvalid  | std_logic_vector (NUM_REGS downto 0)                                   |             |
| reg_s_axil_wready  | std_logic_vector (NUM_REGS downto 0)                                   |             |
| reg_s_axil_bresp   | typea_nslavesxrespstd (NUM_REGS downto 0)(1 downto 0)                  |             |
| reg_s_axil_bvalid  | std_logic_vector (NUM_REGS downto 0)                                   |             |
| reg_s_axil_bready  | std_logic_vector (NUM_REGS downto 0)                                   |             |
| reg_s_axil_araddr  | typea_nslavesxaddrstd (NUM_REGS downto 0)(AXI_ADDR_WIDTH - 1 downto 0) |             |
| reg_s_axil_arprot  | typea_nslavesxprotstd (NUM_REGS downto 0)(2 downto 0)                  |             |
| reg_s_axil_arvalid | std_logic_vector (NUM_REGS downto 0)                                   |             |
| reg_s_axil_arready | std_logic_vector (NUM_REGS downto 0)                                   |             |
| reg_s_axil_rdata   | typea_nslavesxdatastd (NUM_REGS downto 0)(AXI_DATA_WIDTH - 1 downto 0) |             |
| reg_s_axil_rresp   | typea_nslavesxrespstd (NUM_REGS downto 0)(1 downto 0)                  |             |
| reg_s_axil_rvalid  | std_logic_vector (NUM_REGS downto 0)                                   |             |
| reg_s_axil_rready  | std_logic_vector (NUM_REGS downto 0)                                   |             |
