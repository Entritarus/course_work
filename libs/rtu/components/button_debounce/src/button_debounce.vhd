library ieee;
use ieee.std_logic_1164.all;

entity button_debounce is
  port(
    clk      : in  std_logic;
    i_en     : in  std_logic;
    i_signal : in  std_logic;
    o_signal : out std_logic
  );
end entity;

architecture RTL of button_debounce is
  constant CASCADE_COUNT : natural := 3;
  signal ff_reg, ff_next : std_logic_vector(CASCADE_COUNT-1 downto 0) := (others => '0');
begin
  -- reg-state logic
  -- <your code goes here>
	process(clk)
	begin
		if rising_edge(clk) then
			if i_en = '1' then
				ff_reg <= ff_next;
			else
				ff_reg <= ff_reg;
			end if;
		end if;
	end process;
  -- next-state logic
  -- <your code goes here>
	ff_next <= ff_reg(CASCADE_COUNT-2 downto 0) & i_signal;
  -- outputs
  -- <your code goes here>
	process(ff_reg)
	variable and_result : std_logic;
	begin
		and_result := ff_reg(0);
		for i in 1 to CASCADE_COUNT-1 loop
			and_result := and_result and ff_reg(i);
		end loop;
		o_signal <= and_result;
	end process; 
end architecture;
