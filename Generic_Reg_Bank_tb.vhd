library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity TB is
end TB;

architecture Behavioral of TB is

  type data is array (0 to 3) of std_logic_vector (7 downto 0);
  constant this_data  : data := (x"00",x"01",x"02",x"03");  
  type state_type is (S_WAIT, S_WIRTE, S_STOP);
  
  signal current_s  : state_type;
  signal rst_n      : std_logic;
  signal clk_312    : std_logic := '0'; 
  signal addressW   : std_logic_vector(1 downto 0);
  signal addressR   : std_logic_vector(1 downto 0);
  signal dataR      : std_logic_vector(7 downto 0);
  signal dataW      : std_logic_vector(7 downto 0);
  signal ce         : std_logic;

begin
    clk_312    <= not clk_312 after 1.602564105 ns;
    rst_n      <= '0','1' after 35 ns;

	 process(clk_312,rst_n)
	 begin
		if(rst_n = '0') then
		   current_s <= S_WAIT;
			addressW  <= (others => '0');
			ce        <= '0';
		elsif (clk_312'event and clk_312 = '1') then
			case current_s is
				when S_WAIT =>
					ce <= '1';
					current_s <= S_WIRTE;
				when S_WIRTE =>
					if(addressW /= "11") then
						addressW <= addressW + 1;
					else
						ce <= '0';
						current_s <= S_STOP;
					end if;
				when S_STOP => null;
			end case;
		end if;
	 end process;
	 
	 addressR <= addressW;
	 dataW    <= this_data(to_integer(unsigned(addressW)));

    INST_REGISTER_BANK: entity work.RegisterBank
    generic map (DATA_SIZE => 8, REG_N => 4, BITS_N => 2)
    port map(
		clk    => clk_312,           
		reset	 => rst_n,   
		waddr	 => addressW,			      
		raddr	 => addressR,			      
		wdata	 => dataW,	 		      
		rdata	 => dataR,
		ce		 => ce		         
    );

end Behavioral;

