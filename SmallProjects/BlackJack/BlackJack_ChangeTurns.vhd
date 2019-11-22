library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity edge_detector is
port(
	clk, rst: in std_logic;
	input  : in std_logic;
	output : out std_logic
);
end edge_detector;

architecture arch_edge_detector of edge_detector is

	signal delay : std_logic;

begin

process(clk, rst)
begin
	if rst = '1' then
		delay <= '0';
	elsif rising_edge(clk) then
		delay <= input;
	end if;
end process;

	output <= not(delay) and input;
	
end arch_edge_detector;


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity BlackJack is
port(
	clk, reset, hit, stay, debug, show : in std_logic;
	card : in std_logic_vector(3 downto 0);
	win, lose, tie, request : out std_logic;
	total : out std_logic_vector(4 downto 0)
);
end BlackJack;

architecture arch_BlackJack of BlackJack is

	type   state is (holdOn, Play);
	signal fsm : state;
	signal edgeDetectorIn  : std_logic_vector(1 downto 0);
	signal edgeDetectorOut : std_logic_vector(1 downto 0);

	signal sumPlayer   : std_logic;
	signal sumDealer   : std_logic;
	signal endGame     : std_logic;
	signal turn        : std_logic;
	signal pcoward     : std_logic;
	signal dcoward     : std_logic;
	signal playerTotal : std_logic_vector(4 downto 0);
	signal dealerTotal : std_logic_vector(4 downto 0);
	signal cardEleven  : std_logic_vector(3 downto 0);
	signal newCard     : std_logic_vector(3 downto 0);
	
	signal ohAnotherCounter : integer range 0 to 7;
	
begin

--EDGE DETECTION
	edgeDetectorIn(0) <=  hit;
	edgeDetectorIn(1) <=  stay;
	pulse_generation: for i in 0 to 1 generate
    detector: entity work.edge_detector
			PORT MAP (
			clk  	=> clk,
			rst	 => reset,
			input  => edgeDetectorIn(i),
            output => edgeDetectorOut(i)
        );  
	end generate pulse_generation;


--FSM

	
	selector : process(endGame, show, debug, playerTotal, dealerTotal)
	begin
		total <= playerTotal;
		if endGame = '1' or debug = '1'  then
			if show = '0' then
				total <= playerTotal;
			else
				total <= dealerTotal;
			end if;
		end if;
	end process;
	
	
	request   <= edgeDetectorOut(0);
	sumPlayer <= '1' when edgeDetectorOut(0) = '1' else '0';
	sumDealer <= '1' when endGame = '0' else '0';
	
	checker : process(clk, reset)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				lose       <= '0';
				win         <= '0';
				tie         <= '0';
			else
				if playerTotal > 21 then
					lose <= '1';
				elsif endGame = '1' then
					if dealerTotal > 21 or playerTotal > dealerTotal then
						win   <= '1';
					elsif playerTotal < dealerTotal then
						lose <= '1';
					elsif playerTotal = dealerTotal then
						tie   <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;


	cardEleven <= "1011" when (playerTotal > 16 and turn ='0') or (dealerTotal > 16 and turn ='1') else
                  "0001";
                  
    newCard    <= cardEleven when card = "1011" else
                  card;	           
	endGame    <= pcoward and dcoward; 

	adder : process(clk, reset)
		variable currentDealerScore : std_logic_vector(4 downto 0);
	begin
		if rising_edge(clk) then  
			if reset = '1' then --reset sincrono
				currentDealerScore := (others => '0');
				playerTotal        <= (others => '0');
				dealerTotal        <= (others => '0');
				turn               <= '0';
				pcoward            <= '0';
				dcoward            <= '0';
				fsm                <= holdOn;
				ohAnotherCounter   <= 0;	
			else
				case fsm is 
				when HoldOn =>
					ohAnotherCounter <= ohAnotherCounter + 1;
					if ohAnotherCounter = 3 then
						fsm  <= Play;
						turn <= '0';
					else 
						turn <= not(turn);
					end if;
					if turn = '0' then
						playerTotal <= playerTotal + newCard;
					else
						dealerTotal <= dealerTotal + newCard;		
					end if;
				when Play =>
					if turn = '0' then			
						if edgeDetectorOut(0) = '1' then
							playerTotal <= playerTotal + newCard;
						end if;
						if edgeDetectorOut(1) = '1' then
							pcoward      <= '1';
						end if;				
						if dcoward /= '1' and  edgeDetectorOut /= "00" then
							turn <= '1';
						end if;
					else
						if sumDealer = '1' then
							dealerTotal <= dealerTotal + newCard;
							currentDealerScore := dealerTotal + card;
							if currentDealerScore >= 16  then 
								dcoward <= '1';
							end if;
							if pcoward /= '1' then
								turn    <= '0';
							end if;
						end if;
					end if;
				end case;
			end if;
		end if;
	end process;


end arch_BlackJack;
