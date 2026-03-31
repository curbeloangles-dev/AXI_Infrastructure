library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

use     work.axis_interleaving_regs_pkg.all;

--! - **Name:** axis_interleaving_top.vhd  
--!
--! - **Human Name:** Interleaving with AXI Steam interfaces
--!
--! - **One-line Description:**  This module converts up to 5 AXI stream channels into a single one. 
--!
--! - **One-paragraph Description:**  This module converts up to 5 AXI stream channels into a single one. The AXI steam inputs must be the same width and conditions about frequencies must be also met. The core can be control via registers.
--!

--! ## axis_interleaving_top register space 
--! ### Overview 
--! | OFFSET | LABEL                | DESCRIPTION               |
--! | ------ | -------------------- | ------------------------- |
--! | 0x0    | **version**          | IP version register       |
--! | 0x4    | **user_control**     | User control register     |
--! | 0x8    | **channel_status**   | Channel status register   |

--! ### Registers 
--! | OFFSET | LABEL                | R/W   | SC  | DESCRIPTION                                                                                         | RESET VALUE   |
--! | ------ | -------------------- | ----- | --- | --------------------------------------------------------------------------------------------------- | ------------- |
--! | 0x0    | **version**          |       |     |                                                                                                     |               |
--! |        | _[31:0] version_     | R     | NO  | Version value                                                                                       | 0x0           |
--! | 0x4    | **user_control**     |       |     |                                                                                                     |               |
--! |        | _[0:0] enable_       | R/W   | NO  | When '1' the core is controlled by the channel status. By default is '0'.                           | 0x0           |
--! |        | _[31:1] reserved_    | R/W   | NO  | Reserved                                                                                            | 0x0           |
--! | 0x8    | **channel_status**   |       |     |                                                                                                     |               |
--! |        | _[4:0] status_       | R/W   | NO  | Each bit indicates the status of each input channel. When '1' is enabled. By default is '0'.        | 0x0           |
--! |        | _[31:5] reserved_    | R/W   | NO  | Reserved                                                                                            | 0x0           |

