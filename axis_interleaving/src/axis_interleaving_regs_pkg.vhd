-- -----------------------------------------------------------------------------
-- 'axis interleaving' Register Definitions
-- -----------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

package axis_interleaving_regs_pkg is

    -- User-logic ports (from user-logic to register file)
    type t_user2regs is record
        version_value           : std_logic_vector(31 downto 0);    -- read value of field 'VERSION.value'
    end record;

    -- User-logic ports (from register file to user-logic)
    type t_regs2user is record
        user_control_value      : std_logic_vector(0 downto 0);     -- Value of register 'USER_CONTROL', field 'enable'
        channel_status_value    : std_logic_vector(4 downto 0);     -- Value of register 'CHANNEL_STATUS', field 'value'
    end record;

    -- Revision number of the 'axis_interleaving' register map
    constant INTERLEAVING_REVISION          : natural := 1;

    -- Default base address of the 'axis_interleaving' register map
    constant INTERLEAVING_DEFAULT_BASEADDR  : unsigned(31 downto 0)         := unsigned'(x"00000000");

    -- Register 'VERSION'
    constant VERSION_OFFSET                 : unsigned(31 downto 0)         := unsigned'(x"00000000");                                 -- address offset of the 'VERSION' register
    -- Field 'VERSION.value'
    constant VERSION_VALUE_BIT_OFFSET       : natural                       := 0;                                                      -- bit offset of the 'value' field
    constant VERSION_VALUE_BIT_WIDTH        : natural                       := 32;                                                     -- bit width of the 'value' field
    constant VERSION_VALUE_RESET            : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000010000000000000000");  -- reset value of the 'value' field

    -- Register 'USER_CONTROL'
    constant USER_CONTROL_OFFSET            : unsigned(31 downto 0)         := unsigned'(x"00000004");                                  -- address offset of the 'USER_CONTROL' register
    -- Field 'USER_CONTROL.enable'
    constant USER_CONTROL_ENABLE_BIT_OFFSET : natural                       := 0;                                                       -- bit offset of the 'enable' field
    constant USER_CONTROL_ENABLE_BIT_WIDTH  : natural                       := 1;                                                       -- bit width of the 'enable' field
    constant USER_CONTROL_ENABLE_RESET      : std_logic_vector(0 downto 0)  := std_logic_vector'("0");                                  -- reset value of the 'enable' field

    -- Register 'CHANNEL_STATUS'
    constant CHANNEL_STATUS_OFFSET          : unsigned(31 downto 0)         := unsigned'(x"00000008");                                  -- address offset of the 'CHANNEL_STATUS' register
    -- Field 'CHANNEL_STATUS.value'
    constant CHANNEL_STATUS_VALUE_BIT_OFFSET: natural                       := 0;                                                       -- bit offset of the 'value' field
    constant CHANNEL_STATUS_VALUE_BIT_WIDTH : natural                       := 5;                                                       -- bit width of the 'value' field
    constant CHANNEL_STATUS_VALUE_RESET     : std_logic_vector(4 downto 0)  := std_logic_vector'("00000");                              -- reset value of the 'value' field

end axis_interleaving_regs_pkg;
