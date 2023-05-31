library ieee;
library rtu;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use rtu.functions.all;

entity uart_rx_slave is
  generic(
    CLOCK_FREQ_HZ : natural := 50_000_000;
    BAUDRATE      : natural := 115200
  );
  port(
    clk   : in std_logic;

    -- uart interface
    i_sig : in std_logic;

    -- control interface
    o_valid : out std_logic;
    o_data  : out std_logic_vector(7 downto 0)
  );
end entity;


architecture RTL of uart_rx_slave is
  type state_t is (s_idle, s_active, s_done);

  constant TICKS_PER_BIT     : natural := CLOCK_FREQ_HZ/(BAUDRATE*8);
  constant BITS_PER_TRANSFER : natural := 1 + 8 + 1; -- start bit + data + stop bit
  constant TICKS_COUNTER_MAX : natural := TICKS_PER_BIT-1;
  constant BITS_COUNTER_MAX  : natural := BITS_PER_TRANSFER-1;

  signal tcounter_en    : std_logic := '0';
  signal tcounter_value : unsigned(log2c(TICKS_PER_BIT)-1 downto 0) := (others => '0');
  signal bcounter_en    : std_logic := '0';
  signal bcounter_value : unsigned(log2c(BITS_PER_TRANSFER)-1 downto 0) := (others => '0');

  signal sipo_i_enable : std_logic := '0';
  signal sipo_i_data   : std_logic := '0';
  signal sipo_o_data   : std_logic_vector(7 downto 0) := (others => '0');

  signal state_reg, state_next : state_t := s_idle;
  signal valid_reg, valid_next : std_logic := '0';

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

  -- sipo register
  SIPO: entity rtu.sipo_register
  port map(
    clk      => clk,
    rst      => '0',
    i_enable => sipo_i_enable,
    i_data   => sipo_i_data,
    o_data   => sipo_o_data
  );

  -- reg-state logic
  process
  begin
    wait until rising_edge(clk);
    state_reg <= state_next;
    valid_reg <= valid_next;
  end process;


  -- next-state logic
  process(all)
  begin
    state_next    <= state_reg;
    sipo_i_data   <= i_sig;
    sipo_i_enable <= '0';
    valid_next    <= '0';
    tcounter_en   <= '0';
    bcounter_en   <= '0';

    case state_reg is
      when s_idle =>
        -- TODO: switch to 's_active' state if start condition is detected
		if (i_sig = '0') then
			state_next <= s_active;
		end if;

      when s_active =>
        -- TODO: enable tick counter
		tcounter_en <= '1';
        -- TODO: if tick counter reaches maximum value, enable bit counter
        -- TODO: if tick and bit counters reach maximum values, switch to 's_done' state
		if (tcounter_value = TICKS_COUNTER_MAX) then 
			bcounter_en <= '1';
			if (bcounter_value = BITS_COUNTER_MAX) then
				state_next <= s_done;
			end if;
		end if;
        -- TODO: if tick counter's value equals approximately half of the maximum value
        --       (middle of the sample) and bit counter is not maximum, sample input data
        --       by enabling SIPO register
		if (tcounter_value = TICKS_COUNTER_MAX/2 and bcounter_value < BITS_COUNTER_MAX) then
			sipo_i_enable <= '1';
		end if;

      when s_done =>
        -- TODO: generate valid "data received" message (note that sipo is already connected to o_data)
        -- TODO: switch to 's_idle' state
		valid_next <= '1';
		state_next <= s_idle;

    end case;
  end process;


  -- outputs
  o_valid <= valid_reg;
  o_data  <= reverse(sipo_o_data);

end architecture;
