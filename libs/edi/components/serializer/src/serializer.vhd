-------------------------------------------------------------------------------
--! @file serializer.vhd
--! @author Rihards Novickis
-------------------------------------------------------------------------------
-- synthesis VHDL_INPUT_VERSION VHDL_2008
-- synthesis LIBRARY edi

library ieee;
library edi;
use ieee.std_logic_1164.all;
use edi.data_types.all;
use edi.data_types.all;

--! @brief Basically a shift register with a preset, thus 
--!        std_logic_vector is bit-serialized
--!
--! @param DATA_WIDTH number of bits in the shift register
entity serializer is
  generic(
    DATA_WIDTH : natural := 4
  );
  port(
    clk      : in sl;
    rst      : in sl; --! asynchronous reset
    i_load   : in  sl; --! load shift register with data
    i_enable : in  sl; --! enable shift register
    i_data   : in  slv(DATA_WIDTH-1 downto 0); --! data to load
    o_data   : out sl  --! output (serialized) bit 
  );
end entity;

architecture RTL of serializer is
  signal data_reg, data_next : slv(DATA_WIDTH-1 downto 0) := (others =>'0');
begin
  -- reg-state logic
  process(rst, clk)
  begin
    if rst = '1' then
      data_reg <= (others => '0');
    elsif rising_edge (clk) then
      if i_load = '1' then
        data_reg <= i_data;
      elsif i_enable = '1' then
        data_reg <= data_next;
      end if;
    end if;
  end process;

  -- next-state logic
  process(all)
  begin
    for i in 1 to data_next'high loop
      data_next(i) <= data_reg(i-1);
    end loop;
  end process;

  -- outputs
  o_data <= data_reg(data_reg'high);
end architecture;
