library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_misc.all;
--------------------------------------
entity UART_Tx is
	generic(
		g_Parity	:	std_logic_vector(0 downto 0)	:= "0";
		g_N_Bits	:	integer							:= 8;
		g_Baud_Rate	:	integer							:= 230400;
		g_Frequency	:	integer							:= 1e8 -- Hz
	
	);
	port(
		i_Clk		:	in		std_logic;
		i_Send		:	in		std_logic;
		i_Data_In	:	in		std_logic_vector(g_N_Bits - 1 downto 0);
		o_Busy		:	out		std_logic;
		o_Tx		:	out		std_logic
	);
end entity;
--------------------------------------
architecture behavioral of UART_Tx	is

	------------- Constants ------------------
	constant	c_Clks_Per_Bit	:	integer	:=	integer(ceil(real(g_Frequency) / real(g_Baud_Rate)));
	constant	c_Packet_Width	:	integer	:=	g_N_Bits + 2 + to_integer(unsigned(g_Parity));
	------------- Types ------------------
	type t_States is (s_IDLE, s_TRANSMIT, s2);
	signal	r_State				:	t_States	:= s_IDLE;
	------------- Registers ------------------
	signal	r_Send				:	std_logic;
	signal	r_Data_In			:	std_logic_vector(g_N_Bits - 1 downto 0);
	signal	r_Busy				:	std_logic	:= '0';
	signal	r_Tx				:	std_logic	:= '1';
	signal	r_Parity_Bit		:	std_logic;	
	signal	r_Packet			:	std_logic_vector(c_Packet_Width - 1 downto 0);
	------------- Counters ---------------------
	signal	r_Bit_Index			:	integer range 0 to (c_Packet_Width - 1)	:= 0;
	signal	r_Bit_Width_Cntr	:	integer range 0 to (c_Clks_Per_Bit - 1)	:= (c_Clks_Per_Bit - 1);

begin

	process(i_Clk)
	begin
	
		if (i_Clk'event and i_Clk = '1') then
			
			r_Send	<=	i_Send;
			
			case r_State	is
			
				when	s_IDLE		=>
					r_Busy				<=	'0';
					r_Tx				<=	'1';
					
					if (r_Send = '0' and i_Send = '1') then
						r_Bit_Width_Cntr	<=	(c_Clks_Per_Bit - 1);
						r_Bit_Index			<=	0;
						r_Data_In			<=	i_Data_In;
						r_Busy				<=	'1';
						r_State				<=	s_TRANSMIT;
					end if;
					
				when	s_TRANSMIT	=>
				
					r_Tx	<=	r_Packet(r_Bit_Index);
					
					if (r_Bit_Width_Cntr > 0) then
						r_Bit_Width_Cntr	<=	r_Bit_Width_Cntr - 1;
					else
						r_Bit_Width_Cntr	<=	(c_Clks_Per_Bit - 1);
						
						if (r_Bit_Index < (c_Packet_Width - 1)) then
							r_Bit_Index	<=	r_Bit_Index + 1;
						else
							r_Bit_Index	<=	0;
							r_State		<=	s_IDLE;
						end if;
					
					end if;
				when	others		=>
					r_State		<=	s_IDLE;
			end case;
		
		end if;
	
	end process;
		
	r_Parity_Bit	<=	xor_reduce (r_Data_In);
	r_Packet		<=	('1' & r_Parity_Bit & r_Data_In & '0') when (g_Parity = "1") else 
						('1' & r_Data_In & '0');
	o_Busy			<=	r_Busy;
	o_Tx			<=	r_Tx;

end architecture;