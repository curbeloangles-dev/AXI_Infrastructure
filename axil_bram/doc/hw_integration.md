# Entity: axil_bram

- **File**: axil_bram.vhd

## Diagram

![Diagram](hw_integration.svg "Diagram")

## Generics

| Generic name     | Type     | Value | Description                  |
| ---------------- | -------- | ----- | ---------------------------- |
| g_AXI_ADDR_WIDTH | integer  | 32    | Width of the AXI address bus |
| g_data_depth     | positive | 30    |  Memory depth in words (32 bit) |

## Ports

| Port name   | Direction | Type        | Description |
| ----------- | --------- | ----------- | ----------- |
| axi_aclk    | in        | std_logic   |             |
| axi_aresetn | in        | std_logic   |             |
| Axilite     | in        | Virtual bus | bus         |

### Virtual Buses

#### Axilite

| Port name     | Direction | Type                                            | Description |
| ------------- | --------- | ----------------------------------------------- | ----------- |
| s_axi_awaddr  | in        | std_logic_vector(g_AXI_ADDR_WIDTH - 1 downto 0) |             |
| s_axi_awprot  | in        | std_logic_vector(2 downto 0)                    |             |
| s_axi_awvalid | in        | std_logic                                       |             |
| s_axi_awready | out       | std_logic                                       |             |
| s_axi_wdata   | in        | std_logic_vector(31 downto 0)                   |             |
| s_axi_wstrb   | in        | std_logic_vector(3 downto 0)                    |             |
| s_axi_wvalid  | in        | std_logic                                       |             |
| s_axi_wready  | out       | std_logic                                       |             |
| s_axi_araddr  | in        | std_logic_vector(g_AXI_ADDR_WIDTH - 1 downto 0) |             |
| s_axi_arprot  | in        | std_logic_vector(2 downto 0)                    |             |
| s_axi_arvalid | in        | std_logic                                       |             |
| s_axi_arready | out       | std_logic                                       |             |
| s_axi_rdata   | out       | std_logic_vector(31 downto 0)                   |             |
| s_axi_rresp   | out       | std_logic_vector(1 downto 0)                    |             |
| s_axi_rvalid  | out       | std_logic                                       |             |
| s_axi_rready  | in        | std_logic                                       |             |
| s_axi_bresp   | out       | std_logic_vector(1 downto 0)                    |             |
| s_axi_bvalid  | out       | std_logic                                       |             |
| s_axi_bready  | in        | std_logic                                       |             |

