library ieee;
use ieee.std_logic_1164.all;
---------------------------------
entity top is
	generic(
		g_M				:	integer							:= 50;	-- Number of Multiple CUTs
		g_N             :   integer 						:= 67;  -- Number of Segments
		g_R				:	integer							:= 0;	-- Number of Remaining CUTs
		g_O2			:	integer							:= 16;
		g_N_Sets		:	integer							:= 15;
		g_Counter_Width	:	integer							:= 16;
		PARITY			:	std_logic_vector(0 downto 0)	:= "0";
		Data_Bits		:	integer							:= 8;
		Baud_Rate		:	integer							:= 230400;
		Frequency		:	integer							:= 1e8	-- In Hertz	
	);
	port(
		i_Clk_100		:	in		std_logic;
		i_Clk_Launch	:	in		std_logic;
		i_Clk_Sample	:	in		std_logic;
		i_Enable		:	in		std_logic_vector(0 downto 0);
		i_Locked1		:	in		std_logic;
		i_Locked2       :	in		std_logic;
		i_Locked3       :	in		std_logic;
		i_Psdone1       :	in		std_logic;
		i_Psdone2       :	in		std_logic;
		o_Psen1			:	out		std_logic;
		o_Psen2			:	out		std_logic;
		o_Psincdec1		:	out		std_logic;
		o_Psincdec2		:	out		std_logic;	
		o_Reset1		:	out		std_logic;
		o_Reset2		:	out		std_logic;
		o_Reset3		:	out		std_logic;
		o_Tx			:	out		std_logic;
		o_LED1			:	out		std_logic;
		o_LED2			:	out		std_logic	
	);

end entity;
---------------------------------
architecture behavioral of top is

	signal	w_Busy		:	std_logic;
	signal	w_Send		:	std_logic;
	signal	w_Data_Out	:	std_logic_vector(Data_Bits-1 downto 0);

begin

	CPS_Inst	:	entity work.CPS_ILA
		generic map(
			g_M				=>	g_M,
			g_N             =>	g_N,
			g_R				=>	g_R,
			g_O2			=>	g_O2,
			g_N_Sets		=>	g_N_Sets,
			g_Counter_Width	=>	g_Counter_Width
		)
		port map(
			i_Clk_100		=>	i_Clk_100,		
            i_Clk_Launch	=>	i_Clk_Launch,	
            i_Clk_Sample	=>	i_Clk_Sample,	
            i_Enable		=>	i_Enable,		
            i_Locked1		=>	i_Locked1,		
            i_Locked2       =>	i_Locked2,       
            i_Locked3       =>	i_Locked3,       
            i_Psdone1       =>	i_Psdone1,       
            i_Psdone2       =>	i_Psdone2,       
            i_Busy			=>	w_Busy,			
            o_Psen1			=>	o_Psen1,			
            o_Psen2			=>	o_Psen2,
            o_Psincdec1		=> 	o_Psincdec1,
			o_Psincdec2		=>	o_Psincdec2,
			o_Reset1		=> o_Reset1,
			o_Reset2		=> o_Reset2,
			o_Reset3		=> o_Reset3,
            o_Send			=>	w_Send,			
            o_Data_Out		=>	w_Data_Out,		
            o_LED1			=>	o_LED1,			
            o_LED2			=>	o_LED2			
		);		
		
	UART_Inst	:	entity work.UART_Tx
		generic map(
			PARITY			=>	PARITY,
		    Data_Bits	    =>	Data_Bits,
		    Baud_Rate	    =>	Baud_Rate,
		    Frequency	    =>	Frequency
		)
		port map(
			Clk				=>	i_Clk_100,
		    Send		    =>	w_Send,
		    Data_In		    =>	w_Data_Out,
		    Busy		    =>	w_Busy,
			Data_Out        =>	o_Tx
		);

end architecture;