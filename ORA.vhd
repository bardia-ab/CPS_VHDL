library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;
-----------------------------------
entity ORA is
	generic( 
		g_Width	:	integer
	);
	port(
		i_Clk_Sample	:	in		std_logic;
		i_Clk_Launch	:	in		std_logic;
		i_CE			:	in		std_logic;
		i_input			:	in		std_logic;
		i_SCLR			:	in		std_logic;
		o_Q				:	out		std_logic_vector(g_Width - 1 downto 0)
	);
end entity;
-----------------------------------
architecture behavioral of ORA is

	signal	D_launch_int	:	std_logic;
	signal	Q_launch_int	:	std_logic;
	signal	r_Cntr			:	unsigned(g_Width - 1 downto 0)	:= (others => '0');

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
		
	process(i_Clk_Sample)
	begin
		if (i_Clk_Sample'event and i_Clk_Sample = '1') then
			if (i_SCLR = '1') then
				r_Cntr			<=	(others => '0');
			else
				if (i_input /= Q_launch_int and i_CE = '1') then	-- USE i_CE for counting only Rising/Falling Transitions
					r_Cntr	<=	r_Cntr + 1;
				end if;
			end if;
		end if;
	end process;
	
						
	o_Q	<=	std_logic_vector(r_Cntr);

end architecture;