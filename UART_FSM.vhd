library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.my_package.all;
----------------------------------
entity UART_FSM is
	port(
		i_Clk			:	in		std_logic;
		i_Reset			:	in		std_logic;
		i_Data_in		:	in		std_logic_vector;
		i_Enable		:	in		std_logic;
		i_Busy			:	in		std_logic;
		i_Last			:	in		std_logic;
		i_Empty			:	in		std_logic;
		o_Send			:	out 	std_logic;
		o_Data_Out		:	out		std_logic_vector(7 downto 0);
		o_Busy			:	out		std_logic;
		o_Done			:	out		std_logic
	);
end entity;
----------------------------------
architecture behavioral of UART_FSM	is

	
	------------------ Constants ---------------------------
	constant	c_Num_Bytes	:	integer	:=	integer(ceil(real(i_Data_in'length) / 8.0));
	------------------ Counters ---------------------------
	signal	r_Cntr			:	integer range 0 to c_Num_Bytes	:= c_Num_Bytes;
	signal	r_END_Cntr		:	integer range 0 to 2	:= 0;
	------------------ Types ---------------------------
	type t_my_states is (UART_IDLE, UART_SEND, UART_DECISION, s4, UART_END, UART_END_DECISION);
	------------------ Internal Regs ---------------------------
	signal	r_State			:	t_my_states	:= UART_IDLE;
	signal	r_Last			:	std_logic;
	signal	r_Last_2		:	std_logic;
	signal	r_Data_in		:	std_logic_vector(i_Data_in'length - 1 downto 0);
	signal	r_Enable		:	std_logic;
	signal	r_Enable_2		:	std_logic;
	signal	r_Busy			:	std_logic;
	signal	r_Busy_Out		:	std_logic	:= '0';
	signal	r_Send			:	std_logic	:= '0';
	signal	r_Data_Out		:	std_logic_vector(7 downto 0);
	signal	r_Done			:	std_logic	:= '0';
	------------------ Buffer ---------------------------
	signal	w_Buffer		:	std_logic_vector(8*c_Num_Bytes-1 downto 0);
	------------------ END Trans. ------------------------
	signal	w_END_Word		:	my_array(0 to 2)(7 downto 0)	:= (x"45", x"4E", x"44");

begin

	process(i_Clk, i_Reset)
	
	begin
	
		if (i_Reset = '1') then
			r_State	<=	UART_IDLE;
			r_Done	<=	'0';
		elsif (i_Clk'event and i_Clk = '1') then
		
			r_Busy			<=	i_Busy;
			r_Last			<=	i_Last;
			r_Last_2		<=	r_Last;
			r_Enable		<=	i_Enable;
			r_Enable_2		<=	r_Enable;
			--------- Default ----------
			r_Send	<=	'0';
			
			case r_State is
			
			when	UART_IDLE		=>
				r_Busy_Out	<=	'0';				
				
				if (r_Enable = '0' and i_Enable = '1') then
					r_Busy_Out		<=	'1';
					r_Data_in		<=	i_Data_in;
					r_Done			<=	'0';
					r_Cntr			<=	c_Num_Bytes;
					r_State			<=	UART_SEND;
				elsif (i_Last = '1' and i_Empty = '1') then
					r_Busy_Out		<=	'1';
					r_Done			<=	'0';
					r_END_Cntr		<=	0;
					r_State			<=	UART_END;				
				end if;
			when	UART_SEND			=>
				if (i_Busy = '0') then
					r_Data_Out	<=	w_Buffer(8 * r_Cntr - 1 downto 8 * (r_Cntr - 1));
					r_Cntr		<=	r_Cntr - 1;
					r_Send		<=	'1';
					r_State		<=	UART_DECISION;
				end if;
			when	s4					=>
				r_State		<=	UART_DECISION;
			when	UART_DECISION		=>
				if (r_Cntr > 0) then
					r_State	<=	UART_SEND;
				else
					r_Done	<=	'1';
					r_State	<=	UART_IDLE;
				end if;
			when	UART_END			=>
				if (i_Busy = '0') then
					r_Send			<=	'1';
					r_Data_Out		<=	w_END_Word(r_END_Cntr);
					r_State			<=	UART_END_DECISION;
				end if;						
			when	UART_END_DECISION 	=>
				if (r_END_Cntr < 2) then
					r_END_Cntr	<=	r_END_Cntr + 1;
					r_State		<=	UART_END;
				end if;
			when	others				=>
				r_state	<=	UART_IDLE;
			end case;
		
		end if;
	
	end process;
	
	w_Buffer	<=	std_logic_vector(resize(unsigned(r_Data_in), 8 * c_Num_Bytes));
	o_Send		<=	r_Send;
	o_Data_Out	<=	r_Data_Out;
	o_Busy		<=	r_Busy_Out;
	o_Done		<=	r_Done;

end architecture;