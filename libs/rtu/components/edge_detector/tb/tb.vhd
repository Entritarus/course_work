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
  -----------------------------------------------------------------------------
  -- DUT interfacing
  -----------------------------------------------------------------------------
  signal clk        : std_logic := '0';
  signal i_signal   : std_logic := '0';
  signal o_rising   : std_logic := '0';
  signal o_falling  : std_logic := '0';

  -----------------------------------------------------------------------------
  -- Clock-related
  -----------------------------------------------------------------------------
  constant CLK_PERIOD : time := 10 ns;

begin
  -----------------------------------------------------------------------------
  -- DUT instantation
  -----------------------------------------------------------------------------
  DUT: entity rtu.edge_detector
  port map(
    clk        => clk,
    i_signal   => i_signal,
    o_rising   => o_rising,
    o_falling  => o_falling
  );

  -----------------------------------------------------------------------------
  -- Clock generator
  -----------------------------------------------------------------------------
  clk <= not clk after CLK_PERIOD/2;

  -----------------------------------------------------------------------------
  -- Test sequencer
  -----------------------------------------------------------------------------
  process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("rising_edge") then

        -- known init state
        i_signal <= '0';
        wait until falling_edge(clk);
        i_signal <= '1';

        -- 1) detected signal should become active with the rising edge,
        -- 2) further check if indeed it is active only for a single clock
        -- cycle, 3) finally, check if there are no artifacts
        wait until o_rising = '1' for 5*CLK_PERIOD;
        check(o_rising = '1',
          "Rising detection not generated within timeout period");
        check(o_falling = '0',
          "Falling edge detection found during rising edge");

        wait until rising_edge(clk);
        wait for 0.1*CLK_PERIOD;
        check(o_rising = '0',
          "Rising detection should span just a single clock cycle");
        check(o_falling = '0',
          "Falling edge detection found during rising edge");

        wait until o_rising = '1' for 20*CLK_PERIOD;
        check(o_rising = '0',
          "Invalid extra rising detection pulse generated");
        check(o_falling = '0',
          "Falling edge detection found during rising edge");

      elsif run("falling_edge") then

        -- known init state
        i_signal <= '1';
        wait for 10*CLK_PERIOD;
        i_signal <= '0';

        -- 1) detected signal should become active with the falling edge,
        -- 2) further check if indeed it is active only for a single clock
        -- cycle, 3) finally, check if there are no artifacts
        wait until o_falling = '1' for 5*CLK_PERIOD;
        check(o_falling = '1',
          "Falling detection not generated within timeout period");
        check(o_rising = '0',
          "Rising detection active during falling edge");

        wait until rising_edge(clk);
        wait for 0.1*CLK_PERIOD;
        check(o_falling = '0',
          "Falling detection should span just a single clock cycle");
        check(o_rising = '0',
          "Rising edge detection found during falling edge");

        wait until o_rising = '1' for 20*CLK_PERIOD;
        check(o_falling = '0',
          "Invalid extra falling detection pulse generated");
        check(o_rising = '0',
          "Rising edge detection found during rising edge");

      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;
end architecture;
