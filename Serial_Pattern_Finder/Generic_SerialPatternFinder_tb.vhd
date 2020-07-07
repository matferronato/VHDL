library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

ENTITY dut_tb IS
END dut_tb;
 
ARCHITECTURE behavior OF dut_tb IS 

    constant size           : integer := 8; --tamanho do barramento
    constant pktNumber      : integer := 15; --numero de pacotes no payload por rajada
    constant aligmentNumber : integer := 6; --numero de alinhamentos confirmados necessario
    constant aligment       : std_logic_vector(size-1 downto 0) := x"A5"; --valor do byte de alinhamento
    constant seed           : std_logic_vector(size-1 downto 0) := x"55"; --semente do lfsr
    
    type state is (S_IDLE, S_ALIGMENT, S_PAYLOAD);
    signal current_s : state;  
   
	signal clk           : std_logic := '0';
	signal rst           : std_logic;
	signal random_en     : std_logic;
	signal sync          : std_logic;
	signal data_read_en  : std_logic;
	signal data_serial   : std_logic;
	signal data_paralel  : std_logic_vector(size-1 downto 0);
	signal random        : std_logic_vector(size-1 downto 0);
	signal random_delay  : std_logic_vector(size-1 downto 0);
	signal data_right    : std_logic_vector(size-1 downto 0);	
	signal counter_bit   : integer range 0 to size-1;
	signal counter_byte  : integer range 0 to pktNumber;
	signal numberError   : integer;
	
   

 
BEGIN
--###########################################################
--##########RESET AND CLOCK               ###################
--###########################################################
	
	clk <= not(clk) after 5 ns;
	rst <= '1','0' after 20 ns;

--###########################################################
--##########Data Gen                      ###################
--###########################################################


	random_en <= '1' WHEN counter_bit = 0 ELSE '0'; --gera novo byte de payload
	aligment_adder : process (clk, rst) 
	begin
		if rst = '1' then
			current_s    <= S_IDLE;
			data_serial  <= '0';
			counter_bit  <= size-1;
			counter_byte <= pktNumber;
			random_delay   <= (others => '0'); 
		elsif rising_edge(clk) then
			case current_s is 
				when S_IDLE => current_s <= S_ALIGMENT ;
				when S_ALIGMENT => 
					data_serial <= aligment(counter_bit); --envia byte de alinhamento começando com MSB
					if counter_bit /= 0 then    
						counter_bit <= counter_bit - 1;
					else 
						counter_bit <= size-1;
						current_s <= S_PAYLOAD;
					end if;
				when S_PAYLOAD =>
					data_serial <= random(counter_bit);	--envia payload do lfsr
					if random_en = '1' then
						random_delay  <= random;
					end if;
					if counter_byte /= 0 then 					
						if counter_bit /= 0 then 
							counter_bit <= counter_bit - 1;
						else 
							counter_byte <= counter_byte -1;
							counter_bit <= size-1;
						end if;
					else 
						counter_bit <= size-1;
						counter_byte <= pktNumber;
						current_s <= S_ALIGMENT;--encerrou o envio do payload, retorna com byte de alinhamento
					end if;
					
				end case;
			end if;			 
		end process;

--###########################################################
--##########Instanciacao dos circuitos    ###################
--###########################################################


   lfsr: entity work.lsfr_generic_reg
			Generic Map (DATA_SIZE => size)
			PORT MAP (
		 clock  		  =>clk,
		 reset		     =>rst,
		 enable        =>random_en,
		 seed          =>SEED,
         in_value      =>random,
         out_value     =>random
        );
 
    cuv: entity work.rcv_fsm
			Generic Map (
			DATA_SIZE => size,
			PKT_NUMBER => pktNumber,
			ALIGMENT_NUMBER => aligmentNumber,
			ALIGMENT_VALUE => to_integer(unsigned(aligment)))
			PORT MAP (
			clk_in  	=> clk,
			rst_in		=> rst,
			data_sr_in  => data_serial,
            data_pl_out => data_paralel,
            data_en_out => data_read_en,
            sync_out    => sync
        );  

--###########################################################
--##########Instanciacao dos circuitos    ###################
--###########################################################
  
  data_right <= random_delay xor data_paralel; --confere sinal de payload gerado com sinal da saída do cuv

	process(clk, rst)
	begin
	if rst = '1' then
		numberError <= 0;
	elsif rising_edge (clk) then
			if data_read_en = '1' then
				if data_right /= x"00" then --confirma se existe descrepancia entre os dois
					numberError <= numberError +1;
				end if;
			end if;
	end if;
	end process;	

END;
