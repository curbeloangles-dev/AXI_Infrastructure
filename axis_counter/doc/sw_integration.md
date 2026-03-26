# axis_counter

|||
| --- | --- |
| **Description** | Register map for axis_counter |
| **Default base address** | `0x0` |
| **Register width** | 32 bits |
| **Default address width** | 32 bits |
| **Register count** | 2 |
| **Range** | 8 bytes |
| **Revision** | 23 |

## Overview

| Offset | Name | Description | Type |
| --- | --- | --- | --- |
| `0x0` | Control | Control register with:-0x0 start-0x1 resetn-0x2 up_down | REG |
| `0x4` | step_size | Signal that indicates the step of the counter | REG |

## Registers

| Offset | Name | Description | Type | Access | Attributes | Reset |
| ---    | --- | --- | --- | --- | --- | --- |
| `0x0` | Control |Control register with:-0x0 start-0x1 resetn-0x2 up_down | REG | R/W |  | `0x2` |
|        |  [0] Start | Signal to start the counter |  |  |  | `0x0` |
|        |  [1] resetn | Low level active reset |  |  |  | `0x1` |
|        |  [2] up_down | Signal to indicate the direction of the count 1->up, 0->down |  |  |  | `0x0` |
| `0x4` | step_size |Signal that indicates the step of the counter | REG | R/W |  | `0x1` |
|        |  [31:0] step_size |  |  |  |  | `0x1` |

_Generated on 2025-02-06 at 09:27 (UTC) by airhdl version 2023.07.1-936312266_
