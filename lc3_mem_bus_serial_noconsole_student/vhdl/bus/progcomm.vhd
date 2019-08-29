-- ***************************************************************************************
-- LC3 Processor
-- Digital Electronics Lab Course
-- 2019
-- Module: Programming/Communication module for LC3 through UART
-- ***************************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity programming_communication is
Generic(   
			ADDR_LC3_WIDTH	 : natural := 16;
			DATA_LC3_WIDTH  : natural := 16);
port (
			CLK				 : in std_logic;
			RST				 : in std_logic;
			LEDS				 : out std_logic_vector(7 downto 0);
			-- Signals to/from fsm_serial
			ChrReadyFromPC  : in  std_logic;						
			Data_Rx			 : in  std_logic_vector(7 downto 0);
			Rx_Ack 			 : out std_logic;
			ChrReadyToPC	 : out std_logic;								
			Data_Tx			 : out std_logic_vector (7 downto 0);		
			Tx_Ack			 : in std_logic;
			-- Signals from/to fsm_memory
			start_RW			 : out std_logic;	-- Start a memory operation
			R_W				 : out std_logic;	-- Read (0), Write (1)
			AddrM  			 : out std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);	-- Mem Addr
			data_WM			 : out std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- Write Data
			data_RM			 : in  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- Read Data
			MemOpDone		 : in  std_logic;	-- Operation completed
			-- Signals from/to LC3
			StartLC3			 : out std_logic	-- Start LC3
		);
end programming_communication;

architecture Behavioral of programming_communication is
-- FSM for the Protocolo
type fsm_states is (state_tx1, state_tx2, 
                    s1, s2, s3, s4, s5, s6, 
						  s_write0, s_write1, s_write2, s_write3, s_write4, 
						  s_read0, s_read1, s_read2, s_read3, s_read4, 
						  s_lc3);
signal protocol_state, protocol_state_aftertx: fsm_states := s1;	
signal command	: std_logic_vector(7 downto 0);						-- Command received
signal size		: std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);	-- Size of data to be read/write
signal address	: std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);	-- Address given

-- FSM for Memory Access
type frm_mem_states is (m0, m1);
signal mem_state : frm_mem_states := m0;
signal start_write, start_read: std_logic := '0';
signal sdata : std_logic_vector(DATA_LC3_WIDTH-1 downto 0) := (others => '0');