entity axis_interleaving_top is 
    generic (
        g_AXI_ADDR_WIDTH                    : natural                   := 32;      --! width of the AXI lite address bus
		g_AXIS_TDATA_WIDTH	                : natural range 0 to 256	:= 32;      --! width of the AXI stream data bus
        g_BLOCKING_THRESHOLD                : natural range 1 to 5 		:= 5;       --! number of channels that must be NOK to block the output
        g_CHANNELS_USED		                : natural range 1 to 5 		:= 5;       --! number of channels used among the five available
        g_CH0_THROUGHPUT_MBPS               : natural                   := 1000;    --! throughput in Mbps of channel 0
        g_CH1_THROUGHPUT_MBPS               : natural                   := 1000;    --! throughput in Mbps of channel 1
        g_CH2_THROUGHPUT_MBPS               : natural                   := 1000;    --! throughput in Mbps of channel 2
        g_CH3_THROUGHPUT_MBPS               : natural                   := 1000;    --! throughput in Mbps of channel 3
        g_CH4_THROUGHPUT_MBPS               : natural                   := 1000;    --! throughput in Mbps of channel 4
        g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ  : natural                   := 100;     --! highest among the slave axi stream channels
        g_AXIS_OUTPUT_FREQUENCY_MHZ         : natural                   := 100;     --! frequency of the master axi stream output
        g_INTERLEAVING_FREQUENCY_MHZ        : natural                   := 500      --! frequency of the interleaving
    );
    port (
        -- Interleaving Clock and Reset
        interleaving_aclk           : in  std_logic;
        interleaving_aresetn        : in  std_logic;        
        --! @virtualbus AXI_Lite_Slave
        axi_aclk                    : in  std_logic;
        axi_aresetn                 : in  std_logic;
        -- AXI Write Address Channel
        s_axi_awaddr                : in  std_logic_vector(g_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_awprot                : in  std_logic_vector(2 downto 0); -- sigasi @suppress "Unused port"
        s_axi_awvalid               : in  std_logic;
        s_axi_awready               : out std_logic;
        -- AXI Write Data Channel
        s_axi_wdata                 : in  std_logic_vector(31 downto 0);
        s_axi_wstrb                 : in  std_logic_vector(3 downto 0);
        s_axi_wvalid                : in  std_logic;
        s_axi_wready                : out std_logic;
        -- AXI Read Address Channel
        s_axi_araddr                : in  std_logic_vector(g_AXI_ADDR_WIDTH - 1 downto 0);
        s_axi_arprot                : in  std_logic_vector(2 downto 0); -- sigasi @suppress "Unused port"
        s_axi_arvalid               : in  std_logic;
        s_axi_arready               : out std_logic;
        -- AXI Read Data Channel
        s_axi_rdata                 : out std_logic_vector(31 downto 0);
        s_axi_rresp                 : out std_logic_vector(1 downto 0);
        s_axi_rvalid                : out std_logic;
        s_axi_rready                : in  std_logic;
        -- AXI Write Response Channel
        s_axi_bresp                 : out std_logic_vector(1 downto 0);
        s_axi_bvalid                : out std_logic;
        s_axi_bready                : in  std_logic;    --! @end
        --! @virtualbus AXI_Stream_Slave_0
        s0_axis_aclk        	    : in  std_logic;
        s0_axis_aresetn             : in  std_logic;
        s0_axis_tdata		        : in  std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
        s0_axis_tvalid 	            : in  std_logic;
		s0_axis_tready 	            : out std_logic;    --! @end
        --! @virtualbus AXI_Stream_Slave_1
        -- axi stream channel 1
        s1_axis_aclk        	    : in  std_logic;
        s1_axis_aresetn             : in  std_logic;
        s1_axis_tvalid 	            : in  std_logic;
        s1_axis_tdata  	            : in  std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
		s1_axis_tready 	            : out std_logic;    --! @end
        --! @virtualbus AXI_Stream_Slave_2
        -- axi stream channel 2
        s2_axis_aclk        	    : in  std_logic;
        s2_axis_aresetn             : in  std_logic;
        s2_axis_tvalid 	            : in  std_logic;
        s2_axis_tdata  	            : in  std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
		s2_axis_tready 	            : out std_logic;    --! @end
        --! @virtualbus AXI_Stream_Slave_3
        -- axi stream channel 3
        s3_axis_aclk        	    : in  std_logic;
        s3_axis_aresetn             : in  std_logic;
        s3_axis_tvalid 	            : in  std_logic;
        s3_axis_tdata  	            : in  std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
		s3_axis_tready 	            : out std_logic;    --! @end
        --! @virtualbus AXI_Stream_Slave_4
        -- axi stream channel 4
        s4_axis_aclk        	    : in  std_logic;
        s4_axis_aresetn             : in  std_logic;
        s4_axis_tvalid 	            : in  std_logic;
        s4_axis_tdata		        : in  std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
		s4_axis_tready 	            : out std_logic;    --! @end
        --! @virtualbus AXI_Stream_Master
        -- axi stream output
        m_axis_aclk        	        : in  std_logic;
        m_axis_aresetn              : in  std_logic;
        m_axis_tvalid   	        : out std_logic;
        m_axis_tdata    	        : out std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
		m_axis_tready 		        : in  std_logic;    --! @end
        -- 
        channel_status              : in  std_logic_vector(4 downto 0)  --! Channel status. Bit n corresponds to channel n. When bit n is '1'/'0' means that channel n is enable/disable
    );
end entity;

architecture rtl of axis_interleaving_top is

    -- constants
    constant c_CHANNEL_STATUS_WIDTH         : integer   := 5;
    constant c_DEST_SYNC_FF                 : integer   := 4;
    constant c_SRC_INPUT_REG                : integer   := 1;

    -- signals
    signal s_user2regs                      : t_user2regs;
    signal s_regs2user                      : t_regs2user;
    signal s_user_control_from_reg          : std_logic;
    signal s_channel_status_from_reg        : std_logic_vector(c_CHANNEL_STATUS_WIDTH-1 downto 0);
    signal s_channel_status_from_input      : std_logic_vector(c_CHANNEL_STATUS_WIDTH-1 downto 0);
    signal s_user_control_from_reg_fast     : std_logic;
    signal s_channel_status_from_reg_fast   : std_logic_vector(c_CHANNEL_STATUS_WIDTH-1 downto 0);
    signal s_channel_status_from_input_fast : std_logic_vector(c_CHANNEL_STATUS_WIDTH-1 downto 0);
    signal s0_axis_tdata_fast               : std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
    signal s0_axis_tvalid_fast              : std_logic;
    signal s0_axis_tready_fast              : std_logic;
    signal s1_axis_tdata_fast               : std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
    signal s1_axis_tvalid_fast              : std_logic;
    signal s1_axis_tready_fast              : std_logic;
    signal s2_axis_tdata_fast               : std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
    signal s2_axis_tvalid_fast              : std_logic;
    signal s2_axis_tready_fast              : std_logic;
    signal s3_axis_tdata_fast               : std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
    signal s3_axis_tvalid_fast              : std_logic;
    signal s3_axis_tready_fast              : std_logic;
    signal s4_axis_tdata_fast               : std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
    signal s4_axis_tvalid_fast              : std_logic;
    signal s4_axis_tready_fast              : std_logic;
    signal m_axis_tdata_fast                : std_logic_vector(g_AXIS_TDATA_WIDTH-1 downto 0);
    signal m_axis_tvalid_fast               : std_logic;
    signal m_axis_tready_fast               : std_logic;
    signal s_m_demanding_data_fast          : std_logic;
    signal s_m_demanding_data               : std_logic;

    function check_interleaving_clk_condition(interleaving_freq, s_axis_freq, channels_in_used : natural) return boolean is
		begin
            if interleaving_freq >= s_axis_freq * channels_in_used then
                return True;
            end if;
			return False;
		end function;

    function check_m_axis_clk_condition(m_axis_freq, thr_ch0, thr_ch1, thr_ch2, thr_ch3, thr_ch4, s_axis_tdata_width, channels_in_used : natural) return boolean is
        variable  max_output_throughput   : natural := 0;
        begin
            -- calculate maximum output throughput according to the number of input channels in used and their throughputs
            if channels_in_used = 1 then
                max_output_throughput := thr_ch0;
            elsif channels_in_used = 2 then
                max_output_throughput := thr_ch0 + thr_ch1;
            elsif channels_in_used = 3 then
                max_output_throughput := thr_ch0 + thr_ch1 + thr_ch2;
            elsif channels_in_used = 4 then
                max_output_throughput := thr_ch0 + thr_ch1 + thr_ch2 + thr_ch3;
            elsif channels_in_used = 5 then
                max_output_throughput := thr_ch0 + thr_ch1 + thr_ch2 + thr_ch3 + thr_ch4;
            end if;

            -- condition
            if max_output_throughput <= s_axis_tdata_width * m_axis_freq then
                return True;
            end if;

            return False;
        end function;

begin

    ---------------------------------------------------------------------------------------
    -- Check conditions
    ---------------------------------------------------------------------------------------    
    -- interleaving clk
    assert check_interleaving_clk_condition(g_INTERLEAVING_FREQUENCY_MHZ, g_AXIS_INPUT_HIGHEST_FREQUENCY_MHZ, g_CHANNELS_USED)
    report "ERROR: Interleaving frequency is not high enough!"
    severity failure;

    -- master axi stream clk
    assert check_m_axis_clk_condition(g_AXIS_OUTPUT_FREQUENCY_MHZ, g_CH0_THROUGHPUT_MBPS, g_CH1_THROUGHPUT_MBPS, g_CH2_THROUGHPUT_MBPS, g_CH3_THROUGHPUT_MBPS, g_CH4_THROUGHPUT_MBPS, g_AXIS_TDATA_WIDTH, g_CHANNELS_USED)
    report "ERROR: Master AXI stream frequency is not high enough!"
    severity failure;

    ---------------------------------------------------------------------------------------
    -- AXI Lite Clock Domain
    ---------------------------------------------------------------------------------------
    -- registers map
    registers_inst  : entity work.axis_interleaving_regs
        generic map(
            g_AXI_ADDR_WIDTH    => g_AXI_ADDR_WIDTH
        )
        port map(
            -- Clock and Reset
            axi_aclk            => axi_aclk,
            axi_aresetn         => axi_aresetn,
            -- AXI Write Address Channel
            s_axi_awaddr        => s_axi_awaddr,
            s_axi_awprot        => s_axi_awprot,
            s_axi_awvalid       => s_axi_awvalid,
            s_axi_awready       => s_axi_awready,
            -- AXI Write Data Channel
            s_axi_wdata         => s_axi_wdata,
            s_axi_wstrb         => s_axi_wstrb,
            s_axi_wvalid        => s_axi_wvalid,
            s_axi_wready        => s_axi_wready,
            -- AXI Read Address Channel
            s_axi_araddr        => s_axi_araddr,
            s_axi_arprot        => s_axi_arprot,
            s_axi_arvalid       => s_axi_arvalid,
            s_axi_arready       => s_axi_arready,
            -- AXI Read Data Channel
            s_axi_rdata         => s_axi_rdata,
            s_axi_rresp         => s_axi_rresp,
            s_axi_rvalid        => s_axi_rvalid,
            s_axi_rready        => s_axi_rready,
            -- AXI Write Response Channel
            s_axi_bresp         => s_axi_bresp,
            s_axi_bvalid        => s_axi_bvalid,
            s_axi_bready        => s_axi_bready,
            -- User Ports
            user2regs           => s_user2regs,
            regs2user           => s_regs2user
        );

    -- Read registers
    s_user2regs.version_value   <= VERSION_VALUE_RESET;
    -- Write registers
    s_user_control_from_reg     <= s_regs2user.user_control_value(0);
    s_channel_status_from_reg   <= s_regs2user.channel_status_value(c_CHANNEL_STATUS_WIDTH-1 downto 0);
    -- Inputs
    s_channel_status_from_input <= channel_status;

    ---------------------------------------------------------------------------------------
    -- Slave AXI Stream Clock Domain
    ---------------------------------------------------------------------------------------
    -- cdc user control from registers
    cdc_user_control_reg_inst  : entity work.bit_cdc
        generic map(
            g_DEST_SYNC_FF  => c_DEST_SYNC_FF,
            g_SRC_INPUT_REG => c_SRC_INPUT_REG
        )
        port map(
            -- inputs
            src_clk         => axi_aclk,
            src_in          => s_user_control_from_reg,
            dest_clk        => interleaving_aclk,
            -- output        
            dest_out        => s_user_control_from_reg_fast 
        );

    -- cdc channel status from registers
    cdc_channel_status_reg_inst  : entity work.gray_cdc
        generic map(
            g_DEST_SYNC_FF  => c_DEST_SYNC_FF,
            g_SIGNAL_WIDTH  => c_CHANNEL_STATUS_WIDTH
        )
        port map(
            -- inputs
            src_clk         => axi_aclk,
            src_in_bin      => s_channel_status_from_reg,
            dest_clk        => interleaving_aclk,
            -- output        
            dest_out_bin    => s_channel_status_from_reg_fast
        );

    -- cdc channel status from input
    cdc_channel_status_input_inst  : entity work.gray_cdc
        generic map(
            g_DEST_SYNC_FF  => c_DEST_SYNC_FF,
            g_SIGNAL_WIDTH  => c_CHANNEL_STATUS_WIDTH
        )
        port map(
            -- inputs
            src_clk         => axi_aclk,
            src_in_bin      => s_channel_status_from_input,
            dest_clk        => interleaving_aclk,
            -- output        
            dest_out_bin    => s_channel_status_from_input_fast
        );

   	-- input fifo from axi stream to interleaving clock domain for channel 0
	axi_stream_fifo_inst_0 : entity work.axi_stream_fifo
        generic map(
            g_WIDTH 		=> g_AXIS_TDATA_WIDTH,
            g_DEPTH 		=> 2 
        )
        port map(
            s_axis_aclk    	=> s0_axis_aclk,
            s_axis_aresetn 	=> s0_axis_aresetn,
            m_axis_aclk    	=> interleaving_aclk,
            m_axis_aresetn 	=> interleaving_aresetn,
            s_axis_tdata   	=> s0_axis_tdata,
            s_axis_tvalid  	=> s0_axis_tvalid,
            s_axis_tready  	=> s0_axis_tready,
            m_axis_tdata   	=> s0_axis_tdata_fast,
            m_axis_tvalid  	=> s0_axis_tvalid_fast,
            m_axis_tready  	=> s0_axis_tready_fast
        ); 

    -- input fifo from axi stream to interleaving clock domain for channel 1
	axi_stream_fifo_inst_1 : entity work.axi_stream_fifo
        generic map(
            g_WIDTH 		=> g_AXIS_TDATA_WIDTH,
            g_DEPTH 		=> 2 
        )
        port map(
            s_axis_aclk    	=> s1_axis_aclk,
            s_axis_aresetn 	=> s1_axis_aresetn,
            m_axis_aclk    	=> interleaving_aclk,
            m_axis_aresetn 	=> interleaving_aresetn,
            s_axis_tdata   	=> s1_axis_tdata,
            s_axis_tvalid  	=> s1_axis_tvalid,
            s_axis_tready  	=> s1_axis_tready,
            m_axis_tdata   	=> s1_axis_tdata_fast,
            m_axis_tvalid  	=> s1_axis_tvalid_fast,
            m_axis_tready  	=> s1_axis_tready_fast
        ); 

    -- input fifo from axi stream to interleaving clock domain for channel 2
	axi_stream_fifo_inst_2 : entity work.axi_stream_fifo
        generic map(
            g_WIDTH 		=> g_AXIS_TDATA_WIDTH,
            g_DEPTH 		=> 2 
        )
        port map(
            s_axis_aclk    	=> s2_axis_aclk,
            s_axis_aresetn 	=> s2_axis_aresetn,
            m_axis_aclk    	=> interleaving_aclk,
            m_axis_aresetn 	=> interleaving_aresetn,
            s_axis_tdata   	=> s2_axis_tdata,
            s_axis_tvalid  	=> s2_axis_tvalid,
            s_axis_tready  	=> s2_axis_tready,
            m_axis_tdata   	=> s2_axis_tdata_fast,
            m_axis_tvalid  	=> s2_axis_tvalid_fast,
            m_axis_tready  	=> s2_axis_tready_fast
        ); 

    -- input fifo from axi stream to interleaving clock domain for channel 3
	axi_stream_fifo_inst_3 : entity work.axi_stream_fifo
        generic map(
            g_WIDTH 		=> g_AXIS_TDATA_WIDTH,
            g_DEPTH 		=> 2 
        )
        port map(
            s_axis_aclk    	=> s3_axis_aclk,
            s_axis_aresetn 	=> s3_axis_aresetn,
            m_axis_aclk    	=> interleaving_aclk,
            m_axis_aresetn 	=> interleaving_aresetn,
            s_axis_tdata   	=> s3_axis_tdata,
            s_axis_tvalid  	=> s3_axis_tvalid,
            s_axis_tready  	=> s3_axis_tready,
            m_axis_tdata   	=> s3_axis_tdata_fast,
            m_axis_tvalid  	=> s3_axis_tvalid_fast,
            m_axis_tready  	=> s3_axis_tready_fast
        ); 

    -- input fifo from axi stream to interleaving clock domain for channel 4
	axi_stream_fifo_inst_4 : entity work.axi_stream_fifo
        generic map(
            g_WIDTH 		=> g_AXIS_TDATA_WIDTH,
            g_DEPTH 		=> 2 
        )
        port map(
            s_axis_aclk    	=> s4_axis_aclk,
            s_axis_aresetn 	=> s4_axis_aresetn,
            m_axis_aclk    	=> interleaving_aclk,
            m_axis_aresetn 	=> interleaving_aresetn,
            s_axis_tdata   	=> s4_axis_tdata,
            s_axis_tvalid  	=> s4_axis_tvalid,
            s_axis_tready  	=> s4_axis_tready,
            m_axis_tdata   	=> s4_axis_tdata_fast,
            m_axis_tvalid  	=> s4_axis_tvalid_fast,
            m_axis_tready  	=> s4_axis_tready_fast
        );

    ---------------------------------------------------------------------------------------
    -- Interleaving Clock Domain
    ---------------------------------------------------------------------------------------   
    -- interleaving fsm
    interleaving_inst   : entity work.axis_interleaving
        generic map(
    		g_AXIS_TDATA_WIDTH	    => g_AXIS_TDATA_WIDTH,
            g_BLOCKING_THRESHOLD    => g_BLOCKING_THRESHOLD,
            g_CHANNELS_USED		    => g_CHANNELS_USED,
            g_CHANNEL_STATUS_WIDTH  => c_CHANNEL_STATUS_WIDTH      
        )
        port map(
            interleaving_aclk  	    => interleaving_aclk,
            interleaving_aresetn    => interleaving_aresetn,
            -- axi stream channel 0
            s_axis_0_tvalid 	    => s0_axis_tvalid_fast,
            s_axis_0_tdata		    => s0_axis_tdata_fast,
            s_axis_0_tready 	    => s0_axis_tready_fast,
            -- axi stream channel 1
            s_axis_1_tvalid 	    => s1_axis_tvalid_fast,
            s_axis_1_tdata  	    => s1_axis_tdata_fast,
            s_axis_1_tready 	    => s1_axis_tready_fast,
            -- axi stream channel 2
            s_axis_2_tvalid 	    => s2_axis_tvalid_fast,
            s_axis_2_tdata  	    => s2_axis_tdata_fast,
            s_axis_2_tready 	    => s2_axis_tready_fast,
            -- axi stream channel 3
            s_axis_3_tvalid 	    => s3_axis_tvalid_fast,
            s_axis_3_tdata  	    => s3_axis_tdata_fast,
            s_axis_3_tready 	    => s3_axis_tready_fast,
            -- axi stream channel 4
            s_axis_4_tvalid 	    => s4_axis_tvalid_fast,
            s_axis_4_tdata		    => s4_axis_tdata_fast,
            s_axis_4_tready 	    => s4_axis_tready_fast,
            -- axi stream output
            m_axis_tvalid   	    => m_axis_tvalid_fast,
            m_axis_tdata    	    => m_axis_tdata_fast,
            m_axis_tready 		    => m_axis_tready_fast,
            m_demanding_data        => s_m_demanding_data_fast,
            -- register inputs
            user_control_from_reg   => s_user_control_from_reg_fast,
            channel_status_from_reg => s_channel_status_from_reg_fast,
            channel_status_from_rtl => s_channel_status_from_input_fast
        );

    ---------------------------------------------------------------------------------------
    -- Master AXI Stream Clock Domain
    ---------------------------------------------------------------------------------------
    -- output fifo from interleaving to system clock domain 
	axi_stream_fifo_inst_5 : entity work.axi_stream_fifo
    generic map(
        g_WIDTH 		=> g_AXIS_TDATA_WIDTH,
        g_DEPTH 		=> 8
    )
    port map(
        s_axis_aclk    	=> interleaving_aclk,
        s_axis_aresetn 	=> interleaving_aresetn,
        m_axis_aclk    	=> m_axis_aclk,
        m_axis_aresetn 	=> m_axis_aresetn,
        s_axis_tdata   	=> m_axis_tdata_fast,
        s_axis_tvalid  	=> m_axis_tvalid_fast,
        s_axis_tready  	=> m_axis_tready_fast,
        m_axis_tdata   	=> m_axis_tdata,
        m_axis_tvalid  	=> m_axis_tvalid,
        m_axis_tready  	=> m_axis_tready
    );

    -- master is demanding data 
    s_m_demanding_data      <= m_axis_tready;
    demanding_data_cdc_inst  : entity work.bit_cdc
        generic map(
            g_DEST_SYNC_FF  => c_DEST_SYNC_FF,
            g_SRC_INPUT_REG => c_SRC_INPUT_REG
        )
        port map(
            -- inputs
            src_clk         => m_axis_aclk,
            src_in          => s_m_demanding_data,
            dest_clk        => interleaving_aclk,
            -- output        
            dest_out        => s_m_demanding_data_fast 
        );

end architecture;