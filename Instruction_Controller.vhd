library ieee;
use ieee.std_logic_1164.all;
use	IEEE.math_real.all;
use work.my_package.all;
--------------------------------
entity Instruction_Controller is
	generic(
		g_Baud_Rate	:	integer;
		g_Frequency	:	integer
	);
	port(
		i_Clk		:	in	std_logic;
		i_Data_In	:	in	std_logic;
		o_Start		:	out	std_logic;
		o_Reset		:	out	std_logic;
		o_Mode		:	out	std_logic_vector(1 downto 0)
	);
end entity;
--------------------------------
architecture behavioral of Instruction_Controller is

	constant	Bit_Width		:	integer	:=	integer(ceil(real(g_Frequency) / real(g_Baud_Rate)));
	signal	r_Valid		:	std_logic;
	signal	r_Busy		:	std_logic;
	signal	r_Data_Out	:	std_logic_vector(7 downto 0);
	
	signal	r_Start		:	std_logic	:= '0';
	signal	r_Reset		:	std_logic	:= '0';
	signal	r_Mode		:	std_logic_vector(1 downto 0)	:= "10";
	
begin

	UART_Rx_Inst	:	entity work.UART_RX
		generic map(g_CLKS_PER_BIT	=>	Bit_Width)
		port map(
			i_Clk       	=>	i_Clk,
			i_RX_Serial     =>	i_Data_In,
			o_RX_DV         =>	r_Valid,
			o_RX_Byte       =>	r_Data_Out
		);
		
	process(i_Clk)
	
	begin
	
		if (i_Clk'event and i_Clk = '1') then
			
			case Ascii(r_Data_Out)	is
			
			when	'S'	=>
				r_Start		<=	'1';
			when	'R'	=>
				r_Reset     <=	'1';
			when	'U'	=>
				r_Mode     	<=	"11";
				r_Start		<=	'0';
				r_Reset     <=	'0';
			when	'D'	=>
				r_Mode     	<=	"10";
				r_Start		<=	'0';
				r_Reset     <=	'0';
			when	'B'	=>
				r_Mode     	<=	"00";
				r_Start		<=	'0';
				r_Reset     <=	'0';
			when	others	=>
				null;
			end case;
		
		end if;
	
	end process;
	
	o_Start		<=	r_Start;
	o_Reset     <=	r_Reset;
	o_Mode     <=	r_Mode;
		
end architecture;