begin
-- Protocol for Writing and Reading the bus through UART
data_WM <= sdata;
process(RST, CLK)
	begin
		if RST = '1' then
			protocol_state <= s1;
			protocol_state_aftertx <= s1;
			Data_Tx <= x"00";
			ChrReadyToPC <= '0';
			Start_write <= '0';
			Start_read <= '0';
			Rx_Ack <= '0';
			StartLC3 <= '0';	
			LEDS <= x"00";
		elsif rising_edge (CLK) then
			-- Always do the following (a particular case might override them)
			Rx_Ack <= '0';
			-- Process the current state
			case protocol_state is
				when state_tx1 =>							-- Send answer to PC
					ChrReadyToPC <= '1';
					protocol_state <= state_tx2;
				when state_tx2 =>
					ChrReadyToPC <= '0';
					if Tx_Ack = '1' then 				-- Data sent through UART
						protocol_state <= protocol_state_aftertx;	
						Rx_Ack <= '1';
					else
						protocol_state <= state_tx2;
					end if;	
				-- Start receiving chrs to get ready for writing/reading memory
				-- FPGA and PC must have the same baud configuration. 
				--  After FPGA Reset, a 0x55 must be sent from the PC
				when s1 =>
					LEDS <= x"01";
					if (ChrReadyFromPC = '1') then
						if (Data_Rx = x"ff") then -- Start?
							Data_Tx <= x"01";		  -- Ack start received	
							protocol_state_aftertx <= s2;
						else
							Data_Tx <= x"ff";
							protocol_state_aftertx <= s1;
						end if;
						protocol_state <= state_tx1;
					else
						protocol_state <= s1;
					end if;	
				when s2 =>
					LEDS <= x"02";
					if (ChrReadyFromPC = '1') then	
						if (Data_Rx < x"02") then -- Check R/W command
							Data_Tx <= x"02";		  -- Ack command accepted
							command <= Data_Rx;
							StartLC3 <= '0';		  -- Allows communication again
							protocol_state_aftertx <= s3;
						elsif (Data_Rx = x"53") then -- Start LC3 using 'S'
							Data_Tx <= x"c0";
							protocol_state_aftertx <= s_lc3;
						else
							Data_Tx <= x"ff";
							protocol_state_aftertx <= s1;
						end if;
						protocol_state <= state_tx1;
					else
						protocol_state <= s2;
					end if;	
				when s3 =>						-- Stores upper size value
					LEDS <= x"03";
					if (ChrReadyFromPC = '1') then	
						size(DATA_LC3_WIDTH-1 downto DATA_LC3_WIDTH-8) <= Data_Rx;
						Data_Tx <= x"03";		-- Ack upper size value received	
						protocol_state <= state_tx1;
						protocol_state_aftertx <= s4;
					else
						protocol_state <= s3;
					end if;
				when s4 =>						-- Stores lower size value
					LEDS <= x"04";
					if (ChrReadyFromPC = '1') then	
						size(DATA_LC3_WIDTH-9 downto DATA_LC3_WIDTH-16) <= Data_Rx;
						Data_Tx <= x"04";		-- Ack lower size value received	
						protocol_state <= state_tx1;
						protocol_state_aftertx <= s5;
					else
						protocol_state <= s4;
					end if;
				when s5 =>						-- Stores upper address
					LEDS <= x"05";
					if (ChrReadyFromPC = '1') then
						address(ADDR_LC3_WIDTH-1 downto ADDR_LC3_WIDTH-8) <= Data_Rx;
						Data_Tx <= x"05";		-- Ack upper size address received	
						protocol_state <= state_tx1;
						protocol_state_aftertx <= s6;
					else
						protocol_state <= s5;
					end if;
				when s6 =>						-- Stores lower address
					LEDS <= x"06";
					if (ChrReadyFromPC = '1') then
						address(ADDR_LC3_WIDTH-9 downto ADDR_LC3_WIDTH-16) <= Data_Rx;
						Data_Tx <= x"06";		-- Ack lower size address received	
						protocol_state <= state_tx1;
						if command = x"01" then	-- Write
							protocol_state_aftertx <= s_write0;
						else							-- Read
							protocol_state_aftertx <= s_read0;
						end if;
					else
						protocol_state <= s6;
					end if;
				when s_write0 =>
					LEDS <= x"a0";
					if (ChrReadyFromPC = '1') then -- Gets upper byte
						protocol_state <= s_write1;
						sdata(DATA_LC3_WIDTH-1 downto DATA_LC3_WIDTH-8) <= Data_Rx;
						Rx_Ack <= '1';					 -- Ack for current byte
					else 	
						protocol_state <= s_write0;
					end if;
				when s_write1 =>
					LEDS <= x"a1";
					Rx_Ack <= '0';
					if (ChrReadyFromPC = '1') then -- Gets lower byte
						start_write <= '1';			 -- Request memory writing for current word
						protocol_state <= s_write2;
						sdata(DATA_LC3_WIDTH-9 downto DATA_LC3_WIDTH-16) <= Data_Rx;
					else 	
						protocol_state <= s_write1;
					end if;
				when s_write2 =>
					LEDS <= x"a2";
					start_write <= '0';
					if MemOpDone = '1' then			-- Wait for memory to finish
						protocol_state <= s_write3;
						size <= size - 1;
						Rx_Ack <= '1';					-- Ack for second byte when memory is written
					else 	
						protocol_state <= s_write2;
					end if;	
				when s_write3 =>	
					LEDS <= x"a3";
					if size = (size'range => '0')  then	-- Done?
						protocol_state <= s_write4;
					else
						protocol_state <= s_write0;
						address <= address + 1;		-- Next address
					end if;	
				when s_write4 =>
					LEDS <= x"a4";
					if (ChrReadyFromPC = '1') then 						
						if Data_Rx = x"fa" then	-- Should be STOP command
							Data_Tx <= x"0a";
						else
							Data_Tx <= x"ff";
						end if;
						protocol_state <= state_tx1;
						protocol_state_aftertx <= s1;
					else
						protocol_state <= s_write4;
					end if;
				when s_read0 =>
					LEDS <= x"b0";
					if (ChrReadyFromPC = '1') then 		
						if (Data_Rx = x"fa") then -- Should be STOP command
							Data_Tx <= x"0b";
							protocol_state_aftertx <= s_read1;
						else
							protocol_state_aftertx <= s1;
							Data_Tx <= x"ff";
						end if;
						protocol_state <= state_tx1;
					else
						protocol_state <= s_read0;
					end if;	
				when s_read1 =>
					LEDS <= x"b1";
					start_read <= '1';
					protocol_state <= s_read2;
				when s_read2 =>	
					LEDS <= x"b2";
					start_read <= '0';
					if MemOpDone = '1' then			-- Wait for the memory to complete the OP
						-- Upper byte
						Data_Tx <= data_RM(DATA_LC3_WIDTH-1 downto DATA_LC3_WIDTH-8);
						protocol_state <= state_tx1;
						protocol_state_aftertx <= s_read3;
					else 	
						protocol_state <= s_read2;
					end if;	
				when s_read3 =>	
					LEDS<=x"b3";
					-- Lower byte
					Data_Tx <= data_RM(DATA_LC3_WIDTH-9 downto DATA_LC3_WIDTH-16);
					size <= size-1;
					protocol_state <= state_tx1;
					protocol_state_aftertx <= s_read4;
				when s_read4 =>
					LEDS<=x"b4";
					if size = (size'range => '0') then 	-- done?
						protocol_state <= s1;
					else
						address <= address+1; 				-- Next address (Next value)
						protocol_state <= s_read1;
					end if;	
				when s_lc3 =>
					StartLC3 <= '1';
					protocol_state <= s1;
			end case;
		end if;
end process;

-- Memory FSM
AddrM <= address;
process(RST, CLK)
	begin
		if RST = '1' then
			mem_state <= m0;
			start_RW <= '0';
		elsif rising_edge (CLK) then
			case mem_state is
				when m0 =>
					if start_write = '1' then
						mem_state <= m1;
						R_W <= '1';
						start_RW <= '1';
					elsif start_read = '1' then
						mem_state <= m1;
						R_W <= '0';
						start_RW <= '1';
					else
						mem_state <= m0;
						start_RW <= '0';
					end if;
				when m1 =>
					start_RW<='0';
					if MemOpDone='1' then
						mem_state <= m0;
					else	
						mem_state <= m1;
					end if;
			end case;
		end if;
end process;		

end Behavioral;

