library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use work.my_package.all;
---------------------------------
entity CPS_Parallel_ZCU9 is
	generic(
		g_O2			:	integer	:= 8;	
		g_Counter_Width	:	integer	:= 16;
		g_N_Sets		:	integer	:= 15;
		g_N_Segments	:	integer	:= 2;
		g_N_Parallel	:	integer	:= 20;
		g_N_Partial		:	integer	:= 7;
		g_Frequency		:	integer := 100e6;
		g_Baud_Rate		:	integer	:= 230400;
		g_PipeLineStage	:	integer	:= 1
	);
	port(
--		i_Reset		    :	in		std_logic;
--		i_Start		    :	in		std_logic;
--		i_Mode		    :	in		std_logic_vector(1 downto 0);
		i_Clk_100       :   in      std_logic;   
        i_Clk_Launch    :   in      std_logic;
        i_Clk_Sample    :   in      std_logic;
        i_Locked_1      :   in      std_logic;
        i_Locked_2      :   in      std_logic;
        i_Locked_3      :   in      std_logic;
        i_Psdone_1      :   in      std_logic;
        i_Psdone_2      :   in      std_logic;
        i_Rx			:	in		std_logic;
        o_Reset_1       :   out     std_logic;
        o_Reset_2       :   out     std_logic;
        o_Reset_3       :   out     std_logic;
        o_Psen_1        :   out     std_logic;
        o_Psen_2        :   out     std_logic;
        o_Psincdec_1    :   out     std_logic;
        o_Psincdec_2    :   out     std_logic;
        o_UART_Din		:	out		std_logic_vector;
        o_Trigger		:	out		std_logic;
		o_Tx		    :	out		std_logic;
		o_LED_1		    :	out		std_logic;
		o_LED_2		    :	out		std_logic;
		o_LED_3		    :	out		std_logic
	);
end entity;
---------------------------------
architecture behavioral of CPS_Parallel_ZCU9 is

	constant c_Segments		:	integer	:= cal_segment(g_N_Segments, g_N_Partial);
	---------------- Clock Buffers ----------------------
	signal	w_Clk_100	:	std_logic;
	---------------- MMCM_1 ----------------------
	signal	w_Psen_1		:	std_logic;
	signal	w_Psincdec_1	:	std_logic	:= '1';
	signal	w_Psdone_1		:	std_logic;
	signal	w_Reset_1		:	std_logic;
	signal	w_Locked_1		:	std_logic;
	---------------- MMCM_2 ----------------------
	signal	w_Clk_Launch	:	std_logic;
	signal	w_Psen_2		:	std_logic;
	signal	w_Psincdec_2	:	std_logic	:= '0';
	signal	w_Psdone_2		:	std_logic;
	signal	w_Reset_2		:	std_logic;
	signal	w_Locked_2		:	std_logic;
	---------------- MMCM_3 ----------------------
	signal	w_Clk_Sample	:	std_logic;
	signal	w_Reset_3		:	std_logic;
	signal	w_Locked_3		:	std_logic;
	---------------- Debouncer ----------------------
	signal	w_Reset			:	std_logic;
	signal	w_Rst_Debouncer	:	std_logic;
	signal	w_Start			:	std_logic;
	---------------- CUT ----------------------
	signal	w_CE_CUT		:	std_logic;
	signal	w_CUT_Error		:	std_logic;
	---------------- Toggle Counter ----------------------
	signal	w_CE_Cntr		:	std_logic;
	signal	w_CLR_Cntr		:	std_logic;
	--------------- Debug ------------------
	signal	w_Error_Cntr	:	my_array(0 to g_N_Parallel - 1)(g_Counter_Width - 1 downto 0);
	signal	w_Shift_Value	:	std_logic_vector(get_log2(56 * g_O2 * g_N_Sets) downto 0);
	signal	w_Capture		:	std_logic_vector(g_N_Parallel - 1 downto 0);
	signal	w_Capture_ILA   :   std_logic;
	signal	w_Trigger		:	std_logic;
	signal	w_TD_Enable		:	std_logic;
	---------------- MUX ---------------------------------
	signal  w_Error_Mux_In  :   my_array(0 to c_Segments - 1)(g_N_Parallel - 1 downto 0);
	signal  w_Slct_Mux		:	std_logic_vector(get_log2(c_Segments) downto 0);
	signal  w_Error_Mux_Out :   std_logic_vector(g_N_Parallel - 1 downto 0);
	
	constant	c_UART_Din_Length	:	integer	:= w_Shift_Value'length + g_N_Parallel;
	signal	w_Mode			:	std_logic_vector(1 downto 0);
	signal	r_UART_Din		:	std_logic_vector(c_UART_Din_Length - 1 downto 0);
	signal	w_LED_1			:	std_logic;
	
	attribute DONT_TOUCH	:	string;
	attribute DONT_TOUCH of w_Error_Mux_Out	:	signal is "True";
	attribute DONT_TOUCH of w_Slct_Mux		:	signal is "True";
	attribute DONT_TOUCH of w_Error_Mux_In	:	signal is "True";
	
	attribute mark_debug	:	string;
	attribute mark_debug of w_Capture_ILA	:	signal is "True";
	attribute mark_debug of w_Capture		:	signal is "True";
	attribute mark_debug of w_Error_Cntr	:	signal is "True";
	attribute mark_debug of w_TD_Enable		:	signal is "True";
	attribute mark_debug of w_CE_Cntr		:	signal is "True";

