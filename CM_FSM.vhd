library ieee;
use ieee.std_logic_1164.all;
-------------------------------------
entity CM_FSM is
	port(
		i_Clk		:	in		std_logic;
		i_Reset		:	in		std_logic;
		i_Enable	:	in		std_logic;
		i_Psdone	:	in		std_logic;
		o_Psen		:	out		std_logic;
		o_Done		:	out		std_logic
	);
end entity;
-------------------------------------
architecture behavioral of CM_FSM is

	--------------- Types ---------------------
	type t_my_state is (s_Shift, s_Wait);
	
	--------------- Internal Regs ---------------------
	signal	r_State		:	t_my_state	:= s_Shift;
	signal	r_Enable	:	std_logic	:= '0';
	signal	r_Enable_2	:	std_logic	:= '0';
	signal	r_Psdone	:	std_logic	:= '0';
	signal	r_Psen		:	std_logic	:= '0';
	signal	r_Done		:	std_logic	:= '0';

begin

	CM_FSM	:	process(i_Clk, i_Reset)
	
	begin
	
		if (i_Reset = '1') then
			r_State			<=	s_Shift;
		
		elsif (i_Clk'event and i_Clk = '1') then
		
			r_Enable	<=	i_Enable;
			r_Enable_2	<=	r_Enable;
			r_Psdone	<=	i_Psdone;
			----------- Default --------------
			r_Psen	<=	'0';
			
			case r_State is
			
			when	s_Shift		=>
									if (r_Enable_2 = '0' and r_Enable = '1') then
										r_Psen	<=	'1';
										r_Done	<=	'0';
										r_State	<=	s_Wait;
									end if;
			when	s_Wait	=>
									if (r_Psdone = '1') then
										r_Done	<=	'1';
										r_State	<=	s_Shift;
									end if;							
			when	others		=>
									null;
			end case;
		
		end if;
	
	end process;

	o_Psen	<=	r_Psen;
	o_Done	<=	r_Done;

end architecture;