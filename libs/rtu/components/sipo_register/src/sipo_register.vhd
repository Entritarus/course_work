library ieee;
library rtu;
use ieee.std_logic_1164.all;


entity sipo_register is
  port(
    clk      : in  std_logic;       --! clock
    rst      : in  std_logic;       --! asynchronous reset
    i_enable : in  std_logic;       --! enable shift register
    i_data   : in  std_logic;       --! input (serial) data, single bit
    i_srst   : in  std_logic;
    o_data   : out std_logic_vector --! output (parallel) data
  );
end entity;


architecture RTL of sipo_register is
  constant DATA_WIDTH : natural := o_data'length;
  signal data_reg, data_next : std_logic_vector(DATA_WIDTH-1 downto 0) := (others =>'0');
begin

  -- reg-state logic
  -- <TODO: your code goes here>
	process (clk)
	begin
		if (rst = '1') then
			data_reg <= (others => '0');
		else
			if rising_edge(clk) then
				if i_enable = '1' then
					data_reg <= data_next;
				else
					data_reg <= data_reg;
          if i_srst = '1' then
            data_reg <= (others => '0');
          end if;
				end if;
			end if;
		end if;
	end process;
  -- next-state logic
  -- <TODO: your code goes here>
	data_next(DATA_WIDTH-1 downto 1) <= data_reg(DATA_WIDTH-2 downto 0);
	data_next(0) <= i_data;
  -- outputs
  -- <TODO: your code goes here>
  o_data <= data_reg;
end architecture;
