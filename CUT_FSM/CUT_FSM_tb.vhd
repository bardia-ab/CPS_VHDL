library ieee;
use ieee.std_logic_1164.all;
---------------------------------------
entity CUT_FSM_tb is
end entity;
---------------------------------------
architecture rtl of CUT_FSM_tb is

	constant clk_period	:	time	:= 10 ns;
	
	signal	clk			:	std_logic	:= '0';
	signal	reset		:	std_logic	:= '0';
	signal	start		:	std_logic	:= '0';
	signal	locked		:	std_logic	:= '1';
	signal	enable		:	std_logic	:= '0';
	signal	CE_CUT		:	std_logic;
	signal	CE_Cntr		:	std_logic;
	signal	CLR_Cntr	:	std_logic;
	signal	Done		:	std_logic;

begin

	CUT_DSM_Inst	:	entity work.CUT_FSM
		generic map(
			g_Counter_Width	=>	3,	
			g_Mode			=>	"11"
		)
		port map(
			i_Clk			=>	clk,
		    i_Reset			=>	reset,
		    i_Start			=>	start,
		    i_Locked		=>	locked,
		    i_Enable		=>	enable,
		    o_CE_CUT		=>	CE_CUT,
		    o_CE_Cntr		=>	CE_Cntr,
		    o_CLR_Cntr		=>	CLR_Cntr,
		    o_Done			=>	Done
		);
	
	clk		<=	not clk after clk_period/2;
	Reset	<=	'1' after 2000 ns, '0' after 2010 ns;
	enable	<=	'1' after 1000 ns, '0' after 1010 ns;
	start	<=	'1' after 40 ns, '0' after 50 ns, '1' after 2050 ns;

end architecture;