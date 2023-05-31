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
  signal i_valid : std_logic := '0';
  signal i_data  : std_logic_vector(7 downto 0) := (others => '0');
  signal o_busy  : std_logic := '0';
  signal o_sig   : std_logic := '0';

  -----------------------------------------------------------------------------
  -- Clock-related
  -----------------------------------------------------------------------------
  constant TIME_PER_BIT : time := 1000_000_000 ns/(8*BAUDRATE);

begin
  -----------------------------------------------------------------------------
  -- DUT instantation
  -----------------------------------------------------------------------------
  DUT: entity rtu.uart_tx_master
  generic map(
    CLOCK_FREQ_HZ => CLOCK_FREQ_HZ,
    BAUDRATE      => BAUDRATE)
  port map(
    clk     => clk,
    i_valid => i_valid,
    i_data  => i_data,
    o_busy  => o_busy,
    o_sig   => o_sig
  );

  -----------------------------------------------------------------------------
  -- Clock generator
  -----------------------------------------------------------------------------
  clk  <= not clk after CLK_PERIOD/2;

  -----------------------------------------------------------------------------
  -- Test sequencer
  -----------------------------------------------------------------------------
  process

    procedure dut_request_write(data : std_logic_vector(7 downto 0)) is
    begin
      wait until o_busy = '0' for 12*TIME_PER_BIT;
      check(o_busy = '0', "Controller stuck in busy state");

      info("Requesting write with data " & to_hstring(data));
      wait until rising_edge(clk);
      i_valid <= '1';
      i_data  <= data;
      wait until rising_edge(clk);
      i_valid <= '0';
      i_data  <= (others => '0');
    end procedure;

    procedure dut_wait_for_start_condition is
    begin
      info("Waiting for start condition");
      wait until o_sig = '0' for 10*TIME_PER_BIT;
      check(o_sig = '0', "Waiting for start condition timeout reached");
    end procedure;

    procedure dut_wait_for_stop_condition is
    begin
      info("Waiting for stop condition");
      wait until o_sig = '1' for 10*TIME_PER_BIT;
      check(o_sig = '1', "Waiting for stop condition timeout reached");
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

    procedure dut_check_current_bit(data : std_logic) is
    begin
      check(o_sig = data, "Output bit incorrect, "
        & "EXPECTED: " & to_string(data) & "; "
        & "GOT: "      & to_string(o_sig));
    end procedure;

    variable dut_data : std_logic_vector(7 downto 0);

  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop

      if run("full_coverage") then
        wait for 10*TIME_PER_BIT;
        check(o_sig = '1', "UART output by default must be high");

        for i in 0 to 255 loop
          dut_data := std_logic_vector(to_unsigned(i, 8));
          dut_request_write(dut_data);

          dut_wait_for_start_condition;
          dut_wait_for_half_bit;
          dut_wait_for_full_bit;

          for j in 0 downto 7 loop
            dut_check_current_bit(dut_data(j));
            dut_wait_for_full_bit;
          end loop;

          dut_wait_for_stop_condition;
        end loop;
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;

