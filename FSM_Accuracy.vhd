library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_package.all;
------------------------------------
entity FSM_Accuracy is
	generic(
		g_Repetition	:	integer);
	port(
		i_Clk			:	in		std_logic;
		i_Reset			:	in		std_logic;
		i_Enable		:	in		std_logic;
		i_Locked_1		:	in		std_logic;
		i_Locked_2		:	in		std_logic;
		i_Locked_3		:	in		std_logic;
		o_Reset			:	out		std_logic;
		o_Start			:	out		std_logic
	);
end entity;
------------------------------------
architecture rtl of FSM_Accuracy is

	type my_type is (s0, s1);
	
	signal	r_State		:	my_type	:= s0;
	signal	r_Enable	:	std_logic;
	signal	r_Reset		:	std_logic;
	signal	r_Start		:	std_logic;
	signal	r_Cntr		:	unsigned(get_log2(g_repetition) downto 0)	:=	to_unsigned(g_Repetition - 1, get_log2(g_Repetition) + 1);

begin

	Edge_Det_Inst_1	:	entity work.Edge_Detector
		generic map( g_Rising_Edge => '1')
		port map(
			i_Clk		=>	i_Clk,
			i_Reset		=>	i_Reset,
			i_Sig		=>	i_Enable,
			o_Result	=>	r_Enable
	);
	
	
	process(i_Clk, i_Reset)
	
	begin
	
		if (i_Reset = '1') then
		
			r_State	<=	s0;
			r_Cntr	<=	to_unsigned(g_Repetition - 1, r_Cntr'length);
			
		elsif (i_Clk'event and i_Clk = '1') then
		
			r_Reset		<=	'0';
			r_Start		<=	'0';
			
			case	r_State	is
			
			when	s0	=>
				if (r_Enable = '1') then
					if (r_Cntr > 0) then
						r_Cntr		<=	r_Cntr - 1;
						r_Reset		<=	'1';
						r_State		<=	s1;
					end if;
				end if;
			when	s1	=>
				if (i_Locked_1 = '1' and i_Locked_2 = '1' and i_Locked_3 = '1') then
					r_Start		<=	'1';
					r_State		<=	s0;
				end if;
			end case;
						
		end if;
	end process;

	o_Reset	<=	r_Reset;
	o_Start	<=	r_Start;
	
end architecture;