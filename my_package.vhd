library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
---------------------------------
package my_package is

	type my_array is array (integer range <>) of std_logic_vector;
	
   function get_log2 (input  :   integer) return integer; 
   function cal_segment(n_full	:	integer;
    					n_partial	:	integer) return integer;	
end package;
---------------------------------
package body my_package is
	
	function get_log2 (input    :   integer) return integer is
	begin
		if input > 1 then
	   		return integer(floor(log2(real(input - 1))));
		else
			return 0;
		end if;		
	end get_log2;
		
	function cal_segment(n_full	:	integer;
    					n_partial	:	integer) return integer is
	begin
	
		if n_partial > 0 then
			return n_full + 1;
		else
			return n_full;
		end if;
	
	end function;
					
end package body;
