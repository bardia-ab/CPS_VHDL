library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;
--------------------------------------------
entity CUT2 is
	port(
		i_Clk_Launch	:	in		std_logic;
		i_Clk_Sample	:	in		std_logic;
		i_CE			:	in		std_logic;
		i_CLR         	:   in      std_logic;
		o_Error			:	out		std_logic
	);
end entity;
--------------------------------------------
architecture behavioral of CUT2 is

	signal	Q_launch_int	:	std_logic;
	signal	Q_sample_int	:	std_logic;
	signal	Q_capture_int	:	std_logic;
	signal	D_launch_int	:	std_logic;
	signal	D_capture_int	:	std_logic;

	attribute mark_debug	:	string;
	attribute mark_debug of Q_launch_int	:	signal is "True";
	attribute mark_debug of Q_sample_int	:	signal is "True";
	attribute mark_debug of Q_capture_int	:	signal is "True";
	
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
			CE 					=> 		i_CE, 			-- 1-bit input: Clock enable
			CLR 				=> 		i_CLR, 			-- 1-bit input: Asynchronous clear
			D 					=> 		D_launch_int 	-- 1-bit input: Data
		);
		
	sample_FF : FDCE
		generic map (
			INIT 				=> '0',		-- Initial value of register, '0', '1'
			-- Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion
			IS_CLR_INVERTED 	=> '0', 	-- Optional inversion for CLR
			IS_C_INVERTED 		=> '0', 	-- Optional inversion for C
			IS_D_INVERTED 		=> '0' 		-- Optional inversion for D
		)
		port map (
			Q 					=> 		Q_sample_int, 	-- 1-bit output: Data
			C 					=> 		i_Clk_Sample, 	-- 1-bit input: Clock
			CE 					=> 		i_CE, 			-- 1-bit input: Clock enable
			CLR 				=> 		i_CLR, 			-- 1-bit input: Asynchronous clear
			D 					=> 		Q_launch_int 	-- 1-bit input: Data
		);
	
--	capture_FF : FDCE
--		generic map (
--			INIT 				=> '0',		-- Initial value of register, '0', '1'
--			-- Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion
--			IS_CLR_INVERTED 	=> '0', 	-- Optional inversion for CLR
--			IS_C_INVERTED 		=> '0', 	-- Optional inversion for C
--			IS_D_INVERTED 		=> '0' 		-- Optional inversion for D
--		)
--		port map (
--			Q 					=> 		Q_capture_int, 	-- 1-bit output: Data
--			C 					=> 		i_Clk_Sample, 	-- 1-bit input: Clock
--			CE 					=> 		i_CE, 			-- 1-bit input: Clock enable
--			CLR 				=> 		i_CLR, 			-- 1-bit input: Asynchronous clear
--			D 					=> 		D_capture_int 	-- 1-bit input: Data
--		);

	
	not_LUT : LUT1
		generic map (
			INIT => X"1")
		port map (
			O 	=> D_launch_int,   -- LUT general output
			I0 	=> Q_launch_int  -- LUT input
		);	

	o_Error		<=	Q_sample_int xor Q_capture_int;
	
end architecture;