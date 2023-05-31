-------------------------------------------------------------------------------
--! @file i2c_master.vhd
--! @author Rihards Novickis
-------------------------------------------------------------------------------
-- synthesis VHDL_INPUT_VERSION VHDL_2008
-- synthesis LIBRARY edi

library ieee;
library edi;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use edi.data_types.all;

--------------------------------------------------------------------------------
--! @brief Shift register-based EDI I2C Master with support for variable
--!        address/data width and multiple continious transactions, some 
--!        features still could be added, i.e. scl streching
--!
--! @param SLAVE_ADDR_WIDTH I2C standard supports both 7 and 10 bit slave
--!        addressing, this parameter can be used to select that (or
--!        to even set any arbitrary width, of course if used with EDI
--!        I2C slave component)
--! @param DATA_WIDTH I2C standard considers data width of 8 bits, but
--!        for some custom use case (internal EDI), this could be 
--!        modified
entity i2c_master is
  generic(
    SLAVE_ADDR_WIDTH : natural := 7;
    DATA_WIDTH       : natural := 8
  );
  port(
    clk : in sl; --! four times the frequency of the bus
    rst : in sl; --! asynchronous reset
    -- control interface
    i_start     : in  sl; --! start transaction (1 cycle)
    o_done      : out sl; --! transaction done
    o_ready     : out sl; --! ready for the next transaction
    o_error     : out sl; --! error in transaction 
    -- data-flow interface
    i_doRead    : in  sl; --! '0' -> writedata, '1' -> readdata
    i_saddr     : in  slv(SLAVE_ADDR_WIDTH-1 downto 0); --! Slave address
    i_baddr     : in  slv(DATA_WIDTH-1 downto 0); --! Base address
    i_data      : in  slv(DATA_WIDTH-1 downto 0); --! Write data
    -- physical interface to tristate buffer ctl
    o_sda_oe : out sl;
    i_sda    : in  sl;
    o_sda    : out sl;
    o_scl_oe : out sl;
    i_scl    : in  sl;
    o_scl    : out sl
  );
end entity;

architecture RTL of i2c_master is
  constant ADDR_WORD_WIDTH : natural := SLAVE_ADDR_WIDTH + 1;
  --constant COUNTER_WIDTH : natural := log2c(max(ADDR_WORD_WIDTH,DATA_WIDTH));
  constant COUNTER_WIDTH : natural := 4;

  -- scl (clock line) states
  type state_scl_t is (
    s_scl_low_0, s_scl_low_1, s_scl_high_0, s_scl_high_1);

  -- i2c transaction states
  type state_t is (
    s_idle, s_start,
    s_clk0, s_clk1, s_clk2, s_clk3,
    s_clk0a, s_clk1a, s_clk2a, s_clk3a,
    s_stop, s_stop_error);

  type state_func_t is (
    s_writeAddr, s_writeData0, s_writeData1);

  signal state_reg, state_next : state_t := s_idle;
  signal state_func_reg, state_func_next : state_func_t := s_writeAddr;
  signal error_reg, error_next : std_logic := '0';
  signal counter_en : boolean;
  signal counter_reg, counter_next : unsigned(COUNTER_WIDTH-1 downto 0);
  signal shift_saddr_en, shift_saddr_load, shift_saddr_out : std_logic;
  signal shift_baddr_en, shift_baddr_load, shift_baddr_out : std_logic;
  signal shift_wdata_en, shift_wdata_load, shift_wdata_out : std_logic;

