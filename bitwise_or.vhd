library ieee;
use ieee.std_logic_1164.all;
----------------------------------
entity bitwise_or is
	generic(g_Width	:	integer);
	port(
		i_Input_Sig	:	in		std_logic_vector(g_Width - 1 downto 0);
		o_Result	:	out		std_logic
	);
end entity;
----------------------------------
architecture behavioral of bitwise_or is

begin

--	process(i_Input_Sig)
--		variable	v_Result	:	std_logic;
--	begin
	
--		for i in 0 to (g_Width - 1) loop
--			if (i = 0) then
--				v_Result	:=	i_Input_Sig(i);
--			else
--				v_Result	:=	v_Result or i_Input_Sig(i);
--			end if;
--		end loop;
		
--		o_Result	<=	v_Result;
	
--	end process;

	o_Result	<=	or(i_Input_Sig);

end architecture;