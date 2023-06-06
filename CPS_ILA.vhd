library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.my_package.all;
library unisim;
use unisim.vcomponents.all;
--------------------------------------------
entity CPS_ILA is
	generic(
		g_M				:	integer	:= 50;	-- Number of Multiple CUTs
		g_N             :   integer := 88;   -- Number of Segments
		g_R				:	integer	:= 1;	-- Number of Remaining CUTs
		g_O2			:	integer	:= 16;
		g_N_Sets		:	integer	:= 15;
		g_Counter_Width	:	integer	:= 10
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
		i_Busy			:	in		std_logic;
		o_Psen1			:	out		std_logic;
		o_Psen2			:	out		std_logic;
		o_Psincdec1		:	out		std_logic;
		o_Psincdec2		:	out		std_logic;
		o_Reset1		:	out		std_logic;
		o_Reset2		:	out		std_logic;
		o_Reset3		:	out		std_logic;
		o_Send			:	out		std_logic;
		o_Data_Out		:	out		std_logic_vector(7 downto 0);
		o_LED1			:	out		std_logic;
		o_LED2			:	out		std_logic
	);
end entity;
--------------------------------------------
architecture behavioral of CPS_ILA is
		
	--------------- MMCM 0 ------------------
	signal	w_Clk_300		:	std_logic;
	signal	w_Clk_100		:	std_logic;
	--------------- MMCM 1 ------------------
	signal	w_Clk_Out1		:	std_logic;
	signal	w_Clk_Out2		:	std_logic;
	signal	w_Psen1			:	std_logic;
	signal	w_Psdone1		:	std_logic;
	signal	w_Reset1		:	std_logic	:= '0';
	signal	w_Locked1		:	std_logic;
	--------------- MMCM 2 ------------------
	signal	w_Clk_Launch	:	std_logic;
	signal	w_Psen2			:	std_logic;
	signal	w_Psdone2		:	std_logic;
	signal	w_Reset2		:	std_logic	:= '0';
	signal	w_Locked2		:	std_logic;
	--------------- MMCM 3 ------------------
	signal	w_Clk_Sample	:	std_logic;
	signal	w_Reset3		:	std_logic	:= '0';
	signal	w_Locked3		:	std_logic;
	---------------  CUT Rising ------------------
	signal	w_CE_CUT		:	std_logic;
	---------------  UART FSM ------------------
	signal	w_Done_UART		:	std_logic;
	--------------- Counter ------------------
	signal	w_CLR_Cntr		:	std_logic;
	--------------- Decoder ------------------
    signal  w_Slct_Mux		:	std_logic_vector(get_log2(g_N + 1) - 1 downto 0);
	--------------- Debug ------------------
	signal	w_Error_Cntr	:	my_array3(0 to g_M-1)(g_Counter_Width-1 downto 0);
	signal	w_Shift_Value	:	std_logic_vector(get_log2(56 * g_O2 * g_N_Sets) - 1 downto 0);
	signal	w_Capture		:	std_logic_vector(g_M-1 downto 0);
	signal	w_Capture_ILA   :   std_logic;
	signal	w_Trigger		:	std_logic;
	signal	w_ILA_Cap_Rst	:	std_logic;
	--------------- Segment ------------------
	signal  w_Error_Mux_In  :   my_array3(0 to g_N)(g_M-1 downto 0);
	signal  w_Error_Partial :   std_logic_vector(g_R-1 downto 0);
	signal  w_Error_Mux_Out :   std_logic_vector(g_M-1 downto 0);
		
	constant c_Segments		:	integer	:= cal_segment(g_N, g_R);
	
	attribute dont_touch	:	string;
	attribute dont_touch of Mux_Inst	:	label is "True";
			
