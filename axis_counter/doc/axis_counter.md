
# Entity: axis_counter 
- **File**: axis_counter.vhd

## Diagram
![Diagram](axis_counter.svg "Diagram")
## Description

- **Name:** axis_counter

- **Human Name:** Axis Counter Top

- **One-line Description:** This module is the top module for the axis_counter. It instantiates the counter with AXI interfaces.

- **One-paragraph Description:** It receives the input configuration and control from the AXI-Lite interface. The counter is executed and the count is sent to the AXI-Stream interface. The count can: - Count up and down - Change the step of the count

 ### Features

**Generic accepted values** - g_axil_addr_width     : 32 - g_axis_data_width     : 32 - g_counter_width       : 32 **Latency**

**Running mode**

 **Corner cases**



### Future improvements

### Register space **Overview**

| Offset | Name                       | Description | Type | | ------ | -------------------------- | ----------- | ---- | | `0x0`  | control                    |             | REG  | | `0x4`  | step_size                  |             | REG  |

**Registers**

| Offset | Name                       | Description                 | Type | Access | Attributes | Reset        | | ------ | -------------------------- | --------------------------- | ---- | ------ | ---------- | ------------ | | `0x0`  | control                    |                             | REG  | R/W    |            | `0x6`        | |        | [2] up_down                | 1=Up - 0=Down               |      |        |            | `0x1`        | |        | [1] resetn                 |                             |      |        |            | '0x1`        | |        | [0] start                  |                             |      |        |            | '0x0`        | | `0x4`  | step_size                  |                             | REG  | R/W    |            | `0x1`        | |        | [31:0] step_size           |                             |      |        |            | `0x1`        | 
## Generics

| Generic name      | Type    | Value | Description           |
| ----------------- | ------- | ----- | --------------------- |
| g_axil_addr_width | integer | 32    | AXI-lite addr width   |
| g_axis_data_width | integer | 32    | Axi-Stream data width |
| g_counter_width   | integer | 32    | Counter size          |

## Ports

| Port name   | Direction | Type        | Description           |
| ----------- | --------- | ----------- | --------------------- |
| axi_aclk    | in        | std_logic   |                       |
| axi_aresetn | in        | std_logic   |                       |
| S_AXIL      | in        | Virtual bus | AXI-Lite Slave Bus    |
| M_AXIS      | out       | Virtual bus | AXI-Stream Master Bus |

### Virtual Buses

#### S_AXIL

| Port name     | Direction | Type                                             | Description |
| ------------- | --------- | ------------------------------------------------ | ----------- |
| s_axi_awaddr  | in        | std_logic_vector(g_axil_addr_width - 1 downto 0) |             |
| s_axi_awprot  | in        | std_logic_vector(2 downto 0)                     |             |
| s_axi_awvalid | in        | std_logic                                        |             |
| s_axi_awready | out       | std_logic                                        |             |
| s_axi_wdata   | in        | std_logic_vector(31 downto 0)                    |             |
| s_axi_wstrb   | in        | std_logic_vector(3 downto 0)                     |             |
| s_axi_wvalid  | in        | std_logic                                        |             |
| s_axi_wready  | out       | std_logic                                        |             |
| s_axi_araddr  | in        | std_logic_vector(g_axil_addr_width - 1 downto 0) |             |
| s_axi_arprot  | in        | std_logic_vector(2 downto 0)                     |             |
| s_axi_arvalid | in        | std_logic                                        |             |
| s_axi_arready | out       | std_logic                                        |             |
| s_axi_rdata   | out       | std_logic_vector(31 downto 0)                    |             |
| s_axi_rresp   | out       | std_logic_vector(1 downto 0)                     |             |
| s_axi_rvalid  | out       | std_logic                                        |             |
| s_axi_rready  | in        | std_logic                                        |             |
| s_axi_bresp   | out       | std_logic_vector(1 downto 0)                     |             |
| s_axi_bvalid  | out       | std_logic                                        |             |
| s_axi_bready  | in        | std_logic                                        |             |
#### M_AXIS

| Port name     | Direction | Type                                             | Description |
| ------------- | --------- | ------------------------------------------------ | ----------- |
| m_axis_tdata  | out       | std_logic_vector(g_axis_data_width - 1 downto 0) |             |
| m_axis_tvalid | out       | std_logic                                        |             |
| m_axis_tready | in        | std_logic                                        |             |

## Signals

| Name     | Type        | Description |
| -------- | ----------- | ----------- |
| regs_out | user2regs_t |             |
| regs_in  | regs2user_t |             |

## Instantiations

- axi_counter_inst: work.axis_counter_regs
- counter_inst: work.counter
