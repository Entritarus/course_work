library ieee;
library rtu;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;
use rtu.data_types.all;
use rtu.functions.all;

-- in principle this is a SIPO memory
entity sample_memory is
  generic (
    FILTER_ORDER : natural := 50;
    INTEGER_WIDTH : natural := 24;
    FRACTION_WIDTH : natural := 10
  );
  port (
    clk       : in sl;
    rst       : in sl;
    
    -- write port
    i_wreq    : in sl;
    i_wdata   : in sfixed(INTEGER_WIDTH-1 downto -FRACTION_WIDTH);
    
    -- read port
    i_rreq    : in sl;
    i_raddr   : in slv(log2c(FILTER_ORDER)-1 downto 0);
    o_rdata   : out sfixed(INTEGER_WIDTH-1 downto -FRACTION_WIDTH);
    o_rvalid  : out sl
  );
end entity;

architecture RTL of sample_memory is
  
  signal rvalid_reg, rvalid_next : sl := '0';
  signal rdata_reg, rdata_next : sfixed(i_wdata'range);
  
  type sample_memory_t is array (natural range <>) of sfixed(INTEGER_WIDTH-1 downto -FRACTION_WIDTH);
  signal sample_memory_reg, sample_memory_next : sample_memory_t := (others => (others => '0'));
begin
  -- reg-state logic
  process(clk)
    variable i : natural;
  begin
    if (rising_edge(clk)) then
      rvalid_reg <= rvalid_next;
      rdata_reg <= rdata_next;
      if (i_wreq = '1') then
        for i in 0 to FILTER_ORDER-1 loop
          sample_memory_reg(i) <= sample_memory_next(i);
        end loop;
      end if;
    end if;
  end process;
  
  -- next-state logic
  
  sample_memory_next(FILTER_ORDER-1 downto 1) <= sample_memory_reg(FILTER_ORDER-2 downto 0);
  sample_memory_next(0) <= i_wdata;
  
  rdata_next <= sample_memory_reg(to_integer(unsigned(i_raddr)));
  
  rvalid_next <= i_rreq;
  -- outputs 
  o_rdata <= rdata_reg;
  o_rvalid <= rvalid_reg;
end architecture;