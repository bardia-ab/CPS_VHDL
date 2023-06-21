library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_package.all;
---------------------------------------
entity CUT_FSM is
	generic(
		g_Counter_Width	:	integer;
		g_PipeLineStage	:	integer
	);
	port(
		i_Clk		:	in		std_logic;
		i_Reset		:	in		std_logic;
		i_Start		:	in		std_logic;
		i_Locked	:	in		std_logic;
		i_Enable	:	in		std_logic;
		i_Mode		:	in		std_logic_vector(1 downto 0);	-- 0X: All Trans.  10: Falling Trans.  11: Rising Trans.
		o_CE_CUT	:	out		std_logic;
		o_CE_Cntr	:	out		std_logic;
		o_CLR_Cntr	:	out		std_logic;
		o_Done		:	out		std_logic
	);
end entity;
---------------------------------------
architecture behavioral of CUT_FSM is

	--------------- Types ---------------------
	type t_my_state is (s_Start, s_Idle, s_Propagate, s_Sample, s_Wait);
	
	--------------- Constants ---------------------	
	constant c_Num_Samples	:	integer	:= 2 ** (g_Counter_Width);
	constant c_Counter_Init	:	integer	:= c_Num_Samples - 1;

	--------------- Counters ---------------------
	signal	r_Sample_Cntr	:	unsigned(g_Counter_Width - 1 downto 0)			:= to_unsigned(c_Counter_Init, g_Counter_Width);
	signal	r_PipeLine_Cntr	:	unsigned(get_log2(g_PipeLineStage) downto 0)	:= to_unsigned(g_PipeLineStage - 1, get_log2(g_PipeLineStage) + 1);
	--------------- Internal Regs ---------------------
	signal	r_State			:	t_my_state	:= s_Start;
	signal	r_Start			:	std_logic;
	signal	r_Locked		:	std_logic;
	signal	r_Enable		:	std_logic;
	signal	r_Enable_2		:	std_logic	:= '0';
	signal	r_Even			:	std_logic	:= '0';
	signal	r_CE_CUT		:	std_logic	:= '0';
	signal	r_CE_Cntr		:	std_logic	:= '0';
	signal	r_CLR_Cntr		:	std_logic	:= '0';
	signal	r_Done			:	std_logic	:= '0';
	
	attribute mark_debug	:	string;
	attribute mark_debug of r_CE_CUT	:	signal is "True";
	attribute mark_debug of r_CE_Cntr	:	signal is "True";
	attribute mark_debug of r_Enable	:	signal is "True";

begin
	
	CUT_Control	:	process(i_Clk, i_Reset)
	
	begin
	
		if (i_Reset = '1') then
			r_State			<=	s_Start;
			r_CE_CUT		<=	'0';
			r_CLR_Cntr		<=	'0';
			r_Done			<=	'0';
		
		elsif (i_Clk'event and i_Clk = '1') then
		
			r_Start		<=	i_Start;		
			r_Locked	<=	i_Locked;	
			r_Enable	<=	i_Enable;
			r_Enable_2	<=	r_Enable;
			------ Defaut ------
			r_CLR_Cntr	<=	'0';
		
			case	r_State	is
			
			when	s_Start		=>
									if (r_Start = '0' and i_Start = '1') then
										r_State		<=	s_Idle;
									end if;
			
			when	s_Idle		=>
									if (r_Locked = '1') then
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
	
	Sample_Counter	:	process (i_Clk, i_Reset)
	
	begin
	
		if (i_Reset = '1') then
			r_Sample_Cntr	<=	to_unsigned(c_Counter_Init, r_Sample_Cntr'length);
		
		elsif (i_Clk'event and i_Clk = '1') then
		
			if (r_State = s_Propagate) then
				r_Sample_Cntr	<=	r_Sample_Cntr - 1;
			else
				r_Sample_Cntr	<=	to_unsigned(c_Counter_Init, r_Sample_Cntr'length);
			end if;
		
		end if;
	
	end process;
	
	Counter_CE	:	process(i_Clk, i_Reset)
	
	begin
	
		if (i_Reset = '1') then
			r_CE_Cntr	<=	'0';
		
		elsif (i_Clk'event and i_Clk = '1') then
		
			if (r_State = s_Propagate) then
					if (r_PipeLine_Cntr = to_unsigned(0, r_PipeLine_Cntr'length)) then
						if (i_Mode(1) = '0') then
							r_CE_Cntr	<=	'1';
						elsif (i_Mode(0) = '0') then
							r_CE_Cntr	<= r_Even;
						else
							r_CE_Cntr	<= not r_Even;
						end if;
					else
						r_PipeLine_Cntr	<=	r_PipeLine_Cntr - 1;
					end if;
			else
				r_CE_Cntr		<=	'0';
				r_PipeLine_Cntr	<=	to_unsigned(g_PipeLineStage - 1, r_PipeLine_Cntr'length);
			end if;
		
		end if;
	
	end process;
	
	-- As Init value of FF = '0' and initial value of counter = c_Num_Samples - 1 then rising Trans. occurs when counter equals an even number
	-- but CE_Cntr must be asserted in the previous cycle. So, when counter is odd, CE_Cnter must be asserted for rising Trans.
	-- However, due to the pipline stage (sample FF -> Up_Counter), the up_counter must be enabled with 1 cycle delay, which is when counter is even for rising Trans.
	-- In case of adding another pipeline stage in sample clock, r_Even must be registered (with sample clock) and then is assigned to r_CE_Cntr
	r_Even		<=	'1' when (to_integer(r_Sample_Cntr) mod 2 = 0) else '0';
	
	o_CE_CUT	<=	r_CE_CUT;	
	o_CE_Cntr	<=	r_CE_Cntr;
	o_CLR_Cntr	<=	r_CLR_Cntr;	
    o_Done		<=	r_Done;
	
end architecture;