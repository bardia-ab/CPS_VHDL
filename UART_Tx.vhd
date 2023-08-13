library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use	IEEE.math_real.all;
use IEEE.std_logic_misc.all;
-----------------------------------------
entity UART_Tx is
	generic(
		PARITY		:	std_logic_vector(0 downto 0)	:=	"0";
		Data_Bits	:	integer							:=	8;
		Baud_Rate	:	integer							:=	9600;
		Frequency	:	integer							:=	1e8		-- In Hertz
	);
	port(
		Clk			:	in		std_logic;
		Send		:	in		std_logic;
		Data_In		:	in		std_logic_vector((Data_Bits - 1) downto 0);
		Busy		:	out		std_logic;
		Data_Out	:	out		std_logic
	);
end entity;
-----------------------------------------
Architecture Behavioral of UART_Tx is

	-------- Types --------
	type UART_STATE is (UART_IDLE, UART_TRANSMIT);
	
	-------- Constants --------
	constant	Bit_Width		:	integer											:=	integer(ceil(real(Frequency) / real(Baud_Rate)));
	constant	Packet_Width	:	integer											:=	Data_Bits + 2 + to_integer(unsigned(PARITY));
	-------- Internal Signals --------
	signal	state				:	UART_STATE										:=	UART_IDLE;
	signal	Parity_Bit			:	std_logic										:=	'0';
	signal	Packet				:	std_logic_vector((Packet_Width - 1) downto 0)	:=	(others => '0');
	signal	Send_Reg			:	std_logic										:=	'0';
	signal	Data_In_Reg			:	std_logic_vector((Data_Bits - 1) downto 0)		:=	(others => '0');
	signal	Busy_Int			:	std_logic										:=	'0';
	signal	Data_Out_Int		:	std_logic										:=	'1';
	
	-------- Counters --------
	signal	Bit_Index_Counter	:	integer range 0 to (Packet_Width - 1)			:=	0;
	signal	Bit_Width_Counter	:	integer range 1 to Bit_Width					:=	1;

begin

	process(Clk)
	
	begin
	
		if (Clk'event and Clk = '1') then
			Send_Reg	<=	Send;
			
			case	state	is
			
			when	UART_IDLE		=>
							Busy_Int		<=	'0';
							Data_Out_Int	<=	'1';
							
							if (Send_Reg = '0' and Send = '1') then
								Data_In_Reg	<=	Data_In;
								Busy_Int	<=	'1';
								state		<=	UART_TRANSMIT;
							end if;
							
			when	UART_TRANSMIT	=>
							Data_Out_Int	<=	Packet(Bit_Index_Counter);	
							
							if (Bit_Width_Counter < Bit_Width) then
								Bit_Width_Counter	<=	Bit_Width_Counter + 1;
								
							elsif (Bit_Index_Counter = (Packet_Width - 1)) then
								Bit_Width_Counter	<=	1;
								Bit_Index_Counter	<=	0;
								state				<=	UART_IDLE;
								
							else
								Bit_Width_Counter	<=	1;	-- This is one Clk after transmiting the previous bit
								Bit_Index_Counter	<=	Bit_Index_Counter + 1;
							end if;
														
			when	others	=>
							state			<=	UART_IDLE;
							
			end case;
			
		end if;
	
	end process;
	
	Parity_Bit	<=	xor_reduce (Data_In_Reg);
	Packet		<=	'1' & Parity_Bit & Data_In_Reg & '0' when (PARITY = "1") else '1' & Data_In_Reg & '0';
	Busy		<=	Busy_Int;
	Data_Out	<=	Data_Out_Int;

end Architecture;