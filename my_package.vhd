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
	function Ascii (SLV8 :STD_LOGIC_VECTOR (7 downto 0)) return CHARACTER;    
	function char2binary (CHAR :CHARACTER) return STD_LOGIC_VECTOR;						
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
	
	function Ascii (SLV8 :STD_LOGIC_VECTOR (7 downto 0)) return CHARACTER is
		constant XMAP :INTEGER :=0;
		variable TEMP :INTEGER :=0;
	begin
		for i in SLV8'range loop
			TEMP:=TEMP*2;
			case SLV8(i) is
			when '0' | 'L' => null;
			when '1' | 'H' => TEMP :=TEMP+1;
			when others => TEMP :=TEMP+XMAP;
			end case;
		end loop;
		return CHARACTER'VAL(TEMP);
	end Ascii;
	
	function char2binary (CHAR :CHARACTER) return STD_LOGIC_VECTOR is
		variable SLV8 :STD_LOGIC_VECTOR (7 downto 0);
		variable TEMP :INTEGER :=CHARACTER'POS(CHAR);
	begin
		for i in SLV8'reverse_range loop
			case TEMP mod 2 is
			when 0 => SLV8(i):='0';
			when 1 => SLV8(i):='1';
			when others => null;
			end case;
			TEMP:=TEMP/2;
		end loop;
		return SLV8;
	end char2binary;
				
end package body;
