library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_package.all;
------------------------------------------
entity FSM_Controller_Inc is
	generic(
		g_O2			:	integer;
		g_N_Sets		:	integer;
		g_N_Segments	:	integer;
		g_N_Partial		:	integer
	);
	port(
		i_Reset			:	in		std_logic;
		i_Psclk1		:	in		std_logic;
		i_Locked1		:	in		std_logic;
		i_Locked2		:	in		std_logic;
		i_Locked3		:	in		std_logic;
		i_Done_CUT		:	in		std_logic;
		i_Done_CM1		:	in		std_logic;
		i_Done_CM2		:	in		std_logic;
		i_Stop_PS		:	in		std_logic	:= '0';
		o_Reset1		:	out		std_logic;
		o_Reset2		:	out		std_logic;
		o_Reset3		:	out		std_logic;
		o_Psincdec1		:	out		std_logic;
		o_Psincdec2		:	out		std_logic;
		o_En_CUT		:	out		std_logic;
		o_En_CM1		:	out		std_logic;
		o_En_CM2		:	out		std_logic;
		o_Shift_Value	:	out		std_logic_vector(get_log2(56 * g_O2 * g_N_Sets) downto 0);
		o_Slct_Mux		:	out		std_logic_vector(get_log2(g_N_Segments) downto 0);
		o_LED1			:	out		std_logic;
		o_LED2			:	out		std_logic
	);
end entity;
------------------------------------------
architecture behavioral of FSM_Controller_Inc is

	--------------- Constants ---------------------	
	constant	c_N_Shifts	:	integer	:= 56 * g_O2 * g_N_Sets - 1;
	--------------- States ---------------------
	type t_my_type is (s_Shift, s_Delay, s_Decision, s_Next_Segment, s_Reset, s_Enable_CUT);
	signal	r_State	:	t_my_type	:= s_Shift;
	--------------- Counters ---------------------
	signal	r_Shift_Cntr	:	unsigned(get_log2(c_N_Shifts) downto 0) 	:= to_unsigned(c_N_Shifts, get_log2(c_N_Shifts) + 1);
	signal 	r_Segment_Cntr  :   unsigned(get_log2(g_N_Segments) downto 0) 	:= to_unsigned(0, get_log2(g_N_Segments) + 1);

	--------------- Internal Regs ---------------------
	signal	r_Done_CM1	:	std_logic;
	signal	r_En_CUT	:	std_logic;
	signal	r_Reset1	:	std_logic;
	signal	r_Reset2    :	std_logic;
	signal	r_Reset3    :	std_logic;
	signal	r_LED1		:	std_logic	:= '0';
	signal	r_LED2		:	std_logic	:= '0';
	
	attribute mark_debug	:	string;
	-- attribute mark_debug of r_Shift_Cntr	:	signal is "True";
	-- attribute mark_debug of r_Segment_Cntr	:	signal is "True";
	--attribute mark_debug of r_LED1			:	signal is "True";

begin
	
	Edge_Det_Inst1	:	entity work.Edge_Detector
		generic map( g_Rising_Edge => '1')
		port map(
			i_Clk		=>	i_Psclk1,
			i_Reset		=>	i_Reset,
			i_Sig		=>	i_Done_CM1,
			o_Result	=>	r_Done_CM1
		);
		
	process(i_Psclk1, i_Reset)
	
	begin
	
		if (i_Reset = '1') then
			r_State			<=	s_Shift;
			r_Shift_Cntr	<=	to_unsigned(c_N_Shifts, r_Shift_Cntr'length);
			r_Segment_Cntr	<=	to_unsigned(0, r_Segment_Cntr'length);
			r_LED1			<=	'0';
			r_LED2			<=	'0';
			r_Reset1		<=	'1';
			r_Reset2		<=	'1';
			r_Reset3		<=	'1';
		
		elsif (i_Psclk1'event and i_Psclk1 = '1') then
			
			----- Default -----
			r_Reset1	<=	'0';
			r_Reset2	<=	'0';
			r_Reset3	<=	'0';
			
			case r_State is
			
			when	s_Shift	=>
			
				if (r_Done_CM1 = '1' and i_Stop_PS = '0') then
					r_Shift_Cntr	<=	r_Shift_Cntr - 1;
					r_En_CUT		<=	'0';
					r_LED1			<=	'0';
					r_State			<=	s_Delay;
				end if;
				
			when	s_Delay		=>
				r_State			<=	s_Decision;

			when	s_Decision	=>
				if (r_Shift_Cntr = to_unsigned(0, r_Shift_Cntr'length)) then
					r_Shift_Cntr	<=	to_unsigned(c_N_Shifts, r_Shift_Cntr'length);
					r_State			<=	s_Next_Segment;
				else
					r_State			<=	s_Enable_CUT;
				end if;
			
			when	s_Next_Segment	=>
				if (r_Segment_Cntr < g_N_Segments - 1) then
					r_Segment_Cntr	<=	r_Segment_Cntr + 1;
					r_LED2			<=	'1';
					r_State			<=	s_Reset;
				else
					r_Segment_Cntr	<=	(others => '0');
					r_LED1			<=	'1';
					r_State			<=	s_Shift;
				end if;

			when s_Reset =>
				r_Reset1		<=	'1';
				r_Reset2		<=	'1';
				r_Reset3		<=	'1';
				r_State			<=	s_Enable_CUT;
			when	s_Enable_CUT	=>
			
				if (i_Locked1 = '1' and i_Locked2 = '1' and i_Locked3 = '1') then
					r_En_CUT	<=	'1';
					r_State		<=	s_Shift;
				end if;
			
			end case;
							
		end if;
	
	end process;
	
	o_Reset1		<=	r_Reset1;
	o_Reset2    	<=	r_Reset2;
	o_Reset3    	<=	r_Reset3;
	o_En_CUT		<=	r_En_CUT;
	o_En_CM1    	<=	i_Done_CM2;
	o_En_CM2    	<=	i_Done_CUT;
	o_Shift_Value	<=	std_logic_vector(r_Shift_Cntr);
	o_Slct_Mux		<=	std_logic_vector(r_Segment_Cntr);
	o_Psincdec1		<=	'1';
	o_Psincdec2     <=	'0';
	o_LED1			<=	r_LED1;
	o_LED2			<=	r_LED2;
--	o_LED3			<=	std_logic_vector(to_unsigned(g_N_Segments, 2)(1);

end architecture;