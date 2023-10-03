library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;
------------------------------------
entity CPS_Single_Top is
	generic(
		g_O2			:	integer	:= 8;	
		g_Counter_Width	:	integer	:= 10;
		g_N_Sets		:	integer	:= 127;
		g_N_Segments	:	integer	:= 1;
		g_Frequency		:	integer := 100e6;
		g_Baud_Rate		:	integer	:= 230400;
		g_PipeLineStage	:	integer	:= 1
	);
	port(
		i_Clk_In_P	    :	in		std_logic;
		i_Clk_In_N	    :	in		std_logic;
		i_Rx			:	in		std_logic;
--		i_Reset		    :	in		std_logic;
--		i_Start		    :	in		std_logic;
--		i_Mode		    :	in		std_logic_vector(1 downto 0);
		o_Tx		    :	out		std_logic;
		o_LED_1		    :	out		std_logic;
		o_LED_2		    :	out		std_logic;
		o_LED_3		    :	out		std_logic;
		o_LED_4		    :	out		std_logic
	);
end entity;
------------------------------------
architecture behavioral of CPS_Single_Top is

COMPONENT vio_0
  PORT (
    clk : IN STD_LOGIC;
    probe_in0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe_in1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe_in2 : IN STD_LOGIC_VECTOR(1 DOWNTO 0)
  );
END COMPONENT;
	
	---------------- Clock Buffers ----------------------
	signal	w_Clk_300	:	std_logic;
	signal	w_Clk_100	:	std_logic;
	---------------- MMCM_1 ----------------------
	signal	w_Clk_Launch_In	:	std_logic;
	signal	w_Clk_Sample_In	:	std_logic;
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
	signal	w_Q_Launch		:	std_logic;
	signal	w_CUT_Error		:	std_logic;
	---------------- Toggle Counter ----------------------
	signal	w_Propagation	:	std_logic;
	signal	w_CE_Cntr		:	std_logic;
	signal	w_CLR_Cntr		:	std_logic;
	signal	w_Cntr_Out		:	std_logic_vector(g_Counter_Width - 1 downto 0);
	---------------- Debug ----------------------
	signal	w_Trigger		:	std_logic;
	signal	w_Mode			:	std_logic_vector(1 downto 0);
	signal	w_cntr			:	std_logic_vector(15 downto 0);
	---------------- UART ----------------------
	signal	w_Busy			:	std_logic;
	signal	w_Send			:	std_logic;
	signal	w_Done			:	std_logic;
	signal	r_UART_Data_In	:	std_logic_vector(7 downto 0);
	---------------- FIFO ----------------------
	signal	w_WR_En   		:	std_logic;
	signal	w_RD_En   		:	std_logic;
	signal	r_FIFO_Out		:	std_logic_vector(g_Counter_Width - 1 downto 0)	:= (others => '0'); 
	signal	w_Full    		:	std_logic; 
	signal	w_WR_ACK        :	std_logic;
	signal	w_Empty   		:	std_logic;
	signal	w_Valid   		:	std_logic;
	---------------------------------
	signal	w_cntr_rd		:	std_logic_vector(13 downto 0)	:= (others => '0');
	signal	w_cntr_wr		:	std_logic_vector(13 downto 0)	:= (others => '0');
	signal	w_LED_1			:	std_logic;
	
	attribute mark_debug	:	string;
	attribute mark_debug of w_CUT_Error	:	signal is "True";
	attribute mark_debug of w_Trigger	:	signal is "True";

