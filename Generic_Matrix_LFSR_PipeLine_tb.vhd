----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:11:17 04/18/2019 
-- Design Name: 
-- Module Name:    TB - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TB is
end TB;

architecture Behavioral of TB is

  signal lfsr_seed  : std_logic_vector(63 downto 0) := x"00AA11BB22CC33DD";
  signal RANDOM     : std_logic_vector(63 downto 0);
  signal start      : std_logic;
  signal load_seed  : std_logic;
  signal rst_n      : std_logic;
  signal clk_312    : std_logic := '0'; 

begin
    clk_312    <= not clk_312 after 1.602564105 ns;
    rst_n      <= '0','1' after 35 ns;
	 load_seed  <= '0', '1' AFTER 70 ns;
	 start      <= '0', '1' AFTER 140 ns;

    INST_LFSR_MATRIX: entity work.LFSR_MATRIX
    generic map (DATA_SIZE => 64, --64 bits wide
                 PPL_SIZE => 4)   --4 matrix blocks
    port map(
      clock =>      clk_312,
      reset_N =>    rst_n,
      load_seed =>  load_seed,
      seed =>       lfsr_seed,
      polynomial => "10",
      data_in =>    RANDOM,   
      start =>      start,
      data_out =>   RANDOM --datain connected to dataout for a example behaviour
    );


end Behavioral;

