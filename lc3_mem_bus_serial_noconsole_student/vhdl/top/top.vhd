-- ***************************************************************************************
-- LC3 Processor
-- Digital Electronics Lab Course
-- 2019
-- Module: Top Module
-- ***************************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Top is
Generic(   
			ADDR_MEM_WIDTH  : natural := 23;
			ADDR_FPGA_WIDTH : natural := 16;
			DATA_WIDTH      : natural := 16;
			CYCLES_WAITING  : natural := 4);
Port ( 	
			CLK		: in std_logic;
			RST		: in std_logic;
			LEDS		: out std_logic_vector(7 downto 0);
			SWITCHES	: in std_logic_vector(7 downto 0);
			-- Signals from/to PC
			TXD		: out std_logic; 	-- Serial transmission
		 	RXD		: in std_logic;	-- Serial reception
			-- Signals from/to SRAM
			Addr_m   : out   STD_LOGIC_VECTOR (ADDR_MEM_WIDTH-1 downto 0);
			Data_m   : inout STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
			Clk_m    : out   STD_LOGIC;
			ADVn_m   : out   STD_LOGIC;
			CRE_m    : out   STD_LOGIC;
			CEn_m    : out   STD_LOGIC;
			OEn_m    : out   STD_LOGIC;
			WEn_m    : out   STD_LOGIC;
			LBn_m    : out   STD_LOGIC;
			UBn_m    : out   STD_LOGIC
		);

	 -- Pin assignment
	 ATTRIBUTE LOC: string;
	 ATTRIBUTE LOC OF CLK    : SIGNAL IS "B8"; 	-- system clock 50 MHz (Nexys2)
	 ATTRIBUTE LOC OF RST  	 : SIGNAL IS "H13";  -- BTN3
	 ATTRIBUTE LOC OF SWITCHES : SIGNAL IS "R17,N17,L13,L14,K17,K18,H18,G18";
	 ATTRIBUTE LOC OF LEDS   : SIGNAL IS "R4,F4,P15,E17,K14,K15,J15,J14";
	 ATTRIBUTE LOC OF TXD  	 : SIGNAL IS "P9"; 
	 ATTRIBUTE LOC OF RXD  	 : SIGNAL IS "U6";  -- BTN3
	 -- Pin assignment for memory
	 ATTRIBUTE LOC OF Addr_m : SIGNAL IS "K6,D1,K3,D2,C1,C2,E2,M5,E1,F2,G4,G5,G6,G3,F1,H6,H3,J5,H2,H1,H4,J2,J1";
	 ATTRIBUTE LOC OF Data_m : SIGNAL IS "T1,R3,N4,L2,M6,M3,L5,L3,R2,P2,P1,N5,M4,L6,L4,L1";
	 ATTRIBUTE LOC OF Clk_m  : SIGNAL IS "H5";
	 ATTRIBUTE LOC OF ADVn_m : SIGNAL IS "J4";
	 ATTRIBUTE LOC OF CRE_m  : SIGNAL IS "P7";
	 ATTRIBUTE LOC OF CEn_m  : SIGNAL IS "R6";
	 ATTRIBUTE LOC OF OEn_m  : SIGNAL IS "T2";
	 ATTRIBUTE LOC OF WEn_m  : SIGNAL IS "N7";
	 ATTRIBUTE LOC OF LBn_m  : SIGNAL IS "K5";
	 ATTRIBUTE LOC OF UBn_m  : SIGNAL IS "K4";
end TOP;

architecture Behavioral of Top is
	component peripheral_ctrl
		generic(   
				ADDR_LC3_WIDTH  : natural;	
				DATA_LC3_WIDTH  : natural);
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
	end component;

	component Serial 
		Port ( 	
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
	end component;

	component systembus
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
			start_RW_P	: out std_logic;
			R_W_Per		: out std_logic;
			AddrP			: out std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);
			data_WPer 	: out std_logic_vector(DATA_LC3_WIDTH-1 downto 0);
			data_RPer	: in  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);
			PerOpDone	: in  std_logic
		);
	end component;

	component nexys2_mem_interface 
		Generic(   
			ADDR_MEM_WIDTH  : natural;
			ADDR_FPGA_WIDTH : natural;
			DATA_WIDTH      : natural;
			CYCLES_WAITING  : natural);
		Port (  
			CLK    : in    STD_LOGIC;
			RESET  : in    STD_LOGIC;
			-- Connection between Memory Interface <--> CellularRAM Memory (Nexys 2)
			Addr_m : out   STD_LOGIC_VECTOR (ADDR_MEM_WIDTH-1 downto 0);
			Data_m : inout STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
			Clk_m  : out   STD_LOGIC;
			ADVn_m : out   STD_LOGIC;
			CRE_m  : out   STD_LOGIC;
			CEn_m  : out   STD_LOGIC;
			OEn_m  : out   STD_LOGIC;
			WEn_m  : out   STD_LOGIC;
			LBn_m  : out   STD_LOGIC;
			UBn_m  : out   STD_LOGIC;
			-- Connection between FPGA <--> Memory Interface
			Addr_f     : in  STD_LOGIC_VECTOR (ADDR_FPGA_WIDTH-1 downto 0);
			Data_f_in  : out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);	-- To FPGA
			Data_f_out : in  STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);	-- From FPGA
			Op_f       : in  STD_LOGIC_VECTOR (1 downto 0);
			Op_Ack_f   : out STD_LOGIC;
			Busyn_f    : out STD_LOGIC
		);
	end component;	

	--Procesador LC3
	component LC_3_data_path is
		generic (
			DATA_BITS   : integer;
			MEMORY_SIZE : integer);
		port (
			LEDS		   : out std_logic_vector(7 downto 0);
			CLK        : in  std_logic;
			Reset      : in  std_logic;
			-- Interface LC3 -- External Memory
			MDR_out    : out std_logic_vector((DATA_BITS - 1) downto 0);
			MAR_out    : out std_logic_vector((DATA_BITS - 1) downto 0);
			R_W_out    : out std_logic;
			MEM_EN_out : out std_logic;
			mem_input	: in std_logic_vector((DATA_BITS - 1) downto 0);
			R_input    : in std_logic
			);
	end component;

