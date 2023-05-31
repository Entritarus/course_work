library ieee;
use ieee.std_logic_1164.all;

entity edge_detector is
  port(
    clk        : in  std_logic;
    i_signal   : in  std_logic;
    o_rising   : out std_logic;
    o_falling  : out std_logic
  );
end entity;

architecture RTL of edge_detector is
	signal compare_reg, compare_next : std_logic := '0'; -- input FF to compare current and previous vals
	signal re_reg, re_next : std_logic := '0'; -- rising edge
	signal fe_reg, fe_next : std_logic := '0'; -- falling edge
begin

  -- reg-state logic
  -- <your code goes here>
	process(clk)
	begin
		if rising_edge(clk) then
			compare_reg <= compare_next;
			re_reg <= re_next;
			fe_reg <= fe_next;
		end if;
	end process;
  -- next-state logic
  -- <your code goes here>
	compare_next <= i_signal;
	fe_next <= not compare_next and compare_reg;
	re_next <= not compare_reg and compare_next;
  -- outputs
  -- <your code goes here>
	o_falling <= fe_reg;
	o_rising <= re_reg;
end architecture;
