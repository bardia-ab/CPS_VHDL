library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;
--------------------------------------------
entity CUT_Buff is
	generic(g_Buffer	:	std_logic_vector(1 downto 0));
	port(
		i_Clk_Launch	:	in		std_logic;
		i_Clk_Sample	:	in		std_logic;
		i_CE			:	in		std_logic;
		i_CLR         	:   in      std_logic;
		o_Error			:	out		std_logic
	);
end entity;
--------------------------------------------
architecture behavioral of CUT_Buff is

	signal	Q_launch_int	:	std_logic;
	signal	Q_sample_int	:	std_logic;
	signal	D_launch_int	:	std_logic;
	signal	D_capture_int	:	std_logic;
	signal	Route_Thru		:	std_logic;
	signal	sample_in		:	std_logic;
	signal	not_in			:	std_logic;

	attribute dont_touch	:	string;
	attribute dont_touch of Q_launch_int	:	signal is "True";

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
			IS_C_INVERTED 		=> '1', 	-- Optional inversion for C
			IS_D_INVERTED 		=> '0' 		-- Optional inversion for D
		)
		port map (
			Q 					=> 		Q_sample_int, 	-- 1-bit output: Data
			C 					=> 		i_Clk_Sample, 	-- 1-bit input: Clock
			CE 					=> 		i_CE, 			-- 1-bit input: Clock enable
			CLR 				=> 		i_CLR, 			-- 1-bit input: Asynchronous clear
			D 					=> 		sample_in 	-- 1-bit input: Data
		);
		
	not_LUT : LUT1
		generic map (
			INIT => X"1")
		port map (
			O 	=> D_launch_int,   -- LUT general output
			I0 	=> not_in  -- LUT input
		);
		
	Buff_Gen	:	if g_Buffer = "10" generate
		buffer_LUT : LUT1
		generic map (
			INIT => X"2")
		port map (
			O 	=> Route_Thru,   -- LUT general output
			I0 	=> Q_launch_int  -- LUT input
		);
		
		sample_in	<=	Route_Thru;
		not_in		<=	Q_launch_int;
		
	elsif g_Buffer = "11" generate
		buffer_LUT : LUT1
		generic map (
			INIT => X"2")
		port map (
			O 	=> Route_Thru,   -- LUT general output
			I0 	=> Q_launch_int  -- LUT input
		);
	
		sample_in	<=	Route_Thru;
		not_in		<=	Route_Thru;
	
	elsif g_Buffer = "01" generate
		buffer_LUT : LUT1
		generic map (
			INIT => X"2")
		port map (
			O 	=> Route_Thru,   -- LUT general output
			I0 	=> Q_launch_int  -- LUT input
		);
	
		sample_in	<=	Q_launch_int;
		not_in		<=	Route_Thru;
		
	else generate
	
		sample_in	<=	Q_launch_int;
		not_in		<=	Q_launch_int;
		
	end generate;
	
	o_Error		<=	Q_sample_int;
	
end architecture;