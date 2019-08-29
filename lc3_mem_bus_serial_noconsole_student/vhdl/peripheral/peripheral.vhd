-- ***************************************************************************************
-- LC3 Processor
-- Digital Electronics Lab Course
-- 2019
-- Module: Peripheral for Console Emulation Through Serial Communication Module
-- ***************************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity peripheral_ctrl is
generic(   
			ADDR_LC3_WIDTH  : natural := 16;	
			DATA_LC3_WIDTH  : natural := 16);
port (
		CLK			: in  std_logic;
		RST			: in  std_logic;
		-- Inputs
		Switches		: in  std_logic_vector(3 downto 0);
		LEDS			: out std_logic_vector(7 downto 0);
		-- Interface for the peripheral
		start_RW_P	: in  std_logic;
		R_W_Per		: in  std_logic;
		AddrP			: in  std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);
		data_WPer	: in  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- From LC3
		data_RPer	: out std_logic_vector(DATA_LC3_WIDTH-1 downto 0);
		PerOpDone	: out std_logic
	);
end peripheral_ctrl;

architecture Behavioral of peripheral_ctrl is
	type fsm_machine is (init, s0, s1);
	signal peripheral_state	: fsm_machine := init;
	
	constant PER_ADDRESS_READ  : std_logic_vector := x"FE01";
	constant PER_ADDRESS_WRITE : std_logic_vector := x"FE02";
begin
process(CLK, RST)
	begin
		if(RST = '1')then
			PerOpDone <= '0';
			LEDS <= x"00";
			data_RPer <= x"0000";
			peripheral_state <= init;
		elsif (CLK = '1' and CLK'Event) then
			-- Do the following always (a particular case can override it)
			PerOpDone <= '0';

			case peripheral_state is
				when init =>	
					if (start_RW_P = '1')	then
						peripheral_state <= s0;
					else	
						peripheral_state <= init;					
					end if;
				when s0 =>	
					if(R_W_Per = '0')	then --read 
						if(AddrP = PER_ADDRESS_READ) then
							data_RPer <= x"000" & Switches;
							PerOpDone <= '1';
						end if;
					else	
						if(AddrP = PER_ADDRESS_WRITE) then --write 
							LEDS <= data_WPer(7 downto 0);
							PerOpDone <= '1';
						end if;
					end if;
					peripheral_state <= s1;
				when s1 =>
					peripheral_state <= init;
			end case;
		end if;
end process;							
					
end Behavioral;

