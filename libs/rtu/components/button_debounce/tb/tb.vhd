library std;
library ieee;
library rtu;
library osvvm;
library rtu_test;
library vunit_lib;

context vunit_lib.vunit_context;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use osvvm.RandomPkg.all;
use vunit_lib.com_pkg.all;
use rtu.functions.all;
use rtu_test.procedures.all;

entity tb is
  generic(
    runner_cfg            : string
  );
end entity;

architecture RTL of tb is
  constant TRANSITION_COUNT : natural := 5;
 
  -----------------------------------------------------------------------------
  -- DUT interfacing
  -----------------------------------------------------------------------------
  signal clk      : std_logic := '0';
  signal i_en     : std_logic := '0';
  signal i_signal : std_logic := '0';
  signal o_signal : std_logic := '0';

  -----------------------------------------------------------------------------
  -- Clock-related
  -----------------------------------------------------------------------------
  constant CLK_PERIOD   : time := 10 ns;
  constant PULSE_PERIOD : time := 1000*CLK_PERIOD;

begin
  -----------------------------------------------------------------------------
  -- DUT instantation
  -----------------------------------------------------------------------------
  DUT: entity rtu.button_debounce
  port map(
    clk      => clk,
    i_en     => i_en,
    i_signal => i_signal,
    o_signal => o_signal
  );

  -----------------------------------------------------------------------------
  -- Clock generator
  -----------------------------------------------------------------------------
  clk  <= not clk after CLK_PERIOD/2;

  -----------------------------------------------------------------------------
  -- Enable generator
  -----------------------------------------------------------------------------
  process
  begin
    wait for PULSE_PERIOD-CLK_PERIOD;
    i_en <= '1';
    wait for CLK_PERIOD;
    i_en <= '0';
  end process;

  -----------------------------------------------------------------------------
  -- Test sequencer
  -----------------------------------------------------------------------------
  process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("simple_test") then
        -- starting value
        i_signal <= '0';
        check(o_signal = '0', "Stabalized signal should start low");

        -- (poorly) simulate bouncing
        for i in 0 to TRANSITION_COUNT-1 loop
          wait for 5*CLK_PERIOD;
          i_signal <= '1';
          wait for 5*CLK_PERIOD;
          i_signal <= '0';

          check(o_signal = '0', "Stabalized signal seems to bounce, check your enable signal");
        end loop;

        -- signal is stable (bouncing has stopped)
        i_signal <= '1';

        wait until o_signal = '1' for 5*PULSE_PERIOD;
        check(o_signal = '1',
          "Stabalized signal doesn't seem to reach high state");

        -- wait a bit
        wait until o_signal = '0' for 5*PULSE_PERIOD;
        check(o_signal = '1',
          "Stabalized signal seems to bounce");

        -- (poorly) simulate bouncing
        for i in 0 to TRANSITION_COUNT-1 loop
          wait for 5*CLK_PERIOD;
          i_signal <= '1';
          wait for 5*CLK_PERIOD;
          i_signal <= '0';

          check(o_signal = '1', "Stabalized signal seems to bounce, check your enable signal");
        end loop;

        -- signal is stable (bouncing has stopped)
        i_signal <= '0';

        wait until o_signal = '0' for 5*PULSE_PERIOD;
        check(o_signal = '0',
          "Stabalized signal doesn't seem to reach low state");

        -- wait a bit
        wait until o_signal = '1' for 5*PULSE_PERIOD;
        check(o_signal = '0',
          "Stabalized signal seems to bounce");

      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;