begin
		
	Instruction_Cont_Inst	:	entity work.Instruction_Controller
		generic map(
			g_Baud_Rate		=>	g_Baud_Rate,
			g_Frequency		=>	g_Frequency
		)
		port map(
			i_Clk	    	=>	i_Clk_100,
			i_Data_In	    =>	i_Rx,
			o_Start		    =>	w_Start,
			o_Reset		    =>	w_Reset,
			o_Mode		    =>	w_Mode
		);
	
	FSM_Inst:	entity work.FSM
		generic map(
			g_O2			=>	g_O2,	
		    g_Counter_Width	=>	g_Counter_Width,
		    g_N_Sets		=>	g_N_Sets,
		    g_N_Segments	=>	c_Segments,
		    g_N_Partial		=>	g_N_Partial,
		    g_PipeLineStage	=>	g_PipeLineStage
		)
		port map(
				i_Clk_Launch	=>	w_Clk_Launch,
				i_Clk_Sample	=>	w_Clk_Sample,	
		        i_Psclk1		=>	w_Clk_100,
		        i_Psclk2		=>	w_Clk_100,
		        i_Start			=>	w_Start,
		        i_Reset			=>	w_Reset,
		        i_Locked1		=>	w_Locked_1,
		        i_Locked2		=>	w_Locked_2,
		        i_Locked3		=>	w_Locked_3,
		        i_Psdone1		=>	w_Psdone_1,
		        i_Psdone2		=>	w_Psdone_2,
		        i_Mode			=>	w_Mode,
		        o_Trigger		=>	w_Trigger,
		        o_Psen1			=>	w_Psen_1,
		        o_Psen2			=>	w_Psen_2,
		        o_Psincdec1		=>	w_Psincdec_1,
		        o_Psincdec2		=>	w_Psincdec_2,
		        o_Reset1		=>	w_Reset_1,
		        o_Reset2		=>	w_Reset_2,
		        o_Reset3		=>	w_Reset_3,
		        o_CE_CUT		=>	w_CE_CUT,
		        o_CE_Cntr		=>	w_CE_Cntr,
		        o_CLR_Cntr		=>	w_CLR_Cntr,
		        o_Shift_Value	=>	w_Shift_Value,
		        o_Slct_Mux		=>	w_Slct_Mux,
		        o_LED1			=>	w_LED_1,
		        o_LED2			=>	open		
		);

--	Multiple_Segments:   for i in 0 to (c_Segments - 1) generate
--	 	Regular	:	if i < g_N_Segments generate	
--			 Multiple_CUT:	 for j in 0 to (g_N_Parallel - 1) generate
--				CUT	:	entity work.CUT
--					port map(
--						i_Clk_Launch	=>	w_Clk_Launch,
--						i_Clk_Sample	=>	w_Clk_Sample,
--						i_CE			=>	w_CE_CUT,
--						i_CLR        	=>  '0',
--						o_Error			=>	w_Error_Mux_In(i)(j) 
--					);
--			end generate;
--		end generate;
		
