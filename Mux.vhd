library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_package.all;
-------------------------------
entity Mux is
	port(
		i_Input		:	in		my_array;
		i_SLCT		:	in		std_logic_vector;
		o_Output	:	out		std_logic_vector
	);

end entity;
-------------------------------
architecture	behavioral of Mux is

begin

	o_Output	<=	i_Input(to_integer(unsigned(i_SLCT)));

end architecture;