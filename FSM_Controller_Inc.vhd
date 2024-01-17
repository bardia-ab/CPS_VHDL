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
		i_Clk		:	in		std_logic;
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
		o_Shift_Index	:	out		std_logic_vector(get_log2(56 * g_O2 * g_N_Sets) downto 0);
		o_Segment_Index	:	out		std_logic_vector(get_log2(g_N_Segments) downto 0);
		o_LED1			:	out		std_logic;
		o_LED2			:	out		std_logic
	);
end entity;
------------------------------------------
architecture behavioral of FSM_Controller_Inc is

	--------------- Constants ---------------------	
	constant	c_N_Shifts	:	integer	:= 56 * g_O2 * g_N_Sets - 1;
	--------------- States ---------------------
	type t_my_type is (s_Shift, s_DECISION_1, s_NEXT_SEGMENT, s_ENABLE_CUT, s_END);
	signal	r_State	            :	t_my_type	:= s_Shift;
	--------------- Counters ---------------------
	signal	r_Shift_Cntr	    :	integer range 0 to c_N_Shifts 	        := c_N_Shifts;
	signal 	r_Segment_Cntr      :   integer range 0 to (g_N_Segments - 1)   := 0;
	--------------- Internal Regs ---------------------
	signal	r_Done_CM1	        :	std_logic;
	signal	r_En_CUT	        :	std_logic;
	signal	r_Reset1	        :	std_logic;
	signal	r_Reset2            :	std_logic;
	signal	r_Reset3            :	std_logic;
	signal	r_LED1		        :	std_logic	:= '0';
	signal	r_LED2		        :	std_logic	:= '0';


begin

    Shift_Counter:  process(i_Reset, i_Clk)
    begin
        if (i_Reset = '1') then
            r_Shift_Cntr    <=  c_N_Shifts;
            r_Segment_Cntr  <=  0;
            r_LED1          <=	'0';
            r_LED2		    <=	'0';
            r_State         <=  s_Shift;
        elsif rising_edge(i_Clk) then
            r_Done_CM1  <=  i_Done_CM1;
            ----- Default -----
			r_Reset1	<=	'0';
			r_Reset2	<=	'0';
			r_Reset3	<=	'0';
            
            case r_State is
                when    s_Shift =>
                    if (r_Done_CM1 = '0' and i_Done_CM1 = '1') then
                        r_En_CUT	    <=	'0';
                        r_Shift_Cntr    <=  r_Shift_Cntr - 1;
                        r_State         <=  s_DECISION_1;
                    end if;
                when    s_DECISION_1    =>
                    if (r_Shift_Cntr = 0) then
                        r_Segment_Cntr	<=	r_Segment_Cntr + 1;
                        r_State         <=  s_NEXT_SEGMENT;
                    else
                        r_State <=  s_ENABLE_CUT;
                    end if;
                when    s_NEXT_SEGMENT  =>
                    if (r_Segment_Cntr = (g_N_Segments - 1)) then
                        r_State     <=  s_END;
                    else
                        r_Reset1	<=	'1';
                        r_Reset2	<=	'1';
                        r_Reset3	<=	'1';
                        r_LED2		<=	'1';
                        r_State     <=  s_ENABLE_CUT;
                    end if;
                when	s_Enable_CUT	=>
                    if (i_Locked1 = '1' and i_Locked2 = '1' and i_Locked3 = '1') then
                        r_En_CUT	<=	'1';
                        r_State		<=	s_Shift;
                    end if;
                when    s_END   =>
                    r_LED1  <=	'1';
            end case;
        end if;
    end process;


    o_Reset1		<=	r_Reset1;
	o_Reset2    	<=	r_Reset2;
	o_Reset3    	<=	r_Reset3;
	o_En_CUT		<=	r_En_CUT;
	o_En_CM1    	<=	i_Done_CM2;
	o_En_CM2    	<=	i_Done_CUT;
	o_Shift_Index	<=	std_logic_vector(to_unsigned(r_Shift_Cntr, o_Shift_Index'length));
	o_Segment_Index	<=	std_logic_vector(to_unsigned(r_Segment_Cntr, o_Segment_Index'length));
	o_Psincdec1		<=	'1';
	o_Psincdec2     <=	'0';
	o_LED1			<=	r_LED1;
	o_LED2			<=	r_LED2;

end architecture;        
