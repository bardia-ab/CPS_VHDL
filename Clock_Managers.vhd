library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;
----------------------------------
entity Clock_Managers is
    port(
        i_Clk_In_P      :   in      std_logic;
        i_Clk_In_N      :   in      std_logic;
        i_Reset_1       :   in      std_logic;   
        i_Reset_2       :   in      std_logic;
        i_Reset_3       :   in      std_logic;
        i_Psen_1        :   in      std_logic;
        i_Psen_2        :   in      std_logic;
        i_Psincdec_1    :   in      std_logic;
        i_Psincdec_2    :   in      std_logic;
        o_Clk_100       :   out     std_logic;
        o_Clk_Launch    :   out     std_logic;
        o_Clk_Sample    :   out     std_logic;
        o_Locked_1      :   out     std_logic;
        o_Locked_2      :   out     std_logic;
        o_Locked_3      :   out     std_logic;
        o_Psdone_1      :   out     std_logic;
        o_Psdone_2      :   out     std_logic
    );
end entity;
----------------------------------
architecture rtl of Clock_Managers is

	component clk_wiz_0
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
		
	component clk_wiz_1
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
	
	component clk_wiz_2
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
	
	component clk_wiz_3
		port
		(	-- Clock in ports
			-- Clock out ports
			o_Clk_Sample      : out    std_logic;
--			  -- Dynamic phase shift ports
--			psclk             : in     std_logic;
--			psen              : in     std_logic;
--			psincdec          : in     std_logic;
--			psdone            : out    std_logic;
			-- Status and control signals
			reset             : in     std_logic;
			locked            : out    std_logic;
			clk_in1           : in     std_logic
		);
	end component;

    ---------------- Clock Buffers ----------------------
	signal	w_Clk_300	    :	std_logic;
	signal	w_Clk_100	    :	std_logic;
	---------------- MMCM_1 ----------------------
	signal	w_Clk_Launch_In	:	std_logic;
	signal	w_Clk_Sample_In	:	std_logic;


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

--	MMCM_0 : clk_wiz_0
--		port map ( 
--			Clk_100 	=> w_Clk_100,
--			reset 		=> '0',
--			locked 		=> open,
--			clk_in1_p 	=> i_Clk_In_P,
--			clk_in1_n 	=> i_Clk_In_N
--		);
			
	MMCM_1 : clk_wiz_1
		port map ( 
			Clk_Launch_In 	=> w_Clk_Launch_In,
			Clk_Sample_In 	=> w_Clk_Sample_In,
			psclk 			=> w_Clk_100,
			psen 			=> i_Psen_1,
			psincdec 		=> i_Psincdec_1,
			psdone 			=> o_Psdone_1,
			reset 			=> i_Reset_1,
			locked 			=> o_Locked_1,
			clk_in1 		=> w_Clk_100
		);

	MMCM_2 : clk_wiz_2
		port map ( 
			o_Clk_Launch 	=> o_Clk_Launch,
			psclk 			=> w_Clk_100,
			psen 			=> i_Psen_2,
			psincdec 		=> i_Psincdec_2,
			psdone 			=> o_Psdone_2,
			reset 			=> i_Reset_2,
			locked 			=> o_Locked_2,
			clk_in1 		=> w_Clk_Launch_In
		);

	MMCM_3 : clk_wiz_3
		port map ( 
			o_Clk_Sample 	=> o_Clk_Sample,
--			psclk 			=> w_Clk_100,
--			psen 			=> '0',
--			psincdec 		=> '0',
--			psdone 			=> open,
			reset 			=> i_Reset_3,
			locked 			=> o_Locked_3,
			clk_in1 		=> w_Clk_Sample_In
		);

    o_Clk_100   <=  w_Clk_100;

end architecture;