library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

entity lsfr_generic_reg is
           generic( DATA_SIZE : integer := 8);
           port (
			clock  		  : in std_logic;
			reset		     : in std_logic;
			enable        : in std_logic;
			seed          : in std_logic_vector(DATA_SIZE-1 downto 0);
            in_value      : in std_logic_vector(DATA_SIZE-1 downto 0);
            out_value     : out std_logic_vector(DATA_SIZE-1 downto 0)
         );
end lsfr_generic_reg;


architecture arch_lsfr_generic of lsfr_generic_reg is
  signal intermediate: std_logic_vector(DATA_SIZE-1 downto 0);
  signal tap : std_logic;
  begin
  
	process(clock, reset)
	begin
	if reset = '1' then
		intermediate <= seed;
	elsif rising_edge(clock) then
		if enable = '1' then
			intermediate <= intermediate(DATA_SIZE-2 downto 0) & tap;
		end if;
	end if;
	end process;
	
    --provide options to xor diferent bits // change LFSR polynom
    tap <= '0' when reset = '1' else
            in_value(DATA_SIZE-1) xor in_value(DATA_SIZE-2);

    out_value <= seed when reset = '1' else 
				  intermediate;

end arch_lsfr_generic;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

ENTITY blackjack_tb IS
END blackjack_tb;
 
ARCHITECTURE behavior OF blackjack_tb IS 

  procedure print(str : in string) is                                  -- printa na tela sem informacao extra de tempo vinda do comando report
    variable oline   : line;
    variable outline : line;
  begin
    write(oline, str);                 
    writeline(output, oline);
  end procedure;

	
	type cardArray is array (13 downto 1) of integer range 1 to 13;
	signal cardFifo : cardArray;
   
	signal clk  	   :std_logic := '0';
	signal rst		   :std_logic;	
	signal rst21       :std_logic;
	signal stay		   :std_logic;
	signal hit		   :std_logic;
	signal win   	   :std_logic;
	signal request 	   :std_logic;
    signal tie   	   :std_logic;
    signal loose   	   :std_logic;
    signal winHolder   :std_logic;
    signal tieHolder   :std_logic;
    signal looseHolder :std_logic;
	signal show		   :std_logic;
	signal debug	   :std_logic;
	signal card        :std_logic_vector(3 downto 0);
	signal total       :std_logic_vector(4 downto 0);
	
	signal index       :integer range 1 to 13;
	signal lfsren      :std_logic;
	signal output      :std_logic;
	signal random      :std_logic_vector(4 downto 0);

BEGIN
--###########################################################
--##########RESET AND CLOCK               ###################
--###########################################################
	
	clk <= not(clk) after 5 ns;
	rst <= '1','0' after 20 ns;

	process(clk, rst)
	begin
		if rst = '1' then
			index <= 1;
			looseHolder <= '0';
			winHolder <= '0';
			tieHolder <= '0';
		elsif rising_edge(clk) then
			if index = 13 then
				index <= 1;
			else
				index <= index + 1;
			end if;
			if win = '1' then
				winHolder <= '1';
			end if;
			if tie = '1' then
				tieHolder <= '1';
			end if;
			if loose = '1' then
				looseHolder <= '1';
			end if;
		end if;
	end process;
	

	
	tb : process 
	begin
		for i in 1 to 13 loop
			cardFifo(i) <= i;
		end loop; 
		stay  <= '0';   -- inicia dados zerados
		hit   <= '0';
		debug <= '1';
		show  <= '1';
		rst21 <= '1';
		lfsren <= '0';
		
			wait until rst = '0';
			rst21 <= '0';  -- inicia circuito do blackjack
			wait for 5 ns;
			while (1 = 1) loop  -- loop infinito de testes
				if output = '1' then   -- se acabou jogo, resta para iniciar nova partida
					print("partida encerrada seu score foi " & integer'image( to_integer(unsigned(total) )));
					show <= '0';
					wait for 10 ns;		
					print("score do dealer " & integer'image( to_integer(unsigned(total) )));
					show <= '1';
					rst21 <= '1';
					lfsren <= '1';
					wait for 20 ns;
					show <= '0';
					rst21 <= '0';
					lfsren <= '0';
					wait for  to_integer(unsigned(random))*10 ns; -- espera um tempo aleatorio para começar
				end if;
				if total >= 17 then   -- encerra a jogada quando o valor do player é maior que 17
					stay <= '1';
					wait for 10 ns;
				else                  -- se nao, continua requisitando cartas
					hit <= '1';
					wait for 10 ns;				
				end if;
				hit <= '0';
				stay <= '0';
				wait for to_integer(unsigned(random))*10 ns;  -- se nao, continua requisitando cartas	 
			end loop;
	end process;
	
	
    output <= win or loose or tie;
	card <= std_logic_vector(to_unsigned(cardFifo(index), card'length)) ;
 

	-- Instantiate the Unit Under Test (UUT)
	  uut: entity work.BlackJack
			PORT MAP (
          clk => clk,
          reset => rst21,
          hit => hit,
          stay => stay,
          card => card,
          win => win,
          request => request,
          lose => loose,
          tie => tie,
          debug => debug,
          show => show,
          total => total
        );


   lfsr: entity work.lsfr_generic_reg
			Generic Map (DATA_SIZE => 5)
			PORT MAP (
		 clock  	   =>clk,
		 reset		   =>rst,
		 enable        =>lfsren,
		 seed          =>"11010",
		 in_value      =>random,
		 out_value     =>random
		);

END;
