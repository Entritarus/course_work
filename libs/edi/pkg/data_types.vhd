-- synopsis directives:
-- synthesis VHDL_INPUT_VERSION VHDL_2008
-- synthesis LIBRARY edi

library ieee;
use ieee.std_logic_1164.all;

package data_types is
    --! @defgroup types_slv
    --! @brief Deriver types based on std_logic_vector base type
    --! @{
	type array_of_std_logic_vector    is array(integer range <>) of std_logic_vector;
	type array_of_std_logic_vector_2D is array(integer range <>) of array_of_std_logic_vector;
	type array_of_std_logic_vector_3D is array(integer range <>) of array_of_std_logic_vector_2D;
    --! @}

    --! @defgroup types_real
    --! @brief Deriver types based on real base type
    --! @{
	type array_of_real    is array(integer range <>) of real;
	type array_of_real_2D is array(integer range <>) of array_of_real;
	type array_of_real_3D is array(integer range <>) of array_of_real_2D;
    --! @}
	
    --! @defgroup types_int
    --! @brief Deriver types based on integer base type
    --! @{
	type array_of_integers    is array(integer range <>) of integer;
	type array_of_integers_2D is array(integer range <>) of array_of_integers;
	type array_of_integers_3D is array(integer range <>) of array_of_integers_2D;
    --! @}

	-- shorthand - standard_logic_vector
	alias sl       is std_logic;
	alias slv      is std_logic_vector;
	alias aslv     is array_of_std_logic_vector;
	alias aslv_2D  is array_of_std_logic_vector_2D;
	alias aslv_3D  is array_of_std_logic_vector_3D;
	alias a_slv    is array_of_std_logic_vector;
	alias a_slv_2D is array_of_std_logic_vector_2D;
	alias a_slv_3D is array_of_std_logic_vector_3D;

    -- shorthand - real
	alias areal    is array_of_real;
	alias areal_2D is array_of_real_2D;
	alias areal_3D is array_of_real_3D;
	alias a_real    is array_of_real;
	alias a_real_2D is array_of_real_2D;
	alias a_real_3D is array_of_real_3D;

    -- shorthand - integer
	alias aint     is array_of_integers;
	alias aint_2D  is array_of_integers_2D;
	alias aint_3D  is array_of_integers_3D;
	alias a_int     is array_of_integers;
	alias a_int_2D  is array_of_integers_2D;
	alias a_int_3D  is array_of_integers_3D;

end package;


package body data_types is
end package body;
