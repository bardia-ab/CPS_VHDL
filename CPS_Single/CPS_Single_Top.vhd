library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;
------------------------------------
entity CPS_Single_Top is
	generic(
		g_O2			:	integer	:= 16;	
		g_Counter_Width	:	integer	:= 16;
		g_N_Sets		:	integer	:= 15;
		g_N_Segments	:	integer	:= 1;
		g_PipeLineStage	:	integer	:= 1
--		g_Mode			:	std_logic_vector(1 downto 0)	:= "00"	-- 0X: All Trans.  10: Falling Trans.  11: Rising Trans.
	);
	port(
		i_Clk_In_P	:	in		std_logic;
		i_Clk_In_N	:	in		std_logic;
		i_Reset		:	in		std_logic;
		i_Start		:	in		std_logic;
		i_Mode		:	in		std_logic_vector(1 downto 0);
		o_Tx		:	out		std_logic;
		o_LED_1		:	out		std_logic;
		o_LED_2		:	out		std_logic
	);
end entity;
------------------------------------
architecture behavioral of CPS_Single_Top is

	component clk_wiz_3
		port
		(	-- Clock in ports
			-- Clock out ports
			Clk_100           : out    std_logic;
			-- Status and control signals
			reset             : in     std_logic;
			locked            : out    std_logic;
			clk_in1_p         : in     std_logic;
			clk_in1_n         : in     std_logic
		);
	end component;
		
	component clk_wiz_0
		port
		(	-- Clock in ports
			-- Clock out ports
			Clk_Launch_In     : out    std_logic;
			Clk_Sample_In     : out    std_logic;
			-- Dynamic phase shift ports
			psclk             : in     std_logic;
			psen              : in     std_logic;
			psincdec          : in     std_logic;
			psdone            : out    std_logic;
			-- Status and control signals
			reset             : in     std_logic;
			locked            : out    std_logic;
			clk_in1           : in     std_logic
		);
	end component;
	
	component clk_wiz_1
		port
		(	-- Clock in ports
			-- Clock out ports
			o_Clk_Launch      : out    std_logic;
			-- Dynamic phase shift ports
			psclk             : in     std_logic;
			psen              : in     std_logic;
			psincdec          : in     std_logic;
			psdone            : out    std_logic;
			-- Status and control signals
			reset             : in     std_logic;
			locked            : out    std_logic;
			clk_in1           : in     std_logic
		);
	end component;
	
	component clk_wiz_2
		port
		(	-- Clock in ports
			-- Clock out ports
			o_Clk_Sample      : out    std_logic;
			  -- Dynamic phase shift ports
			psclk             : in     std_logic;
			psen              : in     std_logic;
			psincdec          : in     std_logic;
			psdone            : out    std_logic;
			-- Status and control signals
			reset             : in     std_logic;
			locked            : out    std_logic;
			clk_in1           : in     std_logic
		);
	end component;
	
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
    Q : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
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

begin

	IBUFDS_inst : IBUFDS
		port map (
			O 	=> w_Clk_300,   -- 1-bit output: Buffer output
			I 	=> i_Clk_In_P,   -- 1-bit input: Diff_p buffer input (connect directly to top-level port)
			IB 	=> i_Clk_In_N  -- 1-bit input: Diff_n buffer input (connect directly to top-level port)
		);
		
	BUFGCE_DIV_inst : BUFGCE_DIV
		generic map (
			BUFGCE_DIVIDE 	=> 3,              -- 1-8
			IS_CE_INVERTED 	=> '0',           -- Optional inversion for CE
			IS_CLR_INVERTED => '0',          -- Optional inversion for CLR
			IS_I_INVERTED 	=> '0',            -- Optional inversion for I
			SIM_DEVICE 		=> "ULTRASCALE_PLUS"  -- ULTRASCALE, ULTRASCALE_PLUS
		)
		port map (
			O 		=> w_Clk_100,     -- 1-bit output: Buffer
			CE 		=> '1',   -- 1-bit input: Buffer enable
			CLR 	=> '0', -- 1-bit input: Asynchronous clear
			I 		=> w_Clk_300      -- 1-bit input: Buffer
		);

