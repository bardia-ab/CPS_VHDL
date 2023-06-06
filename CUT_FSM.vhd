library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
---------------------------------------
entity CUT_FSM is
	generic(
		g_Counter_Width	:	integer
	);
	port(
		i_Clk		:	in		std_logic;
		i_Start		:	in		std_logic;
		i_Locked	:	in		std_logic;
		i_Enable	:	in		std_logic;
		o_CE_CUT	:	out		std_logic;
		o_CLR_Cntr	:	out		std_logic;
		o_Done		:	out		std_logic
	);
end entity;
---------------------------------------
architecture behavioral of CUT_FSM is

	--------------- Types ---------------------
	type t_my_state is (s_Idle, s_Propagate, s_Sample, s_Wait);
	
	--------------- Constants ---------------------	
	constant c_Num_Samples	:	integer	:= 2 ** (g_Counter_Width);

	--------------- Counters ---------------------
	signal	r_Sample_Cntr	:	unsigned(g_Counter_Width - 1 downto 0)	:= (others => '0');

	--------------- Internal Regs ---------------------
	signal	r_State			:	t_my_state	:= s_Idle;
	signal	r_Start			:	std_logic;
	signal	r_Locked		:	std_logic;
	signal	r_Enable		:	std_logic;
	signal	r_Enable_2		:	std_logic	:= '0';
	signal	r_CE_CUT		:	std_logic	:= '0';
	signal	r_CLR_Cntr		:	std_logic	:= '0';
	signal	r_Done			:	std_logic	:= '0';

begin
	
	CUT_Control	:	process(i_Clk)
	
	begin
	
		if (i_Clk'event and i_Clk = '1') then
		
			r_Start		<=	i_Start;		
			r_Locked	<=	i_Locked;	
			r_Enable	<=	i_Enable;
			r_Enable_2	<=	r_Enable;
			------ Defaut ------
			r_CLR_Cntr	<=	'0';
--			r_Done		<=	'0';
		
			case	r_State	is
			
			when	s_Idle		=>
									if (r_Locked = '1' and r_Start = '1') then
										r_CE_CUT	<=	'1';
										r_CLR_Cntr	<=	'1';
										r_Done		<=	'0';
										r_State		<=	s_Propagate;
									end if;
			when	s_Propagate	=>
									if (r_Sample_Cntr = to_unsigned(0, r_Sample_Cntr'length)) then
										r_CE_CUT	<=	'0';
										r_Done		<=	'1';
										r_State		<=	s_Wait;
									end if;
			when	s_Wait		=>
									if (r_Enable_2 = '0' and r_Enable = '1') then
										r_State	<=	s_Idle;
									end if;
			when	others		=>
									null;
			end case;
			
		end if;
	
	end process;
	
	Sample_Counter	:	process (i_Clk)
	
	begin
	
		if (i_Clk'event and i_Clk = '1') then
		
			if (r_State = s_Propagate) then
				r_Sample_Cntr	<=	r_Sample_Cntr - 1;
			else
				r_Sample_Cntr	<=	to_unsigned(c_Num_Samples - 1, r_Sample_Cntr'length);
			end if;
		
		end if;
	
	end process;

	o_CE_CUT	<=	r_CE_CUT;	
	o_CLR_Cntr	<=	r_CLR_Cntr;	
    o_Done		<=	r_Done;
	
end architecture;