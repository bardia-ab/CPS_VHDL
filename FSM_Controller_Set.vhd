library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.my_package.all;
------------------------------------------
entity FSM_Controller_Set is
	generic(
		g_O2			:	integer;
		g_N_Sets		:	integer;
		g_N_Segments	:	integer
	);
	port(
		i_Clk_Launch	:	in		std_logic;
		i_Psclk1		:	in		std_logic;
		i_Psclk2		:	in		std_logic;
		i_Locked1		:	in		std_logic;
		i_Locked2		:	in		std_logic;
		i_Locked3		:	in		std_logic;
		i_Done_CUT		:	in		std_logic;
		i_Done_CM1		:	in		std_logic;
		i_Done_CM2		:	in		std_logic;
		o_Reset1		:	out		std_logic;
		o_Reset2		:	out		std_logic;
		o_Reset3		:	out		std_logic;
		o_Psincdec1		:	out		std_logic;
		o_Psincdec2		:	out		std_logic;
		o_En_CUT		:	out		std_logic;
		o_En_CM1		:	out		std_logic;
		o_En_CM2		:	out		std_logic;
		o_Shift_Value	:	out		std_logic_vector(get_log2(56 * g_O2 * g_N_Sets) - 1 downto 0);
		o_Slct_Mux		:	out		std_logic_vector(get_log2(g_N_Segments + 1) - 1 downto 0);
		o_LED1			:	out		std_logic;
		o_LED2			:	out		std_logic
	);
end entity;
------------------------------------------
architecture behavioral of FSM_Controller_Set is

	--------------- Constants ---------------------	
	constant	c_N_Shifts	:	integer	:= 56 * g_O2;
	
	--------------- States ---------------------
	type t_my_type1 is (s_Set, s_Decision_Seg, s_Wait_Lock1, s_Wait_Lock2, s_Decision_End, s_End);
	type t_my_type2 is (s_Shift, s_Decision_CUT_CM1, s1);
	type t_my_type3 is (s_Idle, S_Cntr);
	signal	r_State1	:	t_my_type1	:= s_Set;
	signal	r_State2	:	t_my_type2	:= s_Shift;
	signal	r_State3	:	t_my_type3	:= s_Idle;
	--------------- Counters ---------------------
	signal	r_Shift_Cntr		:	unsigned(get_log2(c_N_Shifts+1) - 1 downto 0) 	:= to_unsigned(c_N_Shifts, get_log2(c_N_Shifts+1));
	signal	r_Set_Cntr			:	unsigned(get_log2(g_N_Sets+1) - 1 downto 0)		:= to_unsigned(0, get_log2(g_N_Sets+1));
	signal 	r_Segment_Cntr  	:   unsigned(get_log2(g_N_Segments+1) - 1 downto 0) := to_unsigned(0, get_log2(g_N_Segments+1));
	signal	r_CUT_En_Cntr		:	integer range 0 to 10	:= 10;
	--------------- Internal Regs ---------------------
	signal	r_Done_CUT			:	std_logic;
	signal	r_Done_CM1			:	std_logic;
	signal	r_Done_CM1_2		:	std_logic;	
	signal	r_Done_CM2			:	std_logic;
	signal	r_Done_CM2_2		:	std_logic;
	signal	r_Trig_CUT_1		:	std_logic	:= '0';
	signal	r_Trig_CUT_2		:	std_logic	:= '0';
	signal	r_Trig_CUT_1_p		:	std_logic;
	signal	r_Trig_CUT_2_p		:	std_logic;
	signal	r_En_CUT			:	std_logic	:= '0';
	signal	r_En_CM1			:	std_logic;
	signal	r_Reset1			:	std_logic;
	signal	r_Reset2    		:	std_logic;
	signal	r_Reset3    		:	std_logic;
	signal	r_LED1				:	std_logic	:= '0';
	signal	r_LED2				:	std_logic	:= '0';
	
	-- attribute mark_debug		:	string;
	-- attribute mark_debug of r_Shift_Cntr	:	signal is "True";
	-- attribute mark_debug of r_Segment_Cntr	:	signal is "True";

