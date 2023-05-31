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
use rtu.data_types.all;

entity tb is
  generic(
    runner_cfg : string;
    DATA_WIDTH : natural := 8
  );
end entity;

architecture RTL of tb is
  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  constant CLK_PERIOD : time := 10 ns;

  -----------------------------------------------------------------------------
  -- DUT interfacing
  -----------------------------------------------------------------------------
  signal clk      : std_logic := '0';
  signal rst      : std_logic := '0';
  signal i_load   : std_logic := '0';
  signal i_enable : std_logic := '0';
  signal i_data   : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal o_data   : std_logic := '0';

begin

  -----------------------------------------------------------------------------
  -- clk
  -----------------------------------------------------------------------------
  clk <= not clk after CLK_PERIOD/2;

  -----------------------------------------------------------------------------
  -- DUT instantation
  -----------------------------------------------------------------------------
  DUT: entity rtu.piso_register
  port map(
    clk      => clk,
    rst      => rst,
    i_load   => i_load,
    i_enable => i_enable,
    i_data   => i_data,
    o_data   => o_data
  );

  -----------------------------------------------------------------------------
  -- Test sequencer
  -----------------------------------------------------------------------------
  process
    variable dut_data : std_logic_vector(DATA_WIDTH-1 downto 0);
  begin
    test_runner_setup(runner, runner_cfg);
      if run("full_coverage") then
        for i in 0 to 2**DATA_WIDTH-1 loop
          dut_data := std_logic_vector(to_unsigned(i,DATA_WIDTH));
          i_data   <= dut_data;
          i_load   <= '1';
          i_enable <= '1';
          wait until rising_edge(clk);

          i_load   <= '0';
          i_enable <= '0';
          wait until rising_edge(clk);

          for j in DATA_WIDTH-1 downto 0 loop
            check(o_data = dut_data(j), "Data mismatch"
              & " EXPECTED: " & to_string(dut_data(j))
              & " GOT: " & to_string(o_data));

            i_enable <= '1';
            wait until rising_edge(clk);

            i_enable <= '0';
            wait until rising_edge(clk);
          end loop;

        end loop;
      end if;
    test_runner_cleanup(runner);
  end process;
end architecture;
