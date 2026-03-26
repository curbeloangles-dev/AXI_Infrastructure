## Register space

### Registers
|   OFFSET                      | LABEL         |  R/W  | SC  | DESCRIPTION | RESET VALUE |
| :---------------------------: | ------------- | :---: | --- | ----------- | ----------- |
| from 0x0 to [0x4 * (n/2 - 1)] | readX         |       |     |             |             |
|                               | _[31:0] word_ |  R/W  | NO  | memory word | 0x0         |
| from (0x4 * n/2) to n         | writeX        |       |     |             |             |
|                               | _[31:0] word_ |  R/W  | NO  | memory word | 0x0         |

Where n = generic total amount of registers