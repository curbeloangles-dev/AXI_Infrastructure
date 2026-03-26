-- -----------------------------------------------------------------------------
-- 'axi_bram' Register Definitions
-- Revision: 1
-- -----------------------------------------------------------------------------
-- Generated on 2021-10-18 at 12:19 (UTC) by airhdl version 2021.09.1
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
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

package axi_bram_regs_pkg is

    -- User-logic ports (from user-logic to register file)
    type user2regs_t is record
        register_map_rdata  : std_logic_vector(31 downto 0);    -- read data for memory 'register_map'
    end record;

    -- User-logic ports (from register file to user-logic)
    type regs2user_t is record
        register_map_addr   : std_logic_vector(31 downto 0);    -- read/write address for memory 'register_map'
        register_map_wdata  : std_logic_vector(31 downto 0);    -- write data for memory 'register_map'
        register_map_wen    : std_logic_vector(3 downto 0);     -- byte-wide write-enable for memory 'register_map'
        register_map_ren    : std_logic;                        -- read-enable for memory 'register_map'
    end record;

    -- Revision number of the 'axi_bram' register map
    constant AXI_BRAM_REVISION              : natural                       := 1;

    -- Default base address of the 'axi_bram' register map
    constant AXI_BRAM_DEFAULT_BASEADDR      : unsigned(31 downto 0)         := unsigned'(x"00000000");

    -- Size of the 'axi_bram' register map, in bytes
    constant AXI_BRAM_RANGE_BYTES           : natural                       := 120;

    -- Register 'register_map'
    constant REGISTER_MAP_OFFSET            : unsigned(31 downto 0)         := unsigned'(x"00000000");                                  -- address offset of the 'register_map' register
    -- constant REGISTER_MAP_DEPTH : natural := 30; -- depth of the 'register_map' memory, in elements
    constant REGISTER_MAP_READ_LATENCY      : natural                       := 2;                                                       -- read latency of the 'register_map' memory, in clock cycles
    -- Field 'register_map.value'
    constant REGISTER_MAP_VALUE_BIT_OFFSET  : natural                       := 0;                                                       -- bit offset of the 'value' field
    constant REGISTER_MAP_VALUE_BIT_WIDTH   : natural                       := 32;                                                      -- bit width of the 'value' field
    constant REGISTER_MAP_VALUE_RESET       : std_logic_vector(31 downto 0) := std_logic_vector'("00000000000000000000000000000000");   -- reset value of the 'value' field

end axi_bram_regs_pkg;
