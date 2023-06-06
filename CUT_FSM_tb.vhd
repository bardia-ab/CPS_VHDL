library ieee;
use ieee.std_logic_1164.all;
---------------------------------------
entity CUT_FSM_tb is
end entity;
---------------------------------------
architecture rtl of CUT_FSM_tb is

	constant clk_period	:	time	:= 10ns;
	
	signal	clk			:	std_logic	:= '0';
	signal	reset		:	std_logic	:= '0';
	signal	start		:	std_logic	:= '0';
	signal	locked		:	std_logic	:= '1';
	signal	enable		:	std_logic	:= '0';
	signal	CE_CUT		:	std_logic;
	signal	CE_Cntr		:	std_logic;
	signal	CLR_Cntr	:	std_logic;
	signal	Done		:	std_logic;
	
	component CUT_FSM
		generic(
			g_Counter_Width	:	integer;
			g_Mode			:	std_logic_vector(1 downto 0)	-- 0X: All Trans.  10: Falling Trans.  11: Rising Trans.
		);
		port(
			i_Clk		:	in		std_logic;
			i_Reset		:	in		std_logic;
			i_Start		:	in		std_logic;
			i_Locked	:	in		std_logic;
			i_Enable	:	in		std_logic;
			o_CE_CUT	:	out		std_logic;
			o_CE_Cntr	:	out		std_logic;
			o_CLR_Cntr	:	out		std_logic;
			o_Done		:	out		std_logic
		);
	end component;

begin

	CUT_FSM_Inst	:	CUT_FSM
		generic map(
			g_Counter_Width	=>	3,	
			g_Mode			=>	"10"
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
	Reset	<=	'1' after 2000ns, '0' after 2010ns;
	enable	<=	'1' after 1000ns, '0' after 1010ns;
	start	<=	'1' after 40ns, '0' after 50ns, '1' after 2050ns;

end architecture;