-- ***************************************************************************************
-- LC3 Processor
-- Digital Electronics Lab Course
-- 2019
-- Module: System Bus for communication among LC3, Mem, and Peripherals
-- ***************************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity systembus is
Generic(   
			ADDR_LC3_WIDTH  : natural := 16;	-- LC3
			DATA_LC3_WIDTH  : natural := 16);-- LC3
Port ( 	-- General signals
			CLK		: in  std_logic;
			RST		: in  std_logic;
			LEDS		: out std_logic_vector(7 downto 0);
			
			-- Signals from/to UART
			DATA_R	: in  std_logic;							-- Data ready coming from PC
			DATA_OUT	: in  std_logic_vector(7 downto 0);	-- 8-bit data from PC
			ACK_R		: out std_logic;							-- Data taken ack
			DATA_W	: out std_logic;							-- Data ready to be sent to PC
			DATA_IN	: out std_logic_vector(7 downto 0);	-- 8-bit data to PC
			ACK_W		: in  std_logic;							-- Data sent to PC successfully
			
			-- Signals from/to MEM
			Addr_ToM	: out std_logic_vector(ADDR_LC3_WIDTH-1 downto 0); -- Mem Address
			Data_FrM : in  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- Data to read from MEM
			Data_ToM : out std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- Data to write to MEM
			Op     	: out	std_logic_vector(1 downto 0);	-- Op W(10), R(01), NOT-OP(00)
			Op_Ack 	: in 	std_logic;							-- Operation ACK
			Busyn 	: in  std_logic;							-- Memory busy
			
			 -- LC3 <--> MEM
			MDR    	: in std_logic_vector(DATA_LC3_WIDTH-1 downto 0);
			MAR    	: in std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);
			R_W    	: in std_logic;
			MEM_EN	: in std_logic;
			MEM		: out std_logic_vector(DATA_LC3_WIDTH-1 downto 0);
			R		   : out std_logic;
			
			-- LC3 <--> PERIPHERAL
			ChrReadyFromPC_per : out std_logic;						
			Data_Rx_per			 : out std_logic_vector(7 downto 0);
			Rx_Ack_per 			 : in  std_logic;
			ChrReadyToPC_per	 : in  std_logic;								
			Data_Tx_per			 : in  std_logic_vector (7 downto 0);		
			Tx_Ack_per			 : out std_logic;
			start_RW_P		: out std_logic;
			R_W_Per			: out std_logic;
			AddrP				: out std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);
			data_WPer 		: out std_logic_vector(DATA_LC3_WIDTH-1 downto 0);
			data_RPer		: in  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);
			PerOpDone		: in  std_logic
		);
end systembus;

architecture Behavioral of systembus is

component fsm_serial 
Port ( 	CLK		: in std_logic;
			RST		: in std_logic;
			-- Signals from/to UART
			DATA_R	: in std_logic;								
			DATA_OUT	: in std_logic_vector(7 downto 0);		
			ACK_R		: out std_logic;								
			DATA_W	: out std_logic ;								
			DATA_IN	: out std_logic_vector(7 downto 0);		
			ACK_W		: in std_logic; 								
			-- Signals used by the read/write mem and peripheral modules
			ChrReadyFromPC : out std_logic;						
			Data_Rx			: out std_logic_vector(7 downto 0);
			Rx_Ack			: in  std_logic;
			ChrReadyToPC	: in  std_logic;
			Data_Tx			: in  std_logic_vector (7 downto 0);
			Tx_Ack			: out std_logic
		);		
end component;

component fsm_readwritemem
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
			LC3Started		 : out std_logic	-- Start LC3
		);	
end component;

component fsm_memory
Generic(   
			ADDR_LC3_WIDTH	 : natural := 16;
			DATA_LC3_WIDTH  : natural := 16);
Port ( 	
			CLK		 : in std_logic;
			RST		 : in std_logic;
			-- Signals from/to Read/Write MEM module
			start_RW	 : in  std_logic;								-- Start a memory operation
			R_W		 : in  std_logic;								-- Read (0), Write (1)
			AddrM  	 : in  std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);	-- Mem Addr
			data_WM	 : in  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- Write Data
			data_RM	 : out std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- Read Data
			MemOpDone : out std_logic;								-- Mem completed operation
			-- Signals from/to Memory Interface module
			Addr_ToM	 : out std_logic_vector(ADDR_LC3_WIDTH-1 downto 0); -- Mem Address
			Data_FrM  : in  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- Data to read from MEM
			Data_ToM  : out std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- Data to write to MEM
			Op     	 : out std_logic_vector(1 downto 0);	-- Op W(10), R(01), NOT-OP(00)
			Op_Ack 	 : in  std_logic;							-- Operation ACK
			Busyn 	 : in  std_logic							-- Memory busy
   );
