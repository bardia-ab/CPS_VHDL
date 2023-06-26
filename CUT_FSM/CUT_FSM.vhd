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
		i_Clk_Launch	:	in		std_logic;
		i_Clk_Sample	:	in		std_logic;
		i_Reset			:	in		std_logic;
		i_Start			:	in		std_logic;
		i_Locked		:	in		std_logic;
		i_Enable		:	in		std_logic;
		i_Mode			:	in		std_logic_vector(1 downto 0);	-- 0X: All Trans.  10: Falling Trans.  11: Rising Trans.
		o_CE_CUT		:	out		std_logic;
		o_CE_Cntr		:	out		std_logic;
		o_CLR_Cntr		:	out		std_logic;
		o_Done			:	out		std_logic
	);
end entity;
---------------------------------------
architecture behavioral of CUT_FSM is

	--------------- Types ---------------------
	type t_my_state is (s_Start, s_Idle, s_Propagate, s_Sample, s_Wait);
	
	--------------- Constants ---------------------	
--	constant c_Num_Samples	:	integer	:= 2 ** (g_Counter_Width + to_integer(unsigned(i_Mode(1 downto 1))));
--	constant c_Counter_Init	:	integer	:= c_Num_Samples - 1;
	constant	c_Min		:	unsigned(g_Counter_Width downto 0)	:= to_unsigned(10, g_Counter_Width+1);

	--------------- Counters ---------------------
	signal	r_Sample_Cntr	:	unsigned(g_Counter_Width downto 0);
	signal	r_PipeLine_Cntr	:	unsigned(get_log2(g_PipeLineStage) downto 0)	:= to_unsigned(g_PipeLineStage - 1, get_log2(g_PipeLineStage) + 1);
	--------------- Internal Regs ---------------------
	signal	r_State			:	t_my_state	:= s_Start;
	signal	r_Start			:	std_logic;
	signal	r_Locked		:	std_logic;
	signal	r_Enable		:	std_logic;
	signal	r_Enable_2		:	std_logic	:= '0';
	signal	r_Even			:	std_logic	:= '0';
	signal	r_CE_CUT		:	std_logic	:= '0';
	signal	r_CE_Cntr		:	std_logic_vector(g_PipeLineStage downto 0)	:= (others => '0');
	signal	r_CLR_Cntr		:	std_logic	:= '0';
	signal	r_Done			:	std_logic	:= '0';
	signal	r_Num_Samples	:	unsigned(g_Counter_Width downto 0);
	signal	r_Activate_Cntr	:	std_logic	:= '0';
	
	attribute mark_debug	:	string;
	attribute mark_debug of r_CE_CUT		:	signal is "True";
	attribute mark_debug of r_CE_Cntr		:	signal is "True";
	attribute mark_debug of r_Enable		:	signal is "True";
	attribute mark_debug of r_Even			:	signal is "True";
	attribute mark_debug of r_Num_Samples	:	signal is "True";

begin
	
	CUT_Control	:	process(i_Clk_Launch, i_Reset)
	
	begin
	
		if (i_Reset = '1') then
			r_State			<=	s_Start;
			r_CE_CUT		<=	'0';
			r_CLR_Cntr		<=	'0';
			r_Done			<=	'0';
			r_Activate_Cntr	<=	'0';
		
		elsif (i_Clk_Launch'event and i_Clk_Launch = '1') then
		
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
									if (r_CLR_Cntr = '1') then
										r_Activate_Cntr	<= '1';
									end if;
									
									if (r_Sample_Cntr = c_Min) then
										r_CE_CUT		<=	'0';
										r_Done			<=	'1';
										r_State			<=	s_Wait;
									end if;
			when	s_Wait		=>
									r_Activate_Cntr	<= '0';
									
									if (r_Enable_2 = '0' and r_Enable = '1') then
										r_State	<=	s_Idle;
									end if;
			when	others		=>
									null;
			end case;
			
		end if;
	
	end process;
	
	Sample_Counter	:	process (i_Clk_Launch)
	
	begin
	
		if (i_Clk_Launch'event and i_Clk_Launch = '1') then
		
			if (r_State = s_Propagate) then
				r_Sample_Cntr	<=	r_Sample_Cntr - 1;
			else
--				r_Sample_Cntr	<=	r_Num_Samples;
				r_Sample_Cntr	<=	r_Num_Samples - 10;
			end if;
		
		end if;
	
	end process;
	
	Counter_CE	:	process(i_Clk_Sample)
	
	begin
	
		if (i_Clk_Sample'event and i_Clk_Sample = '1') then
			
			for k in g_PipeLineStage downto 1 loop
					r_CE_Cntr(k)	<=	r_CE_Cntr(k - 1);
			end loop;
				
			if (r_Activate_Cntr = '1') then
				
				if (i_Mode = "10") then
					r_CE_Cntr(0)	<=	r_Even;
				elsif (i_Mode = "11") then
					r_CE_Cntr(0)	<=  not r_Even;
				else
					r_CE_Cntr(0)	<=	'1';
				end if;
			else
				r_CE_Cntr(0)		<=	'0';
				
			end if;
		
		end if;
	
	end process;
	
	-- As Init value of FF = '0' and initial value of counter = c_Num_Samples - 1 then rising Trans. occurs when counter transitions
	-- from an odd value to an even value. As CE_Cntr must be set one cycle before, it must be asserted when Cntr is even for rising Trans.
	r_Num_Samples	<=	i_Mode(1) & to_unsigned(2 ** g_Counter_Width - 1, g_Counter_Width);
	r_Even			<=	not std_logic(r_Sample_Cntr(0));
	
	o_CE_CUT		<=	r_CE_CUT;	
	o_CE_Cntr		<=	r_CE_Cntr(r_CE_Cntr'high);
	o_CLR_Cntr		<=	r_CLR_Cntr;	
    o_Done			<=	r_Done;
	
end architecture;