library ieee;
library rtu;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.
use rtu.data_types.all;
use rtu.functions.all;


entity register_map is
  generic(
    REGISTER_COUNT : natural := 4;
	ADDR_WIDTH     : natural := 2;
    DATA_WIDTH     : natural := 8
  );
  port(
    clk      : in  std_logic;

    -- write port
    i_wreq   : in  std_logic;
    i_waddr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    i_wdata  : in  std_logic_vector(DATA_WIDTH-1 downto 0);

    -- read port
    i_rreq   : in  std_logic;
    i_raddr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    o_rdata  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    o_rvalid : out std_logic;

    -- register output
    o_regmap : out aslv(0 to REGISTER_COUNT-1)(DATA_WIDTH-1 downto 0)
  );
end entity;


architecture RTL of register_map is

  signal rvalid_reg, rvalid_next : std_logic := '0';
  signal rdata_reg,  rdata_next  : std_logic_vector(o_rdata'range) := (others => '0');
  signal regmap_en               : std_logic_vector(o_regmap'range) := (others => '0');
  signal regmap_reg, regmap_next : aslv(o_regmap'range)(o_regmap(0)'range)
    := (others => (others => '0'));

begin

  -- reg-state logic
  -- <your code goes here>
  process(clk)
  variable i : natural;
  begin
	if (rising_edge(clk)) then
		rvalid_reg <= rvalid_next;
		rdata_reg <= rdata_next;
		for i in 0 to REGISTER_COUNT-1 loop
			if (regmap_en(i) = '1') then
				regmap_reg(i) <= regmap_next(i);
			end if;
		end loop;
	end if;
  end process;
  -- next-state logic
  -- <your code goes here>
  
  -- Input DEMUX
	IN_DEMUX: for i in 0 to REGISTER_COUNT-1 generate
		regmap_en(i) <= i_wreq when to_integer(unsigned(i_waddr)) = i else '0';
	end generate;
	
	-- Output MUX
	rdata_next <= regmap_reg(to_integer(unsigned(i_raddr)));
	
	regmap_next <= (others => i_wdata);
	
	rvalid_next <= i_rreq;
  -- outputs
  -- <your code goes here>
	o_rdata <= rdata_reg;
	o_rvalid <= rvalid_reg;
	o_regmap <= regmap_reg;
end architecture;