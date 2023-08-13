library ieee;
use ieee.std_logic_1164.all;
use work.my_package.all;
---------------------------------
entity top is
	generic(
		g_O2			:	integer	:= 8;	
		g_Counter_Width	:	integer	:= 16;
		g_N_Sets		:	integer	:= 15;
		g_N_Segments	:	integer	:= 1;
		g_N_Parallel	:	integer	:= 1;
		g_N_Partial		:	integer	:= 0;
		g_Frequency		:	integer := 100e6;
		g_Baud_Rate		:	integer	:= 230400;
		g_PipeLineStage	:	integer	:= 1
	);
	port(
		i_Reset		    :	in		std_logic;
		i_Start		    :	in		std_logic;
		i_Mode		    :	in		std_logic_vector(1 downto 0);
		i_Clk_100       :   in      std_logic;   
        i_Clk_Launch    :   in      std_logic;
        i_Clk_Sample    :   in      std_logic;
        i_Locked_1      :   in      std_logic;
        i_Locked_2      :   in      std_logic;
        i_Locked_3      :   in      std_logic;
        i_Psdone_1      :   in      std_logic;
        i_Psdone_2      :   in      std_logic;
        o_Reset_1       :   out     std_logic;
        o_Reset_2       :   out     std_logic;
        o_Reset_3       :   out     std_logic;
        o_Psen_1        :   out     std_logic;
        o_Psen_2        :   out     std_logic;
        o_Psincdec_1    :   out     std_logic;
        o_Psincdec_2    :   out     std_logic;
		o_Tx		    :	out		std_logic;
		o_LED_1		    :	out		std_logic
		-- o_LED_2		    :	out		std_logic
		-- o_LED_3		    :	out		std_logic
	);
end entity;
---------------------------------
architecture rtl of top is

	constant c_UART_Din	:	integer	:= get_log2(56 * g_O2 * g_N_Sets) + g_N_Parallel;
	signal	r_Trigger	:	std_logic;
	signal	r_UART_Din	:	std_logic_vector(c_UART_Din downto 0);

begin

	Inst	:	entity work.CPS_Parallel_ZCU9
		generic map(
			g_O2			=>	g_O2,			
		    g_Counter_Width	=>	g_Counter_Width,
		    g_N_Sets		=>	g_N_Sets,		
		    g_N_Segments	=>	g_N_Segments,
		    g_N_Parallel	=>	g_N_Parallel,	
		    g_N_Partial		=>	g_N_Partial,	
		    g_Frequency		=>	g_Frequency,	
		    g_Baud_Rate		=>	g_Baud_Rate,	
		    g_PipeLineStage	=>	g_PipeLineStage
		)
		port map(
			i_Reset		 	=>	i_Reset,		 
			i_Start		    =>	i_Start,		 
			i_Mode		    =>	i_Mode,		 
			i_Clk_100       =>	i_Clk_100,    
			i_Clk_Launch    =>	i_Clk_Launch, 
			i_Clk_Sample    =>	i_Clk_Sample, 
			i_Locked_1      =>	i_Locked_1,   
		    i_Locked_2      =>	i_Locked_2,   
		    i_Locked_3      =>	i_Locked_3,   
		    i_Psdone_1      =>	i_Psdone_1,   
		    i_Psdone_2      =>	i_Psdone_2,   
		    o_Reset_1       =>	o_Reset_1,    
		    o_Reset_2       =>	o_Reset_2,    
		    o_Reset_3       =>	o_Reset_3,    
		    o_Psen_1        =>	o_Psen_1,     
		    o_Psen_2        =>	o_Psen_2,     
		    o_Psincdec_1    =>	o_Psincdec_1, 
		    o_Psincdec_2    =>	o_Psincdec_2, 
		    o_UART_Din		=>	r_UART_Din,
		    o_Trigger		=>	r_Trigger,
--		    o_Tx		    =>	o_Tx,		 
		    o_LED_1		    =>	o_LED_1		 
		);

	FIFO_UART_Inst	:	entity work.FIFO_UART
		generic map(
			g_Data_Width	=>	r_UART_Din'length,
			g_Parity		=>	"0",
			g_Data_Bits		=>	8,
			g_Baud_Rate		=>	g_Baud_Rate,
			g_Frequency		=>	g_Frequency
		)
		port map(
			i_Clk_Wr	=>	i_Clk_Sample,
			i_Clk_Rd	=>	i_Clk_100,
			i_Din		=>	r_UART_Din,
			i_Wr_En		=>	r_Trigger,
			o_Wr_Ack	=>	open,
			o_Full		=>	open,
			o_Empty		=>	open,
			o_Tx		=>	o_Tx
		);

end architecture;