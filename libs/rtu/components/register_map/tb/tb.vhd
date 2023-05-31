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
    runner_cfg     : string;
    REGISTER_COUNT : natural := 4;
    DATA_WIDTH     : natural := 8
  );
end entity;

architecture RTL of tb is
 
  -----------------------------------------------------------------------------
  -- DUT interfacing
  -----------------------------------------------------------------------------
  signal clk      : std_logic := '0';
  signal i_wreq   : std_logic := '0';
  signal i_waddr  : std_logic_vector(log2c(REGISTER_COUNT)-1 downto 0) := (others => '0');
  signal i_wdata  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal i_rreq   : std_logic := '0';
  signal i_raddr  : std_logic_vector(log2c(REGISTER_COUNT)-1 downto 0) := (others => '0');
  signal o_rdata  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal o_rvalid : std_logic := '0';
  signal o_regmap : aslv(0 to REGISTER_COUNT-1)(DATA_WIDTH-1 downto 0) := (others => (others => '0'));
  signal regmap_internal : aslv(0 to REGISTER_COUNT-1)(DATA_WIDTH-1 downto 0) := (others => (others => '0'));

  -----------------------------------------------------------------------------
  -- Clock-related
  -----------------------------------------------------------------------------
  constant CLK_PERIOD   : time := 10 ns;

begin
  -----------------------------------------------------------------------------
  -- DUT instantation
  -----------------------------------------------------------------------------
  DUT: entity rtu.register_map
  generic map(
    REGISTER_COUNT => REGISTER_COUNT,
    ADDR_WIDTH     => log2c(REGISTER_COUNT),
    DATA_WIDTH     => DATA_WIDTH)
  port map(
    clk      => clk,
    i_wreq   => i_wreq,
    i_waddr  => i_waddr,
    i_wdata  => i_wdata,
    i_rreq   => i_rreq,
    i_raddr  => i_raddr,
    o_rdata  => o_rdata,
    o_rvalid => o_rvalid,
    o_regmap => o_regmap);

  -----------------------------------------------------------------------------
  -- Clock generator
  -----------------------------------------------------------------------------
  clk  <= not clk after CLK_PERIOD/2;

  -----------------------------------------------------------------------------
  -- Interface to the internal regmap signal
  -----------------------------------------------------------------------------
  regmap_internal <= << signal .tb.DUT.regmap_reg : aslv >>;

  -----------------------------------------------------------------------------
  -- Test sequencer
  -----------------------------------------------------------------------------
  process
    variable tmp : integer;

    procedure regmap_write(addr : integer; data : integer) is
    begin
      wait until rising_edge(clk);
      i_wreq  <= '1';
      i_waddr <= slv(to_unsigned(addr, i_waddr'length));
      i_wdata <= slv(to_unsigned(data, i_wdata'length));
      wait until rising_edge(clk);
      i_wreq  <= '0';
      wait until rising_edge(clk);
    end procedure;

    procedure regmap_read(addr : integer; data : out integer) is
    begin
      wait until rising_edge(clk);
      i_rreq  <= '1';
      i_raddr <= slv(to_unsigned(addr, i_waddr'length));
      wait until o_rvalid = '1' for 10*CLK_PERIOD;
      check(o_rvalid = '1', "No read valid signal detected");
      data := to_integer(unsigned(o_rdata));
      wait until rising_edge(clk);
      wait until rising_edge(clk);
    end procedure;

  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop

      if run("write") then
        for i in 0 to REGISTER_COUNT-1 loop
          regmap_write(i, REGISTER_COUNT-i);
        end loop;

        for i in 0 to REGISTER_COUNT-1 loop
          check(unsigned(regmap_internal(i)) = REGISTER_COUNT-i, 
            "Register " & integer'image(i)
             & "; EXPECTED: " & integer'image(REGISTER_COUNT-i)
             & "; GOT: " & integer'image(to_integer(unsigned(regmap_internal(i)))));
        end loop;


      elsif run("write_read") then
        for i in 0 to REGISTER_COUNT-1 loop
          regmap_write(i, REGISTER_COUNT-i);
        end loop;

        for i in 0 to REGISTER_COUNT-1 loop
          regmap_read(i, tmp);
          check(REGISTER_COUNT-i = tmp,
            "Register " & integer'image(i)
             & "; EXPECTED: " & integer'image(REGISTER_COUNT-i)
             & "; GOT: " & integer'image(tmp));
        end loop;


      elsif run("write_regmap") then
        for i in 0 to REGISTER_COUNT-1 loop
          regmap_write(i, REGISTER_COUNT-i);
        end loop;

        for i in 0 to REGISTER_COUNT-1 loop
          check(REGISTER_COUNT-i = unsigned(o_regmap(i)),
            "Register " & integer'image(i)
             & "; EXPECTED: " & integer'image(REGISTER_COUNT-i)
             & "; GOT: " & integer'image(to_integer(unsigned(o_regmap(i)))));
        end loop;
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

end architecture;