--	MMCM_0 : clk_wiz_3
--		port map ( 
--			Clk_100 	=> w_Clk_100,
--			reset 		=> '0',
--			locked 		=> open,
--			clk_in1_p 	=> i_Clk_In_P,
--			clk_in1_n 	=> i_Clk_In_N
--		);
			
	MMCM_1 : clk_wiz_0
		port map ( 
			Clk_Launch_In 	=> w_Clk_Launch_In,
			Clk_Sample_In 	=> w_Clk_Sample_In,
			psclk 			=> w_Clk_100,
			psen 			=> w_Psen_1,
			psincdec 		=> w_Psincdec_1,
			psdone 			=> w_Psdone_1,
			reset 			=> w_Reset_1,
			locked 			=> w_Locked_1,
			clk_in1 		=> w_Clk_100
		);

	MMCM_2 : clk_wiz_1
		port map ( 
			o_Clk_Launch 	=> w_Clk_Launch,
			psclk 			=> w_Clk_100,
			psen 			=> w_Psen_2,
			psincdec 		=> w_Psincdec_2,
			psdone 			=> w_Psdone_2,
			reset 			=> w_Reset_2,
			locked 			=> w_Locked_2,
			clk_in1 		=> w_Clk_Launch_In
		);

	MMCM_3 : clk_wiz_2
		port map ( 
			o_Clk_Sample 	=> w_Clk_Sample,
			psclk 			=> w_Clk_100,
			psen 			=> '0',
			psincdec 		=> '0',
			psdone 			=> open,
			reset 			=> w_Reset_3,
			locked 			=> w_Locked_3,
			clk_in1 		=> w_Clk_Sample_In
		);
	
	Debouncer_Inst:	entity work.debounce
		generic map(
			clk_freq	=>	100e6,
			stable_time	=>	10
		)
		port map(
			clk		=>	w_Clk_100,
			reset_n	=>	w_Rst_Debouncer,
			button	=>	i_Reset,
			result	=>	w_Reset	
		);
	
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
		        i_Start			=>	i_Start,
		        i_Reset			=>	w_Reset,
		        i_Locked1		=>	w_Locked_1,
		        i_Locked2		=>	w_Locked_2,
		        i_Locked3		=>	w_Locked_3,
		        i_Psdone1		=>	w_Psdone_1,
		        i_Psdone2		=>	w_Psdone_2,
		        i_Mode			=>	r_Mode,
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
		        o_LED1			=>	o_LED_1,
		        o_LED2			=>	o_LED_2		
		);
		
	Counter_Inst:	entity work.Toggle_Counter
		generic map(
			g_Width	=>	g_Counter_Width
		)
		port map(
			i_Clk			=>	w_Clk_Sample,
		    i_CE	        =>	w_CE_Cntr,
		    i_input	        =>	w_CUT_Error,
		    i_SCLR	        =>	w_CLR_Cntr,
		    i_Mode			=>	r_Mode,
		    o_Q		        =>	w_Cntr_Out
		);
		
	UART_Controller:	entity work.UART_FSM
		port map(
			i_Clk			=>	w_Clk_Sample,
			i_Data_in       =>	w_Cntr_Out,
			i_Enable        =>	w_Trigger,
			i_Busy          =>	w_Busy,
			o_Send          =>	w_Send,
			o_Data_Out      =>	r_UART_Data_In,
			o_Done          =>	w_Done
		);

	UART_Tx_Inst:	entity work.UART_Tx
	generic map(
		PARITY		=>	"0",
		Data_Bits	=>	8,
		Baud_Rate	=>	921600,
		Frequency	=>	100e6
	)
	port map(
		Clk			=>	w_Clk_Sample,
		Send		=>	w_Send,
		Data_In     =>	r_UART_Data_In,
		Busy        =>	w_Busy,
		Data_Out    =>	o_Tx
	);
	
--	ILA_Inst : ila_0
--		PORT MAP (
--			clk 		=> w_Clk_Sample,
--			probe0(0) 	=> w_Trigger,
--			probe1 		=> w_Cntr_Out
--	);

--Cntr : c_counter_binary_0
--  PORT MAP (
--    CLK => w_Clk_Sample,
--    CE => '1',
--    Q => w_cntr
--  );


	w_Rst_Debouncer	<=	not i_Start;
	r_Mode			<=	i_Mode;

end architecture;