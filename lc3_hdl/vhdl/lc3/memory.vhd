-- ***************************************************************************************
-- LC3 Processor
-- Digital Electronics Lab Course
-- 2019
-- Module: Memory Unit
-- ***************************************************************************************

library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std;
entity MEMORY is
  generic (
    DATA_BITS   : integer := 16;
    MEMORY_SIZE : integer := 16);
  port (
--    Clock  : in std_logic;
--    Reset  : in std_logic;
-- Interface between LC3 and this interface
    MDR     : in std_logic_vector((DATA_BITS - 1) downto 0);
    MAR     : in std_logic_vector((DATA_BITS - 1) downto 0);
    R_W     : in std_logic;
    MEM_EN  : in std_logic;
    MEM 	   : out std_logic_vector((DATA_BITS - 1) downto 0);
    R       : out std_logic;
-- Interface between this interface and the external memory
	 MDR_o    : out std_logic_vector((DATA_BITS - 1) downto 0);
    MAR_o    : out std_logic_vector((DATA_BITS - 1) downto 0);
    R_W_o    : out std_logic;
    MEM_EN_o : out std_logic;
	 MEM_in	 : in std_logic_vector((DATA_BITS - 1) downto 0);
    R_in   	 : in std_logic);

end MEMORY;

architecture behavior of MEMORY is
begin
  MDR_o <= MDR;    
  MAR_o <= MAR;   
  R_W_o <= R_W;    
  MEM_EN_o <= MEM_EN;
  MEM <= MEM_in;
  -- mem(15 downto 8)<=mem_in(7 downto 0);
  -- mem(7 downto 0)<=mem_in(15 downto 8);
  R <= R_in;
end behavior;
