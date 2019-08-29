-- ***************************************************************************************
-- LC3 Processor
-- Digital Electronics Lab Course
-- 2019
-- Module: FSM for Serial Communication
-- ***************************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity fsm_serial is
Port ( 	CLK		: in std_logic;
			RST		: in std_logic;
			-- Signals from/to UART (Seen from UART)
			DATA_R	: in std_logic;								
			DATA_OUT	: in std_logic_vector(7 downto 0);		
			ACK_R		: out std_logic;								
			DATA_W	: out std_logic ;								
			DATA_IN	: out std_logic_vector(7 downto 0);		
			ACK_W		: in std_logic; 								
			-- Signals used by the programming/communication module
			ChrReadyFromPC : out std_logic;						
			Data_Rx			: out std_logic_vector(7 downto 0);
			Rx_Ack			: in  std_logic;
			ChrReadyToPC	: in  std_logic;
			Data_Tx			: in  std_logic_vector (7 downto 0);
			Tx_Ack			: out std_logic
			);								
end fsm_serial;

architecture Behavioral of fsm_serial is

-- FSM for Reception
type uart_rx is (rx0, rx1, rx2);
signal state_rx	:	uart_rx := rx0;

-- FSM for Transmission
type uart_tx is (tx0, tx1, tx2);
signal state_tx	:	uart_tx	:=tx1;

begin
-- Reception Process
	process (CLK, RST)
	begin
		if RST = '1' then
			state_rx <= rx0;
			ACK_R <= '0';
			Data_Rx <= x"00";
			ChrReadyFromPC <= '0';
		elsif (rising_edge(CLK)) then
			case state_rx is
				when rx0 =>
					ACK_R <= '0';
					if DATA_R = '1' then 		-- Data ready in UART?
						Data_Rx <= DATA_OUT; 
						state_rx <= rx1;
						ACK_R <= '1';
					else
						state_rx <= rx0;					
					end if;			
				when rx1 => 
					ChrReadyFromPC <= '1'; 		-- Start processing incoming char
					state_rx <= rx2;
					ACK_R <= '0';
				when rx2 => 
					ChrReadyFromPC <= '0';
					if (Rx_Ack = '1') then 		-- Protocol already processed char
						state_rx <= rx0;
					else
						state_rx <= rx2;
					end if;	
			end case;
		end if;
	end process;
	
-- Transmission Process
	process(CLK, RST)
	begin
		if RST = '1' then
			state_tx <= tx0;
			DATA_W <= '0';
			DATA_IN <= x"00";
		elsif (rising_edge(CLK)) then
			case state_tx is
				when tx0 =>	
					if(ChrReadyToPC = '1') then			-- Transmission started
						state_tx <= tx1;	
						DATA_IN <= Data_Tx;
					else		
						state_tx <= tx0;	
					end if;	
				when tx1 =>									
					DATA_W <= '1';							-- Send data to PC
					state_tx <= tx2;
				when tx2 =>									
					DATA_W <= '0';
					if ACK_W = '1' then 					-- Wait until UART process data
						state_tx<=tx0;	
					else
						state_tx<=tx2;	
					end if;	
			end case;
		end if;
	end process;
	Tx_Ack <= ACK_W;
end Behavioral;

