library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;
------------------------------------
entity CPS_Single_ZU9_Top is
	generic(
		g_O2			:	integer	:= 16;	
		g_Counter_Width	:	integer	:= 16;
		g_N_Sets		:	integer	:= 15;
		g_N_Segments	:	integer	:= 1;
		g_PipeLineStage	:	integer	:= 1;
		g_Baud_Rate		:	integer	:= 230400;
		g_Frequency		:	integer	:= 1e8
--		g_Mode			:	std_logic_vector(1 downto 0)	:= "00"	-- 0X: All Trans.  10: Falling Trans.  11: Rising Trans.
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
		o_LED_1		    :	out		std_logic;
		o_LED_2		    :	out		std_logic;
		o_LED_3		    :	out		std_logic
	);
end entity;
------------------------------------
architecture behavioral of CPS_Single_ZU9_Top is

	COMPONENT ila_0
		PORT (
			clk 	: IN STD_LOGIC;
			probe0 	: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
			probe1 	: IN STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	END COMPONENT  ;
	
	COMPONENT c_counter_binary_0
  PORT (
    CLK : IN STD_LOGIC;
    CE : IN STD_LOGIC;
    Q : OUT STD_LOGIC_VECTOR(13 DOWNTO 0)
  );
	END COMPONENT;

	COMPONENT fifo_generator_0
		PORT (
			srst 		: IN STD_LOGIC;
			wr_clk 		: IN STD_LOGIC;
			rd_clk 		: IN STD_LOGIC;
			din 		: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			wr_en 		: IN STD_LOGIC;
			rd_en 		: IN STD_LOGIC;
			dout 		: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			full 		: OUT STD_LOGIC;
			wr_ack 		: OUT STD_LOGIC;
			empty 		: OUT STD_LOGIC;
			valid 		: OUT STD_LOGIC;
			wr_rst_busy : OUT STD_LOGIC;
			rd_rst_busy : OUT STD_LOGIC
		);
	END COMPONENT;
	
	COMPONENT vio_0
  PORT (
    clk : IN STD_LOGIC;
    probe_in0 : IN STD_LOGIC_VECTOR(13 DOWNTO 0)
  );

END COMPONENT;

COMPONENT vio_1
  PORT (
    clk : IN STD_LOGIC;
    probe_in0 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    probe_in1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe_in2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
  );
END COMPONENT;
	
	---------------- PSINCDEC ----------------------
	signal	w_Psincdec_1	:	std_logic	:= '1';
	signal	w_Psincdec_2	:	std_logic	:= '0';
	---------------- Debouncer ----------------------
	signal	w_Reset			:	std_logic;
	signal	w_Rst_Debouncer	:	std_logic;
	---------------- CUT ----------------------
	signal	w_CE_CUT		:	std_logic;
	signal	w_CUT_Error		:	std_logic;
	---------------- Toggle Counter ----------------------
	signal	w_CE_Cntr		:	std_logic;
	signal	w_CLR_Cntr		:	std_logic;
	signal	w_Cntr_Out		:	std_logic_vector(g_Counter_Width - 1 downto 0);
	---------------- Debug ----------------------
	signal	w_Trigger		:	std_logic;
	signal	r_Mode			:	std_logic_vector(1 downto 0);
	signal	w_cntr			:	std_logic_vector(15 downto 0);
	---------------- UART ----------------------
	signal	w_Busy			:	std_logic;
	signal	w_Send			:	std_logic;
	signal	w_Done			:	std_logic;
	signal	r_UART_Data_In	:	std_logic_vector(7 downto 0);
	---------------- FIFO ----------------------
	signal	w_WR_En   		:	std_logic;
	signal	w_RD_En   		:	std_logic;
	signal	r_FIFO_Out		:	std_logic_vector(g_Counter_Width - 1 downto 0); 
	signal	w_Full    		:	std_logic; 
	signal	w_WR_ACK        :	std_logic;
	signal	w_Empty   		:	std_logic;
	signal	w_Valid   		:	std_logic;
	---------------------------------
	signal	w_cntr_rd		:	std_logic_vector(13 downto 0)	:= (others => '0');
	signal	w_cntr_wr		:	std_logic_vector(13 downto 0)	:= (others => '0');
	signal	w_LED_1			:	std_logic;

begin

--    Debouncer_Inst:	entity work.debounce
--		generic map(
--			clk_freq	=>	100e6,
--			stable_time	=>	10
--		)
--		port map(
--			clk		=>	i_Clk_100,
--			reset_n	=>	w_Rst_Debouncer,
--			button	=>	i_Reset,
--			result	=>	w_Reset	
--		);
	
	CUT_Inst:	entity work.CUT
		port map(
			i_Clk_Launch	=>	i_Clk_Launch,
		    i_Clk_Sample	=>	i_Clk_Sample,
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
				i_Clk_Launch	=>	i_Clk_Launch,
				i_Clk_Sample	=>	i_Clk_Sample,	
		        i_Psclk1		=>	i_Clk_100,
		        i_Psclk2		=>	i_Clk_100,
		        i_Start			=>	i_Start,
		        i_Reset			=>	i_Reset,
		        i_Locked1		=>	i_Locked_1,
		        i_Locked2		=>	i_Locked_2,
		        i_Locked3		=>	i_Locked_3,
		        i_Psdone1		=>	i_Psdone_1,
		        i_Psdone2		=>	i_Psdone_2,
		        i_Mode			=>	r_Mode,
		        o_Trigger		=>	w_Trigger,
		        o_Psen1			=>	o_Psen_1,
		        o_Psen2			=>	o_Psen_2,
		        o_Psincdec1		=>	w_Psincdec_1,
		        o_Psincdec2		=>	w_Psincdec_2,
		        o_Reset1		=>	o_Reset_1,
		        o_Reset2		=>	o_Reset_2,
		        o_Reset3		=>	o_Reset_3,
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
			i_Clk_Sample	=>	i_Clk_Sample,
			i_Clk_Launch	=>	i_Clk_Launch,
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
			i_Clk_Wr	=>	i_Clk_Launch,
			i_Clk_Rd	=>	i_Clk_100,
			i_Reset		=>	i_Reset,
			i_Din		=>	w_Cntr_Out,
			i_Last		=>	w_LED_1,
			i_Wr_En		=>	w_Trigger,
			o_Wr_Ack	=>	open,
			o_Full		=>	open,
			o_Empty		=>	open,
			o_Tx		=>	o_Tx
		);
	
--	w_Rst_Debouncer	<=	not i_Start;
--	r_Mode			<=	i_Mode;
	o_LED_1			<=	w_LED_1;
	o_LED_3			<=	w_Empty;

end architecture;