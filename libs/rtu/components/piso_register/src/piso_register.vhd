library ieee;
library rtu;
use ieee.std_logic_1164.all;

entity piso_register is
  port(
    clk      : in  std_logic;        --! clock signal
    rst      : in  std_logic;        --! asynchronous reset
    i_load   : in  std_logic;        --! load shift register with data
    i_enable : in  std_logic;        --! enable shift register
    i_data   : in  std_logic_vector; --! input data (parallel)
    i_srst   : in  std_logic;
    o_data   : out std_logic         --! output data (serialized) bit 
  );
end entity;

architecture RTL of piso_register is
  -- retrieve input data width using attributes (modern style)
  constant DATA_WIDTH : natural := i_data'length;

  signal data_reg, data_next : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
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
				end if;
        if i_srst = '1' then
          data_reg <= (others => '0');
        end if;
			end if;
		end if;
	end process;
  -- next-state logic
  -- <TODO: your code goes here>
	data_next(DATA_WIDTH-1 downto 1) <= i_data(DATA_WIDTH-1 downto 1) when i_load = '1' else
										data_reg(DATA_WIDTH-2 downto 0);
	data_next(0) <= i_data(0);
  -- outputs
  -- <TODO: your code goes here>
	o_data <= data_reg(DATA_WIDTH-1);
end architecture;
