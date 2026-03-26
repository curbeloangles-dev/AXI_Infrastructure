# AXI GPIO
Module that implements width-configurable GPIO ports controlled via AXI-Lite. The allowed range is from 1 to 33 GPO and GPI ports

## Diagram
![Diagram](axi_gpio.svg "Diagram")

## Generics and ports
### Table 1.1 Generics
| Generic name     | Type                  | Value | Description                                                     |
| ---------------- | --------------------- | ----- | --------------------------------------------------------------- |
| g_GPO_WIDTH      | integer range 1 to 32 | 32    | Configuration of the number of GPO Ports. Range allowed: [1,32] |
| g_GPI_WIDTH      | integer range 1 to 32 | 32    | Configuration of the number of GPI Ports. Range allowed: [1,32] |
| g_AXI_ADDR_WIDTH | integer               | 32    | Width of the AXI address bus                                    |

### Table 1.2 Ports
| Port name   | Direction | Type                                       | Description                          |
| ----------- | --------- | ------------------------------------------ | ------------------------------------ |
| gpo         | out       | std_logic_vector(g_GPO_WIDTH - 1 downto 0) | GPO ports                            |
| gpi         | in        | std_logic_vector(g_GPI_WIDTH - 1 downto 0) | GPI ports                            |
| axi_aclk    | in        | std_logic                                  | AXI4-Lite clock (used as core clock) |
| axi_aresetn | in        | std_logic                                  | AXI4-Lite aresetn                    |
| s_axi       | bus       | AXI4-Lite bus                              | AXI4-Lite slave interface            |