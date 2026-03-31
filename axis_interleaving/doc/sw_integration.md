# AXI stream interleaving
## Registers map
|               Address              | LABEL                    | DESCRIPTION                                               |
| :--------------------------------: | ------------------------ | --------------------------------------------------------- |
|                0x00                |  **Version**             |                                                           |
|                                    | _[31:20] reserved_       | Reserverd                                                 |
|                                    | _[19:14] major version_  | Major version of the core                                 |
|                                    | _[13:8] minor version_   | Minor version of the core                                 |
|                                    | _[7:0] patch version_    | Patch version of the core                                 |
|                0x04                |  **User Control**        |                                                           |
|                                    | _[31:1] reserved_        | Reserved                                                  |
|                                    | _[0:0] enable_           | When '1' user has control on the core. By default is '0'  |
|                0x08                |  **Channel Status**      |                                                           |   
|                                    | _[31:5] reserved_        | Reserved                                                  |
|                                    | _[4:0] value_            | Set/Reset bit N to enable/disable channel N               |