library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_package.all;
use	IEEE.math_real.all;
-------------------------------
ENTITY FIFO_UART IS
	generic (
		g_Data_Width	:	integer;
		g_Parity		:	std_logic_vector(0 downto 0);
		g_Data_Bits		:	integer;
		g_Baud_Rate		:	integer;
		g_Frequency		:	integer
	);
	port(
		i_Clk_Wr	:	in		std_logic;
		i_Clk_Rd	:	in		std_logic;
		i_Reset		:	in		std_logic;
		i_Din		:	in		std_logic_vector(g_Data_Width - 1 downto 0);
		i_Wr_En		:	in		std_logic;
		i_Last		:	in		std_logic;
		o_Wr_Ack	:	out		std_logic;
		o_Full		:	out		std_logic;
		o_Empty		:	out		std_logic;
		o_Tx		:	out		std_logic;
		o_LED_2		:	out		std_logic;
		o_LED_3		:	out		std_logic
	);
END ENTITY;
-------------------------------
architecture rtl of FIFO_UART is


	COMPONENT fifo_generator_0
		PORT (
			srst 		: IN 	STD_LOGIC;
			wr_clk 		: IN 	STD_LOGIC;
			rd_clk 		: IN 	STD_LOGIC;
			din 		: IN 	STD_LOGIC_VECTOR(g_Data_Width - 1 DOWNTO 0);
			wr_en 		: IN 	STD_LOGIC;
			rd_en 		: IN 	STD_LOGIC;
			dout 		: OUT 	STD_LOGIC_VECTOR(g_Data_Width - 1 DOWNTO 0);
			full 		: OUT 	STD_LOGIC;
			wr_ack 		: OUT 	STD_LOGIC;
			empty 		: OUT 	STD_LOGIC;
			valid 		: OUT 	STD_LOGIC;
			wr_rst_busy : OUT 	STD_LOGIC;
			rd_rst_busy : OUT 	STD_LOGIC
		);
	END COMPONENT;

		constant	Bit_Width		:	integer	:=	integer(ceil(real(g_Frequency) / real(g_Baud_Rate)));
	------------------- Type ------------------------
	type t_States is (s0, s1, s2, s3);
	signal	r_State				:	t_States	:= s0;
	------------------- FIFO ------------------------
	signal	r_Dout				:	std_logic_vector(g_Data_Width - 1 downto 0);
	signal	w_Rd_En				:	std_logic;
	signal	r_Wr_En				:	std_logic;
	signal	w_Full				:	std_logic;
	signal	w_Wr_Ack				:	std_logic;
	signal	w_Empty				:	std_logic;
	signal	r_Empty				:	std_logic;
	signal	w_Valid				:	std_logic;
	------------------- UART ------------------------
	signal	w_Busy				:	std_logic;
	signal	r_Busy				:	std_logic;
	signal	w_Send				:	std_logic;
	signal	w_Send_1			:	std_logic;
	signal	w_Send_2			:	std_logic;
	signal	r_Send_2			:	std_logic;
	signal	w_UART_Din			:	std_logic_vector(7 downto 0);
	signal	w_UART_Din_1		:	std_logic_vector(7 downto 0);
	signal	w_UART_Din_2		:	my_array(0 to 2)(7 downto 0)	:= (x"45", x"4E", x"44");
	signal	w_UART_Done			:	std_logic;
	signal	r_UART_Done			:	std_logic;
	signal	w_Busy_UART_FASM	:	std_logic;
	
	signal	w_Mux_Slct			:	std_logic				:= '0';
	signal	r_End_Cntr			:	integer	range 0 to 2	:= 0;
	signal	r_lock				:	std_logic				:= '0';
	signal	r_lock_2			:	std_logic				:= '0';
	signal	first_flag			:	std_logic				:= '0';
	signal	r_LED_2				:	std_logic				:= '0';
	signal	r_LED_3				:	std_logic				:= '0';
	
		
begin

	
	FIFO_Inst : fifo_generator_0
		PORT MAP (
			srst 		=> '0',
			wr_clk 		=> i_Clk_Wr,
			rd_clk 		=> i_Clk_Rd,
			din 		=> i_Din,
			wr_en 		=> r_Wr_En,
			rd_en 		=> w_Rd_En,
			dout 		=> r_Dout,
			full 		=> w_Full,
			wr_ack 		=> w_Wr_Ack,
			empty 		=> w_Empty,
			valid 		=> w_Valid,
			wr_rst_busy => open,
			rd_rst_busy => open
		);
		
	UART_Controller:	entity work.UART_FSM
		port map(
			i_Clk			=>	i_Clk_Rd,
			i_Reset			=>	i_Reset,
			i_Data_in       =>	r_Dout,
			i_Enable        =>	w_Valid,
			i_Busy          =>	w_Busy,
			o_Send          =>	w_Send_1,
			o_Data_Out      =>	w_UART_Din_1,
			o_Busy			=>	w_Busy_UART_FASM,
			o_Done          =>	w_UART_Done
		);

	UART_Tx_Inst:	entity work.UART_Tx
	generic map(
		g_Parity	=>	g_Parity,
		g_N_Bits	=>	g_Data_Bits,
		g_Baud_Rate	=>	g_Baud_Rate,
		g_Frequency	=>	g_Frequency
	)
	port map(
		i_Clk		=>	i_Clk_Rd,
		i_Send		=>	w_Send,
		i_Data_In	=>	w_UART_Din,
		o_Busy      =>	w_Busy,
		o_Tx    	=>	o_Tx
	);
	
