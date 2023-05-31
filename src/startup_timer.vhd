library ieee;
library edi;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use edi.functions.all;
use edi.data_types.all;

entity startup_timer is
  generic (
    COUNTER_MAX : natural := 25000000
  );
  port (
    clk : in sl;
    rst : in sl;
    
    i_start : in sl;
    o_out : out sl
  );
end entity;

architecture RTL of startup_timer is
  signal ctr_reg, ctr_next : unsigned(log2c(COUNTER_MAX)-1 downto 0) := (others => '0');
  signal ctr_is_full : boolean;
  
  type state_t is (s_idle, s_active, s_stop);
  signal state_reg, state_next : state_t := s_idle;
begin
  process (clk) is
  begin
    if rst = '1' then
      state_reg <= s_idle;
      ctr_reg <= (others => '0');
    else 
      if rising_edge(clk) then
        ctr_reg <= ctr_next;
        state_reg <= state_next;
      else
        ctr_reg <= ctr_reg;
        state_reg <= state_reg;
      end if;
    end if;
  end process;
  
  process (clk) is 
    variable ctr_is_full : boolean;
  begin
    state_next <= state_reg;
    ctr_next <= ctr_reg;
    o_out <= '0';
    case state_reg is
      when s_idle =>
        if i_start = '1' then
          state_next <= s_active;
        end if;
      when s_active =>
        ctr_is_full := ctr_reg = COUNTER_MAX-1;
        if ctr_is_full then
          ctr_next <= (others => '0');
          state_next <= s_stop;
        else
          ctr_next <= ctr_reg + 1;
        end if;
      when s_stop =>
        o_out <= '1';
    end case;
  end process;
  
  
end architecture;