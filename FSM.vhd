library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_package.all;
-----------------------------------
entity FSM is
	generic(
		g_O2			:	integer;
		g_Counter_Width	:	integer;
		g_N_Sets		:	integer;
		g_N_Segments	:	integer;
		g_N_Partial		:	integer	:= 0;
		g_PipeLineStage	:	integer
	);
	port(
		i_Clk_Launch	:	in		std_logic;
		i_Clk_Sample	:	in		std_logic;
		i_Psclk1		:	in		std_logic;
		i_Psclk2		:	in		std_logic;
		i_Start			:	in		std_logic;
		i_Reset			:	in		std_logic;
		i_Locked1		:	in		std_logic;
		i_Locked2		:	in		std_logic;
		i_Locked3		:	in		std_logic;
		i_Psdone1		:	in		std_logic;
		i_Psdone2		:	in		std_logic;
		i_Mode			:	in		std_logic_vector(1 downto 0);
		i_Stop_PS		:	in		std_logic	:= '0';
		o_Trigger		:	out		std_logic;
		o_Psen1			:	out		std_logic;
		o_Psen2			:	out		std_logic;
		o_Psincdec1		:	out		std_logic;
		o_Psincdec2		:	out		std_logic;
		o_Reset1		:	out		std_logic;
		o_Reset2		:	out		std_logic;
		o_Reset3		:	out		std_logic;
		o_CE_CUT		:	out		std_logic;
		o_CE_Cntr		:	out		std_logic;
		o_CLR_Cntr		:	out		std_logic;
		o_Shift_Value	:	out		std_logic_vector(get_log2(56 * g_O2 * g_N_Sets) downto 0);
		o_Slct_Mux		:	out		std_logic_vector(get_log2(g_N_Segments) downto 0);
		o_LED1			:	out		std_logic;
		o_LED2			:	out		std_logic
	);
end entity;
-----------------------------------
architecture behavioral of FSM is

	--------------- Internal Regs ---------------------
	signal	w_Enable_CUT	:	std_logic	:= '0';
	signal	w_Trigger_CUT_1	:	std_logic;
	signal	w_Trigger_CUT_2	:	std_logic;
	signal	r_Locked		:	std_logic	:= '0';
	signal	r_Done_CUT		:	std_logic	:= '0';
	signal	r_Done_CM1		:	std_logic	:= '0';
	signal	r_Done_CM2		:	std_logic	:= '0';
	signal	r_En_CUT		:	std_logic;
	signal	r_En_CM1		:	std_logic;
	signal	r_En_CM2		:	std_logic;
	signal	r_ILA_Cap_RST	:	std_logic	:= '0';
	signal	r_LED1			:	std_logic;
	signal	r_LED2			:	std_logic;
	
begin
		
	CUT_FSM_Inst	:	entity work.CUT_FSM
		generic map(g_Counter_Width => g_Counter_Width,
					g_PipeLineStage => g_PipeLineStage
		)
		port map(
			i_Clk_Launch	=>	i_Clk_Launch,
			i_Clk_Sample	=>	i_Clk_Sample,
			i_Reset			=>	i_Reset,
		    i_Start			=>	i_Start,		
		    i_Locked		=>	r_Locked,	
		    i_Enable		=>	r_En_CUT,	
		    i_Mode			=>	i_Mode,
		    o_CE_CUT		=>	o_CE_CUT,	
			o_CE_Cntr		=>	o_CE_Cntr,
		    o_CLR_Cntr		=>	o_CLR_Cntr,	
		    o_Done			=>	r_Done_CUT		
		);
		
	CM1_FSM_Inst	:	entity work.CM_FSM
		port map(
			i_Clk		=>	i_Psclk1,
			i_Reset		=>	i_Reset,
			i_Enable	=>	r_En_CM1,
			i_Psdone	=>	i_Psdone1,
			o_Psen		=>	o_Psen1,
			o_Done		=>	r_Done_CM1
		);
	
	CM2_FSM_Inst	:	entity work.CM_FSM
		port map(
			i_Clk		=>	i_Psclk2,
			i_Reset		=>	i_Reset,
			i_Enable	=>	r_En_CM2,
			i_Psdone	=>	i_Psdone2,
			o_Psen		=>	o_Psen2,
			o_Done		=>	r_Done_CM2
		);
	
	-- FSM_Controller_Set_Inst	:	entity work.FSM_Controller_Set
	FSM_Controller_Inc_Inst	:	entity work.FSM_Controller_Inc
		generic map(
		g_O2			=>	g_O2,
		g_N_Sets		=>	g_N_Sets,
		g_N_Segments	=>	g_N_Segments,
		g_N_Partial		=>	g_N_Partial
	)
	port map(
		i_Reset			=>	i_Reset,
		i_Psclk1		=>	i_Psclk1,
		i_Locked1		=>	i_Locked1,
		i_Locked2		=>	i_Locked2,
		i_Locked3		=>	i_Locked3,
		i_Done_CUT		=>	r_Done_CUT,
		i_Done_CM1		=>	r_Done_CM1,
		i_Done_CM2		=>	r_Done_CM2,
		o_Reset1		=>	o_Reset1,
		o_Reset2		=>	o_Reset2,
		o_Reset3		=>	o_Reset3,
		o_Psincdec1		=>	o_Psincdec1,
		o_Psincdec2		=>	o_Psincdec2,
		o_En_CUT		=>	r_En_CUT,
		o_En_CM1		=>	r_En_CM1,
		o_En_CM2		=>	r_En_CM2,
		o_Shift_Value	=>	o_Shift_Value,
		o_Slct_Mux		=>	o_Slct_Mux,
		o_LED1			=>	r_LED1,
		o_LED2			=>	r_LED2
	);

	r_Locked		<=	i_Locked1 and i_Locked2 and i_Locked3;	
	o_Trigger		<=	r_Done_CUT;
	o_LED1			<=	r_LED1;
	o_LED2			<=	r_LED2;
	
end architecture;