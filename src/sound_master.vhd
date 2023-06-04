library ieee;
library edi;
library rtu;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use edi.functions.all;
use edi.data_types.all;

entity sound_master is
  generic (
    DATA_WIDTH : natural := 24
  );
  port(
    clk : in sl; -- FCLK = 2*DATA_WIDTH*48 kHz
    rst : in sl;
    i_enable : in sl;
    
    i_data : in slv(DATA_WIDTH-1 downto 0); -- data to playback
    o_ready : out sl;
    
    
    o_data : out slv(DATA_WIDTH-1 downto 0); -- data from record
    o_valid : out sl;
    
    o_bclk : out sl; -- sound codec interface
    o_pbdat : out sl; --
    i_recdat : in sl; --
    o_lrc : out sl --
  ); 
end entity; 

architecture RTL of sound_master is
  constant FRAME_WIDTH : natural := 32;
  constant CLK_DIV_RATIO : natural := 10; 
  signal int_en : sl;
  
  signal piso_load : sl := '0';
  signal piso_en   : sl := '0';
  signal piso_data : slv(FRAME_WIDTH-1 downto 0) := (others => '0');
  
  signal sipo_data : slv(FRAME_WIDTH-1 downto 0) := (others => '0');
  signal sipo_en : sl := '0';
  
  signal ctr_reg, ctr_next : unsigned(log2c(FRAME_WIDTH)-1 downto 0) := (others => '0');--to_unsigned(FRAME_WIDTH-1, log2c(FRAME_WIDTH));
  
  signal bclk_reg, bclk_next : sl := '0';
  signal lrc_reg, lrc_next   : sl := '1';
  
  signal ctr_is_full : boolean;
  signal out_data_valid : sl;
  signal in_ready : sl;
  signal shift_reg_rst : sl;
  
begin
  PISO : entity rtu.piso_register
    port map(
      clk        => clk,
      rst        => rst,
      i_load     => piso_load,
      i_enable   => piso_en,
      i_data     => piso_data,
      i_srst     => '0',
      o_data     => o_pbdat
    );
    
  SIPO : entity rtu.sipo_register
    port map (
      clk       => clk,
      rst       => rst,
      i_enable  => sipo_en,
      i_data    => i_recdat,
      i_srst    => '0',
      o_data    => sipo_data
    );
  
  CLK_DIV_PULSE : entity work.clock_divider_pulse
    generic map (
      DIVISION_RATIO => CLK_DIV_RATIO
    )
    port map (
      rst => rst,
      i_clk => clk,
      o_en => int_en
    );
  
  -- reg-state logic
  process(clk) is
  begin
    if rst = '1' then
      ctr_reg <= (others => '0');--to_unsigned(FRAME_WIDTH-1, log2c(FRAME_WIDTH)); --to_unsigned(FRAME_WIDTH-1, log2c(FRAME_WIDTH));
      bclk_reg <= '0';
      lrc_reg <= '0';
    else
      if rising_edge(clk) then
        if int_en and i_enable then
          ctr_reg  <= ctr_next;
          bclk_reg <= bclk_next;
          lrc_reg  <= lrc_next;
        else
          ctr_reg  <= ctr_reg;
          bclk_reg <= bclk_reg;
          lrc_reg  <= lrc_reg;
        end if;
      end if;
    end if;
  end process;
  
  -- next-state logic
  ctr_is_full <= ctr_reg = FRAME_WIDTH-1;
  
  ctr_next <= ctr_reg + 1 when bclk_reg = '1' and not ctr_is_full else
              (others => '0') when bclk_reg = '1' and ctr_is_full else
              ctr_reg;
  bclk_next <= not bclk_reg;
  lrc_next <= not lrc_reg when bclk_reg = '1' and ctr_is_full else lrc_reg;
  
  -- shift register control
  
  sipo_en <= '1' when bclk_reg = '1' and int_en = '1' else 
             '0';
  piso_en <= '1' when bclk_reg = '1' and int_en = '1' else 
             '0';
				 
  piso_data <= i_data & (FRAME_WIDTH-DATA_WIDTH-1 downto 0 => '0');

  piso_load <= '1' when ctr_reg = 0 and bclk_reg = '1' else 
               '0';
  
  out_data_valid <= '1' when ctr_reg = 0 and bclk_reg = '1' else
                    '0';
  in_ready <= '1' when ctr_reg = 0 and bclk_reg = '1' else
                   '0'; 
                   
  -- shift_reg_rst <= '1' when ctr_reg = 0 and bclk_reg = '0' and int_en = '1' else
                   -- '0'; 
  -- outputs
  o_bclk <= bclk_reg;
  o_lrc <= lrc_reg;
  
  -- i know this is not how it is supposed to work, but it works
  o_data <= sipo_data(FRAME_WIDTH-2 downto FRAME_WIDTH-DATA_WIDTH-1) when out_data_valid else (others => '0');
  --o_data <= sipo_data when out_data_valid else (others => '0');
  
  o_valid <= out_data_valid;
  o_ready <= in_ready;
  
end architecture;