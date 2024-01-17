library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;
--------------------------------------------
entity CUT_BRAM is
    generic(
        g_BRAM_Width    :   integer :=  1;
        g_BRAM_Length   :   integer :=  14
    );
	port(
		i_Clk_Launch	:	in		std_logic;
		i_Clk_Sample	:	in		std_logic;
        i_Addr          :   in      std_logic_vector(g_BRAM_Length - 1 downto 0);
        i_WE			:	in		std_logic;
		i_CE			:	in		std_logic;
		i_CLR         	:   in      std_logic;
		o_Error			:	out		std_logic_vector(g_BRAM_Width - 1 downto 0)
	);
end entity;
--------------------------------------------
architecture behavioral of CUT_BRAM is

	signal	Q_launch_int	:	std_logic_vector(g_BRAM_Width - 1 downto 0);
	signal	Q_sample_int	:	std_logic_vector(g_BRAM_Width - 1 downto 0);
	signal	D_launch_int	:	std_logic_vector(g_BRAM_Width - 1 downto 0);

	attribute dont_touch	:	string;
	attribute dont_touch of i_Addr	:	signal is "True";

begin

	TPG:	for i in 0 to g_BRAM_Width - 1 generate
		launch_FF : FDCE
			generic map (
				INIT 				=> '0',		-- Initial value of register, '0', '1'
				-- Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion
				IS_CLR_INVERTED 	=> '0', 	-- Optional inversion for CLR
				IS_C_INVERTED 		=> '0', 	-- Optional inversion for C
				IS_D_INVERTED 		=> '0' 		-- Optional inversion for D
			)
			port map (
				Q 					=> 		Q_launch_int(i), 	-- 1-bit output: Data
				C 					=> 		i_Clk_Launch, 	-- 1-bit input: Clock
				CE 					=> 		i_CE, 			-- 1-bit input: Clock enable
				CLR 				=> 		i_CLR, 			-- 1-bit input: Asynchronous clear
				D 					=> 		D_launch_int(i) 	-- 1-bit input: Data
			);
		
		not_LUT : LUT1
			generic map (
				INIT => X"1")
			port map (
				O 	=> D_launch_int(i),   -- LUT general output
				I0 	=> Q_launch_int(i)  -- LUT input
			);	
	end generate;
	
    BRAM_Inst	:	entity work.bram
		generic map(
			g_Width		=>	g_BRAM_Width,
			g_Length	=>	g_BRAM_Length
		)
		port map(
			i_Clk     		=>	i_Clk_Sample,         
			i_WE      		=>	i_WE,
			i_Enable  		=>	i_CE,
			i_Data_In 		=>	Q_launch_int,     
			i_Addr    		=>	i_Addr,        
			o_Data_Out		=>	Q_sample_int    
		);

	o_Error		<=	Q_sample_int;
	
end architecture;