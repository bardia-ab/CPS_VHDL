library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------------------
entity ILA_Capture is
	generic (g_Counter_Width	:	integer);
	port(
		i_Clk			:	in		std_logic;
		i_Enable		:	in		std_logic;
		i_Reset			:	in		std_logic;
		i_Error_Cntr	:	in		std_logic_vector(g_Counter_Width-1 downto 0);
		o_Capture		:	out		std_logic
	);
end entity;
-----------------------------------
architecture behavioral of ILA_Capture is

	--------------- Types ---------------------
	type t_my_state is (s0, s1, s2, s3, s4);
	
	--------------- Internal Regs ---------------------
--	signal	r_state			:	t_my_state	:= s0;
	signal	r_State			:	std_logic_vector(1 downto 0)	:= "00";	
	signal	w_MSB			:	std_logic;
	signal	r_MSB			:	std_logic;
	signal	r_Enable		:	std_logic;
	signal	r_Capture		:	std_logic		:= '0';
	signal	r_Error_Cntr	:	std_logic_vector(g_Counter_Width-1 downto 0);
		
	--------------- Constants ---------------------
	constant	c_Zero		:	std_logic_vector(g_Counter_Width-1 downto 0)	:=	std_logic_vector(to_unsigned(0, g_Counter_Width));
	constant	c_Max		:	std_logic_vector(g_Counter_Width-1 downto 0)	:=	std_logic_vector(to_unsigned(2**g_Counter_Width-1, g_Counter_Width));
	
--	attribute	mark_debug	:	string;
--	attribute	mark_debug of r_State	:	signal is "True";

begin

	process(i_Clk, i_Reset)
	
	begin
	
		if (i_Reset = '1') then
			r_State		<=	"00";
			
		elsif (i_Clk'event and i_Clk = '1') then
			
			r_Enable	<=	i_Enable;
--			r_Capture	<=	'0';
			
			if (r_Enable = '0' and i_Enable = '1') then
				r_Capture		<=	'0';
				r_Error_Cntr	<=	i_Error_Cntr;
				w_MSB			<=	i_Error_Cntr(g_Counter_Width-1);
				r_MSB			<=	w_MSB;
				
			end if;
		
			case	r_State	is
			
			when	"00"	=>
							if (r_Enable = '0' and i_Enable = '1') then
								r_State		<=	"01";	-- it's essential for the begining because the state machine must start after enable assertion
							end if;
			when	"01"	=>
							if (r_Error_Cntr = c_Zero) then
								r_State	<=	"10";
							elsif (r_Error_Cntr = c_Max) then
								r_State	<=	"11";
							end if;
			when	"10"	=>
							if (r_MSB = '0' and w_MSB = '1') then	-- Detect Rising Edge
								r_Capture	<=	'1';
								r_State		<=	"01";
							end if;
			when	"11"	=>
							if (r_MSB = '1' and w_MSB = '0') then	-- Detect Falling Edge
								r_Capture	<=	'1';
								r_State		<=	"01";
							end if;
			when	others	=>
								null;
			end case;
		
		end if;
	
	end process;

--	w_MSB		<=	i_Error_Cntr(g_Counter_Width-1);
--	r_MSB		<=	r_Error_Cntr(g_Counter_Width-1);
	o_Capture	<=	r_Capture;

end architecture;