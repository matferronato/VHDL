library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity TB is
end TB;

architecture Behavioral of TB is

  type data is array (0 to 4) of std_logic_vector (3 downto 0);
  constant this_data  : data := (x"0", x"B", x"A", x"F", x"A");  
  type state_type is (S_WIRTE_BORDER0, S_WAIT, S_WIRTE_BORDER1, S_STOP);
  
  signal current_s  : state_type;
  signal rst_n      : std_logic;
  signal clk_312    : std_logic := '0'; 
  signal clk_312_n  : std_logic; 
  signal clk_156    : std_logic; 
  signal datain     : std_logic_vector(3 downto 0);
  signal dataout    : std_logic_vector(7 downto 0);
  signal counter    : integer range 0 to 3;

begin
    clk_312   <= not clk_312 after 1.602564105 ns;
	  clk_312_n <= not (clk_312); --Checks circuit behaviour with 180geg shifted clock 
    rst_n     <= '0','1' after 35 ns;
	 
	 clk_divider: process (clk_312)
	 begin
		if rst_n = '0' then
			clk_156 <= '0';
		elsif clk_312'event and clk_312 = '1' then
			clk_156 <= not(clk_156);
		end if;
	 end process;

	 process(clk_312,rst_n) --provides datain
	 begin
		if(rst_n = '0') then
		   current_s <= S_WIRTE_BORDER0;
			counter <= 0;
		elsif (clk_312'event and clk_312 = '1') then
			case current_s is
				when S_WIRTE_BORDER0 =>
					if(counter /= 4) then
						counter <= counter + 1;
					else
						current_s <= S_WAIT;
					end if;
				when S_WAIT => --provides one cicle of no new data
					counter <= 0;
					current_s <= S_WIRTE_BORDER1;
				when S_WIRTE_BORDER1 => 
					if(counter /= 4) then
						counter <= counter + 1;
					else
						current_s <= S_STOP;
					end if;
				when S_STOP => null; 
			end case;
		end if;
	 end process;
	 
	 datain    <= (others => '0') when current_s = S_WAIT else 
					  this_data(counter);

    INST_CC_Faster_Slower: entity work.CC_Faster_Slower
    generic map (DATA_SIZE => 4, COUNTER_STAGES =>2)
    port map(
		 clk_faster  =>clk_312_n,
		 clk_slower  =>clk_156,
		 rst_n		 =>rst_n,
		 data_in  	 =>datain,
		 data_out 	 =>dataout	         
    );

end Behavioral;

