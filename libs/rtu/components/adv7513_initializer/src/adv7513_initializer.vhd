library ieee;
library edi;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use edi.functions.all;

entity adv7513_initializer is
  port(
    -- input to the PLL
    clk : in  std_logic; -- 400 KHz clock for 100 KHz I2C
    rst : in  std_logic; -- push button used as a reset

    -- reconfigure request
    reconfigure : in std_logic;

    -- physical interface with I2C
    o_sda_oe : out std_logic;
    i_sda    : in  std_logic;
    o_sda    : out std_logic;
    o_scl_oe : out std_logic;
    i_scl    : in  std_logic;
    o_scl    : out std_logic
  );
end entity;

architecture RTL of adv7513_initializer is
  constant SLAVE_ADDR_WIDTH : natural := 7;
  constant DATA_WIDTH       : natural := 8;
  constant DEVICE_ADDRESS : std_logic_vector(6 downto 0) := "0111001"; --0x72

  type aslv is array(integer range <>) of std_logic_vector;
  constant INIT_DATA : aslv(0 to 30)(15 downto 0) := ( 
    -- register / data
   	0	=> x"9803",  --Must be set to 0x03 for proper operation
	1	=> x"0100",  --Set 'N' value at 6144
	2	=> x"0218",  --Set 'N' value at 6144
	3	=> x"0300",  --Set 'N' value at 6144
	4	=> x"1470",  --Set Ch count in the channel status to 8.
	5	=> x"1520",  --Input 444 (RGB or YCrCb) with Separate Syncs, 48kHz fs
	6	=> x"1630",  --Output format 444, 24-bit input
	7	=> x"1846",  --Disable CSC
	8	=> x"4080",  --General control packet enable
	9	=> x"4110",  --Power down control
	10	=> x"49A8",  --Set dither mode - 12-to-10 bit
	11	=> x"5510",  --Set RGB in AVI infoframe
	12	=> x"5608",  --Set active format aspect
	13	=> x"96F6",  --Set interrup
	14	=> x"7307",  --Info frame Ch count to 8
	15	=> x"761f",  --Set speaker allocation for 8 channels
	16	=> x"9803",  --Must be set to 0x03 for proper operation
	17	=> x"9902",  --Must be set to Default Value
	18	=> x"9ae0",  --Must be set to 0b1110000
	19	=> x"9c30",  --PLL filter R1 value
	20	=> x"9d61",  --Set clock divide
	21	=> x"a2a4",  --Must be set to 0xA4 for proper operation
	22	=> x"a3a4",  --Must be set to 0xA4 for proper operation
	23	=> x"a504",  --Must be set to Default Value
	24	=> x"ab40",  --Must be set to Default Value
	25	=> x"af16",  --Select HDMI mode
	26	=> x"ba60",  --No clock delay
	27	=> x"d1ff",  --Must be set to Default Value
	28	=> x"de10",  --Must be set to Default for proper operation
	29	=> x"e460",  --Must be set to Default Value
	30	=> x"fa7d"   --Nbr of times to look for good phase 
   );

  signal device_not_initialized : boolean;
  signal done_reg, done_next    : std_logic := '0';
  signal start_reg, start_next  : std_logic := '0';
  signal counter_reg, counter_next : unsigned(log2c(INIT_DATA'length)-1 downto 0) 
    := (others => '0');

  -- control interface
  signal i2c_start : std_logic;
  signal i2c_done, i2c_ready, i2c_error : std_logic;
  -- data-flow interface
  signal i2c_doRead    : std_logic;
  signal i2c_saddr     : std_logic_vector(SLAVE_ADDR_WIDTH-1 downto 0);
  signal i2c_baddr     : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal i2c_writedata : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

  -- instantiate I2C mater 
  I2C_MASTER : entity edi.i2c_master
  generic map(
    SLAVE_ADDR_WIDTH => 7,
    DATA_WIDTH       => 8)
  port map(
    clk => clk,
    rst => rst,
    -- control interface
    i_start     => i2c_start,
    o_done      => i2c_done,
    o_ready     => i2c_ready,
    o_error     => i2c_error,
    -- data-flow interface
    i_doRead    => i2c_doRead,
    i_saddr     => i2c_saddr,
    i_baddr     => i2c_baddr,
    i_data      => i2c_writedata,
    -- physical interface to tristate buffer ctl
    o_sda_oe => o_sda_oe,
    i_sda    => i_sda,
    o_sda    => o_sda,
    o_scl_oe => o_scl_oe,
    i_scl    => i_scl,
    o_scl    => o_scl);

  -- reg-state logic
  process(rst, clk)
  begin
    if rst = '1' then
      counter_reg <= (others => '0');
      done_reg    <= '0';
      start_reg   <= '0';
    else
      if rising_edge(clk) then
        counter_reg <= counter_next;
        done_reg    <= done_next;
        start_reg   <= start_next;
      end if;
    end if;
  end process;

  -- utility signals
  device_not_initialized <= true when counter_reg <= INIT_DATA'length else
                            false;

  -- next-state logic - counter
  process(all)
  begin
    counter_next <= counter_reg;
    if device_not_initialized and done_reg = '1' and i2c_error = '0' then
      counter_next <= counter_reg + 1;
    elsif (not device_not_initialized) and reconfigure = '1' then
      counter_next <= (others => '0');
    else
      counter_next <= counter_reg;
    end if;
  end process;

  -- generate done and start event signals
  done_next  <= '1' when i2c_done  = '1' and done_reg /= '1' else
                '0';
  start_next <= '1' when i2c_ready = '1' and start_reg /= '1' and device_not_initialized else 
                '0';

  -- next-state logic
  i2c_start     <= start_reg;
  i2c_doRead    <= '0';
  i2c_saddr     <= DEVICE_ADDRESS; 
  i2c_baddr     <= INIT_DATA(to_integer(counter_reg))(15 downto 8);
  i2c_writedata <= INIT_DATA(to_integer(counter_reg))(7  downto 0);

end architecture;
