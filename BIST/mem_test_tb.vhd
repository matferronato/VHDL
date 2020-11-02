library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dut_tb is
end dut_tb;

architecture Behavioral of dut_tb is

  signal  WORD_SIZE      : integer := 4;
  signal  LENGHT_SIZE    : integer := 8;

  signal rst              : std_logic;
  signal flag             : std_logic;
  signal run              : std_logic;
  signal clk              : std_logic := '0'; 
 

	function Log2(temp : natural) return natural is
	begin
		for i in 0 to integer'high loop
			 if (2**i >= temp) then
				  return i;
			 end if;
		end loop;
		return 0;
	end function Log2;

begin
    clk    <= not clk after 1 ns;
    rst      <= '1','0' after 20 ns;

    INST_MEM_CHECKER: entity work.mem_checker
    generic map (DATA_SIZE => WORD_SIZE,
                 SRAM_N => LENGHT_SIZE,
				 BITS => LOG2(LENGHT_SIZE))  
    port map(
		clk => clk,
		rst => rst,
		run => '1',
		flag => flag
    );
	

end Behavioral;