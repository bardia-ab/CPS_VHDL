library ieee;
use ieee.std_logic_1164.all;
---------------------------------
entity Edge_Detector is
	generic(
		g_Rising_Edge	:	std_logic
	);
	port(
		i_Clk		:	in		std_logic;
		i_Reset		:	in		std_logic;
		i_Sig		:	in		std_logic;
		O_Result	:	out		std_logic
	);
end entity;
---------------------------------
architecture behavioral of Edge_Detector is 

	signal	r_Sig		:	std_logic;
	signal	r_Result	:	std_logic;
	signal	w_Level		:	std_logic;
	signal	w_Level_Prv	:	std_logic;

begin

	process(i_Clk, i_Reset)
	
	begin
	
		if (i_Reset = '1') then
			r_Result	<=	w_Level_Prv;
			
		elsif (i_Clk'event and i_Clk = '1') then
		
			r_Sig		<=	i_Sig;
			r_Result	<=	'0';
			
			if (r_Sig = w_Level_Prv and i_Sig = w_Level) then
				r_Result	<=	'1';
			end if;
		
		end if;
	
	end process;

	w_Level			<=	'1' when g_Rising_Edge = '1' else '0';
	w_Level_Prv		<=	'0' when g_Rising_Edge = '1' else '1';
	o_Result		<=	r_Result;

end architecture;