begin
  -- SERIALIZER - slave address
  SERIALIZER_SADDR: entity edi.serializer
  generic map(ADDR_WORD_WIDTH)
  port map(clk => clk, rst => rst,
    i_load   => shift_saddr_load, 
    i_enable => shift_saddr_en,
    i_data   => i_saddr & i_doRead,
    o_data   => shift_saddr_out);

  -- SERIALIZER - base address
  SERIALIZER_BADDR: entity edi.serializer
  generic map(ADDR_WORD_WIDTH)
  port map(clk => clk, rst => rst,
    i_load   => shift_baddr_load, 
    i_enable => shift_baddr_en,
    i_data   => i_baddr,
    o_data   => shift_baddr_out);

  -- SERIALIZER - wdata
  SERIALIZER_WDATA: entity edi.serializer
  generic map(DATA_WIDTH)
  port map(clk => clk, rst => rst,
    i_load   => shift_wdata_load, 
    i_enable => shift_wdata_en,
    i_data   => i_data,
    o_data   => shift_wdata_out);

  -- reg-state logic
  process(rst, clk)
  begin
    if rst = '1' then
      state_reg      <= s_idle;
      state_func_reg <= s_writeAddr;
      error_reg      <= '0';
      counter_reg    <= to_unsigned(ADDR_WORD_WIDTH-1, counter_reg'length);
    else
      if rising_edge(clk) then
        state_reg      <= state_next;
        state_func_reg <= state_func_next;
        error_reg      <= error_next;
        if counter_en then
          counter_reg <= counter_next;
        end if;
      end if;
    end if;
  end process;

  -- FSMs
  process(all)
  begin
    -- default
    state_next      <= state_reg;
    state_func_next <= state_func_reg;

    case state_reg is
      when s_idle =>
        if i_start = '1' then
          state_next <= s_start;
        end if;

      when s_start =>
        state_next <= s_clk0;

      when s_clk0 =>
        state_next <= s_clk1;

      when s_clk1 =>
        state_next <= s_clk2;

      when s_clk2 =>
        state_next <= s_clk3;

      when s_clk3 =>
        if counter_reg = 0 then
          state_next <= s_clk0a;
        else
          state_next <= s_clk0;
        end if;

      when s_clk0a =>
        state_next <= s_clk1a;

      when s_clk1a =>
        state_next <= s_clk2a;

      when s_clk2a =>
        if i_sda = '1' then
          state_next <= s_stop_error;
        else
          state_next <= s_clk3a;
        end if;

      when s_clk3a =>
        if state_func_reg = s_writeAddr then
          state_next <= s_clk0;
          state_func_next <= s_writeData0;
        elsif state_func_reg = s_writeData0 then
          state_next <= s_clk0;
          state_func_next <= s_writeData1;
        elsif state_func_reg = s_writeData1 then
          state_next <= s_stop;
        end if;

      when s_stop =>
        state_next <= s_idle;
        state_func_next <= s_writeAddr;

      when s_stop_error => 
        state_next <= s_idle;
        state_func_next <= s_writeAddr;
    end case;
  end process;


  -- shift register enable signals
  shift_saddr_en <= '1' when state_func_reg = s_writeAddr and state_reg = s_clk3 else '0';
  shift_baddr_en <= '1' when state_func_reg = s_writeData0 and state_reg = s_clk3 else '0';
  shift_wdata_en <= '1' when state_func_reg = s_writeData1 and state_reg = s_clk3 else '0';

  -- shift register load signals
  shift_saddr_load <= '1' when state_reg = s_idle and i_start = '1' else '0';
  shift_baddr_load <= '1' when state_reg = s_idle and i_start = '1' else '0';
  shift_wdata_load <= '1' when state_reg = s_idle and i_start = '1' else '0';

  -- counter enable logic
  counter_en <= (state_reg = s_idle and i_start = '1') 
             or (state_reg = s_clk3);

  -- counter set/reset logic
  counter_next <= 
      to_unsigned(ADDR_WORD_WIDTH-1, counter_next'length) when (state_reg = s_idle) else
      to_unsigned(DATA_WIDTH-1, counter_next'length) when counter_reg = 0 and state_reg = s_clk3 else
      counter_reg-1;

  -- error handling
  error_next <= i_sda when state_reg = s_clk1a else
                '0'   when state_reg = s_start else
                error_reg;

  -- outputs
  o_error <= error_reg;
  o_done  <= '1' when (state_reg = s_stop) or (state_reg = s_stop_error) else '0';
  o_ready <= '1' when (state_reg = s_idle) else '0';

  -- sda line
  process(all)
  begin
    -- default sda output enable
    o_sda_oe <= '1';
    o_scl_oe <= '1';
    o_sda    <= '1';
    o_scl    <= '1';

    -- sda/sda_oe control
    case state_reg is
      when s_start | s_clk0 | s_stop | s_stop_error =>
        o_sda <= '0';
      when s_clk1 | s_clk2 | s_clk3 =>
        if state_func_reg = s_writeAddr then
          o_sda <= shift_saddr_out;
        elsif state_func_reg = s_writeData0 then
          o_sda <= shift_baddr_out;
        else
          o_sda <= shift_wdata_out;
        end if;
       when s_clk1a | s_clk2a | s_clk3a =>
        o_sda    <= '0';
        o_sda_oe <= '0';
      when others =>
    end case;

    -- scl/scl_oe control
    case state_reg is
      when s_clk2 | s_clk2a =>
        o_scl <= '1';
      when s_clk0|s_clk1|s_clk3|s_clk0a|s_clk1a|s_clk3a =>
        o_scl <= '0';
      when others =>
        o_scl <= '1';
    end case;

  end process;
end architecture;