begin
				
		FSM_Inst	:	entity work.FSM
		generic map(
			g_O2				=>	g_O2,	
			g_Counter_Width		=>	g_Counter_Width,
			g_N_Sets			=>	g_N_Sets,
			g_N_Segments		=>	c_Segments
		)
		port map(
			i_Clk_Launch	=>	w_Clk_Launch,	
			i_Psclk1		=>	w_Clk_100,
			i_Psclk2		=>	w_Clk_100,
			i_Start			=>	i_Enable(0),
			i_Locked1		=>	w_Locked1,
		    i_Locked2		=>	w_Locked2,
		    i_Locked3		=>	w_Locked3,
		    i_Psdone1		=>	w_Psdone1,
		    i_Psdone2		=>	w_Psdone2,
		    o_Trigger		=>	w_Trigger,
		    o_Psen1			=>	w_Psen1,
		    o_Psen2			=>	w_Psen2,
		    o_Psincdec1		=>	o_Psincdec1,
			o_Psincdec2     =>	o_Psincdec2,
			o_Reset1		=>	w_ILA_Cap_Rst,
			o_Reset2		=>	o_Reset2,
			o_Reset3		=>	o_Reset3,
		    o_CE_CUT		=>	w_CE_CUT,
		    o_CLR_Cntr		=>	w_CLR_Cntr,
		    o_Shift_Value	=>	w_Shift_Value,
		    o_Slct_Mux		=>	w_Slct_Mux,
		    o_LED1			=>	o_LED1,
		    o_LED2			=>	o_LED2
		);

	 Multiple_Segments:   for i in 0 to (c_Segments - 1) generate
	 	Regular	:	if i < g_N generate	
			 Multiple_CUT:	 for j in 0 to (g_M - 1) generate
				CUT	:	entity work.CUT
					port map(
						i_Clk_Launch	=>	w_Clk_Launch,
						i_Clk_Sample	=>	w_Clk_Sample,
						i_CE			=>	w_CE_CUT,
						i_CLR        	=>  '0',
						o_Error			=>	w_Error_Mux_In(i)(j) 
					);
			end generate;
		end generate;
		
		Partial	:	if i = g_N generate	
			Multiple_CUT:	 for j in 0 to (g_R - 1) generate
				CUT	:	entity work.CUT
					port map(
						i_Clk_Launch	=>	w_Clk_Launch,
						i_Clk_Sample	=>	w_Clk_Sample,
						i_CE			=>	w_CE_CUT,
						i_CLR        	=>  '0',
						o_Error			=>	w_Error_Partial(j) 
					);
			end generate;
		end generate;
	end generate;
		
	COUNTER_GEN	:	for j in 0 to (g_M - 1) generate
		Up_Counter:	entity work.Toggle_Counter
			generic map(g_Width => g_Counter_Width)
			port map(
				i_Clk   	=> w_Clk_Launch,
			    i_input   	=> w_Error_Mux_Out(j),
			    i_SCLR   	=> w_CLR_Cntr,
			    o_Q			=> w_Error_Cntr(j)
			);
    
		ILA_Capture_inst	:	entity work.ILA_Capture
			generic map (g_Counter_Width => g_Counter_Width)
			port map(
				i_Clk			=>	w_Clk_Launch,
				i_Enable		=>	w_Trigger,
				i_Reset			=>	w_ILA_Cap_Rst,
				i_Error_Cntr	=>	w_Error_Cntr(j),
				o_Capture		=>	w_Capture(j)
			);
			
	end generate;
	
	UART_FSM_Inst	:	entity work.UART_FSM
		port map(
			i_Clk			=>	i_Clk_100,
			i_Data_in		=>	w_Error_Cntr(0),
			i_Enable		=>	w_Trigger,
			i_Busy			=>	i_Busy,
			o_Send			=>	o_Send,
			o_Data_Out		=>	o_Data_out,
			o_Done			=>	w_Done_UART
	);
		
	Bitwise_or_Inst	:	entity work.bitwise_or
		generic map (g_Width => g_M)
		port map(i_Input_Sig => w_Capture, o_Result => w_capture_ILA);	
		
	Mux_Inst	:	entity work.Mux
		port map(
			i_Input		=>	w_Error_Mux_In,
			i_SLCT		=>	w_Slct_Mux,
			o_Output	=>	w_Error_Mux_Out
		);
					    
    w_Error_Mux_In(g_N)	<=	std_logic_vector(resize(unsigned(w_Error_Partial), g_M));
    w_Clk_100			<=	i_Clk_100;
    w_Clk_Launch		<=	i_Clk_Launch;
    w_Clk_Sample		<=	i_Clk_Sample;
    w_Locked1			<=	i_Locked1;
    w_Locked2			<=	i_Locked2;
    w_Locked3			<=	i_Locked3;
    w_Psdone1			<=	i_Psdone1;
    w_Psdone2			<=	i_Psdone2;
    o_Psen1				<=	w_Psen1;
    o_Psen2				<=	w_Psen2;
    o_Reset1			<=	w_ILA_Cap_Rst;
    		
end architecture;