library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
---------------------------------
package my_package is

	type my_array3 is array (integer range <>) of std_logic_vector;
	
   function get_log2 (input  :   integer) return integer; 
   function or_reduce( V: std_logic_vector )
                return std_ulogic;
   function xor_reduce( V: std_logic_vector )
                return std_ulogic;	
    function cal_segment(n_full	:	integer;
    					n_partial	:	integer) return integer;	
end package;
---------------------------------
package body my_package is
	
	function get_log2 (input    :   integer) return integer is
	begin
	   return integer(ceil(log2(real(input))));
	end get_log2;
	
	function or_reduce( V: std_logic_vector )
                return std_ulogic is
      variable result: std_ulogic;
    begin
      for i in V'range loop
        if i = V'left then
          result := V(i);
        else
          result := result OR V(i);
        end if;
        exit when result = '1';
      end loop;
      return result;
    end or_reduce;
		
	function xor_reduce( V: std_logic_vector )
                return std_ulogic is
      variable result: std_ulogic;
    begin
      for i in V'range loop
        if i = V'left then
          result := V(i);
        else
          result := result xor V(i);
        end if;
      end loop;
      return result;
    end xor_reduce;

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
