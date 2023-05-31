library std;
library ieee;
library rtu;
library osvvm;
library vunit_lib;
library rtu_test;

context vunit_lib.vunit_context;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use osvvm.RandomPkg.all;
use std.env.all;
use vunit_lib.com_pkg.all;
use rtu.functions.all;
use rtu_test.procedures.all;


entity tb is
  generic(
    runner_cfg : string;
    COUNTER_MAX_VALUE : natural := 800
  );
end entity;

architecture RTL of tb is
  -----------------------------------------------------------------------------
  -- DUT interfacing
  -----------------------------------------------------------------------------
  signal clk       : std_logic := '0';
  signal en        : std_logic := '0';
  signal o_counter : unsigned(log2c(COUNTER_MAX_VALUE+1)-1 downto 0);

  -----------------------------------------------------------------------------
  -- Clock-related
  -----------------------------------------------------------------------------
  constant CLK_PERIOD : time := 10 ns;
begin
  -----------------------------------------------------------------------------
  -- DUT instantation
  -----------------------------------------------------------------------------
  DUT: entity rtu.counter
  generic map(
    COUNTER_MAX_VALUE => COUNTER_MAX_VALUE)
  port map(
    clk       => clk,
    en        => en,
    o_counter => o_counter);

  -----------------------------------------------------------------------------
  -- Clock generator
  -----------------------------------------------------------------------------
  clk <= not clk after CLK_PERIOD/2;

  -----------------------------------------------------------------------------
  -- Test sequencer
  -----------------------------------------------------------------------------
  process
    variable v_en      : std_logic;
    variable v_counter : integer := 0;
    variable random    : RandomPType;
  begin
    test_runner_setup(runner, runner_cfg);
    random.InitSeed(random'instance_name);

    while test_suite loop
      if run("two_full_cycles") then
        wait until falling_edge(clk);
        check(unsigned(o_counter) = v_counter, "Checking initial counter value"
          & "EXPECTED: 0; GOT: " & to_hstring(o_counter));
        
        for i in 0 to 2*COUNTER_MAX_VALUE+1 loop
          -- randomized input
          v_en := random.RandSl;
          en   <= v_en;
          wait until falling_edge(clk);

          -- update model
          if v_en = '1' then
            if v_counter = COUNTER_MAX_VALUE then
              v_counter := 0;
            else
              v_counter := v_counter + 1;
            end if;
          end if;

          -- check expected
          check(unsigned(o_counter)=v_counter, "Checking counter value"
            & "EXPECTED: " & integer'image(to_integer(unsigned(o_counter))) 
            & "; GOT: " & integer'image(v_counter));
        end loop;
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;
end architecture;
