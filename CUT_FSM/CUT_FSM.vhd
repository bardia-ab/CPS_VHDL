library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_package.all;
library unisim;
use unisim.vcomponents.all;
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
	constant	c_Min		:	unsigned(g_Counter_Width downto 0)	:= to_unsigned(5, g_Counter_Width+1);

	--------------- Counters ---------------------
	signal	r_Sample_Cntr	:	unsigned(g_Counter_Width downto 0);
	signal	r_PipeLine_Cntr	:	unsigned(get_log2(g_PipeLineStage) downto 0)	:= to_unsigned(g_PipeLineStage - 1, get_log2(g_PipeLineStage) + 1);
	--------------- Internal Regs ---------------------
	signal	r_State				:	t_my_state	:= s_Start;
	signal	r_Start				:	std_logic;
	signal	r_Locked			:	std_logic;
	signal	r_Enable			:	std_logic;
	signal	r_Enable_2			:	std_logic	:= '0';
	signal	r_Even				:	std_logic	:= '0';
	signal	r_CE_CUT			:	std_logic	:= '1';
	signal	r_CE_Cntr			:	std_logic;
	signal	r_CLR_Cntr			:	std_logic	:= '0';
	signal	r_Done				:	std_logic	:= '0';
	signal	r_Num_Samples		:	unsigned(g_Counter_Width downto 0);
	signal	r_Activate_Cntr		:	std_logic	:= '0';
	signal	r_CLR_Cntr_2		:	std_logic;
	-------------------- Launch FF ---------------------
	signal	D_launch_int		:	std_logic;
	signal	Q_launch_int		:	std_logic;
	
begin
	
	launch_FF : FDCE
		generic map (
			INIT 				=> '0',		-- Initial value of register, '0', '1'
			-- Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion
			IS_CLR_INVERTED 	=> '0', 	-- Optional inversion for CLR
			IS_C_INVERTED 		=> '0', 	-- Optional inversion for C
			IS_D_INVERTED 		=> '0' 		-- Optional inversion for D
		)
		port map (
			Q 					=> 		Q_launch_int, 	-- 1-bit output: Data
			C 					=> 		i_Clk_Launch, 	-- 1-bit input: Clock
			CE 					=> 		'1', 			-- 1-bit input: Clock enable
			CLR 				=> 		'0', 			-- 1-bit input: Asynchronous clear
			D 					=> 		D_launch_int 	-- 1-bit input: Data
		);

	not_LUT : LUT1
		generic map (
			INIT => X"1")
		port map (
			O 	=> D_launch_int,   -- LUT general output
			I0 	=> Q_launch_int  -- LUT input
		);

	CUT_Control	:	process(i_Clk_Launch, i_Reset)
	begin	
		if (i_Reset = '1') then
			r_State			<=	s_Start;
			r_Done			<=	'0';
		
		elsif (i_Clk_Launch'event and i_Clk_Launch = '1') then
		
			r_Start		<=	i_Start;		
			r_Locked	<=	i_Locked;	
			r_Enable	<=	i_Enable;
			r_Enable_2	<=	r_Enable;
			------ Defaut ------
					
			case	r_State	is
			
			when	s_Start		=>
									if (r_Start = '0' and i_Start = '1') then
										r_State		<=	s_Idle;
									end if;
			
			when	s_Idle		=>
									-- as the r_CE_CUT is not used the output of the launch_FF can change once the PLL gets locked
									-- so we need to make sure the i_Q_Launch = '0'
									if (r_Locked = '1' and Q_Launch_int = '1') then
										r_Done			<=	'0';
										r_State			<=	s_Propagate;
									end if;
			when	s_Propagate	=>
									if (r_Sample_Cntr = c_Min) then
										r_Done			<=	'1';
										r_State			<=	s_Wait;
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
	
	Sample_Counter	:	process (i_Clk_Launch)
	begin
		if (i_Clk_Launch'event and i_Clk_Launch = '1') then
			if (r_State = s_Propagate) then
				r_Sample_Cntr	<=	r_Sample_Cntr - 1;
			else
				r_Sample_Cntr	<=	r_Num_Samples - 5;
			end if;
		end if;
	end process;
	
	CLR_Countr	:	process(i_Clk_Sample)
	begin
		if (i_Clk_Sample'event and i_Clk_Sample = '1') then
			r_CLR_Cntr		<=	'0';
			r_Activate_Cntr	<= 	'0';
			if (r_State = s_Idle) then
				r_CLR_Cntr	<=	'1';
			elsif (r_State = s_Propagate) then
				r_Activate_Cntr	<= 	'1';
			end if;
		end if;
	end process;

	CE_Countr	:	process(i_Clk_Sample)
	begin
		if (i_Clk_Sample'event and i_Clk_Sample = '1') then
--			r_CLR_Cntr_2	<=	r_CLR_Cntr;
--			if (r_CLR_Cntr_2 = '1') then
			if (r_CLR_Cntr = '1') then	--r_Activate_Cntr goes high at this moment
				r_CE_Cntr	<=	not i_Mode(1) or i_Mode(0);
			elsif (r_Activate_Cntr = '0') then	--before rising edge
				r_CE_Cntr	<=	'0';
			elsif (i_Mode(1) = '0') then		--after rising edge (both transitions)
				r_CE_Cntr	<=	'1';
			else								--after rising edge (rising/falling transitions)
				r_CE_Cntr	<=	not r_CE_Cntr;
			end if;
		end if;
	end process;
	
	r_Num_Samples	<=	i_Mode(1) & to_unsigned(2 ** g_Counter_Width - 1, g_Counter_Width);
	
	o_CE_CUT		<=	r_CE_CUT;	
	o_CE_Cntr		<=	r_CE_Cntr;
	o_CLR_Cntr		<=	r_CLR_Cntr;
    o_Done			<=	r_Done;
	
end architecture;