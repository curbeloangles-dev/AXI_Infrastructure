-- -----------------------------------------------------------------------------
-- 'axis_interleaving' Register Component
-- -----------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

use     work.axis_interleaving_regs_pkg.all;

entity axis_interleaving_regs is
    generic(
        g_AXI_ADDR_WIDTH    : integer := 32  -- width of the AXI address bus
    );
    port(
        -- Clock and Reset
        axi_aclk            : in  std_logic;
        axi_aresetn         : in  std_logic;
        -- AXI Write Address Channel
        s_axi_awaddr        : in  std_logic_vector(g_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_awprot        : in  std_logic_vector(2 downto 0); -- sigasi @suppress "Unused port"
        s_axi_awvalid       : in  std_logic;
        s_axi_awready       : out std_logic;
        -- AXI Write Data Channel
        s_axi_wdata         : in  std_logic_vector(31 downto 0);
        s_axi_wstrb         : in  std_logic_vector(3 downto 0);
        s_axi_wvalid        : in  std_logic;
        s_axi_wready        : out std_logic;
        -- AXI Read Address Channel
        s_axi_araddr        : in  std_logic_vector(g_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_arprot        : in  std_logic_vector(2 downto 0); -- sigasi @suppress "Unused port"
        s_axi_arvalid       : in  std_logic;
        s_axi_arready       : out std_logic;
        -- AXI Read Data Channel
        s_axi_rdata         : out std_logic_vector(31 downto 0);
        s_axi_rresp         : out std_logic_vector(1 downto 0);
        s_axi_rvalid        : out std_logic;
        s_axi_rready        : in  std_logic;
        -- AXI Write Response Channel
        s_axi_bresp         : out std_logic_vector(1 downto 0);
        s_axi_bvalid        : out std_logic;
        s_axi_bready        : in  std_logic;
        -- User Ports
        user2regs           : in  t_user2regs;
        regs2user           : out t_regs2user
    );
end entity axis_interleaving_regs;

architecture rtl of axis_interleaving_regs is

    -- Constants
    constant c_AXI_DIR_BITS         : positive                      := 8;
    constant c_AXI_OKAY             : std_logic_vector(1 downto 0)  := "00";
    constant c_AXI_DECERR           : std_logic_vector(1 downto 0)  := "11";

    -- Signals
    signal s_reg_version_value      : std_logic_vector(31 downto 0);

    -- Registered signals
    signal r_axi_awready            : std_logic;
    signal r_axi_wready             : std_logic;
    signal r_axi_awaddr             : unsigned(s_axi_awaddr'range);
    signal r_axi_bvalid             : std_logic;
    signal r_axi_bresp              : std_logic_vector(s_axi_bresp'range);
    signal r_axi_arready            : std_logic;
    signal r_axi_araddr             : unsigned(g_AXI_ADDR_WIDTH - 1 downto 0);
    signal r_axi_rvalid             : std_logic;
    signal r_axi_rresp              : std_logic_vector(s_axi_rresp'range);
    signal r_axi_wdata              : std_logic_vector(s_axi_wdata'range);
    signal r_axi_wstrb              : std_logic_vector(s_axi_wstrb'range);
    signal r_axi_rdata              : std_logic_vector(s_axi_rdata'range);

    -- User-defined registers
    signal r_user_control_value     : std_logic_vector(0 downto 0);
    signal r_channel_status_value   : std_logic_vector(4 downto 0);

begin

    ------------------------------------------------------------------------------------------------
    -- Inputs
    --
    s_reg_version_value              <= user2regs.version_value;
    
    ----------------------------------------------------------------------------
    -- Read-transaction FSM
    --
    read_fsm : process(axi_aclk, axi_aresetn) is
        constant MAX_MEMORY_LATENCY : natural := 5;
        type t_state is (IDLE, READ_REGISTER, WAIT_MEMORY_RDATA, READ_RESPONSE, DONE);
        -- registered state variables
        variable v_state_r          : t_state;
        variable v_rdata_r          : std_logic_vector(31 downto 0);
        variable v_rresp_r          : std_logic_vector(s_axi_rresp'range);
        variable v_mem_wait_count_r : natural range 0 to MAX_MEMORY_LATENCY;
        -- combinatorial helper variables
        variable v_addr_hit         : boolean;
        variable v_mem_addr         : unsigned(g_AXI_ADDR_WIDTH-1 downto 0);
    begin
        if axi_aresetn = '0' then
            v_state_r               := IDLE;
            v_rdata_r               := (others => '0');
            v_rresp_r               := (others => '0');
            v_mem_wait_count_r      := 0;
            r_axi_arready           <= '0';
            r_axi_rvalid            <= '0';
            r_axi_rresp             <= (others => '0');
            r_axi_araddr            <= (others => '0');
            r_axi_rdata             <= (others => '0');

        elsif rising_edge(axi_aclk) then
            -- Default values:
            r_axi_arready           <= '0';

            case v_state_r is

                -- Wait for the start of a read transaction, which is
                -- initiated by the assertion of ARVALID
                when IDLE =>
                    if s_axi_arvalid = '1' then
                        r_axi_araddr    <= unsigned(s_axi_araddr); -- save the read address
                        r_axi_arready   <= '1'; -- acknowledge the read-address
                        v_state_r       := READ_REGISTER;
                    end if;

                -- Read from the actual storage element
                when READ_REGISTER =>
                    -- defaults:
                    v_addr_hit := false;
                    v_rdata_r  := (others => '0');

                    -- Register 'VERSION' at address offset 0x0
                    if r_axi_araddr(c_AXI_DIR_BITS - 1 downto 2) = resize(VERSION_OFFSET(c_AXI_DIR_BITS - 1 downto 2), c_AXI_DIR_BITS - 2) then
                        v_addr_hit              := true;
                        v_rdata_r(31 downto 0)  := s_reg_version_value;
                        v_state_r               := READ_RESPONSE;
                    end if;
                    -- register 'USER_CONTROL' at address offset 0x4
                    if r_axi_araddr(c_AXI_DIR_BITS-1 downto 2) = resize(USER_CONTROL_OFFSET(c_AXI_DIR_BITS-1 downto 2), c_AXI_DIR_BITS-2) then
                        v_addr_hit              := true;
                        v_rdata_r(0 downto 0)   := r_user_control_value;
                        v_state_r               := READ_RESPONSE;
                    end if;
                    -- register 'CHANNEL_STATUS' at address offset 0x8
                    if r_axi_araddr(c_AXI_DIR_BITS-1 downto 2) = resize(CHANNEL_STATUS_OFFSET(c_AXI_DIR_BITS-1 downto 2), c_AXI_DIR_BITS-2) then
                        v_addr_hit              := true;
                        v_rdata_r(4 downto 0)   := r_channel_status_value;
                        v_state_r               := READ_RESPONSE;
                    end if;

                -- Wait for memory read data
                when WAIT_MEMORY_RDATA =>
                    if v_mem_wait_count_r = 0 then
                        v_state_r               := READ_RESPONSE;
                    else
                        v_mem_wait_count_r      := v_mem_wait_count_r - 1;
                    end if;

                -- Generate read response
                when READ_RESPONSE =>
                    r_axi_rvalid        <= '1';
                    r_axi_rresp         <= v_rresp_r;
                    r_axi_rdata         <= v_rdata_r;
                    --
                    v_state_r           := DONE;

                -- Write transaction completed, wait for master RREADY to proceed
                when DONE =>
                    if s_axi_rready = '1' then
                        r_axi_rvalid    <= '0';
                        r_axi_rdata     <= (others => '0');
                        v_state_r       := IDLE;
                    end if;
            end case;
        end if;
    end process read_fsm;

    ----------------------------------------------------------------------------
    -- Write-transaction FSM
    --
    write_fsm : process(axi_aclk, axi_aresetn) is
        type t_state is (IDLE, ADDR_FIRST, DATA_FIRST, UPDATE_REGISTER, DONE);
        variable v_state_r          : t_state;
        variable v_addr_hit         : boolean;
        variable v_mem_addr         : unsigned(g_AXI_ADDR_WIDTH-1 downto 0);
    begin
        if axi_aresetn = '0' then
            v_state_r               := IDLE;
            r_axi_awready           <= '0';
            r_axi_wready            <= '0';
            r_axi_awaddr            <= (others => '0');
            r_axi_wdata             <= (others => '0');
            r_axi_wstrb             <= (others => '0');
            r_axi_bvalid            <= '0';
            r_axi_bresp             <= (others => '0');
            --
            r_user_control_value    <= USER_CONTROL_ENABLE_RESET;
            r_channel_status_value  <= CHANNEL_STATUS_VALUE_RESET;

        elsif rising_edge(axi_aclk) then
            -- Default values:
            r_axi_awready           <= '0';
            r_axi_wready            <= '0';

            case v_state_r is

                -- Wait for the start of a write transaction, which may be
                -- initiated by either of the following conditions:
                --   * assertion of both AWVALID and WVALID
                --   * assertion of AWVALID
                --   * assertion of WVALID
                when IDLE =>
                    if s_axi_awvalid = '1' and s_axi_wvalid = '1' then
                        r_axi_awaddr    <= unsigned(s_axi_awaddr); -- save the write-address
                        r_axi_awready   <= '1'; -- acknowledge the write-address
                        r_axi_wdata     <= s_axi_wdata; -- save the write-data
                        r_axi_wstrb     <= s_axi_wstrb; -- save the write-strobe
                        r_axi_wready    <= '1'; -- acknowledge the write-data
                        v_state_r       := UPDATE_REGISTER;
                    elsif s_axi_awvalid = '1' then
                        r_axi_awaddr    <= unsigned(s_axi_awaddr); -- save the write-address
                        r_axi_awready   <= '1'; -- acknowledge the write-address
                        v_state_r       := ADDR_FIRST;
                    elsif s_axi_wvalid = '1' then
                        r_axi_wdata     <= s_axi_wdata; -- save the write-data
                        r_axi_wstrb     <= s_axi_wstrb; -- save the write-strobe
                        r_axi_wready    <= '1'; -- acknowledge the write-data
                        v_state_r       := DATA_FIRST;
                    end if;

                -- Address-first write transaction: wait for the write-data
                when ADDR_FIRST =>
                    if s_axi_wvalid = '1' then
                        r_axi_wdata     <= s_axi_wdata; -- save the write-data
                        r_axi_wstrb     <= s_axi_wstrb; -- save the write-strobe
                        r_axi_wready    <= '1'; -- acknowledge the write-data
                        v_state_r       := UPDATE_REGISTER;
                    end if;

                -- Data-first write transaction: wait for the write-address
                when DATA_FIRST =>
                    if s_axi_awvalid = '1' then
                        r_axi_awaddr    <= unsigned(s_axi_awaddr); -- save the write-address
                        r_axi_awready   <= '1'; -- acknowledge the write-address
                        v_state_r       := UPDATE_REGISTER;
                    end if;

                -- Update the actual storage element
                when UPDATE_REGISTER =>
                    r_axi_bresp         <= c_AXI_OKAY; -- default value, may be overriden in case of decode error
                    r_axi_bvalid        <= '1';
                    --
                    v_addr_hit := false;
                    -- register 'USER_CONTROL' at address offset 0x4
                    if r_axi_awaddr(c_AXI_DIR_BITS-1 downto 2) = resize(USER_CONTROL_OFFSET(c_AXI_DIR_BITS-1 downto 2), c_AXI_DIR_BITS-2) then
                        v_addr_hit := true;
                        -- field 'enable':
                        if r_axi_wstrb(0) = '1' then
                            r_user_control_value(0) <= r_axi_wdata(0); -- value(0)
                        end if;
                    end if;
                    -- register 'CHANNEL_STATUS' at address offset 0x8
                    if r_axi_awaddr(c_AXI_DIR_BITS-1 downto 2) = resize(CHANNEL_STATUS_OFFSET(c_AXI_DIR_BITS-1 downto 2), c_AXI_DIR_BITS-2) then
                        v_addr_hit := true;
                        -- field 'value':
                        if r_axi_wstrb(0) = '1' then
                            r_channel_status_value(4 downto 0)  <= r_axi_wdata(4 downto 0);   
                        end if;
                    end if;
                    --
                    if not v_addr_hit then
                        r_axi_bresp <= c_AXI_DECERR;
                        -- pragma translate_off
                        report "AWADDR decode error" severity warning;
                        -- pragma translate_on
                    end if;
                    --
                    v_state_r := DONE;

                -- Write transaction completed, wait for master BREADY to proceed
                when DONE =>
                    if s_axi_bready = '1' then
                        r_axi_bvalid    <= '0';
                        v_state_r       := IDLE;
                    end if;

            end case;
        end if;
    end process write_fsm;

    ----------------------------------------------------------------------------
    -- Outputs
    --
    s_axi_awready <= r_axi_awready;
    s_axi_wready  <= r_axi_wready;
    s_axi_bvalid  <= r_axi_bvalid;
    s_axi_bresp   <= r_axi_bresp;
    s_axi_arready <= r_axi_arready;
    s_axi_rvalid  <= r_axi_rvalid;
    s_axi_rresp   <= r_axi_rresp;
    s_axi_rdata   <= r_axi_rdata;

    regs2user.user_control_value    <= r_user_control_value;
    regs2user.channel_status_value  <= r_channel_status_value;

end architecture rtl;
