library ieee;
use ieee.std_logic_1164.all;
---------------------------------------
entity CUT_FSM_tb is
end entity;
---------------------------------------
architecture rtl of CUT_FSM_tb is

	constant clk_period	:	time	:= 10 ns;
	constant cntr_width	:	integer	:= 3;
	
	signal	clk_launch	:	std_logic	:= '0';
	signal	clk_sample	:	std_logic	:= '0';
	signal	reset		:	std_logic	:= '0';
	signal	start		:	std_logic	:= '0';
	signal	locked		:	std_logic	:= '1';
	signal	enable		:	std_logic	:= '0';
	signal	CE_CUT		:	std_logic;
	signal	CE_Cntr		:	std_logic;
	signal	CLR_Cntr	:	std_logic;
	signal	Done		:	std_logic;
	signal	Error		:	std_logic;
	signal	Cntr_Out	:	std_logic_vector(cntr_width - 1 downto 0);

begin

	CUT_DSM_Inst	:	entity work.CUT_FSM
		generic map(
			g_Counter_Width	=>	cntr_width,	
			g_PipeLineStage	=>	1,
			g_Mode			=>	"00"
		)
		port map(
			i_Clk			=>	clk_launch,
		    i_Reset			=>	reset,
		    i_Start			=>	start,
		    i_Locked		=>	locked,
		    i_Enable		=>	enable,
		    o_CE_CUT		=>	CE_CUT,
		    o_CE_Cntr		=>	CE_Cntr,
		    o_CLR_Cntr		=>	CLR_Cntr,
		    o_Done			=>	Done
		);
		
	CUT_Inst:	entity work.CUT
		port map(
			i_Clk_Launch	=>	clk_launch,
		    i_Clk_Sample	=>	clk_sample,
		    i_CE			=>	CE_CUT,
		    i_CLR         	=>	'0',
		    o_Error			=>	Error
		);
		
	Counter_Inst:	entity work.Toggle_Counter
		generic map(g_Width	=>	cntr_width)
		port map(
			i_Clk			=>	clk_sample,
		    i_CE	        =>	CE_Cntr,
		    i_input	        =>	Error,
		    i_SCLR	        =>	CLR_Cntr,
		    o_Q		        =>	Cntr_Out
		);
	
	clk_launch		<=	not clk_launch after clk_period/2;
	clk_sample		<=	transport clk_launch after clk_period/4;
	Reset			<=	'1' after 2000 ns, '0' after 2010 ns;
	enable			<=	'1' after 1000 ns, '0' after 1010 ns;
	start			<=	'1' after 40 ns, '0' after 50 ns, '1' after 2050 ns;

end architecture;