--	Edge_Det_Inst1	:	entity work.Edge_Detector
--		generic map( g_Rising_Edge => '1')
--		port map(
--			i_Clk		=>	i_Clk_Rd,
--			i_Reset		=>	i_Reset,
--			i_Sig		=>	w_UART_Done,
--			o_Result	=>	r_UART_Done
--	);
	
	
	Edge_Det_Inst2	:	entity work.Edge_Detector
		generic map( g_Rising_Edge => '1')
		port map(
			i_Clk		=>	i_Clk_Wr,
			i_Reset		=>	i_Reset,
			i_Sig		=>	i_Wr_En,
			o_Result	=>	r_Wr_En
	);
	
	Edge_Det_Inst3	:	entity work.Edge_Detector
		generic map( g_Rising_Edge => '0')
		port map(
			i_Clk		=>	i_Clk_Rd,
			i_Reset		=>	i_Reset,
			i_Sig		=>	w_Empty,
			o_Result	=>	r_Empty
	);

	process(i_Clk_Rd)
	begin
	
		if (i_Clk_Rd'event and i_Clk_Rd = '1') then
			w_rd_en	<=	'0';
			
			if (w_Empty = '0') then
				if (w_Busy_UART_FASM = '0' and w_UART_Done = '0') then
					w_rd_en	<=	'1';	-- first Data
				elsif (w_Busy_UART_FASM = '0' and w_UART_Done = '1') then
					w_rd_en	<=	'1';
				end if;
			end if;
			
		end if;	
	end process;
	
	process(i_Clk_Wr)
	begin
	
		if (i_Clk_Wr'event and i_Clk_Wr = '1') then
			r_lock	<=	w_full or r_lock;
		end if;
	
	end process;
	
	process(i_Clk_Rd, i_Reset)
	begin
	
		if (i_Reset = '1') then
			first_flag	<=	'0';
			r_Lock_2	<=	'0';
		elsif (i_Clk_Rd'event and i_Clk_Rd = '1') then
			if (first_flag = '0' and r_Empty = '1') then
				first_flag	<=	'1';
			end if;
			
			r_lock_2	<=	(w_Empty or r_lock_2) and (not i_Last) and first_flag;
		end if;
	
	end process;
	
	
--	process(i_Reset, i_Clk_Rd)
--	begin
	
--		if (i_Reset = '1') then
		
--			w_Mux_Slct	<=	'0';
--			r_End_Cntr	<=	0;
--			r_State		<=	s0;
			
--		elsif (i_Clk_Rd'event and i_Clk_Rd = '1') then
			
--			w_Send_2	<=	'0';
--			r_Busy		<=	w_Busy;
			
--			case r_State	is
--				when	s0		=>
--					w_Mux_Slct	<=	'0';
					
--					if (w_Busy_UART_FASM = '0' and w_UART_Done = '1' and w_Empty = '1' and i_Last = '1') then
--						w_Mux_Slct	<=	'1';
--						r_End_Cntr	<=	0;
--						r_State		<=	s1;
--					end if;
					
--				when	s1		=>
				
--					if (w_Busy = '0') then
--						w_Send_2	<=	'1';
--						r_State		<=	s2;							
--					end if;
				
--				when	s2		=>
				
--					if (r_End_Cntr < 2) then
--						if (w_Busy = '1') then
--							r_End_Cntr	<=	r_End_Cntr + 1;
--							r_State		<=	s1;	
--						end if;
--					else
--						r_End_Cntr	<=	0;
--						r_State		<=	s3;											
--					end if;
					
--				when	s3		=>
--					null;				
--				when	others	=>
--					null;
--			end case;		
--		end if;
	
--	end process;
	
		
	w_Send		<=	w_Send_1 		when w_Mux_Slct = '0' 	else w_Send_2;	
	w_UART_Din	<=	w_UART_Din_1 	when w_Mux_Slct = '0' 	else w_UART_Din_2(r_End_Cntr);
	
	o_Wr_Ack	<=	w_Wr_Ack;
	o_Empty		<=	w_Empty;
	o_Full		<=	w_Full;
--	o_Full		<=	r_lock;
	o_LED_2		<=	r_lock;
	o_LED_3		<=	r_lock_2;
--	o_LED_2		<=	r_LED_2;
--	o_LED_3		<=	r_LED_3;
	
end architecture;