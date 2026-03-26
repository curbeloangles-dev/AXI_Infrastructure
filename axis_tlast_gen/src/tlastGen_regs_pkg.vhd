-- -----------------------------------------------------------------------------
-- 'tlastGen' Register Definitions
-- Revision: 5
-- -----------------------------------------------------------------------------
-- Generated on 2021-08-30 at 11:10 (UTC) by airhdl version 2021.08.1
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

package tlastGen_regs_pkg is

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

    -- User-logic ports (from user-logic to register file)
    type user2regs_t is record
        version_value : std_logic_vector(31 downto 0); -- value of register 'version', field 'value'
    end record;

    -- User-logic ports (from register file to user-logic)
    type regs2user_t is record
        version_strobe : std_logic; -- Strobe signal for register 'version' (pulsed when the register is read from the bus}
        control_strobe : std_logic; -- Strobe signal for register 'control' (pulsed when the register is written from the bus}
        control_rstn : std_logic_vector(0 downto 0); -- Value of register 'control', field 'rstn'
        control_enable : std_logic_vector(0 downto 0); -- Value of register 'control', field 'enable'
        transferlen_strobe : std_logic; -- Strobe signal for register 'transferLen' (pulsed when the register is written from the bus}
        transferlen_value : std_logic_vector(31 downto 0); -- Value of register 'transferLen', field 'value'
        packetsnum_strobe : std_logic; -- Strobe signal for register 'packetsNum' (pulsed when the register is written from the bus}
        packetsnum_value : std_logic_vector(31 downto 0); -- Value of register 'packetsNum', field 'value'
        data_swap_strobe : std_logic; -- Strobe signal for register 'dataSwap' (pulsed when the register is written from the bus}
        data_swap_value : std_logic_vector(31 downto 0); -- Value of register 'dataSwap', field 'value'
        tlast_gen_mode_strobe : std_logic; -- Strobe signal for register 'tlastGenMode' (pulsed when the register is written from the bus}
        tlast_gen_mode_value : std_logic_vector(31 downto 0); -- Value of register 'tlastGenMode', field 'value'
        data_mask_strobe : std_logic; -- Strobe signal for register 'dataMask' (pulsed when the register is written from the bus}
        data_mask_value : std_logic_vector(31 downto 0); -- Value of register 'dataMask', field 'value'
    end record;

    -- Revision number of the 'tlastGen' register map
    constant TLASTGEN_REVISION : natural := 5;

    -- Default base address of the 'tlastGen' register map
    constant TLASTGEN_DEFAULT_BASEADDR : unsigned(31 downto 0) := unsigned'(x"00000000");

    -- Register 'version'
    constant VERSION_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000000"); -- address offset of the 'version' register
    -- Field 'version.value'
    constant VERSION_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant VERSION_VALUE_BIT_WIDTH : natural := 32; -- bit width of the 'value' field
    constant VERSION_VALUE_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000001"); -- reset value of the 'value' field

    -- Register 'control'
    constant CONTROL_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000004"); -- address offset of the 'control' register
    -- Field 'control.rstn'
    constant CONTROL_RSTN_BIT_OFFSET : natural := 0; -- bit offset of the 'rstn' field
    constant CONTROL_RSTN_BIT_WIDTH : natural := 1; -- bit width of the 'rstn' field
    constant CONTROL_RSTN_RESET : std_logic_vector(0 downto 0) := std_logic_vector'("0"); -- reset value of the 'rstn' field
    -- Field 'control.enable'
    constant CONTROL_ENABLE_BIT_OFFSET : natural := 1; -- bit offset of the 'enable' field
    constant CONTROL_ENABLE_BIT_WIDTH : natural := 1; -- bit width of the 'enable' field
    constant CONTROL_ENABLE_RESET : std_logic_vector(1 downto 1) := std_logic_vector'("0"); -- reset value of the 'enable' field

    -- Register 'transferLen'
    constant TRANSFERLEN_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000008"); -- address offset of the 'transferLen' register
    -- Field 'transferLen.value'
    constant TRANSFERLEN_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant TRANSFERLEN_VALUE_BIT_WIDTH : natural := 32; -- bit width of the 'value' field
    constant TRANSFERLEN_VALUE_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000000"); -- reset value of the 'value' field

    -- Register 'packetsNum'
    constant PACKETSNUM_OFFSET : unsigned(31 downto 0) := unsigned'(x"0000000C"); -- address offset of the 'packetsNum' register
    -- Field 'packetsNum.value'
    constant PACKETSNUM_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant PACKETSNUM_VALUE_BIT_WIDTH : natural := 32; -- bit width of the 'value' field
    constant PACKETSNUM_VALUE_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000001"); -- reset value of the 'value' field

    -- Register 'Data swap'
    constant DATA_SWAP_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000010"); -- address offset of the 'dataSwap' register
    -- Field 'dataSwap.value'
    constant DATA_SWAP_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant DATA_SWAP_VALUE_BIT_WIDTH : natural := 32; -- bit width of the 'value' field
    constant DATA_SWAP_VALUE_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000000"); -- reset value of the 'value' field

    -- Register 'tlast generation mode'
    constant TLAST_GEN_MODE_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000014"); -- address offset of the 'tlastGenMode' register
    -- Field 'tlastGenMode.value'
    constant TLAST_GEN_MODE_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant TLAST_GEN_MODE_VALUE_BIT_WIDTH : natural := 32; -- bit width of the 'value' field
    constant TLAST_GEN_MODE_VALUE_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000001"); -- reset value of the 'value' field

    -- Regsiter 'Data mask'
    constant DATA_MASK_OFFSET : unsigned(31 downto 0) := unsigned'(x"00000018"); -- address offset of the 'dataMask' register
    -- Field 'dataMask.value'
    constant DATA_MASK_VALUE_BIT_OFFSET : natural := 0; -- bit offset of the 'value' field
    constant DATA_MASK_VALUE_BIT_WIDTH : natural := 32; -- bit width of the 'value' field
    constant DATA_MASK_VALUE_RESET : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000000"); -- reset value of the 'value' field

end tlastGen_regs_pkg;
