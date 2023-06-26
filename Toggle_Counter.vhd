library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------------------
entity Toggle_Counter is
	generic( 
		g_Width	:	integer
	);
	port(
		i_Clk	:	in		std_logic;
		i_CE	:	in		std_logic;
		i_input	:	in		std_logic;
		i_SCLR	:	in		std_logic;
		i_Mode	:	in		std_logic_vector(1 downto 0);
		o_Q		:	out		std_logic_vector(g_Width - 1 downto 0)
	);
end entity;
-----------------------------------
architecture behavioral of Toggle_Counter is

	signal	r_input			:	std_logic;
	signal	r_SCLR			:	std_logic;
	signal	r_Cntr			:	unsigned(g_Width - 1 downto 0)	:= (others => '0');
	signal	w_Error_Value	:	std_logic;
	signal	r_Even			:	std_logic;

	attribute mark_debug	:	string;
	attribute mark_debug of r_input			:	signal is "True";
	attribute mark_debug of r_Even			:	signal is "True";
	attribute mark_debug of r_Cntr			:	signal is "True";
	attribute mark_debug of w_Error_Value	:	signal is "True";

begin

	process(i_Clk)
	
	begin
	
		if (i_Clk'event and i_Clk = '1') then
--			r_SCLR		<=	i_SCLR;
			r_input		<=	i_input;
			
			if (i_SCLR = '1') then
				r_Cntr	<=	(others => '0');
				r_Even	<=	'0';
			else
				r_Even	<=	not r_Even;
				
				if (i_input = w_Error_Value and i_CE = '1') then	-- USE i_CE for counting only Rising/Falling Transitions
					r_Cntr	<=	r_Cntr + 1;
				end if;
			end if;
		end if;
	
	end process;
	
	w_Error_Value	<=	'1'				when (i_Mode = "10") else
						'0'				when (i_Mode = "11") else
						not r_Even;
						
	o_Q	<=	std_logic_vector(r_Cntr);

end architecture;