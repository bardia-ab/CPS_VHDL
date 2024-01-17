library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use work.my_package.all;
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
		o_Tx		:	out		std_logic
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
--	signal	w_UART_Din_2		:	my_array(0 to 2)(7 downto 0)	:= (x"45", x"4E", x"44");
	signal	w_UART_Done			:	std_logic;
	signal	r_UART_Done			:	std_logic;
	signal	w_Busy_UART_FASM	:	std_logic;
	
	signal	w_Full_Lock			:	std_logic	:= '0';
		
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
			i_Last			=>	i_Last,
			i_Empty			=>	w_Empty,
			o_Send          =>	w_Send,
			o_Data_Out      =>	w_UART_Din,
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

	Edge_Det_Inst2	:	entity work.Edge_Detector
		generic map( g_Rising_Edge => '1')
		port map(
			i_Clk		=>	i_Clk_Wr,
			i_Reset		=>	i_Reset,
			i_Sig		=>	i_Wr_En,
			o_Result	=>	r_Wr_En
	);
	
	process(i_Clk_Rd, i_Reset)
	begin
	
		if (i_Reset = '1') then
			r_State	<=	s0;
		elsif (i_Clk_Rd'event and i_Clk_Rd = '1') then
			w_rd_en	<=	'0';
			
			case	r_State	is
				when	s0		=>
					if (w_Empty = '0') then
						r_State	<=	s1;
					end if;
				when	s1		=>
					if (w_Busy_UART_FASM = '0') then
						w_rd_en	<=	'1';
						r_State	<=	s2;	
					end if;
				when	s2		=>
					if (w_Busy_UART_FASM = '1') then
						r_State	<=	s0;
					end if;
				when	others	=>	
					r_State	<=	s0;
			end case;
						
		end if;	
	end process;
		
	process(i_Clk_Wr)
	begin
		if rising_edge(i_Clk_Wr) then
			w_Full_Lock	<=	w_Full_Lock or w_Full;
		end if;
	
	end process;
	
	o_Wr_Ack	<=	w_Wr_Ack;
	o_Empty		<=	w_Empty;
	o_Full		<=	w_Full_Lock;
	
end architecture;