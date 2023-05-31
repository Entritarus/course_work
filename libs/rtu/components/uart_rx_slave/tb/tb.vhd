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
use rtu.data_types.all;
use rtu_test.procedures.all;

entity tb is
  generic(
    runner_cfg    : string;
    CLOCK_FREQ_HZ : natural := 50_000_000;
    BAUDRATE      : natural := 115200
  );
end entity;

architecture RTL of tb is
  constant CLK_PERIOD   : time := 1000_000_000 ns/CLOCK_FREQ_HZ;
 
  -----------------------------------------------------------------------------
  -- DUT interfacing
  -----------------------------------------------------------------------------
  signal clk     : std_logic := '0';
  signal i_sig   : std_logic := '0';
  signal o_valid : std_logic := '0';
  signal o_data  : std_logic_vector(7 downto 0) := (others => '0');

  -----------------------------------------------------------------------------
  -- Clock-related
  -----------------------------------------------------------------------------
  constant TIME_PER_BIT : time := 1000_000_000 ns/(8*BAUDRATE);

begin
  -----------------------------------------------------------------------------
  -- DUT instantation
  -----------------------------------------------------------------------------
  DUT: entity rtu.uart_rx_slave
  generic map(
    CLOCK_FREQ_HZ => CLOCK_FREQ_HZ,
    BAUDRATE      => BAUDRATE)
  port map(
    clk     => clk,
    i_sig   => i_sig,
    o_valid => o_valid,
    o_data  => o_data
  );

  -----------------------------------------------------------------------------
  -- Clock generator
  -----------------------------------------------------------------------------
  clk  <= not clk after CLK_PERIOD/2;

  -----------------------------------------------------------------------------
  -- Test sequencer
  -----------------------------------------------------------------------------
  process

    procedure dut_generate_start_condition is
    begin
      info("Generating start condition");
      i_sig <= '0';
    end procedure;

    procedure dut_set_data(data : std_logic) is
    begin
      info("Setting input data to " & to_string(data));
      i_sig <= data;
    end procedure;

    procedure dut_wait_for_half_bit is
    begin
      info("Waiting for half bit");
      wait for TIME_PER_BIT/2;
    end procedure;

    procedure dut_wait_for_full_bit is
    begin
      info("Waiting for full bit");
      wait for TIME_PER_BIT;
    end procedure;

    procedure dut_check_output(data : std_logic_vector(7 downto 0)) is
    begin
      wait until o_valid = '1' for 10*TIME_PER_BIT;
      check(o_valid = '1', "High output valid state never reached (timeout)");
      check(o_data = data, "Expected data mismatch detected, "
        & "EXPECTED: " & to_hstring(data) & "; "
        & "GOT: "      & to_hstring(o_data));
    end procedure;


    variable dut_data : std_logic_vector(7 downto 0);

  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop

      if run("full_coverage") then
        i_sig <= '1';
        wait for 10*TIME_PER_BIT;

        for i in 0 to 255 loop
          dut_data := std_logic_vector(to_unsigned(i, 8));

          dut_generate_start_condition;
          dut_wait_for_full_bit;

          for j in 0 to 7 loop
            dut_set_data(dut_data(j));
            dut_wait_for_full_bit;
          end loop;

          dut_set_data('1');
          dut_check_output(dut_data);
          dut_wait_for_full_bit;
          dut_wait_for_full_bit;
          dut_wait_for_full_bit;
        end loop;
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;

