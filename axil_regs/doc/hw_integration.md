# Entity: axil_regs 
- **File**: axil_regs.vhd

## Diagram
![Diagram](hw_integration.svg "Diagram")

## Description
This core implements a register map where the amount of registers can be customized. Every time a register is written or readd an irq signals is triggered to indicate which of those registers modified its content. No matter what size the register map is, the write and read irq ports always will be the same: half of the total amount of registers, e.g: g_total_registers = 128 will have 64 read irqs and 64 write irqs. 

## Generics
| Generic name      | Type    | Value | Description                                                                                             |
| ----------------- | ------- | ----- | ------------------------------------------------------------------------------------------------------- |
| g_axi_addr_width  | integer | 32    | width of the AXI address bus                                                                            |
| g_axi_data_width  | integer | 32    | width of the AXI data bus                                                                               |
| g_total_registers | integer | 64    | Total amount of registers. It has to be even                                                            |
| g_external_bresp  | boolean | true  | When false bresp is asserted after writing a register. When true bresp comes from an external source    |

## Ports
| Port name             | Direction | Type                                               | Description                              |
| --------------------- | --------- | -------------------------------------------------- | ---------------------------------------- |
| axi_aclk              | in        | std_logic                                          |                                          |
| axi_aresetn           | in        | std_logic                                          |                                          |
| register_value        | out       | std_logic_vector(g_axi_data_width - 1 downto 0)    | Last data written                        |
| read_irq              | out       | std_logic_vector(g_total_registers/2 - 1 downto 0) | Read irq bus                             |
| write_irq             | out       | std_logic_vector(g_total_registers/2 - 1 downto 0) | Write irq bus                            |
| external_bresp        | in        | std_logic                                          | bresp from an external source            |
| external_bresp_vld    | in        | std_logic_vector(1 downto 0)                       | bresp valid from an external source      |
| Axilite               | in        | virtual bus                                        | bus                                      |

### Virtual Buses
#### Axilite
| Port name     | Direction | Type                                            | Description |
| ------------- | --------- | ----------------------------------------------- | ----------- |
| s_axi_awaddr  | in        | std_logic_vector(g_axi_addr_width - 1 downto 0) |             |
| s_axi_awprot  | in        | std_logic_vector(2 downto 0)                    |             |
| s_axi_awvalid | in        | std_logic                                       |             |
| s_axi_awready | out       | std_logic                                       |             |
| s_axi_wdata   | in        | std_logic_vector(g_axi_data_width - 1 downto 0) |             |
| s_axi_wstrb   | in        | std_logic_vector(3 downto 0)                    |             |
| s_axi_wvalid  | in        | std_logic                                       |             |
| s_axi_wready  | out       | std_logic                                       |             |
| s_axi_araddr  | in        | std_logic_vector(g_axi_addr_width - 1 downto 0) |             |
| s_axi_arprot  | in        | std_logic_vector(2 downto 0)                    |             |
| s_axi_arvalid | in        | std_logic                                       |             |
| s_axi_arready | out       | std_logic                                       |             |
| s_axi_rdata   | out       | std_logic_vector(g_axi_data_width - 1 downto 0) |             |
| s_axi_rresp   | out       | std_logic_vector(1 downto 0)                    |             |
| s_axi_rvalid  | out       | std_logic                                       |             |
| s_axi_rready  | in        | std_logic                                       |             |
| s_axi_bresp   | out       | std_logic_vector(1 downto 0)                    |             |
| s_axi_bvalid  | out       | std_logic                                       |             |
| s_axi_bready  | in        | std_logic                                       |             |

## Signals
| Name               | Type                                            | Description |
| ------------------ | ----------------------------------------------- | ----------- |
| s_read_state       | read_states                                     |             |
| s_write_state      | write_states                                    |             |
| s_axi_awready_r    | std_logic                                       |             |
| s_axi_wready_r     | std_logic                                       |             |
| s_axi_awaddr_reg_r | unsigned(s_axi_awaddr'range)                    |             |
| s_axi_bvalid_r     | std_logic                                       |             |
| s_axi_bresp_r      | std_logic_vector(s_axi_bresp'range)             |             |
| s_axi_arready_r    | std_logic                                       |             |
| s_axi_araddr_reg_r | unsigned(g_axi_addr_width - 1 downto 0)         |             |
| s_axi_rvalid_r     | std_logic                                       |             |
| s_axi_rresp_r      | std_logic_vector(s_axi_rresp'range)             |             |
| s_axi_wdata_reg_r  | std_logic_vector(s_axi_wdata'range)             |             |
| s_axi_wstrb_reg_r  | std_logic_vector(s_axi_wstrb'range)             |             |
| s_axi_rdata_r      | std_logic_vector(s_axi_rdata'range)             |             |
| register_map       | register_array                                  |             |
| s_read_irq_r       | std_logic_vector(0 to g_total_registers/2 - 1)  |             |
| s_write_irq_r      | std_logic_vector(0 to g_total_registers/2 - 1)  |             |
| last_data_written  | std_logic_vector(g_axi_data_width - 1 downto 0) |             |

## Constants
| Name           | Type                         | Value | Description |
| -------------- | ---------------------------- | ----- | ----------- |
| c_AXI_DIR_BITS | positive                     | 12    |             |
| AXI_OKAY       | std_logic_vector(1 downto 0) | "00"  |             |
| AXI_DECERR     | std_logic_vector(1 downto 0) | "11"  |             |