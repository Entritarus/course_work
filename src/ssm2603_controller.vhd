library ieee;
library edi;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use edi.functions.all;
use edi.data_types.all;

entity ssm2603_controller is
	port(
		clk : in sl;
    rst : in sl;
    
    
    i_reconfig_req     : in sl;
    o_reconfig_success : out sl;
    
    io_scl  : inout sl;
    io_sda  : inout sl;
    o_error : out sl
	);
end entity;

architecture RTL of ssm2603_controller is
  constant SLAVE_ADDR_WIDTH : natural := 7;
  constant DATA_WIDTH : natural := 8;
  constant SLAVE_ADDR : std_logic_vector(SLAVE_ADDR_WIDTH-1 downto 0) := "0011010"; -- CODEC_SEL = '0'
  constant CFG_LEN : natural := 12;
  
  type cfg_dat_t is array(integer range<>) of slv;
  constant CONFIG_DATA : cfg_dat_t(0 to CFG_LEN-1)(DATA_WIDTH*2 - 1 downto 0) := (
    0  => x"1E00", -- R15: initial chip reset
    1  => x"0C72", -- R6:  turn on whole chip, DAC, ADC, LINEIN
    2  => x"000B", -- R0:  disable LRINBOTH (0), no LINMUTE (0), 0 dB left channel ADC volume --OK
    3  => x"020B", -- R1:  disable LRINBOTH (0), no RINMUTE (0), 0 dB right channel ADC volume --OK
    4  => x"0451", -- R2:  disable LRHPBOTH (0), -40 dB left channel DAC volume --OK
    5  => x"0651", -- R3:  disable LRHPBOTH (0), -40 dB right channel DAC volume --OK
    6  => x"0812", -- R4:  select DAC, bypass disable, line in to ADC --OK
    7  => x"0A00", -- R5:  no DAC mute, no de-emphasis, no ADC HPF --OK
    8  => x"0E02", -- R7:  BCLK not inverted, slave mode (master = 0x40), no LRSWAP, LRP normal, 16 bit, i2s --OK
    9  => x"1001", -- R8:  USB mode, fs = 48 kHz --OK
    10 => x"1201", -- R9:  activate digital core
    11 => x"0C62"  -- R6:  turn on output
  );
  
  type state_t is (s_idle, s_perform_config, s_done, s_error);
  
  signal data_byte0 : slv(DATA_WIDTH-1 downto 0);
  signal data_byte1 : slv(DATA_WIDTH-1 downto 0);
  signal ctr_reg, ctr_next : unsigned(log2c(CFG_LEN)-1 downto 0) := (others => '0');
  signal state_reg, state_next : state_t := s_idle;
  
  
  signal i2c_start  : sl;
  signal i2c_done   : sl;
  signal i2c_ready  : sl;
  signal i2c_error  : sl;
  
  signal i2c_sda_oe : sl;
  signal i2c_sda_i  : sl;
  signal i2c_sda_o  : sl;
  signal i2c_scl_oe : sl;
  signal i2c_scl_i  : sl;
  signal i2c_scl_o  : sl;
begin
	I2C_MASTER: entity edi.i2c_master
		generic map (
      SLAVE_ADDR_WIDTH => SLAVE_ADDR_WIDTH,
      DATA_WIDTH => DATA_WIDTH
    )
		port map (
      clk       => clk,
      rst       => rst,
      
      
      i_start   => i2c_start,
      o_done    => i2c_done,
      o_ready   => i2c_ready,
      o_error   => i2c_error,
      
      i_doRead  => '0',
      i_saddr   => SLAVE_ADDR,
      i_baddr   => data_byte1,
      i_data    => data_byte0,
      
      o_sda_oe  => i2c_sda_oe,
      i_sda     => i2c_sda_i,
      o_sda     => i2c_sda_o,
      o_scl_oe  => i2c_scl_oe,
      i_scl     => i2c_scl_i,
      o_scl     => i2c_scl_o
    );
  
  process(clk) is
  begin
    if rst = '1' then
      ctr_reg <= (others => '0');
      state_reg <= s_idle;
    else
      if rising_edge(clk) then
        state_reg <= state_next;
        ctr_reg <= ctr_next;
      else
        state_reg <= state_reg;
        ctr_reg <= ctr_reg;
      end if;
    end if;
  end process;
  
  process(all) is 
  begin
    state_next <= state_reg;
    ctr_next <= ctr_reg;
    i2c_start <= '0';
    o_reconfig_success <= '0';
    case state_reg is
      when s_idle =>
        if i_reconfig_req = '1' then
          state_next <= s_perform_config;
        end if;
        
      when s_perform_config =>
        if ctr_reg = CFG_LEN then
          state_next <= s_done;
        else
          
          if (i2c_ready = '1') then
            i2c_start <= '1';
          end if;
          if (i2c_done = '1') then
            ctr_next <= ctr_reg + 1;
          end if;
          if (i2c_error = '1') then
            state_next <= s_error;
          end if;
        end if;
      
      when s_done =>
        o_reconfig_success <= '1';
      when s_error =>
        
    end case;
  end process;
  
  data_byte0 <= CONFIG_DATA(to_integer(ctr_reg))(7 downto 0);
  data_byte1 <= CONFIG_DATA(to_integer(ctr_reg))(15 downto 8);
  
  i2c_sda_i <= io_sda;
  i2c_scl_i <= io_scl;
  
  io_sda <=  i2c_sda_o when i2c_sda_oe = '1' else
              'Z';
  io_scl <=  i2c_scl_o when i2c_scl_oe = '1' else
              'Z';
  o_error <= i2c_error;
end architecture;

