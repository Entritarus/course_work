library ieee;
library edi;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use edi.data_types.all;
use edi.functions.all;

entity clock_divider_pulse is
  generic(
    DIVISION_RATIO : natural := 20
  );
  port(
    rst     : in  sl;
    i_clk  : in  sl;
    o_en : out sl
  );
end entity;

architecture RTL of clock_divider_pulse is
  signal ctr_reg, ctr_next : unsigned(log2c(DIVISION_RATIO)-1 downto 0) := (others => '0');
  signal ctr_is_full : boolean;
begin

  -- reg-state logic
  process (i_clk) is
  begin
    if rst = '1' then
      ctr_reg <= (others => '0');
    else
      if rising_edge(i_clk) then
        ctr_reg <= ctr_next;
      else
        ctr_reg <= ctr_reg;
      end if;
    end if;
  end process;

  -- next-state logic
  ctr_is_full <= ctr_reg = DIVISION_RATIO-1;
  
  ctr_next <= ctr_reg + 1 when not ctr_is_full else
              (others => '0');
  -- outputs
  o_en <= '1' when ctr_is_full else
          '0';

end architecture;
