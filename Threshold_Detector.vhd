library ieee;
use ieee.std_logic_1164.all;
---------------------------------
entity Threshold_Detector is
	generic(
		g_Rising_Edge	:	std_logic
	);
	port(
		i_Clk		:	in		std_logic;
		i_Enable	:	in		std_logic;
		i_Reset		:	in		std_logic;
		i_Sig		:	in		std_logic;
		o_Capture	:	out		std_logic
	);
end entity;
---------------------------------
architecture behavioral of Threshold_Detector is 

	type my_type is (s0, s1, s2, s3);
	
	signal	r_State		:	my_type	:= s0;
	signal	r_Sig		:	std_logic;
	signal	r_Enable	:	std_logic;
	signal	r_Result	:	std_logic;
	signal	w_Level		:	std_logic;
	signal	w_Level_Prv	:	std_logic;

begin
	
	process(i_Clk, i_Reset)
	begin
		if (i_Reset = '1') then
			r_Result	<=	w_Level_Prv;
			r_State		<=	s0;
			
		elsif (i_Clk'event and i_Clk = '1') then
			r_Enable	<=	i_Enable;
			
			case r_State is
			
			when s0		=>
				if (r_Enable = '0' and i_Enable = '1') then	--Triggers on the Rising Edge
					r_Sig	<=	i_Sig;
										
					if (r_Sig = w_Level_Prv and i_Sig = w_Level) then
						r_Result	<=	'1';
						r_State		<=	s1;
					end if;
				end if;				
			when s1		=>
				if (r_Enable = '1' and i_Enable = '0') then
					r_Result	<=	'0';
					r_State		<=	s2;
				end if;
			when s2	=>
				null;
			when others	=>
				r_State	<=	s2;
			end case;
		end if;
	end process;

	w_Level			<=	'1' when g_Rising_Edge = '1' else '0';
	w_Level_Prv		<=	'0' when g_Rising_Edge = '1' else '1';
	o_Capture		<=	r_Result;

end architecture;