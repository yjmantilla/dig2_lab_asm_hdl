-- ***************************************************************************************
-- LC3 Processor
-- Digital Electronics Lab Course
-- 2019
-- Module: Serial Peripheral Interface
-- ***************************************************************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

-- Serial Interface
entity Serial is
port(
			CLK		: in  std_logic;
			RST		: in  std_logic;
			-- Signals from/to PC
			TXD		: out std_logic;
		 	RXD		: in  std_logic;
			-- Signals from/to FPGA
			DATA_R	: out std_logic;
			DATA_OUT	: out std_logic_vector(7 downto 0);
			ACK_R		: in  std_logic;
			DATA_W	: in  std_logic 	:= '1';
			DATA_IN	: in  std_logic_vector(7 downto 0) := x"f0";
			ACK_W		: out std_logic 	:= '1'
		);		
end;

architecture Serial of Serial is  
	signal sig_DATA_OUT	:	std_logic_vector(7 downto 0); 
	signal sig_DATA_IN	:	std_logic_vector(7 downto 0);
	signal sig_DATA_R		:	std_logic;	
	signal sig_DATA_W		:	std_logic;	
	signal sig_ACK_W		:	std_logic;	
	
	type mainState is (stIddle, stReceive, stSend, stSend2);
	signal state	:	mainState := stIddle;
component serialinterface 
port(
    clock		: 	in std_logic;                        
    reset		: 	in std_logic;                        
    rx_data		: 	in std_logic_vector (7 downto 0);  
    rx_start	: 	in std_logic;                     
    rx_busy		: 	out std_logic;                     
    rxd			: 	out std_logic;                         
    txd			: 	in std_logic;                          
    tx_data		: 	out std_logic_vector (7 downto 0); 
    tx_av		: 	out std_logic                        
  );
end component;
begin

UART: serialinterface
port map(
    clock	=> CLK,
    reset	=> not RST,                        
    rx_data	=> sig_DATA_IN,			-- Data to PC
    tx_data	=> sig_DATA_OUT,			-- Data from PC
    rxd		=> TXD,						-- Connection to PC rx
    txd		=> RXD,						-- Connection to PC tx
	 rx_start=> sig_DATA_W,				-- Start transmission
    rx_busy	=> sig_ACK_W,				-- Data sent to PC
    tx_av	=> sig_DATA_R				-- Data ready to be read
  );
  
-- FSM
	process (CLK, RST)
	begin
		if RST = '1' then
			state <= stIddle;
			ACK_W <='0';
			DATA_R<='0';
		elsif (CLK = '1' and CLK'Event) then
			case state is
				when stIddle => 
					if sig_DATA_R = '1' then 		-- Data available in UART
						DATA_OUT <= sig_DATA_OUT;	-- Data taken from PC
						state <= stReceive;
						DATA_R <= '1';					-- Send notification data is available from PC
					elsif (DATA_W = '1')then  		-- Data ready to be txed
						sig_DATA_IN<=DATA_IN;		
						sig_DATA_W<='1';
						state <= stSend;
					end if;	
				when stReceive =>
					if(ACK_R = '1') then 			-- Data taken by the system
						DATA_R <= '0';
						state <= stIddle;		
					end if;
				when stSend =>							
					sig_DATA_W <= '0';
					if sig_ACK_W = '0' then
						ACK_W <= '1';
						state <= stSend2;
					end if;	
				when stSend2 =>						-- Tx ends
					ACK_W <='0';
					state <= stIddle;	
			end case;	
		end if;
	end process;
end Serial;
