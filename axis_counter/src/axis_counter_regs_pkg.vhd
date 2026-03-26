-- -----------------------------------------------------------------------------
-- 'axis_counter' Register Definitions
-- Revision: 22
-- -----------------------------------------------------------------------------
-- Generated on 2025-01-30 at 08:25 (UTC) by airhdl version 2023.07.1-936312266
-- -----------------------------------------------------------------------------
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package axis_counter_regs_pkg is

    -- Revision number of the 'axis_counter' register map
    constant AXIS_COUNTER_REVISION : natural := 22;

    -- Default base address of the 'axis_counter' register map
    constant AXIS_COUNTER_DEFAULT_BASEADDR : unsigned(31 downto 0) := unsigned'(x"00000000");

    -- Size of the 'axis_counter' register map, in bytes
    constant AXIS_COUNTER_RANGE_BYTES : natural := 8;

    -- Register 'Control'
    constant CONTROL_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000000"); -- address offset of the 'Control' register

    -- Field 'Control.Start'
    constant CONTROL_START_BIT_OFFSET : natural := 0; -- bit offset of the 'Start' field
    constant CONTROL_START_BIT_WIDTH : natural := 1; -- bit width of the 'Start' field
    constant CONTROL_START_RESET : std_logic_vector(0 downto 0) := std_logic_vector'("1"); -- reset value of the 'Start' field

    -- Field 'Control.resetn'
    constant CONTROL_RESETN_BIT_OFFSET : natural := 1; -- bit offset of the 'resetn' field
    constant CONTROL_RESETN_BIT_WIDTH : natural := 1; -- bit width of the 'resetn' field
    constant CONTROL_RESETN_RESET : std_logic_vector(1 downto 1) := std_logic_vector'("1"); -- reset value of the 'resetn' field

    -- Field 'Control.up_down'
    constant CONTROL_UP_DOWN_BIT_OFFSET : natural := 2; -- bit offset of the 'up_down' field
    constant CONTROL_UP_DOWN_BIT_WIDTH : natural := 1; -- bit width of the 'up_down' field
    constant CONTROL_UP_DOWN_RESET : std_logic_vector(2 downto 2) := std_logic_vector'("1"); -- reset value of the 'up_down' field

    -- Register 'step_size'
    constant STEP_SIZE_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000004"); -- address offset of the 'step_size' register

    -- Field 'step_size.step_size'
    constant STEP_SIZE_STEP_SIZE_BIT_OFFSET : natural := 0; -- bit offset of the 'step_size' field
    constant STEP_SIZE_STEP_SIZE_BIT_WIDTH : natural := 32; -- bit width of the 'step_size' field
    constant STEP_SIZE_STEP_SIZE_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000001"); -- reset value of the 'step_size' field

    -- Type definitions
    type slv1_array_t is array(natural range <>) of std_logic_vector(0 downto 0);
    type slv2_array_t is array(natural range <>) of std_logic_vector(1 downto 0);
    type slv3_array_t is array(natural range <>) of std_logic_vector(2 downto 0);
    type slv4_array_t is array(natural range <>) of std_logic_vector(3 downto 0);
    type slv5_array_t is array(natural range <>) of std_logic_vector(4 downto 0);
    type slv6_array_t is array(natural range <>) of std_logic_vector(5 downto 0);
    type slv7_array_t is array(natural range <>) of std_logic_vector(6 downto 0);
    type slv8_array_t is array(natural range <>) of std_logic_vector(7 downto 0);
    type slv9_array_t is array(natural range <>) of std_logic_vector(8 downto 0);
    type slv10_array_t is array(natural range <>) of std_logic_vector(9 downto 0);
    type slv11_array_t is array(natural range <>) of std_logic_vector(10 downto 0);
    type slv12_array_t is array(natural range <>) of std_logic_vector(11 downto 0);
    type slv13_array_t is array(natural range <>) of std_logic_vector(12 downto 0);
    type slv14_array_t is array(natural range <>) of std_logic_vector(13 downto 0);
    type slv15_array_t is array(natural range <>) of std_logic_vector(14 downto 0);
    type slv16_array_t is array(natural range <>) of std_logic_vector(15 downto 0);
    type slv17_array_t is array(natural range <>) of std_logic_vector(16 downto 0);
    type slv18_array_t is array(natural range <>) of std_logic_vector(17 downto 0);
    type slv19_array_t is array(natural range <>) of std_logic_vector(18 downto 0);
    type slv20_array_t is array(natural range <>) of std_logic_vector(19 downto 0);
    type slv21_array_t is array(natural range <>) of std_logic_vector(20 downto 0);
    type slv22_array_t is array(natural range <>) of std_logic_vector(21 downto 0);
    type slv23_array_t is array(natural range <>) of std_logic_vector(22 downto 0);
    type slv24_array_t is array(natural range <>) of std_logic_vector(23 downto 0);
    type slv25_array_t is array(natural range <>) of std_logic_vector(24 downto 0);
    type slv26_array_t is array(natural range <>) of std_logic_vector(25 downto 0);
    type slv27_array_t is array(natural range <>) of std_logic_vector(26 downto 0);
    type slv28_array_t is array(natural range <>) of std_logic_vector(27 downto 0);
    type slv29_array_t is array(natural range <>) of std_logic_vector(28 downto 0);
    type slv30_array_t is array(natural range <>) of std_logic_vector(29 downto 0);
    type slv31_array_t is array(natural range <>) of std_logic_vector(30 downto 0);
    type slv32_array_t is array(natural range <>) of std_logic_vector(31 downto 0);

    -- User-logic ports (from user-logic to register bank)
    type user2regs_t is record
        dummy : std_logic; -- a dummy element to prevent empty records
    end record;

    -- User-logic ports (from register bank to user-logic)
    type regs2user_t is record
        control_strobe : std_logic; -- strobe signal for register 'Control' (pulsed when the register is written from the bus}
        control_start : std_logic_vector(0 downto 0); -- write value of field 'Control.Start'
        control_resetn : std_logic_vector(0 downto 0); -- write value of field 'Control.resetn'
        control_up_down : std_logic_vector(0 downto 0); -- write value of field 'Control.up_down'
        step_size_strobe : std_logic; -- strobe signal for register 'step_size' (pulsed when the register is written from the bus}
        step_size_step_size : std_logic_vector(31 downto 0); -- write value of field 'step_size.step_size'
    end record;

end axis_counter_regs_pkg;
