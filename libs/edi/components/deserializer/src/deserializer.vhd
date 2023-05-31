-------------------------------------------------------------------------------
--! @file deserializer.vhd
--! @author Rihards Novickis
-------------------------------------------------------------------------------
-- synthesis VHDL_INPUT_VERSION VHDL_2008
-- synthesis LIBRARY edi

library ieee;
library edi;
use ieee.std_logic_1164.all;
use edi.data_types.all;
use edi.data_types.all;

--! @brief Basically a shift register with a bit input and with a 
--!        parallel access to std_logic_vector
--!
--! @param DATA_WIDTH number of bits in the shift register
entity deserializer is
  generic(
    DATA_WIDTH : natural := 4
  );
  port(
    clk      : in  sl;
    rst      : in  sl; --! asynchronous reset
    i_enable : in  sl; --! enable shift register
    i_data   : in  sl; --! input (serial) bit 
    o_data   : out slv(DATA_WIDTH-1 downto 0) --! parallel data
  );
end entity;

architecture RTL of deserializer is
  signal data_reg, data_next : slv(DATA_WIDTH-1 downto 0) := (others =>'0');
begin
  -- reg-state logic
  process(rst, clk)
  begin
    if rst = '1' then
      data_reg <= (others => '0');
    elsif rising_edge(clk) and i_enable = '1' then
      data_reg <= data_next;
    end if;
  end process;

  -- next-state logic
  process(all)
  begin
    data_next(0) <= i_data;
    for i in 1 to data_next'high loop
      data_next(i) <= data_reg(i-1);
    end loop;
  end process;

  -- outputs
  o_data <= data_reg;
end architecture;
