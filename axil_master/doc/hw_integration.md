# Entity: axil_master 

## Diagram
![Diagram](hw_integration.svg "Diagram")

## Generics
| Generic name     | Type    | Value | Description                  |
| ---------------- | ------- | ----- | ---------------------------- |
| g_axi_addr_width | integer | 32    | Width of the AXI address bus |
| g_axi_data_width | integer | 32    | Width of the AXI data bus    |

## Ports
| Port name   | Direction | Type                                             | Description                                      |
| ----------- | --------- | ------------------------------------------------ | ------------------------------------------------ |
| addr        | in        | std_logic_vector (g_axi_addr_width - 1 downto 0) | Address to be written or read                    |
| write_vld   | in        | std_logic                                        | Trigger to start the AXI writing transaction     |
| dataIn      | in        | std_logic_vector (g_axi_data_width - 1 downto 0) | Data to write	                                |
| read_vld    | in        | std_logic                                        | Trigger to start the AXI reading transaction     |
| dataOut_vld | out       | std_logic                                        | Indicates when the data read is available        |
| dataOut     | out       | std_logic_vector (g_axi_data_width - 1 downto 0) | Data read                                        |
| done        | out       | std_logic                                        | Indicates when an AXI transaction is finished    |
| write_result| in        | std_logic_vector (1 downto 0)                    | Transaction result. bresp extension signal       |
| AXI_Lite    | in        | virtual bus                                      |                                                  |

### Virtual Buses
#### AXI_Lite
| Port name     | Direction | Type                                            | Description |
| ------------- | --------- | ----------------------------------------------- | ----------- |
| m_axi_aclk    | in        | std_logic                                       |             |
| m_axi_aresetn | in        | std_logic                                       |             |
| m_axi_awaddr  | out       | std_logic_vector(g_axi_addr_width - 1 downto 0) |             |
| m_axi_awvalid | out       | std_logic                                       |             |
| m_axi_awready | in        | std_logic                                       |             |
| m_axi_wdata   | out       | std_logic_vector(g_axi_data_width - 1 downto 0) |             |
| m_axi_wstrb   | out       | std_logic_vector(3 downto 0)                    |             |
| m_axi_wvalid  | out       | std_logic                                       |             |
| m_axi_wready  | in        | std_logic                                       |             |
| m_axi_araddr  | out       | std_logic_vector(g_axi_addr_width - 1 downto 0) |             |
| m_axi_arvalid | out       | std_logic                                       |             |
| m_axi_arready | in        | std_logic                                       |             |
| m_axi_rdata   | in        | std_logic_vector(g_axi_data_width - 1 downto 0) |             |
| m_axi_rresp   | in        | std_logic_vector(1 downto 0)                    |             |
| m_axi_rvalid  | in        | std_logic                                       |             |
| m_axi_rready  | out       | std_logic                                       |             |
| m_axi_bresp   | in        | std_logic_vector(1 downto 0)                    |             |
| m_axi_bvalid  | in        | std_logic                                       |             |
| m_axi_bready  | out       | std_logic                                       |             |