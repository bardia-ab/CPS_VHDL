library ieee;
use ieee.std_logic_1164.all;
use	IEEE.math_real.all;
--------------------------------
entity Instruction_Controller is
	generic(
		g_Baud_Rate	:	integer;
		g_Frequency	:	integer
	);
	port(
		i_Clk_In_p	:	in	std_logic;
		i_Clk_In_n	:	in	std_logic;
		i_Data_In	:	in	std_logic;
		o_Start		:	out	std_logic;
		o_Reset		:	out	std_logic;
		o_Mode		:	out	std_logic_vector(1 downto 0)
	);
end entity;
--------------------------------
architecture behavioral of Instruction_Controller is

	component clk_wiz_0
		port(
			clk_out1          : out    std_logic;
			-- Status and control signals
			locked            : out    std_logic;
			clk_in1_p         : in     std_logic;
			clk_in1_n         : in     std_logic
		);
	end component;

	constant	Bit_Width		:	integer	:=	integer(ceil(real(g_Frequency) / real(g_Baud_Rate)));
	signal	w_Clk_100	:	std_logic;
	signal	r_Valid		:	std_logic;
	signal	r_Busy		:	std_logic;
	signal	r_Data_Out	:	std_logic_vector(7 downto 0);
	
	signal	r_Start		:	std_logic;
	signal	r_Reset		:	std_logic;
	signal	r_Mode		:	std_logic_vector(1 downto 0);
	
	function Ascii (SLV8 :STD_LOGIC_VECTOR (7 downto 0)) return CHARACTER is
		constant XMAP :INTEGER :=0;
		variable TEMP :INTEGER :=0;
	begin
		for i in SLV8'range loop
			TEMP:=TEMP*2;
			case SLV8(i) is
			when '0' | 'L' 	=> null;
			when '1' | 'H' 	=> TEMP :=TEMP+1;
			when others 	=> TEMP :=TEMP+XMAP;
			end case;
		end loop;
		return CHARACTER'VAL(TEMP);
	end Ascii;
	
begin

	MMCM : clk_wiz_0
		port map ( 
			clk_out1 => w_CLK_100,
			-- Status and control signals                
			locked => open,
			clk_in1_p => i_Clk_In_p,
			clk_in1_n => i_Clk_In_n
		);


	UART_Rx_Inst	:	entity work.UART_RX
		generic map(g_CLKS_PER_BIT	=>	Bit_Width)
		port map(
			i_Clk       	=>	w_Clk_100,
			i_RX_Serial     =>	i_Data_In,
			o_RX_DV         =>	r_Valid,
			o_RX_Byte       =>	r_Data_Out
		);
		
	process(w_Clk_100)
	
	begin
	
		if (w_Clk_100'event and w_Clk_100 = '1') then
			
			case Ascii(r_Data_Out)	is
			
			when	'S'	=>
				r_Start		<=	'1';
			when	'R'	=>
				r_Reset     <=	'1';
			when	'U'	=>
				r_Mode     <=	"11";
			when	'D'	=>
				r_Mode     <=	"10";
			when	'B'	=>
				r_Mode     <=	"00";
			when	others	=>
				null;
			end case;
		
		end if;
	
	end process;
	
	o_Start		<=	r_Start;
	o_Reset     <=	r_Reset;
	o_Mode     <=	r_Mode;
		
end architecture;