library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
----------------------------------
entity bram is
    generic(
        g_Width     :   integer :=  1;
        g_Length    :   integer :=  14
    );
    port(
        i_Clk       :   in      std_logic;
        i_WE        :   in      std_logic;
        i_Enable    :   in      std_logic;
        i_Data_In   :   in      std_logic_vector(g_Width - 1 downto 0);
        i_Addr      :   in      std_logic_vector(g_Length - 1 downto 0);
        o_Data_Out  :   out     std_logic_vector(g_Width - 1 downto 0)
    );
end entity;
----------------------------------
architecture behavioral of bram is

    type t_Mem is array (0 to 2 ** g_Length - 1) of std_logic_vector(g_Width - 1 downto 0);
    signal 	r_Ram 		: t_Mem;
    signal	r_Data_Out  : std_logic_vector(g_Width - 1 downto 0);

    attribute ram_style :   string;
    attribute ram_style of r_Ram    :   signal is "block";
    
    attribute dont_touch	:	string;
	attribute dont_touch of i_Addr	:	signal is "True";
	attribute dont_touch of r_Ram	:	signal is "True";


begin

    process(i_Clk)
    begin
        if falling_edge(i_Clk) then
            if (i_Enable = '1') then
                if (i_WE = '1') then
                    r_Ram(to_integer(unsigned(i_Addr))) <=  i_Data_In;  
                    r_Data_Out							<=	i_Data_In;                 
                else
                	r_Data_Out	<=	r_Ram(to_integer(unsigned(i_Addr)));
                end if;
            end if;
        end if;
    end process;

    o_Data_Out	<=	r_Data_Out;

end architecture;