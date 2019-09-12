-- ***************************************************************************************
-- LC3 Processor
-- Digital Electronics Lab Course
-- 2019
-- Module: Peripheral for Console Emulation Through Serial Communication Module
-- ***************************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity peripheral_uart is
generic(   
			ADDR_LC3_WIDTH  : natural := 16;	
			DATA_LC3_WIDTH  : natural := 16);
port (
		CLK				: in  std_logic;
		RST				: in  std_logic;
		-- Signals to/from fsm_serial
		ChrReadyFromPC : in  std_logic;						
		Data_Rx			: in  std_logic_vector(7 downto 0);
		Rx_Ack 			: out std_logic;
		ChrReadyToPC	: out std_logic;								
		Data_Tx			: out std_logic_vector (7 downto 0);		
		Tx_Ack			: in std_logic;
		-- Interface for the peripheral
		start_RW_P		: in  std_logic;
		R_W_Per			: in  std_logic;
		AddrP				: in  std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);
		data_WPer		: in  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- From LC3
		data_RPer		: out std_logic_vector(DATA_LC3_WIDTH-1 downto 0);
		PerOpDone		: out std_logic
	);
end peripheral_uart;

architecture Behavioral of peripheral_uart is
	-- To interface with fsm_lc3_comp
	type fsm_machine is (init, s0, s1);
	signal peripheral_state	: fsm_machine := init;
	
	-- To interface with serial module
	type fsm_uart_tx is (tx_uart0, tx_uart1, tx_uart2);
	signal tx_chr_state : fsm_uart_tx := tx_uart0;
	type fsm_uart_rx is (rx_uart0, rx_uart1, rx_uart2);
	signal rx_chr_state : fsm_uart_rx := rx_uart0;
	signal lc3_rx_ready : std_logic := '0';
	signal lc3_tx_ready : std_logic := '0';
	signal lc3_rx_data  : std_logic_vector(7 downto 0) := x"00";
	signal lc3_tx_data  : std_logic_vector(7 downto 0) := x"00";
	signal lc3_rx_next  : std_logic := '0';
	signal lc3_tx_write : std_logic := '0';
	
	-- Address to be used in ASM code
	constant PER_ADDRESS_BASE : std_logic_vector := x"FE00";
	constant PER_ADDRESS_KBSR : std_logic_vector := x"FE00";
	constant PER_ADDRESS_KBDR : std_logic_vector := x"FE02";
	constant PER_ADDRESS_DSR  : std_logic_vector := x"FE04";
	constant PER_ADDRESS_DDR  : std_logic_vector := x"FE06";
begin
	-- Process to write/read to/from peripheral 
	process(CLK, RST)
	begin
		if (RST = '1') then
			PerOpDone <= '0';
			data_RPer <= x"0000";
			peripheral_state <= init;
		elsif (rising_edge(CLK)) then
			-- Do the following always (a particular case can override it)
			PerOpDone <= '0';
			lc3_rx_next <= '0';
			lc3_tx_write <= '0';

			case peripheral_state is
				when init =>	
					if (start_RW_P = '1')	then
						peripheral_state <= s0;
					else	
						peripheral_state <= init;					
					end if;
				when s0 =>	
					if (R_W_Per = '0') then --read 
						if (AddrP = PER_ADDRESS_KBSR) then
							if (lc3_rx_ready = '1') then
								data_RPer <= x"8000";	-- UART has received data from PC
							else
								data_RPer <= x"0000";	-- UART hasn't received data from PC yet
							end if;	
						elsif (AddrP = PER_ADDRESS_KBDR) then
							data_RPer <= lc3_rx_data;
							if (lc3_rx_ready = '1') then
								lc3_rx_next <= '1';		-- Clear KBSR register and allows a new chr
							end if;	
						elsif (AddrP = PER_ADDRESS_DSR) then
							if (lc3_tx_ready = '1') then
								data_RPer <= x"8000";	-- UART ready to transmit data
							else
								data_RPer <= x"0000";	-- UART busy
							end if;	
						end if;
					else	
						if (AddrP = PER_ADDRESS_DDR) then
							if (lc3_tx_ready = '1') then
								lc3_tx_data <= data_WPer;
								lc3_tx_write <= '1';		-- Clear DSR register and allows a new chr
							end if;	
						end if;
					end if;
					PerOpDone <= '1';					-- For any peripheral address, ack the operation
					peripheral_state <= s1;
				when s1 =>	-- Wait one cycle
					peripheral_state <= init;
			end case;
		end if;
	end process;							
				
	-- Process to send chrs to UART (if enabled: LC3Started = '1')
	process(CLK, RST)
	begin
		if (RST = '1') then
			lc3_tx_ready <= '0';
			ChrReadyToPC <= '0';
			Data_Tx <= x"00";
			
			tx_chr_state <= tx_uart0;
		elsif (rising_edge(CLK)) then
			-- Always do the following (a particular case might override them)
			lc3_tx_ready <= '0';							-- UART cannot send a new data (DSR = x0000)

			case tx_chr_state is
				when tx_uart0 =>
					lc3_tx_ready <= '1';					-- UART can send a new data (DSR = x8000)
					if (lc3_tx_write = '1') then
						Data_Tx <= lc3_tx_data;
						tx_chr_state <= tx_uart1;
					else
						tx_chr_state <= tx_uart0;
					end if;
				when tx_uart1 =>
					ChrReadyToPC <= '1';
					tx_chr_state <= tx_uart2;
				when tx_uart2 =>
					if Tx_Ack = '1' then 				-- Data sent through UART
						ChrReadyToPC <= '0';				-- UART waits for it to restart tx
						tx_chr_state <= tx_uart0;
					else
						tx_chr_state <= tx_uart2;
					end if;	
			end case;
		end if;
	end process;
	
	-- Process to get chrs from UART (if allowed: LC3Started = '1')
	process(CLK, RST)
	begin
		if (RST = '1') then
			lc3_rx_ready <= '0';
			lc3_rx_data <= x"00";
			Rx_Ack <= '0';
			
			rx_chr_state <= rx_uart0;
		elsif (rising_edge(CLK)) then
			-- Always do the following (a particular case might override them)
			lc3_rx_ready <= '0';
			Rx_Ack <= '0';

			case rx_chr_state is
				when rx_uart0 =>
					if (ChrReadyFromPC = '1') then	-- UART has received data
						lc3_rx_data <= Data_Rx;
						rx_chr_state <= rx_uart1;
					else
						rx_chr_state <= rx_uart0;
					end if;
				when rx_uart1 =>
					lc3_rx_ready <= '1';					-- Indicate a new data is available (KBSR = x8000)
					if (lc3_rx_next = '1') then
						lc3_rx_ready <= '0';				-- Data was read (KBSR = x0000)
						Rx_Ack <= '1';						-- Ack the data read to wait for a new one
						rx_chr_state <= rx_uart2;
					else
						rx_chr_state <= rx_uart1;
					end if;	
				when rx_uart2 =>
					if (ChrReadyFromPC = '0') then
						rx_chr_state <= rx_uart0;
					else
						rx_chr_state <= rx_uart2;
					end if;	
			end case;
		end if;
	end process;
end Behavioral;

