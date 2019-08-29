-- ***************************************************************************************
-- LC3 Processor
-- Digital Electronics Lab Course
-- 2019
-- Module: LC3 FSM to access the communication bus
-- ***************************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fsm_lc3 is
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
			StartLC3		: in  std_logic;
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
end fsm_lc3;

architecture Behavioral of fsm_lc3 is
-- LC3 FSM
type fsm_lc3_states is (lc3_init, lc3_memen, lc3_memper, lc3_mem, lc3_per);
signal lc3_state : fsm_lc3_states := lc3_init;

constant PERIPHERAL_MEM_BASE : std_logic_vector(ADDR_LC3_WIDTH-1 downto 0) := x"FE00";
signal memper_operation : std_logic := '0';
begin
	-- Memory
	AddrM   	 <= MAR;
	data_WMem <= MDR;
	R_W_Mem 	 <= R_W; -- Read(0), Write(1)
	
	-- Peripheral
	AddrP     <= MAR;
	data_WPer <= MDR;
	R_W_Per   <= R_W; -- Read(0), Write(1)

	process(CLK, RST)
		begin
			if (RST = '1') then
				R <= '0';
				start_RW_M <= '0';
				start_RW_P <= '0';
				
				memper_operation <= '0';
				lc3_state <= lc3_init;
			elsif (CLK = '1' and CLK'Event) then
				-- Do the following always (a particular case can override them)
				R <= '0';					
				start_RW_M <= '0';
				start_RW_P <= '0';

				case lc3_state is	
					when lc3_init =>
						if (StartLC3 = '1') then
							lc3_state <= lc3_memen;
						else
							lc3_state <= lc3_init;
						end if;
					when lc3_memen =>
						if (MEM_EN = '1') then
							lc3_state <= lc3_memper;
						else
							lc3_state <= lc3_init;
						end if;
					when lc3_memper =>
						memper_operation <= R_W;
						if (MAR < PERIPHERAL_MEM_BASE) then
							start_RW_M <= '1';
							lc3_state <= lc3_mem;
						else
							start_RW_P <= '1';
							lc3_state <= lc3_per;	
						end if;	
					when lc3_mem =>						-- Writing or Reading Memory
						if (MemOpDone = '1') then
							if (memper_operation = '0') then	-- In case the memory is being read
								MEM <= data_RMem;
							end if;	
							R <= '1';
							lc3_state <= lc3_init;	
						end if;	
					when lc3_per =>						-- Writing or Reading Peripheral
						if(PerOpDone = '1') then
							if (memper_operation = '0') then -- In case the peripheral is being read
								MEM <= data_RPer;
							end if;	
							R <= '1';
							lc3_state <= lc3_init;
						end if;
				end case;
			end if;
	end process;		
end Behavioral;

