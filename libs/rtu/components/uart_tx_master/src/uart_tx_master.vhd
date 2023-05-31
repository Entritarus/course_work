library ieee;
library rtu;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use rtu.functions.all;

entity uart_tx_master is
  generic(
    CLOCK_FREQ_HZ : natural := 50_000_000;
    BAUDRATE      : natural := 115200
  );
  port(
    clk     : in std_logic;

    -- control interface
    i_valid : in  std_logic;
    i_data  : in  std_logic_vector(7 downto 0);
    o_busy  : out std_logic;

    -- uart interface
    o_sig   : out std_logic
  );
end entity;


architecture RTL of uart_tx_master is
  type state_t is (s_reset, s_idle, s_active);

  constant TICKS_PER_BIT     : natural := CLOCK_FREQ_HZ/(BAUDRATE*8);
  constant BITS_PER_TRANSFER : natural := 1 + 8 + 1; -- start bit + data + stop bit
  constant TICKS_COUNTER_MAX : natural := TICKS_PER_BIT-1;
  constant BITS_COUNTER_MAX  : natural := BITS_PER_TRANSFER-1;

  signal tcounter_en    : std_logic := '0';
  signal tcounter_value : unsigned(log2c(TICKS_PER_BIT)-1 downto 0) := (others => '0');
  signal bcounter_en    : std_logic := '0';
  signal bcounter_value : unsigned(log2c(BITS_PER_TRANSFER)-1 downto 0) := (others => '0');

  signal piso_i_data   : std_logic_vector(BITS_PER_TRANSFER-1 downto 0) := (others => '0');
  signal piso_i_load   : std_logic := '0';
  signal piso_i_enable : std_logic := '0';
  signal piso_o_data   : std_logic := '0';

  signal state_reg, state_next : state_t := s_reset;
begin

  -- ticks counter
  TCOUNTER: entity rtu.counter
  generic map(COUNTER_MAX_VALUE => TICKS_COUNTER_MAX)
  port map(
    clk       => clk,
    en        => tcounter_en,
    o_counter => tcounter_value
  );
  
  -- bits counter
  BCOUNTER: entity rtu.counter
  generic map(COUNTER_MAX_VALUE => BITS_COUNTER_MAX)
  port map(
    clk       => clk,
    en        => bcounter_en,
    o_counter => bcounter_value
  );

  -- piso register
  PISO: entity rtu.piso_register
  port map(
    clk      => clk,
    rst      => '0',
    i_load   => piso_i_load,
    i_enable => piso_i_enable,
    i_data   => piso_i_data,
    o_data   => piso_o_data
  );


  -- reg-state logic
  process
  begin
    wait until rising_edge(clk);
    state_reg <= state_next;
  end process;


  -- next-state logic
  process(all)
  begin
    -- default
    state_next    <= state_reg;
    piso_i_load   <= '0';
    piso_i_enable <= '0';
    piso_i_data   <= (others => '0');
    tcounter_en   <= '0';
    bcounter_en   <= '0';
    o_busy        <= '0';

    case state_reg is
      when s_reset =>
        -- TODO: set busy state high
        -- TODO: switch to 's_idle' state
        -- TODO: load piso register with default (high) "1111111111" values
		o_busy <= '1';
		state_next <= s_idle;
		piso_i_load <= '1';
		piso_i_enable <= '1';
		piso_i_data <= (others => '1');
      when s_idle =>
        -- TODO: set busy state low
		o_busy <= '0';
        -- TODO: if i_valid is high:
        --       - switch to 's_active' state
        --       - load piso register with '0' (start bit) + data + '1' (high stop bit)
        --         use reverse routine to change the order of the data
		if i_valid = '1' then
			state_next <= s_active;
			piso_i_load <= '1';
			piso_i_enable <= '1';
			piso_i_data <= '0' & reverse(i_data) & '1';
		end if;

      when s_active =>
        -- TODO: set busy state high
        -- TODO: enable tick counter
		o_busy <= '1';
		tcounter_en <= '1';
        -- TODO: if tick counter reaches maximum value enable bit counter
        -- TODO: if tick counter and bit counter reaches maximum values, switch to 's_idle' state
        -- TODO: if tick counter is maximum and bit counter is not maximum, enable piso register
		if (tcounter_value = TICKS_COUNTER_MAX) then
			bcounter_en <= '1';
			if (bcounter_value = BITS_COUNTER_MAX) then
				state_next <= s_idle;
			else
				piso_i_enable <= '1';
			end if;
		end if;
		
    end case;
  end process;


  -- outputs
  o_sig  <= piso_o_data;


end architecture;
