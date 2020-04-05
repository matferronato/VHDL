library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

ENTITY dut_tb IS
END dut_tb;

ARCHITECTURE behavior OF dut_tb IS

  procedure print(str : in string) is  -- printa na tela sem informacao extra de tempo vinda do comando report
    variable oline   : line;
    variable outline : line;
  begin
    write(oline, str);
    writeline(output, oline);
  end procedure;

  function hex_to_string (number : std_logic_vector) return string is  -- transforma byte em string para melhor impressao no relatorio
	variable intermediate : std_logic_vector(7 downto 0);
	variable result       : string(1 to 2);
	variable half_byte    : std_logic_vector(3 downto 0);

  begin
	intermediate := number;
	for i in 0 to 1 loop
		half_byte := intermediate(((i+1)*4)-1 downto i*4);
		case half_byte is
          when x"0"   => result(2-i) := '0';
          when x"1"   => result(2-i) := '1';
          when x"2"   => result(2-i) := '2';
          when x"3"   => result(2-i) := '3';
          when x"4"   => result(2-i) := '4';
          when x"5"   => result(2-i) := '5';
          when x"6"   => result(2-i) := '6';
          when x"7"   => result(2-i) := '7';
          when x"8"   => result(2-i) := '8';
          when x"9"   => result(2-i) := '9';
          when x"A"   => result(2-i) := 'A';
          when x"B"   => result(2-i) := 'B';
          when x"C"   => result(2-i) := 'C';
          when x"D"   => result(2-i) := 'D';
          when x"E"   => result(2-i) := 'E';
          when x"F"   => result(2-i) := 'F';
          when "ZZZZ" => result(2-i) := 'Z';
          when others => result(2-i) := 'X';
        end case;
      end loop;
	return result;
   end function hex_to_string;

  type state is (S_IDLE, S_NORMAL, S_READ, S_WRITE, S_OVERFLOW);
  signal current_s : state;
  signal current_a : state;

	constant data_size : integer := 8;
	constant fifo_size : integer := 8;

	signal clk_A : std_logic := '0';
	signal clk_B : std_logic := '0';
	signal rst   : std_logic;

	signal data_wr_s : std_logic_vector(data_size-1 downto 0);
	signal data_rd_s : std_logic_vector(data_size-1 downto 0);
	signal wr_en_s   : std_logic;
	signal rd_en_s   : std_logic;
	signal full_s    : std_logic;
	signal a_full_s  : std_logic;
	signal empty_s   : std_logic;
	signal a_empty_s : std_logic;

	signal data_wr_a : std_logic_vector(data_size-1 downto 0);
	signal data_rd_a : std_logic_vector(data_size-1 downto 0);
	signal wr_en_a   : std_logic;
	signal rd_en_a   : std_logic;
	signal full_a    : std_logic;
	signal a_full_a  : std_logic;
	signal empty_a   : std_logic;
	signal a_empty_a : std_logic;

   signal counter_s : integer;
   signal counter_a : integer;

BEGIN

--###########################################################
--##########Gerador clock reset           ###################
--###########################################################
    rst <='1', '0' after 25 ns;
    clk_A <= not(clk_A) after 25 ns;
	 
	 process(clk_A, rst)
	 begin
		if rst = '1' then
		clk_B <= '0';
		elsif rising_edge(clk_A) then
			clk_B <= not(clk_B);
		end if;
	 end process;

--###########################################################
--##########Geracao de estimulos Sync     ###################
--###########################################################

	process(clk_A, rst)
	begin
	if rst = '1' then
	   data_wr_s   <= (others => '0');
	   counter_s   <= 0;
	   current_s   <= S_IDLE;
	   wr_en_s     <= '0';
	   rd_en_s     <= '0';
	elsif rising_edge(clk_A) then
		data_wr_s <= data_wr_s -1;
    case current_s is
      when S_IDLE =>
        current_s <= S_WRITE;
        data_wr_s <= (others => '1');
		  wr_en_s   <= '1';
      when S_WRITE => --WRITE
		  if counter_s < fifo_size-1 then
			counter_s <= counter_s + 1;
		  else
			counter_s <= 0;
			current_s <= S_READ;
			rd_en_s     <= '1';
			wr_en_s     <= '0';
		  end if;		  
      when S_READ =>  --READ
		  if counter_s < fifo_size-1 then
			counter_s <= counter_s + 1;
		  else
			counter_s <= 0;
			current_s <= S_NORMAL;
			rd_en_s     <= '0';
			wr_en_s     <= '1';
		  end if;		 
      when S_NORMAL =>  --READ		  
		  rd_en_s     <= '1';
		when others => null;
		end case;
	end if;
	end process;

--###########################################################
--##########Geracao de estimulos BiSyn    ###################
--###########################################################


	process(clk_A, rst)
	begin
		if rst = '1' then
			data_wr_a   <= (others => '0');
			counter_a   <= 0;
			current_a   <= S_IDLE;
			wr_en_a     <= '0';
			rd_en_a     <= '0';
		elsif rising_edge(clk_A) then
			data_wr_a <= data_wr_s -1;
			case current_a is
				when S_IDLE =>
					current_a <= S_NORMAL;
					data_wr_a   <= (others => '1');
					wr_en_a   <= '1';
				when S_NORMAL => --NORMAL
					if counter_a > 2 then
						rd_en_a   <= '1';
						wr_en_a   <= '0';
						counter_a <= 0;
					else
						rd_en_a   <= '0';
						wr_en_a   <= '1';
						counter_a <= counter_a + 1;

					end if;
				when others => null;
			end case;
		end if;
	end process;
--###########################################################
--##########Instanciacao dos circuitos    ###################
--###########################################################

   dut_s: entity work.FIFO_SYNC
   GENERIC MAP (data_size => data_size,
                fifo_size => fifo_size)
   PORT MAP (
					clk       => clk_A,
					rst       => rst,
					wr_en     => wr_en_s,
					wr_data   => data_wr_s,
					rd_en     => rd_en_s,
					rd_data   => data_rd_s,
    			   sts_full  => full_s,
					sts_high  => a_full_s,
					sts_low   => a_empty_s,
					sts_empty => empty_s
        );

   dut_as: entity work.FIFO_ASYNC
   GENERIC MAP (data_size => data_size,
                fifo_size => fifo_size)
   PORT MAP (
					clk_wr    => clk_A,
					clk_rd    => clk_B,
					rst       => rst,
					wr_en     => wr_en_a,
					wr_data   => data_wr_a,
					rd_en     => rd_en_a,
					rd_data   => data_rd_a,
    			   sts_full  => full_a,
					sts_high  => a_full_a,
					sts_low   => a_empty_a,
					sts_empty => empty_a
        );

END;
