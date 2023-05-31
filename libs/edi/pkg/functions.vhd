-- synopsis directives:
-- synthesis VHDL_INPUT_VERSION VHDL_2008
-- synthesis LIBRARY edi

library ieee;
use ieee.std_logic_1164.all;

package functions is
    --! @defgroup Math
    --! @brief Handy mathematical operations, can be used in vector width 
    --!        calculations
    --! @{
    function log2c (input:integer) return integer;
    function log2f (input:integer) return integer;
    function max(a: integer; b: integer) return integer;
    function minimum(a: integer; b: integer) return integer;
    function absolute(input: real) return real;
    --! @}
end package;


package body functions is
    ----------------------------------------------------------------------------
    -- Math
    ----------------------------------------------------------------------------
    function log2c( input:integer ) return integer is
    variable temp,log:integer;
    begin
        temp:=input-1;
        log:=0;
        while (temp > 0) loop
            temp:=temp/2;
            log:=log+1;
        end loop;
        return log;
    end function log2c;

    function log2f( input:integer ) return integer is
    variable temp,log:integer;
    begin
        temp:=input;
        log:=0;
        while (temp > 1) loop
            temp:=temp/2;
            log:=log+1;
        end loop;
        return log;
    end function log2f;

    function max(a:integer; b:integer) return integer is
    begin
        if a > b then return a; else return b; end if;
    end function max;

    function minimum(a: integer; b: integer) return integer is
    begin
        if a < b then return a; else return b; end if;
    end function;

    function absolute(input: real) return real is
    begin
        if( input > 0.0 ) then
            return input;
        end if;
        return -input;
    end function;
end package body;
