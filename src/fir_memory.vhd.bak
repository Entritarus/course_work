library ieee;
library rtu;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.fixed_float_types.all;
use rtu.data_types.all;
use rtu.functions.all;

entity fir_memory is
  generic (
    FILTER_ORDER : natural := 50;
    INTEGER_WIDTH : natural := 24;
    FRACTION_WIDTH : natural := 10
  );
  port (
    clk       : in sl;
    
    -- write port
    i_wreq    : in sl;
    i_waddr   : in slv(log2c(FILTER_ORDER)-1 downto 0);
    i_wdata   : in sfixed(INTEGER_WIDTH-1 downto -FRACTION_WIDTH);
    
    -- read port
    i_rreq    : in sl;
    i_raddr   : in slv(log2c(FILTER_ORDER)-1 downto 0);
    o_rdata   : out sfixed(INTEGER_WIDTH-1 downto -FRACTION_WIDTH);
    o_rvalid  : out sl
  );
end entity;

architecture RTL of fir_memory is
  
  signal rvalid_reg, rvalid_next : sl := '0';
  signal rdata_reg, rdata_next : sfixed(i_wdata'range);
  signal fir_memory_en : slv(FILTER_ORDER-1 downto 0);
  
  type fir_memory_t is array (natural range <>) of sfixed(INTEGER_WIDTH-1 downto -FRACTION_WIDTH);
  signal fir_memory_reg, fir_memory_next : fir_memory_t := (others => (others => '0'));
begin
  -- reg-state logic
  process(clk)
    variable i : natural;
  begin
    if (rising_edge(clk)) then
      rvalid_reg <= rvalid_next;
      rdata_reg <= rdata_next;
      for i in 0 to FILTER_ORDER-1 loop
        if (fir_memory_en(i) = '1') then
          fir_memory_reg(i) <= fir_memory_next(i);
        end if;
      end loop;
    end if;
  end process;
  
  -- next-state logic
  IN_DEMUX: for i in 0 to REGISTER_COUNT-1 generate
		fir_memory_en(i) <= i_wreq when to_integer(unsigned(i_waddr)) = i else '0';
	end generate;
  
  rdata_next <= fir_memory_reg(to_integer(unsigned(i_raddr)));
	
	fir_memory_next <= (others => i_wdata);
	
	rvalid_next <= i_rreq;
  
  -- outputs 
  o_rdata <= rdata_reg;
  o_rvalid <= rvalid_reg;
end architecture;