library ieee;
library edi;
library rtu;
library pll_12MHz;
library pll_61_44MHz;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use edi.functions.all;
use edi.data_types.all;

entity main is
  port( 
    i_clk_50MHz : in sl;
    
    i_rst : in sl;
    --i_btn_reconfigure : in sl;
		  
    io_sda : inout sl;
    io_scl : inout sl;
    
    o_ssm_clk : out sl;
    o_error_led : out sl;
    o_success_led : out sl;
    
    o_bclk : out sl; -- out by default 
    o_pbdat : out sl; -- out by default
    i_recdat : in sl; -- 
    o_lrc_dac : out sl; -- out by default 
    o_lrc_adc : out sl -- out by default
	 --o_mute : out sl
  );
end entity;

architecture RTL of main is

  signal int_reset : sl;
  signal clk_i2c : sl;
  signal clk_ssm : sl;
  signal clk_sound_io : sl;
  signal ssm_sda_out, ssm_sda_in, ssm_sda_oe: sl;
  signal ssm_scl_out, ssm_scl_in, ssm_scl_oe: sl;
	
  signal i_sound_data : slv(15 downto 0);
  signal o_sound_data : slv(15 downto 0);
  signal enable_sound_io : sl;
  
  signal snd_test_bit : sl;
  
  signal ready, valid : sl;
  
  signal lrc : sl;
  
begin
  int_reset <= not i_rst;

	CLK_DIVIDER_DUTY: entity work.clock_divider_duty
		generic map (
			DIVISION_RATIO => 125,
			DUTY => 50
		)
		port map (
			rst => int_reset,
			clk_in => i_clk_50MHz,
			clk_out => clk_i2c
		);
	CLK_PLL_SSM: entity pll_12MHz.pll_12MHz
		port map (
			refclk   => i_clk_50MHz,
			rst      => int_reset,
			outclk_0 => clk_ssm
		);
  o_ssm_clk <= clk_ssm;
  CLK_PLL_SOUND_IO: entity pll_61_44MHz.pll_61_44MHz
		port map (
			refclk   => i_clk_50MHz,
			rst      => int_reset,
			outclk_0 => clk_sound_io
		);
  
	SSM2603_CONTROLLER: entity work.ssm2603_controller
		port map (
			clk => clk_i2c,
			rst => int_reset,
			
			i_reconfig_req => enable_sound_io,
			o_reconfig_success => o_success_led,
			
			io_scl  => io_scl,
      io_sda  => io_sda,
      o_error => o_error_led
		);
	
  SOUND_IO: entity work.sound_master
    port map (
      clk => clk_sound_io,
      rst => int_reset,
		i_enable => enable_sound_io,
		
      i_data => i_sound_data, -- data to playback
      o_ready => open, --ready,
    
      o_data => i_sound_data, -- data from record
      o_valid => open, --valid,
    
      o_bclk => o_bclk, 
      o_pbdat => o_pbdat,
      i_recdat => i_recdat,
      o_lrc => lrc
    );
   
  STARTUP_TIMER: entity work.startup_timer
    port map (
      clk => i_clk_50MHz,
      rst => int_reset,
      
      i_start => '1',
      o_out => enable_sound_io
    );
    
  SOUND_TEST: entity work.clock_divider_duty
		generic map (
			DIVISION_RATIO => 100000,
			DUTY => 50
		)
		port map (
			rst => int_reset,
			clk_in => i_clk_50MHz,
			clk_out => snd_test_bit
		);
  
  --i_sound_data <= (14 => snd_test_bit, others => '0'); -- sound test
  --i_sound_data <= (others => '0');
  -- o_lrc_dac <= lrc;
  -- o_lrc_adc <= lrc;
  --o_pbdat <= i_recdat;
  --o_lrc_dac <= i_lrc_adc;
  --o_mute <= '1';
  --o_pbdat <= '0';
end architecture;