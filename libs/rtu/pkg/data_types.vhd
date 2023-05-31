--------------------------------------------------------------------------------
--! @file data_types.vhd
--------------------------------------------------------------------------------

-- libraries and packages
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- declarations of the package (types, prototypes of functions and procedures)
package data_types is
  -- convinient custom data types and their aliases
  type array_of_std_logic_vector  is array(integer range <>) of std_logic_vector;
  alias sl   is std_logic;
  alias slv  is std_logic_vector;
  alias aslv is array_of_std_logic_vector;

  -- for Lab2, VGA controller pattern selection
  type pattern_t is (PATTERN_UNIFORM_COLOR, PATTERN_GENERATED, PATTERN_MEMORY);

  -- for Lab2, VGA configuration
  type vga_config_t is record
    HOR_DISPLAY     : natural;
    HOR_FRONT_PORCH : natural;
    HOR_SYNC        : natural;
    HOR_BACK_PORCH  : natural;
    VER_DISPLAY     : natural;
    VER_FRONT_PORCH : natural;
    VER_SYNC        : natural;
    VER_BACK_PORCH  : natural;
  end record;

  -- for Lab4, SPI controller's states
  type state_ll_t is (s_idle, s_start, s_clk_low0, s_clk_low1, s_clk_high0, s_clk_high1, s_stop);
  type state_hl_t is (s_idle, s_command, s_write, s_read);
end package;

-- implementations of the package (functions, procedures)
package body data_types is
end package body;
