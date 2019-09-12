-- ***************************************************************************************
-- LC3 Processor
-- Digital Electronics Lab Course
-- 2019
-- Module: Serial Peripheral Controller
-- ***************************************************************************************

--#############################################################################
--
--   modulo serial com. autobaud - sin señales CTS ni RTS!
--  
--    clock     -- clock
--    reset     -- reset (activo en 1)
--
--    rx_data   -- byte a ser transmitido hacia el PC
--    rx_start  -- indica byte disponible en rx_data (activo en 1) 
--    rx_busy   -- fijo en '1' cuando envia al PC
--    rxd       -- línea de envío hacia el PC
--
--    txd       -- línea de transmisión desde el PC
--    tx_data   -- Registro que contiene el dato que proviene del PC
--    tx_av     -- Indica que ha llegado un dato desde el PC
-- 
--          +------------------+
--          | SERIAL           |                   
--          |    +--------+    |
--  PC_TXD  |    |        |    |
--     --------->|        |=========> tx_data (8bits)
--          |    | TRANS. |    |
--          |    |        |---------> tx_av
--          |    |        |    |
--          |    +--------+    |
--          |                  |
--          |    +--------+    |
--          |    |        |    |
--  RC_RXD  |    |        |<========== rx_data (8bits)
--     <---------| RECEP. |<---------- rx_start
--          |    |        |----------> rx_busy
--          |    |        |    |
--          |    +--------+    |
--          +------------------+
--
--
--#############################################################################

--*******************************************************************   
--   módulo serial
--*******************************************************************   
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity serialinterface is
port(
    clock	: 	in std_logic;                        
    reset	: 	in std_logic;                        
   
    rx_data	: 	in std_logic_vector (7 downto 0);  
    rx_start: 	in std_logic;                     
    rx_busy	: 	out std_logic;                     
    rxd		: 	out std_logic;                         
    
    txd		: 	in std_logic;                          
    tx_data	: 	out std_logic_vector (7 downto 0); 
    tx_av	: 	out std_logic                        
  );
end serialinterface;
 
architecture serialinterface of serialinterface is
 -- auto baud
 type Sreg0_type is (S1, S2, S3, S4, S6);
 signal Sreg0:     Sreg0_type;
 signal ctr0    :  STD_LOGIC_VECTOR(16 downto 0);
 signal Bit_Cnt:   STD_LOGIC_VECTOR (1 downto 0);    
 -- Generación de señal de reloj
 signal CK_CYCLES  : STD_LOGIC_VECTOR(13 downto 0);      
 signal contador   : STD_LOGIC_VECTOR(13 downto 0);
 signal serial_clk : STD_LOGIC; 
 -- Recepción
 signal word, busy : STD_LOGIC_VECTOR (8 downto 0);
 signal go         : STD_LOGIC;
 -- Transmisión
 signal regin     : STD_LOGIC_VECTOR(9 downto 0);   -- 10 bits:  start/byte/stop
 signal resync, r : STD_LOGIC;
begin                                                                            
    
  --#############################################################################
  -- autobaud: El PC envia 55H (0101 0101). Este proceso cuenta cuantos
  -- pulsos de clock 'caben' en cada '1'. Luego, cuenta 4 veces. Para
  -- obtener el semiperiodo, se divide por 8
  --#############################################################################
  Sreg0_machine: process (reset, clock)
  begin
    if Reset = '0' then
      Sreg0 <= S1;
      Bit_Cnt <= "00";  
      ck_cycles <= (OTHERS=>'0');   
      ctr0 <=(OTHERS=>'0');     
    elsif clock'event and clock = '1' then
		case Sreg0 is
		 when S1 => if txd = '0'  then    
							  Sreg0 <= S2;     
							  ctr0 <= (OTHERS=>'0');
						end if;
		 when S2 => ctr0 <= ctr0 + 1;      
						if txd = '1' then      
							  Sreg0 <= S3;
							  Bit_cnt <= Bit_Cnt + '1';
						end if;
		 when S3 => if Bit_cnt /= "00"   and txd = '0' then
							  Sreg0 <= S2;
						elsif Bit_cnt = "00" and txd = '0' then
							  Sreg0 <= S4;
						end if;
		 when S4 => if txd = '1' then
							  Sreg0 <= S6;
						end if;
		 when S6 => Sreg0 <= S6; 
						ck_cycles <= ctr0(16 downto 3);
		end case;
   end if;
  end process; 
    
   process(resync, clock)      
    begin 
      if resync='1' then   
		  contador <= (0=>'1', others=>'0');
		  serial_clk <='0';       
      elsif clock'event and clock='0' then     
        if contador = ck_cycles then
			  serial_clk <= not serial_clk;      
			  contador <= (0=>'1', others=>'0');
        else
			  contador <= contador + 1;
        end if;
    end if;       
   end process;                              
                                 
   process (resync, serial_clk)
   begin
     if resync = '1' then 
       regin <= (others=>'1');  
     elsif serial_clk'event and serial_clk='1' then
       regin <= txd & regin(9 downto 1);
     end if;
   end process;
  
   process (clock, ck_cycles)
   begin
     if ck_cycles=0 then 
		r      <= '0';
		resync <= '1';
		tx_data <= (others=>'0'); 
		tx_av <= '0';
     elsif clock'event and clock='1' then
		if r='0' and txd='0' then  
		 r      <= '1';
		 resync <= '1';    
		 tx_av <= '0';
		elsif r='1' and regin(0)='0' then  
		 r      <= '0';
		 tx_data <= regin(8 downto 1); 
		 tx_av <= '1';
		else
		 resync <= '0'; 
		 tx_av <= '0';
		end if;
     end if;
   end process;
  
   process(rx_start, reset, serial_clk)
	begin     
		if rx_start='1' or reset='0' then   
			go      <= rx_start ;
			rx_busy <= rx_start ;
			--           word    <= (others=>'1');
			if reset='0' then
				busy    <= (others=>'0');
			else
				busy    <= (others=>'1');
			end if;
		elsif serial_clk'event and serial_clk ='1' then
			go <= '0';  
			if go='1' then      
			 word <= rx_data & '0';   
			 busy <= (8=>'0', others=>'1');
			else
			 word <= '1' & word(8 downto 1); 
			 busy <= '0' & busy(8 downto 1); 
			 rx_busy <= busy(0);
			end if;
		end if; 
	end process;    
    
   rxd <= word(0);
end serialinterface;

