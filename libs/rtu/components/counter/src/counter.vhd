library ieee;
library rtu;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use rtu.functions.all;

entity counter is
  generic(
    COUNTER_MAX_VALUE : natural := 800
  );
  port(
    clk       : in std_logic;
    en        : in std_logic;
    o_counter : out unsigned(log2c(COUNTER_MAX_VALUE+1)-1 downto 0)
  );
end entity;

architecture RTL of counter is
  -- <your code goes here>
  signal ctr_next : unsigned(o_counter'high downto 0);
  signal ctr_reg : unsigned(o_counter'high downto 0) := (others => '0');
  signal ctr_is_full : boolean;
	
begin
  -- reg-state logic
  -- <your code goes here>
  process (clk)
  begin
    if rising_edge(clk) then
	  if en = '1' then
	    ctr_reg <= ctr_next;
	  else
	    ctr_reg <= ctr_reg;
	  end if;
	end if;
  end process;
  
  -- next-state logic
  -- <your code goes here>
  
  ctr_next <= (others => '0') when ctr_is_full else
               ctr_reg + 1;
  ctr_is_full <= ctr_reg = COUNTER_MAX_VALUE;
  
  -- output
  -- <your code goes here>
  
  o_counter <= ctr_reg;

end architecture;