--		Partial	:	if i = g_N_Segments generate	
--			Multiple_CUT:	 for j in 0 to (g_N_Partial - 1) generate
--				CUT	:	entity work.CUT
--					port map(
--						i_Clk_Launch	=>	w_Clk_Launch,
--						i_Clk_Sample	=>	w_Clk_Sample,
--						i_CE			=>	w_CE_CUT,
--						i_CLR        	=>  '0',
--						o_Error			=>	w_Error_Mux_In(i)(j) 
--					);
--			end generate;
			
--			w_Error_Mux_In(i)(g_N_Parallel - 1 downto g_N_Partial)	<=	(others => '0');
			
--		end generate;
--	end generate;

	CUTs_Inst	:	entity work.CUTs
	generic map(
		g_N_Segments	=>	c_Segments, 
		g_N_Parallel 	=>	g_N_Parallel
	)
	port map(
		i_Clk_Launch	=>	w_Clk_Launch,
		i_Clk_Sample	=>	w_Clk_Sample,
		i_CE			=>	w_CE_CUT,
		i_CLR        	=>  '0',
		o_Error			=>	w_Error_Mux_In
	);
		
	COUNTER_GEN	:	for j in 0 to (g_N_Parallel - 1) generate

		ORA_Inst:	entity work.ORA
			generic map(
				g_Width	=>	g_Counter_Width
			)
			port map(
				i_Clk_Sample	=>	w_Clk_Sample,
				i_Clk_Launch	=>	w_Clk_Launch,
				i_CE	        =>	w_CE_Cntr,
				i_input	        =>	w_Error_Mux_Out(j),
				i_SCLR	        =>	w_CLR_Cntr,
				o_Q		        =>	w_Error_Cntr(j)
			);
		
		Threshold_Detector_inst	:	entity work.Threshold_Detector
			generic map (g_Rising_Edge => '1')
			port map(
				i_Clk			=>	w_Clk_Sample,
				i_Enable		=>	w_TD_Enable,
				i_Reset			=>	w_Reset_1,
				i_Sig			=>	w_Error_Cntr(j)(g_Counter_Width - 1),
				o_Capture		=>	w_Capture(j)
			);
			
	end generate;

	Mux_Inst	:	entity work.Mux
		port map(
			i_Input		=>	w_Error_Mux_In,
			i_SLCT		=>	w_Slct_Mux,
			o_Output	=>	w_Error_Mux_Out
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
			i_Reset		=>	w_Reset,
			i_Din		=>	r_UART_Din,
			i_Wr_En		=>	w_Capture_ILA,
			i_Last		=>	w_LED_1,
			o_Wr_Ack	=>	open,
			o_Full		=>	o_LED_2,
			o_Empty		=>	o_LED_3,
			o_Tx		=>	o_Tx
		);
		
	process(w_Clk_Sample)
	begin
		w_TD_Enable	<=	w_Trigger;
	end process;
	
--	w_Rst_Debouncer	<=	not i_Start;
--	r_Mode			<=	i_Mode;
	w_Capture_ILA	<=	OR_REDUCE(w_Capture);
	r_UART_Din		<=	w_Shift_Value & w_Capture;
	o_UART_Din		<=	r_UART_Din;
--	o_Trigger		<=	w_Capture_ILA;
	o_LED_1			<=	w_LED_1;		
	
	o_Reset_1		<=	w_Reset_1;
	o_Reset_2       <=	w_Reset_2;
	o_Reset_3       <=	w_Reset_3;
	o_Psen_1        <=	w_Psen_1;
	o_Psen_2        <=	w_Psen_2;
	o_Psincdec_1    <=	w_Psincdec_1;
	o_Psincdec_2    <=	w_Psincdec_2;
--	w_Start		    <=	i_Start;
--	w_Reset		    <=	i_Reset;
--	w_Mode		    <=	i_Mode;
	w_Clk_100       <=	i_Clk_100;
	w_Clk_Launch    <=	i_Clk_Launch;
	w_Clk_Sample    <=	i_Clk_Sample;
	w_Locked_1      <=	i_Locked_1;
	w_Locked_2      <=	i_Locked_2;
	w_Locked_3      <=	i_Locked_3;
	w_Psdone_1      <=	i_Psdone_1;
	w_Psdone_2      <=	i_Psdone_2; 
	
end architecture;