--Declaracion de seales
	signal sDATA_R		:  std_logic;
	signal sDATA_OUT	:  std_logic_vector(7 downto 0);
	signal sACK_R		:  std_logic;
	signal sDATA_W		:	std_logic ;
	signal sDATA_IN	:	std_logic_vector(7 downto 0) ;
	signal sACK_W		:	std_logic ;
	
	signal sOp     	: 	std_logic_vector(1 downto 0);		
	signal sAddr_ToM  : 	std_logic_vector(ADDR_FPGA_WIDTH-1 downto 0);	
	signal sData_FrM	: 	std_logic_vector(DATA_WIDTH-1 downto 0);   
	signal sData_ToM 	: 	std_logic_vector(DATA_WIDTH-1 downto 0);		
	signal sBusyn 		: 	std_logic;								
	signal sOp_Ack 	: 	std_logic;								
	
	signal sMDR    	:  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal sMAR    	:  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal sR_W    	:  std_logic;
	signal sMEM_EN		:  std_logic;
	signal sMEM			:  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal sR	   	:  std_logic;
	
	signal sstart_RW_P: std_logic;	
	signal sR_W_Per	: std_logic;
	signal sAddrP		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal sdata_WPer	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal sdata_RPer	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal sPerOpDone	: std_logic;
begin

Peripheral_m: peripheral_ctrl 
	generic map(   
		ADDR_LC3_WIDTH => ADDR_FPGA_WIDTH,	
		DATA_LC3_WIDTH => DATA_WIDTH)
	port map(
		CLK => CLK,
		RST => RST,
		Switches => SWITCHES(3 downto 0),
		LEDS => open,
		
		start_RW_P => sstart_RW_P,
		R_W_Per 	  => sR_W_Per,
		AddrP      => sAddrP,
		data_WPer  => sdata_WPer,
		data_RPer  => sdata_RPer,
		PerOpDone  => sPerOpDone
	);
	
Serial_m: Serial
	Port map ( 	
		CLK		=> CLK,
		RST		=>	RST,
		
		TXD		=> TXD,
		RXD		=> RXD,
		
		DATA_R	=>	sDATA_R,
		DATA_OUT	=> sDATA_OUT,
		ACK_R		=> sACK_R,
		DATA_W	=> sDATA_W,
		DATA_IN	=> sDATA_IN,
		ACK_W		=> sACK_W
	);

SystemBus_m: systembus
	Generic Map (ADDR_LC3_WIDTH => ADDR_FPGA_WIDTH,
	             DATA_LC3_WIDTH => DATA_WIDTH)
	Port map ( 	
		CLK		=> CLK,
		RST		=>	RST,
		LEDS		=> LEDS,

		DATA_R	=> sDATA_R,
		DATA_OUT	=> sDATA_OUT,
		ACK_R		=> sACK_R,
		DATA_W	=> sDATA_W,
		DATA_IN	=> sDATA_IN,
		ACK_W		=> sACK_W,
		
		Addr_ToM => sAddr_ToM,
		Data_FrM	=> sData_FrM,
		Data_ToM => sData_ToM,
		Op     	=> sOp,
		Op_Ack 	=> sOp_Ack,
		Busyn 	=> sBusyn,
	
		MDR    	=> sMDR,
		MAR    	=> sMAR,
		R_W    	=> sR_W,
		MEM_EN 	=> sMEM_EN,
		MEM	 	=> sMEM,
		R	    	=> sR,
		
		start_RW_P => sstart_RW_P,
		R_W_Per    => sR_W_Per,
		AddrP      => sAddrP,
		data_WPer  => sdata_WPer,
		data_RPer  => sdata_RPer,
		PerOpDone  => sPerOpDone
	);
			
Memory_m: nexys2_mem_interface
	Generic Map(   
		ADDR_MEM_WIDTH => ADDR_MEM_WIDTH,
		ADDR_FPGA_WIDTH => ADDR_FPGA_WIDTH,
		DATA_WIDTH => DATA_WIDTH,
		CYCLES_WAITING => CYCLES_WAITING)
	Port Map(         
		CLK 	=> CLK,
		RESET => RST,
		
		Addr_m => Addr_m, 
		Data_m => Data_m, 
		Clk_m  => Clk_m, 
		ADVn_m => ADVn_m, 
		CRE_m  => CRE_m, 
		CEn_m  => CEn_m,
		OEn_m  => OEn_m, 
		WEn_m  => WEn_m, 
		LBn_m  => LBn_m, 
		UBn_m  => UBn_m,
		
		Addr_f     => sAddr_ToM, 
		Data_f_in  => sData_FrM, 
		Data_f_out => sData_ToM,
		Op_f       => sOp, 
		Op_Ack_f   => sOp_Ack, 
		Busyn_f    => sBusyn
	);

LC3: LC_3_data_path 
	Generic Map (
		DATA_BITS   => DATA_WIDTH,
		MEMORY_SIZE => ADDR_FPGA_WIDTH)
	Port map (
		CLK	   	=> CLK,
		Reset   		=> RST,
		LEDS			=> open,
		
		MDR_out     => sMDR,
		MAR_out     => sMAR,
		R_W_out     => sR_W,
		MEM_EN_out  => sMEM_EN,
		mem_input   => sMEM,
		R_input     => sR
	);
end Behavioral;

