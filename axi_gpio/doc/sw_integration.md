## Register space

### Overview
| OFFSET | LABEL       | DESCRIPTION       |
| ------ | ----------- | ----------------- |
| 0x0    | **Version** | Core version info |
| 0x4    | **GPO**     | GPO Ports values  |
| 0x8    | **GPI**     | GPI Ports values  |

### Registers
| OFFSET | LABEL            |  R/W  | SC  | DESCRIPTION                                                                                       | RESET VALUE |
| :----: | ---------------- | :---: | --- | ------------------------------------------------------------------------------------------------- | ----------- |
|  0x0   | **Version**      |       |     |                                                                                                   |             |
|        | _[31:0] Version_ |   R   | NO  | Version info                                                                                      | 0x1         |
|  0x4   | **GPO**          |       |     |                                                                                                   |             |
|        | _[31:0] GPO_     |  R/W  | NO  | Write GPO values. Each bit corresponds to a single port in the same order as the module interface | 0x0         |
|  0x8   | **GPI**          |       |     |                                                                                                   |             |
|        | _[31:0] GPI_     |   R   | NO  | Read GPI values. Each bit corresponds to a single port in the same order as the module interface  | 0x0         |