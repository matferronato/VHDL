library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

ENTITY rcv_fsm IS 
generic( DATA_SIZE : integer := 8;
		 PKT_NUMBER : integer := 5;
		 ALIGMENT_NUMBER : integer := 3;
		 ALIGMENT_VALUE : integer);
PORT
(
	clk_in, rst_in, data_sr_in :IN STD_LOGIC;
	data_pl_out :OUT STD_LOGIC_VECTOR(DATA_SIZE-1 downto 0);
	data_en_out, sync_out :OUT STD_LOGIC
);
END rcv_fsm;

ARCHITECTURE arch_rcv_fsm OF rcv_fsm IS
	type fsm_state is (S_Idle,S_Look4Aligment,S_WaitPayload, S_Payload);
	
	constant aligment : std_logic_vector(DATA_SIZE-1 downto 0) := std_logic_vector(to_unsigned(ALIGMENT_VALUE, DATA_SIZE));
	
	signal current_s, next_s : fsm_state;
	
	
	signal aligment_found   : std_logic;
	signal counter_aligment : integer;
	signal counter_payload  : integer range 0 to PKT_NUMBER;
	signal counter_data     : integer range 0 to DATA_SIZE;
	signal counter_bits     : integer;
	signal counter_delay    : integer range 0 to DATA_SIZE-1;
	
	
	signal buffer_data    : std_logic_vector(DATA_SIZE-1 downto 0);

BEGIN


current_updater :
  process(clk_in,rst_in)
	BEGIN
	if rst_in = '1' then
		current_s       <= S_Idle;
		aligment_found  <= '0';
		data_en_out     <= '0';
		sync_out        <= '0';
		counter_delay   <= 0;
		counter_payload <= 0;
		counter_data    <= 0;
		counter_bits    <= 0;
		data_pl_out     <= (others => '0');
		buffer_data     <= (others => '0');
	elsif rising_edge(clk_in) then
	 buffer_data <= buffer_data(DATA_SIZE-2 downto 0) & data_sr_in; --shift regiser de N bits que recebe a entrada serial
		case current_s is 
			when S_Idle => current_s <= S_Look4Aligment;
			when S_Look4Aligment =>   
				if buffer_data = aligment then  --procura valor de alinhamento
					counter_aligment <= counter_aligment +1;  --quando achou, incrementa contador
					if counter_aligment >= ALIGMENT_NUMBER-1 then --se contador ja esta no valor esperado -1, entao transiciona para estado de leitura de payload
						current_s <= S_Payload;
					else
						current_s <= S_WaitPayload;
					end if;
				else 
					counter_aligment <= 0;
					sync_out         <= '0';  --se nao achou valor de alinhamento, desincroniza
				end if;
			when S_WaitPayload => 
				if counter_bits < (DATA_SIZE*PKT_NUMBER)+(DATA_SIZE-1) then  --espera todo trem de payloads passar e mais size-1 ciclos de clock, para esperar shift register preencher o aligment 
					counter_bits <= counter_bits + 1;
				else
					counter_bits <= 0;
					current_s    <= S_Look4Aligment;
				end if;
			when S_Payload => 
				sync_out <= '1'; --informa que sincronizacao foi obtida
				if counter_payload < PKT_NUMBER then
					if counter_data < DATA_SIZE-1 then
						counter_data <= counter_data +1;
						data_en_out  <= '0';
					else 
						data_en_out <= '1';  --manda dados para fora do cuv
						data_pl_out <= buffer_data;
						counter_data <= 0;
						counter_payload <= counter_payload +1;
					end if;	
				else
					data_en_out     <= '0';  
					if counter_delay < DATA_SIZE-1 then
						counter_delay <= counter_delay + 1;
					else
						counter_payload <= 0;
						counter_delay   <= 0;
						current_s       <= S_Look4Aligment;		
					end if;
				end if; 
			end case;
	end if;
  end process;



END arch_rcv_fsm;
