library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
----------------------------------
entity UART_FSM is
--	generic(
--		g_Shift_Value_Length	:	integer	:= 14;
--		g_Capture_Length		:	integer	:= 50
--	);
	port(
		i_Clk			:	in		std_logic;
--		i_Shift_Value	:	in		std_logic_vector(g_Shift_Value_Length-1 downto 0);
--		i_Capture		:	in		std_logic_vector(g_Capture_Length-1 downto 0);
		i_Data_in		:	in		std_logic_vector;
		i_Enable		:	in		std_logic;
		i_Busy			:	in		std_logic;
		o_Send			:	out 	std_logic;
		o_Data_Out		:	out		std_logic_vector(7 downto 0);
		o_Done			:	out		std_logic
	);
end entity;
----------------------------------
architecture behavioral of UART_FSM	is

	
	------------------ Constants ---------------------------
--	constant	c_Num_Bytes	:	integer	:=	integer(ceil(real(g_Shift_Value_Length + g_Capture_Length) / 8.0));
	constant	c_Num_Bytes	:	integer	:=	integer(ceil(real(i_Data_in'length) / 8.0));
	------------------ Counters ---------------------------
	signal	r_Cntr			:	integer range 0 to c_Num_Bytes	:= c_Num_Bytes;
	------------------ Types ---------------------------
	type t_my_states is (UART_IDLE, UART_SEND, UART_DECISION, s4);
	------------------ Internal Regs ---------------------------
	signal	r_State			:	t_my_states	:= UART_IDLE;
--	signal	r_Shift_Value	:	std_logic_vector(g_Shift_Value_Length-1 downto 0);
--	signal	r_Capture		:	std_logic_vector(g_Capture_Length-1 downto 0);
	signal	r_Data_in		:	std_logic_vector(i_Data_in'length - 1 downto 0);
	signal	r_Enable		:	std_logic;
	signal	r_Enable_2		:	std_logic;
	signal	r_Busy			:	std_logic;
	signal	r_Send			:	std_logic;
	signal	r_Data_Out		:	std_logic_vector(7 downto 0);
	signal	r_Done			:	std_logic;
	------------------ Buffer ---------------------------
	signal	w_Buffer		:	std_logic_vector(8*c_Num_Bytes-1 downto 0);

begin

	process(i_Clk)
	
	begin
	
		if (i_Clk'event and i_Clk = '1') then
		
			r_Busy			<=	i_Busy;
			r_Enable		<=	i_Enable;
			r_Enable_2		<=	r_Enable;
			--------- Default ----------
			r_Send	<=	'0';
			
			case r_State is
			
			when	UART_IDLE		=>
									if (r_Enable_2 = '0' and r_Enable = '1') then
--										r_Shift_Value	<=	i_Shift_Value;
--										r_Capture		<=	i_Capture;
										r_Data_in		<=	i_Data_in;
										r_Done			<=	'0';
										r_Cntr			<=	c_Num_Bytes;
										r_State			<=	UART_SEND;
									end if;
			when	UART_SEND		=>
									if (r_Busy = '0') then
										r_Data_Out	<=	w_Buffer(8 * r_Cntr - 1 downto 8 * (r_Cntr - 1));
										r_Cntr		<=	r_Cntr - 1;
										r_Send		<=	'1';
										r_State		<=	s4;
									end if;
			when	s4	=>
									r_State		<=	UART_DECISION;
			when	UART_DECISION	=>
									if (r_Cntr > 0) then
										r_State	<=	UART_SEND;
									else
										r_Done	<=	'1';
										r_State	<=	UART_IDLE;
									end if;
			when	others			=>
									r_state	<=	UART_IDLE;
			end case;
		
		end if;
	
	end process;
	
	w_Buffer	<=	std_logic_vector(resize(unsigned(r_Data_in), 8 * c_Num_Bytes));
	o_Send		<=	r_Send;
	o_Data_Out	<=	r_Data_Out;
	o_Done		<=	r_Done;

end architecture;