begin
	
	-- Edge_Det_Inst1	:	entity work.Edge_Detector
		-- generic map( g_Rising_Edge => '1')
		-- port map(
			-- i_Clk		=>	i_Psclk1,
			-- i_Sig		=>	i_Done_CM1,
			-- o_Result	=>	r_Done_CM1
		-- );
		
	Edge_Det_Inst2	:	entity work.Edge_Detector
		generic map( g_Rising_Edge => '1')
		port map(
			i_Clk		=>	i_Psclk2,
			i_Sig		=>	i_Done_CM2,
			o_Result	=>	r_Done_CM2
		);
	
	-- Edge_Det_Inst3	:	entity work.Edge_Detector
		-- generic map( g_Rising_Edge => '1')
		-- port map(
			-- i_Clk		=>	i_Clk_Launch,
			-- i_Sig		=>	r_Trig_CUT_1,
			-- o_Result	=>	r_Trig_CUT_1_p
		-- );
		
	-- Edge_Det_Inst4	:	entity work.Edge_Detector
		-- generic map( g_Rising_Edge => '1')
		-- port map(
			-- i_Clk		=>	i_Clk_Launch,
			-- i_Sig		=>	r_Trig_CUT_2,
			-- o_Result	=>	r_Trig_CUT_2_p
		-- );
		
	process(i_Psclk2)
	
	begin
	
	if (i_Psclk2'event and i_Psclk2 = '1') then
	
		-- r_Done_CUT		<=	i_Done_CUT;
		-- r_Done_CM2		<=	i_Done_CM2;
		-- r_Done_CM2_2	<=	r_Done_CM2;
		-- r_Trig_CUT_1_p	<=	r_Trig_CUT_1;
	
		case r_State2	is
		
		when s_Shift	=>
		
			-- if (r_Done_CM2_2 = '0' and r_Done_CM2 = '1') then
			if (r_Done_CM2 = '1') then
				r_Shift_Cntr	<=	r_Shift_Cntr - 1;
				r_Trig_CUT_1	<=	'0';
				r_En_CM1		<=	'0';
				r_State2		<=	s1;
			end if;
			r_LED1			<=	'1';
			r_LED2			<=	'0';
			
		when s1	=>
			r_State2		<=	s_Decision_CUT_CM1;
		when s_Decision_CUT_CM1	=>
			
			r_State2		<=	s_Shift;
			r_LED1			<=	'0';
			r_LED2			<=	'1';
			
			if (r_Shift_Cntr > to_unsigned(0, r_Shift_Cntr'length)) then
				r_Trig_CUT_1	<=	'1';
			else
				r_En_CM1		<=	'1';
				r_Shift_Cntr	<=	to_unsigned(c_N_Shifts, r_Shift_Cntr'length);
				r_LED1			<=	'1';
				r_LED2			<=	'1';
			end if;
		
		end case;
	
	end if;
	
	end process;
		

	
	o_Reset1		<=	r_Reset1;
	o_Reset2    	<=	r_Reset2;
	o_Reset3    	<=	r_Reset3;
	-- o_En_CUT		<=	r_En_CUT;
	o_En_CUT		<=	r_Trig_CUT_1;
	o_En_CM1    	<=	r_En_CM1;
	o_En_CM2    	<=	i_Done_CUT;
	o_Shift_Value	<=	std_logic_vector(resize(r_Set_Cntr & r_Shift_Cntr, o_Shift_Value'length));
	o_Slct_Mux		<=	std_logic_vector(r_Segment_Cntr);
	o_Psincdec1		<=	'1';
	o_Psincdec2     <=	'1';
	o_LED1			<=	r_LED1;
	o_LED2			<=	r_LED2;

end architecture;