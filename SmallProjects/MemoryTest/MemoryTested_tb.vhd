library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

ENTITY dut_tb IS
END dut_tb;
 
ARCHITECTURE behavior OF dut_tb IS 
  
  procedure print(str : in string) is                                  -- printa na tela sem informacao extra de tempo vinda do comando report
    variable oline   : line;
    variable outline : line;
  begin
    write(oline, str);                 
    writeline(output, oline);
  end procedure;
   
  function hex_to_string (number : std_logic_vector) return string is  -- transforma byte em string para melhor impressao no relatorio
	variable intermediate : std_logic_vector(number'length -1 downto 0);
	variable result       : string(1 to number'length/4);
	variable half_byte    : std_logic_vector(3 downto 0);

  begin
	intermediate := number;
	for i in 0 to result'length -1 loop
		half_byte := intermediate( ( ( (result'length) -i) *4)-1 downto ((result'length-1)-i )*4); 
		case half_byte is
          when x"0"   => result(i+1) := '0';
          when x"1"   => result(i+1) := '1';
          when x"2"   => result(i+1) := '2';
          when x"3"   => result(i+1) := '3';
          when x"4"   => result(i+1) := '4';
          when x"5"   => result(i+1) := '5';
          when x"6"   => result(i+1) := '6';
          when x"7"   => result(i+1) := '7';
          when x"8"   => result(i+1) := '8';
          when x"9"   => result(i+1) := '9';
          when x"A"   => result(i+1) := 'A';
          when x"B"   => result(i+1) := 'B';
          when x"C"   => result(i+1) := 'C';
          when x"D"   => result(i+1) := 'D';
          when x"E"   => result(i+1) := 'E';
          when x"F"   => result(i+1) := 'F';
          when "ZZZZ" => result(i+1) := 'Z';
          when others => result(i+1) := 'X';
        end case;
      end loop;		
	return result;
   end function hex_to_string;
   
   type state is (S_IDLE, S_READ, S_WRITE, S_POR, S_END);
   signal current_s : state;   
   type test_state is (S_IDLE, S_TEST);
   signal test_current, test_next : test_state;   
   type test_table is array ( 0 to 4 ) of std_logic_vector (7 downto 0);
   type rom_table is array  ( 0 to 5 ) of std_logic_vector (7 downto 0);
   constant rom           : rom_table  := (x"32", x"30", x"31",x"37",x"30",x"39");  --valores read only a serem comparados
   constant test_value    : test_table := (x"ff", x"00", x"55",x"33",x"0f");        --valores para teste de diferentes tipos de problemas
                                                                                    --FF stuck at zero
                                                                                    --00 stuck at one
                                                                                    --55 para um byte com bits ordenados como 76543210, encontra problemas de roteamento do tipo 67543210
                                                                                    --33 para um byte com bits ordenados como 76543210, encontra problemas de roteamento do tipo 56743210
                                                                                    --0F para um byte com bits ordenados como 76543210, encontra problemas de roteamento do tipo 36547210  
 
   constant WRITE_VALUES  : integer := 5;
   constant DELAY         : integer := 5;
   constant SIZE          : integer := 4;
   constant ADDRESS_SPACE : integer := 2**SIZE;
    
   
   signal clk             : std_logic := '0';
   signal writeHeader     : std_logic := '0';
   signal cuv_rst         : std_logic;
   signal POR_end         : std_logic;
   signal rst             : std_logic;
   signal rd_en           : std_logic;
   signal wr_en           : std_logic; 
   signal wr_address      : std_logic_vector( SIZE-1 downto 0 );
   signal rd_address      : std_logic_vector( SIZE-1 downto 0 );
   signal counter_rw      : std_logic_vector( SIZE-1 downto 0 );
   signal addres_delay    : std_logic_vector( SIZE-1 downto 0 );
   signal rd_data         : std_logic_vector( 7 downto 0 );   
   signal wr_data         : std_logic_vector( 7 downto 0 );
   signal checker         : std_logic_vector( 7 downto 0 );
   signal test_data_wire  : std_logic_vector( 7 downto 0 );
   signal test_data_reg   : std_logic_vector( 7 downto 0 );
   signal counter_POR     : integer range 0 to 5;
   signal counter_id      : integer range 0 to 4;	
   


   

 
BEGIN

--###########################################################
--##########Gerador clock reset           ###################
--###########################################################

    rst <='1', '0' after 200 ns;       
	clk <= not(clk) after 20 ns;
	
--###########################################################
--##########Geracao de estimulos          ###################
--###########################################################

  current_updater : 
	process(clk, rst)
	  begin
	  if rst = '1' then 
		test_data_reg <= (others => '0');
		counter_rw    <= (others => '0');
		addres_delay  <= (others => '0');
		counter_POR   <= 0;
		rd_en         <= '0';
		wr_en         <= '0';
		cuv_rst       <= '1';
		counter_id    <=  0;
		POR_end       <= '0';
	  elsif rising_edge(clk) then
		test_data_reg <= test_data_wire;
		addres_delay  <= counter_rw;
		case current_s is 
			when S_IDLE =>                                   --quando em idle, espera 100ns para operar rst do cuv
				if counter_POR < DELAY then
					counter_POR <= counter_POR +1;
				else                                         -- apos 100ns coloca write enable em nivel logico alto
					cuv_rst <= '0';
					counter_POR <= 0;
					current_s <= S_WRITE;
					wr_en <= '1';
				end if;

			when S_WRITE =>   
				if counter_rw < ADDRESS_SPACE-1 then         --escreve valor value(i) nos 2^N -1 registradores
				    counter_rw <= counter_rw +1;
				else
					counter_rw <= (others => '0');
					current_s  <= S_READ;
					rd_en      <= '1';
					Wr_en      <= '0';
				end if;					
				
			when S_READ =>                                   --le os 2^N -1 registradores a procura de falhas
				if counter_rw < ADDRESS_SPACE-1 then
				    counter_rw <= counter_rw +1;
				else
					if counter_id < WRITE_VALUES-1  then     --executa os testes para novos valores a seres verificados
						counter_rw   <= (others => '0');
						current_s    <= S_WRITE;
						rd_en        <= '0';
						wr_en        <= '1';
						counter_id <= counter_id +1;
					else                                     --quando testou todos os valores, executa teste de reset
						rd_en      <= '0';
						wr_en      <= '0';
						counter_rw <= (others => '0');
						if POR_end = '1' then 
							current_s <= S_END;
						else                                 --se ja executou por, encerra o teste
							current_s <= S_POR;
							cuv_rst   <= '1';
						end if;
					end if;
				end if;
				
			when S_POR =>                                    --reinicia a banco de registradores
				if counter_POR < DELAY then
					counter_POR <= counter_POR +1;
				else
				    rd_en  <= '1';
					POR_end <= '1';
					current_s <= S_READ;
					cuv_rst <= '0';
				end if;
				
			when S_END => null;
		end case;
	  end if;
	end process current_updater;


--###########################################################
--##########Instanciacao dos circuitos    ###################
--###########################################################
	wr_address <= counter_rw;
	rd_address <= counter_rw;
	wr_data    <= test_value(counter_id);

   cuv: entity work.reg_bank PORT MAP (
           clk        => clk,  
           rd_en      => rd_en,  
           rst        => cuv_rst,  
           wr_en      => wr_en,  
           rd_data    => rd_data,   
           rd_address => rd_address, 
           wr_data    => wr_data, 
           wr_address => wr_address
        );
   


--###########################################################
--##########Testador                      ###################
--###########################################################

	test_data_wire <= rom(to_integer(unsigned(counter_rw)) mod 6) when counter_rw < 6    else                  -- compara com valor read only esperado sempre
			          "0000" & counter_rw                         when counter_rw < 11 and POR_end = '1' else  -- ou com o numero do registrador, quando teste de reset
			          test_value(0)                               when POR_end = '1' else                      -- ou com a constante FF quando teste de reset
			          test_value(counter_id);	                                                               -- se não compara com o valor que deveria ter sido escrito

	checker   <= rd_data xor test_data_reg;      --confere se os valores são iguais, e apresenta onde eles diferem
	
  update_next_tester : 
	process(current_s, test_current, rd_en)
	begin
		test_next <= test_current;
		case test_current is
			when S_IDLE => if current_s = S_READ then test_next <=  S_TEST; end if;  -- estado de idle altera quando maquina de estimulos esta lendo 
			when S_TEST => if rd_en = '0' then test_next <=  S_IDLE; end if;         -- estadi de teste altera quando maquina de estimulos para de ler
		end case; 
	end process;
	
	
	update_current_tester :
	process(clk, rst)
		variable outline : line;
	    file file_hexa   : TEXT open write_mode is "file_hexa.csv";
	begin
	if rst = '1' then
		test_current <= S_IDLE;
		if writeHeader = '0' then
			write(outline, string'("ENDERECO;RESULTADO ESPERADO;RESULTADO OBTIDO")); --escreve cabecalho da tabela
			writeline(file_hexa, outline);
			writeHeader <= '1';
		end if;
	elsif rising_edge (clk) then
	test_current <= test_next;
	 case test_current is
		when S_IDLE =>
			null;
		when S_TEST =>
			if checker /= x"00" then       --quando valores nao sao iguais
				if POR_end = '1' then      -- confere se esta realizando teste de rest ou nao
					print("teste POR - valor escrito em " &hex_to_string(addres_delay) & " tem valore de reset "  &hex_to_string(test_data_reg) 
					&" mas foi lido "  &hex_to_string(rd_data));		 --escreve no terminal
					write(outline, string'(hex_to_string(addres_delay) & ";" &hex_to_string(test_data_reg) & ";" &hex_to_string(rd_data)));  -- escreve no csv
					writeline(file_hexa, outline);
				else
					print("valor escrito em " &hex_to_string(addres_delay) & " deveria ser "  &hex_to_string(test_data_reg)   
					&" mas foi "  &hex_to_string(rd_data));  --escreve no terminal
					write(outline, string'(hex_to_string(addres_delay) & ";" &hex_to_string(test_data_reg) & ";" &hex_to_string(rd_data)));-- escreve no csv
					writeline(file_hexa, outline);
				end if;
			end if;
	 end case;
	end if;
	end process;



END;
