library ieee;
library edi;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use edi.data_types.all;
use edi.functions.all;

entity clock_divider_duty is
  generic(
    DIVISION_RATIO : natural;
    DUTY : natural := 50
  );
  port(
    rst     : in  sl;
    clk_in   : in  sl;
    clk_out  : out sl
  );
end entity;

architecture RTL of clock_divider_duty is
  signal ctr_reg, ctr_next : unsigned(log2c(DIVISION_RATIO)-1 downto 0) := (others => '0');
  signal clk_div : sl := '0';
begin

  -- reg-state logic
  process (clk_in) is
  begin
    if rst = '1' then
      ctr_reg <= (others => '0');
    else
      if rising_edge(clk_in) then
        ctr_reg <= ctr_next;
      else
        ctr_reg <= ctr_reg;
      end if;
    end if;
  end process;

  -- next-state logic
  ctr_next <= ctr_reg + 1 when ctr_reg /= DIVISION_RATIO-1 else
              (others => '0');
  clk_div <= '1' when ctr_reg < DIVISION_RATIO*DUTY/100 else
             '0';

  -- outputs
  clk_out <= clk_div;

end architecture;
