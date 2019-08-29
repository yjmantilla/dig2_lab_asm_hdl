-- ***************************************************************************************
-- LC3 Processor
-- Digital Electronics Lab Course
-- 2019
-- Module: Memory SRAM Interface
-- ***************************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity nexys2_mem_interface is
    Generic(   
			   ADDR_MEM_WIDTH  : natural := 23;
			   ADDR_FPGA_WIDTH : natural := 16;
			   DATA_WIDTH      : natural := 16;
			   CYCLES_WAITING  : natural := 4);
    Port (  CLK    : in    STD_LOGIC;
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
end nexys2_mem_interface;

architecture Behavioral of nexys2_mem_interface is
-- Signals declaration for Memory Interface <--> MEM
signal sAddr_m : STD_LOGIC_VECTOR (ADDR_MEM_WIDTH-1 downto 0) := (others => '0');
signal sData_m : STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0) := (others => '0'); -- To Mem
signal sClk_m  : STD_LOGIC := '0';	-- Clock enabled
signal sADVn_m : STD_LOGIC := '0';	-- Address valid enabled
signal sCRE_m  : STD_LOGIC := '0';	-- Control register disabled
signal sCEn_m  : STD_LOGIC := '1';	-- Chip select disabled	
signal sOEn_m  : STD_LOGIC := '1';	-- Output disabled
signal sWEn_m  : STD_LOGIC := '1';	-- Read enabled: data is enabled for read
signal sLBn_m  : STD_LOGIC := '0';	-- Lower Byte enabled
signal sUBn_m  : STD_LOGIC := '0';	-- Upper Byte enabled
-- Signals declaration for FPGA <--> Memory Interface
signal sData_f_in : STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0) := (others => '0'); -- To FPGA
signal sOp_Ack_f  : STD_LOGIC := '0';	-- No acked
signal sBusyn_f   : STD_LOGIC := '0';	-- Mem busy

-- States for controlling the memory
type memory_op_states_t is (MEMST_RESET, MEMST_WAITINGOP, MEMST_OPERATION);
signal memory_op_states : memory_op_states_t := MEMST_RESET;
signal memory_cnt_cycles : natural range 0 to CYCLES_WAITING-1 := 0;

begin
	-- Port connections: Memory Interface <--> MEM
	Addr_m <= sAddr_m;
	Data_m <= sData_m when sWEn_m = '0' else (others => 'Z');
	Clk_m  <= sClk_m;
	ADVn_m <= sADVn_m;
	CRE_m  <= sCRE_m;
	CEn_m  <= sCEn_m;
	OEn_m  <= sOEn_m;
	WEn_m  <= sWEn_m;
	LBn_m  <= sLBn_m;
	UBn_m  <= sUBn_m;
	-- Port connections: FPGA <--> Memory Interface
	Data_f_in <= sData_f_in;
	Op_Ack_f  <= sOp_Ack_f;
	Busyn_f   <= sBusyn_f;
	
	-- Memory process
	MemCtrl: process(CLK, RESET)
	begin
		if (RESET = '1') then
			memory_op_states <= MEMST_RESET;
			memory_cnt_cycles <= 0;
		elsif (RISING_EDGE(CLK)) then
			case memory_op_states is
				when MEMST_RESET =>
					-- Memory Interface <--> MEM
					sAddr_m <= (others => '0');
					sData_m <= (others => '0');
					sClk_m  <= '0';	-- Clock always enabled
					sADVn_m <= '0';	-- Address always valid
					sCRE_m  <= '0';	-- Control register always disabled
					sCEn_m  <= '1';	-- Chip select disabled	
					sOEn_m  <= '1';	-- Output disabled
					sWEn_m  <= '1';	-- Read enabled
					sLBn_m  <= '0';	-- Lower Byte always enabled
					sUBn_m  <= '0';	-- Upper Byte always enabled
					-- FPGA <--> Memory Interface
					sData_f_in <= (others => '0');
					sOp_Ack_f  <= '0';	-- No ack
					sBusyn_f   <= '1';	-- Memory not busy
					-- Others
					memory_cnt_cycles <= 0;
					memory_op_states <= MEMST_WAITINGOP;
				when MEMST_WAITINGOP =>
					sOp_Ack_f  <= '0';			-- Not ack yet
					sBusyn_f   <= '1';			-- Memory not busy
					memory_cnt_cycles <= 0;		
					if (Op_f = "10") then 		-- Writing
						sAddr_m(ADDR_FPGA_WIDTH-1 downto 0) <= Addr_f;		-- Address
						sData_m <= Data_f_out;	-- Data
						sCEn_m  <= '0';			-- Chip select enabled
						sOEn_m  <= '1';			-- Output disabled
						sWEn_m  <= '0';			-- Write enabled
						sOp_Ack_f  <= '1';		-- Ack the operation
						sBusyn_f   <= '0';		-- Memory busy (Writing)

						memory_op_states <= MEMST_OPERATION;
					elsif (Op_f = "01") then	-- Reading
						sAddr_m(ADDR_FPGA_WIDTH-1 downto 0) <= Addr_f;		-- Address
						sCEn_m  <= '0';			-- Chip select enabled
						sOEn_m  <= '0';			-- Output enabled
						sWEn_m  <= '1';			-- Read enabled
						sOp_Ack_f  <= '1';		-- Ack the operation
						sBusyn_f   <= '0';		-- Memory busy (Reading)

						memory_op_states <= MEMST_OPERATION;
					else
						memory_op_states <= MEMST_WAITINGOP;
					end if;
				when MEMST_OPERATION =>
					sOp_Ack_f <= '0';
					sBusyn_f  <= '0';				-- Memory still busy
					memory_cnt_cycles <= memory_cnt_cycles + 1;
					if (memory_cnt_cycles+1 = CYCLES_WAITING) then
						if (sWEn_m = '1') then -- Reading
							sData_f_in <= Data_m;
						end if;

						sCEn_m <= '1';		-- Chip select disabled	
						sOEn_m <= '1';		-- Output disabled
						sWEn_m <= '1';		-- Read enabled
						sBusyn_f <= '1';	-- Memory no longer busy

						memory_cnt_cycles <= 0;
						memory_op_states <= MEMST_WAITINGOP;
					end if;	
			end case;	
		end if;
	end process;
end Behavioral;