end component;

component fsm_lc3 
generic(   
			ADDR_LC3_WIDTH	 : natural := 16;
			DATA_LC3_WIDTH  : natural := 16);
port (
			CLK			: in  std_logic;
			RST			: in  std_logic;
			-- LC3 Interface
			MDR    		: in  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);
			MAR    		: in  std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);
			R_W    		: in  std_logic;
			MEM_EN		: in  std_logic;
			MEM			: out std_logic_vector(DATA_LC3_WIDTH-1 downto 0);
			R		   	: out std_logic;
			-- Memory FSM Interface
			LC3Started	: in  std_logic;
			start_RW_M	: out std_logic;
			R_W_Mem		: out std_logic;
			AddrM			: out std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);	-- Memory Address
			data_WMem	: out std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- To Mem
			data_RMem	: in  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- From Mem
			MemOpDone	: in  std_logic;
			-- Peripheral Interface
			start_RW_P	: out std_logic;
			R_W_Per		: out std_logic;
			AddrP			: out std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);
			data_WPer	: out std_logic_vector(DATA_LC3_WIDTH-1 downto 0);
			data_RPer	: in  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);
			PerOpDone	: in  std_logic
		);
end component;

-- Signals to connect fsm_serial, fsm_memory, read/writemem and fsm_lc3_comp modules
-- Serial
signal sChrReadyFromPC_serial	: std_logic;	
signal sData_Rx_serial			: std_logic_vector(7 downto 0);
signal sRx_Ack_serial			: std_logic;	
signal sChrReadyToPC_serial	: std_logic;	
signal sData_Tx_serial			: std_logic_vector(7 downto 0);	
signal sTx_Ack_serial			: std_logic;	
		
-- Read/Write Memory		
signal sChrReadyFromPC_rwm	: std_logic;	
signal sData_Rx_rwm			: std_logic_vector(7 downto 0);
signal sRx_Ack_rwm			: std_logic;	
signal sChrReadyToPC_rwm	: std_logic;	
signal sData_Tx_rwm			: std_logic_vector(7 downto 0);	
signal sTx_Ack_rwm			: std_logic;	
signal sstart_RW_rwm			: std_logic;							
signal sR_W_rwm				: std_logic;							
signal sAddrM_rwm  			: std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);	
signal sdata_WM_rwm			: std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	

-- Memory
signal sstart_RW_end		:  std_logic;							
signal sR_W_end	      :  std_logic;							
signal sAddrM_end  		:  std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);	
signal sdata_WM_end		:  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	
signal sdata_RM_end		:  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	
signal sMemOpDone_end	:  std_logic;								

-- LC3
signal sstart_RW_lc3		:  std_logic;							
signal sR_W_lc3			:  std_logic;							
signal sAddrM_lc3  		:  std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);	
signal sdata_WM_lc3		:  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	
signal sLC3Started		:  std_logic;								
		
begin

fsm_serial_comp: fsm_serial
port map (
			CLK		=> CLK,
			RST		=> RST,
			-- Signals from/to Serial module
			DATA_R	=> DATA_R,
			DATA_OUT	=> DATA_OUT,
			ACK_R		=> ACK_R,
			DATA_W	=> DATA_W,
			DATA_IN	=> DATA_IN,
			ACK_W		=> ACK_W,
			-- Signals from/to MUX between Read/Write Mem and Peripheral modules
			ChrReadyFromPC => sChrReadyFromPC_serial,
			Data_Rx			=> sData_Rx_serial,
			Rx_Ack         => sRx_Ack_serial,
			ChrReadyToPC   => sChrReadyToPC_serial,
			Data_Tx        => sData_Tx_serial,
			Tx_Ack         => sTx_Ack_serial
		);

readwritemem_comp: fsm_readwritemem
generic map (ADDR_LC3_WIDTH => ADDR_LC3_WIDTH,
				 DATA_LC3_WIDTH => DATA_LC3_WIDTH)
