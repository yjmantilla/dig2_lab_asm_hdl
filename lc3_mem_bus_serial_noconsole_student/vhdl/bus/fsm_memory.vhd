-- ***************************************************************************************
-- LC3 Processor
-- Digital Electronics Lab Course
-- 2019
-- Module: FSM for Memory Access
-- ***************************************************************************************
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fsm_memory is
Generic(   
			ADDR_LC3_WIDTH	 : natural := 16;
			DATA_LC3_WIDTH  : natural := 16);
Port ( 	
			CLK		 : in  std_logic;
			RST		 : in  std_logic;
			-- Signals from/to programming/communication module
			start_RW	 : in  std_logic;								-- Start a memory operation
			R_W		 : in  std_logic;								-- Read (0), Write (1)
			AddrM  	 : in  std_logic_vector(ADDR_LC3_WIDTH-1 downto 0);	-- Mem Addr
			data_WM	 : in  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- Write Data
			data_RM	 : out std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- Read Data
			MemOpDone : out std_logic;								--fin de la operacion
			-- Signals from/to Memory Interface module
			Addr_ToM	 : out std_logic_vector(ADDR_LC3_WIDTH-1 downto 0); -- Mem Address
			Data_FrM  : in  std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- Data to read from MEM
			Data_ToM  : out std_logic_vector(DATA_LC3_WIDTH-1 downto 0);	-- Data to write to MEM
			Op     	 : out std_logic_vector(1 downto 0);	-- Op W(10), R(01), NOT-OP(00)
			Op_Ack 	 : in  std_logic;							-- Operation ACK
			Busyn 	 : in  std_logic							-- Memory busy
   );
end fsm_memory;

architecture Behavioral of fsm_memory is

signal sdata_RM   : std_logic_vector(DATA_LC3_WIDTH-1 downto 0) := (others => '0');
signal sMemOpDone : std_logic := '0';
signal sAddr_ToM  : std_logic_vector(ADDR_LC3_WIDTH-1 downto 0) := (others => '0');
signal sData_ToM  : std_logic_vector(DATA_LC3_WIDTH-1 downto 0) := (others => '0');
signal sOp 			: std_logic_vector(1 downto 0) := (others => '0');
signal sR_W       : std_logic := '0';

--Maquina de estados para administrar la MEM
type fsm_mem_states is (m0, m1, m2, m3, m4);
signal mem_state : fsm_mem_states := m0;

begin
	data_RM   <= sdata_RM;
	MemOpDone <= sMemOpDone;
	Addr_ToM  <= sAddr_ToM;
	Data_ToM  <= sData_ToM;
	Op        <= sOp;
	
	process(CLK, RST)
	begin
		if RST = '1' then
			mem_state <= m0;
			sdata_RM  <= (others => '0');
			sMemOpDone <= '0';
			sAddr_ToM <= (others => '0');
			sData_ToM <= (others => '0');
			sOp       <= (others => '0');
			sR_W      <= '0';
		elsif (rising_edge(CLK)) then			
			-- Always do the following (it can be override by a particular case)
			sMemOpDone <= '0';
			
			case mem_state is							
				when m0 =>	
					if (start_RW = '1') then	-- Ready to start a writing/reading process?
						mem_state <= m1;
					else	
						mem_state <= m0;
					end if;	
				when m1 =>								
					if (Busyn = '1') then 		-- Memory ready?
						mem_state <= m2;
					else	
						mem_state <= m1;
					end if;	
				when m2 =>
					sAddr_ToM <= AddrM;
					if R_W = '1' then				-- Writing process
						sData_ToM <= data_WM;
						sOP <= "10";
					else 								-- Reading process
						sOP <= "01";
					end if;
					sR_W <= R_W;
					mem_state <= m3;				
				when m3 =>
					if (op_ack = '1') then		-- Waiting for operation ack
						sOp <= "00";					
						mem_state <= m4;					
					end if;	
				when m4 =>	
					if (Busyn = '1') then		-- Memory already available?
						sMemOpDone <= '1';		-- Operation acomplished
						if (sR_W = '0') then		-- Was a reading operation?
							sdata_RM <= Data_FrM;
						end if;	
						mem_state <= m0;
					end if;	
				end case;	
			end if;
	end process;
end Behavioral;

