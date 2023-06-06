library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------------------
entity Toggle_Counter is
	generic( g_Width	:	integer);
	port(
		i_Clk	:	in		std_logic;
		i_input	:	in		std_logic;
		i_SCLR	:	in		std_logic;
		o_Q		:	out		std_logic_vector(g_Width - 1 downto 0)
	);
end entity;
-----------------------------------
architecture behavioral of Toggle_Counter is

	signal	r_input		:	std_logic;
	signal	r_input_2	:	std_logic;
	signal	r_SCLR		:	std_logic;
	signal	r_Cntr		:	unsigned(g_Width - 1 downto 0)	:= (others => '0');

begin

	process(i_Clk)
	
	begin
	
		if (i_Clk'event and i_Clk = '1') then
		
			r_SCLR		<=	i_SCLR;
			r_input		<=	i_input;
			r_input_2	<=	r_input;
			
			if (r_SCLR = '1') then
				r_Cntr		<=	(others => '0');
				r_input_2	<=	i_input;
				
			else
				if (i_input = r_input) then
					r_Cntr	<=	r_Cntr + 1;
					
				end if;
			
			end if;
		
		end if;
	
	end process;
	
	o_Q	<=	std_logic_vector(r_Cntr);

end architecture;