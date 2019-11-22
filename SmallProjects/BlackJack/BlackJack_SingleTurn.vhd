library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity edge_detector is
port(
	clk, reset: in std_logic;
	input  : in std_logic;
	output : out std_logic
);
end edge_detector;

architecture arch_edge_detector of edge_detector is

	signal delay : std_logic;

begin

process(clk, reset)
begin
	if reset = '1' then
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

	signal turn          : std_logic;
	signal playereseturn : std_logic;
	signal sumPlayer     : std_logic;
	signal sumDealer     : std_logic;
	signal endGame       : std_logic;
	signal playerTotal   : std_logic_vector(4 downto 0);
	signal dealerTotal   : std_logic_vector(4 downto 0);
	signal cardEleven    : std_logic_vector(3 downto 0);
	signal newCard       : std_logic_vector(3 downto 0);
	
	signal ohAnotherCounter : integer range 0 to 7;
	
begin

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

--EDGE DETECTION
	edgeDetectorIn(0) <=  hit;
	edgeDetectorIn(1) <=  stay;
	pulse_generation: for i in 0 to 1 generate
    detector: entity work.edge_detector
			PORT MAP (
			clk  	=> clk,
			reset	 => reset,
			input  => edgeDetectorIn(i),
            output => edgeDetectorOut(i)
        );  
	end generate pulse_generation;


--FSM


	sumPlayer <= '1' when edgeDetectorOut(0) = '1' else '0';
	sumDealer <= '1' when endGame = '0' else '0';
	
	process(clk, reset)
	begin
		if reset = '1' then
			playereseturn <= '1';
			lose       <= '0';
			win         <= '0';
			tie         <= '0';
		elsif rising_edge(clk) then
			if edgeDetectorOut(1) = '1' then
				playereseturn <= '0';
			end if;
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
	end process;

	request    <= edgeDetectorOut(0);
	cardEleven <= "1011" when (playerTotal > 16 and playereseturn ='1') or (dealerTotal > 16 and playereseturn ='0') else
                  "0001";

                  
    newCard    <= cardEleven when card = "0001" else
				  "1010"     when card > "1001" else
                  card;	           

	process(clk, reset)
		variable currentDealerScore : std_logic_vector(4 downto 0);
	begin
		if reset = '1' then
			currentDealerScore := (others => '0');
			playerTotal        <= (others => '0');
			dealerTotal        <= (others => '0');
			endGame            <= '0';
			turn               <= '0';
			ohAnotherCounter   <= 0;
			fsm                <= HoldOn;
		elsif rising_edge(clk) then
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
				if sumPlayer = '1' and playereseturn = '1' then
					playerTotal <= playerTotal + newCard;
				end if;
				if sumDealer = '1' and playereseturn = '0' then
					if dealerTotal >= 16 then 
						endGame <= '1';
					else
						dealerTotal <= dealerTotal + newCard;
					end if;
				end if;
			end case;
		end if;
	end process;


end arch_BlackJack;