begin

	Instruction_Cont_Inst	:	entity work.Instruction_Controller
		generic map(
			g_Baud_Rate		=>	g_Baud_Rate,
			g_Frequency		=>	g_Frequency
		)
		port map(
			i_Clk	    	=>	w_Clk_100,
			i_Data_In	    =>	i_Rx,
			o_Start		    =>	w_Start,
			o_Reset		    =>	w_Reset,
			o_Mode		    =>	w_Mode
		);

	CMs_Inst    :   entity work.Clock_Managers
        port map(
            i_Clk_In_P      =>  i_Clk_In_P,
            i_Clk_In_N      =>  i_Clk_In_N,
            i_Reset_1       =>  w_Reset_1,
            i_Reset_2       =>  w_Reset_2,
            i_Reset_3       =>  w_Reset_3,
            i_Psen_1        =>  w_Psen_1,
            i_Psen_2        =>  w_Psen_2,
            i_Psincdec_1    =>  w_Psincdec_1,
            i_Psincdec_2    =>  w_Psincdec_2,
            o_Clk_100       =>  w_Clk_100,
            o_Clk_Launch    =>  w_Clk_Launch,
            o_Clk_Sample    =>  w_Clk_Sample,
            o_Locked_1      =>  w_Locked_1,
            o_Locked_2      =>  w_Locked_2,
            o_Locked_3      =>  w_Locked_3,
            o_Psdone_1      =>  w_Psdone_1,
            o_Psdone_2      =>  w_Psdone_2   
        );
	
--    Debouncer_Inst:	entity work.debounce
--		generic map(
--			clk_freq	=>	100e6,
--			stable_time	=>	10
--		)
--		port map(
--			clk		=>	w_Clk_100,
--			reset_n	=>	w_Rst_Debouncer,
--			button	=>	i_Reset,
--			result	=>	w_Reset	
--		);
	
	CUT_Inst:	entity work.CUT
		port map(
			i_Clk_Launch	=>	w_Clk_Launch,
		    i_Clk_Sample	=>	w_Clk_Sample,
		    i_CE			=>	w_CE_CUT,
		    i_CLR         	=>	'0',
		    o_Error			=>	w_CUT_Error
		);
		
	FSM_Inst:	entity work.FSM
		generic map(
			g_O2			=>	g_O2,	
		    g_Counter_Width	=>	g_Counter_Width,
		    g_N_Sets		=>	g_N_Sets,
		    g_N_Segments	=>	g_N_Segments,
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
		        o_Shift_Value	=>	open,
		        o_Slct_Mux		=>	open,
		        o_LED1			=>	w_LED_1,
		        o_LED2			=>	o_LED_2		
		);
		
	ORA_Inst:	entity work.ORA
		generic map(
			g_Width	=>	g_Counter_Width
		)
		port map(
			i_Clk_Sample	=>	w_Clk_Sample,
			i_Clk_Launch	=>	w_Clk_Launch,
		    i_CE	        =>	w_CE_Cntr,
		    i_input	        =>	w_CUT_Error,
		    i_SCLR	        =>	w_CLR_Cntr,
		    o_Q		        =>	w_Cntr_Out
		);
		
	FIFO_UART_Inst	:	entity work.FIFO_UART
		generic map(
			g_Data_Width	=>	g_Counter_Width,
			g_Parity		=>	"0",
			g_Data_Bits		=>	8,
			g_Baud_Rate		=>	g_Baud_Rate,
			g_Frequency		=>	g_Frequency
		)
		port map(
			i_Clk_Wr	=>	w_Clk_Launch,
			i_Clk_Rd	=>	w_Clk_100,
			i_Reset		=>	w_Reset,
			i_Din		=>	w_Cntr_Out,
			i_Last		=>	w_LED_1,
			i_Wr_En		=>	w_Trigger,
			o_Wr_Ack	=>	open,
			o_Full		=>	o_LED_4,
			o_Empty		=>	w_Empty,
			o_Tx		=>	o_Tx
		);

--VIO_Inst : vio_0
--  PORT MAP (
--    clk 			=> w_Clk_100,
--    probe_in0(0) 	=> w_Start,
--    probe_in1(0) 	=> w_Reset,
--    probe_in2 		=> w_Mode
--  );

--	w_Rst_Debouncer	<=	not i_Start;
--	r_Mode			<=	i_Mode;
	o_LED_1			<=	w_LED_1;
	o_LED_3			<=	w_Empty;

end architecture;