port map(
			CLK		=> CLK,
			RST		=> RST,
			LEDS     => LEDS,
			-- Signals from/to Read/Write Mem module
			ChrReadyFromPC => sChrReadyFromPC_rwm,
			Data_Rx			=> sData_Rx_rwm,
			Rx_Ack         => sRx_Ack_rwm,
			ChrReadyToPC   => sChrReadyToPC_rwm,
			Data_Tx        => sData_Tx_rwm,
			Tx_Ack         => sTx_Ack_rwm,
			-- Signals from/to fsm_memory
			start_RW	 		=> sstart_RW_rwm,
			R_W		 		=> sR_W_rwm,
			AddrM     		=> sAddrM_rwm,
			data_WM	 		=> sdata_WM_rwm,
			data_RM	 		=> sdata_RM_end,
			MemOpDone 		=> sMemOpDone_end,
			-- Outputs to the mux (Memory + Peripheral)
			LC3Started  	=> sLC3Started
			);
			
fsm_memory_comp: fsm_memory
generic map (ADDR_LC3_WIDTH => ADDR_LC3_WIDTH,
				 DATA_LC3_WIDTH => DATA_LC3_WIDTH)
port map(
			CLK		=> CLK,
			RST		=> RST,
			-- Signals from/to different modules (MUX)
			start_RW	 => sstart_RW_end,
			R_W		 => sR_W_end,
			AddrM 	 => sAddrM_end,
			data_WM	 => sdata_WM_end,
			data_RM	 => sdata_RM_end,
			MemOpDone => sMemOpDone_end,

			Addr_ToM  => Addr_ToM,
			Data_FrM  => Data_FrM,
			Data_ToM  => Data_ToM,
			Op        => Op,
			Op_Ack    => Op_Ack,
			Busyn     => Busyn
		);
		
fsm_lc3_comp: fsm_lc3 
generic map (ADDR_LC3_WIDTH => ADDR_LC3_WIDTH,
				 DATA_LC3_WIDTH => DATA_LC3_WIDTH)
port map(
			CLK		=> CLK,
			RST		=> RST,
			-- LC3 Interface
			MDR    	=> MDR,
			MAR    	=> MAR,
			R_W    	=> R_W,
			MEM_EN	=> MEM_EN,
			MEM		=> MEM,
			R		   => R,
			-- Memory Interface
			LC3Started => sLC3Started,
			start_RW_M => sstart_RW_lc3,
			R_W_Mem	  => sR_W_lc3,
			AddrM		  => sAddrM_lc3,
			data_WMem  => sdata_WM_lc3,
			data_RMem  => sdata_RM_end,
			MemOpDone  => sMemOpDone_end,
			-- Peripheral Interface
			start_RW_P => start_RW_P,
			R_W_Per	  => R_W_Per,
			AddrP		  => AddrP,
			data_WPer  => data_WPer,
			data_RPer  => data_RPer,
			PerOpDone  => PerOpDone
		);
		
-- Signals through muxes (Memory <--> Read/Write MEM / LC3)
sstart_RW_end <= sstart_RW_rwm when sLC3Started = '0' 
                 else sstart_RW_lc3;
sR_W_end	     <= sR_W_rwm when sLC3Started = '0' 
                 else sR_W_lc3;
sAddrM_end 	  <= sAddrM_rwm when sLC3Started = '0' 
                 else sAddrM_lc3;
sdata_WM_end  <= sdata_WM_rwm when sLC3Started = '0' 
                 else sdata_WM_lc3;

-- Signals through muxes (Serial <--> Read/Write MEM / Peripheral)
sChrReadyFromPC_rwm  <= sChrReadyFromPC_serial when sLC3Started = '0' 
						 	   else '0';
ChrReadyFromPC_per   <= sChrReadyFromPC_serial when sLC3Started = '1' 
					 		   else '0';
sData_Rx_rwm         <= sData_Rx_serial when sLC3Started = '0' 
				 			   else (others => '0');
Data_Rx_per          <= sData_Rx_serial when sLC3Started = '1' 
							   else (others => '0');
sRx_Ack_serial       <= sRx_Ack_rwm when sLC3Started = '0' 
							   else Rx_Ack_per;
sChrReadyToPC_serial <= sChrReadyToPC_rwm when sLC3Started = '0' 
								else ChrReadyToPC_per;
sData_Tx_serial      <= sData_Tx_rwm when sLC3Started = '0' 
							   else Data_Tx_per;
sTx_Ack_rwm          <= sTx_Ack_serial when sLC3Started = '0' 
							   else '0';
Tx_Ack_per           <= sTx_Ack_serial when sLC3Started = '1' 
							   else '0';

end Behavioral;
