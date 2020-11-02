
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity pattern_gen is
	generic(DATA_SIZE : integer := 16;
			ARRAY_SIZE : integer := 5);
  	port
  	(
      clk             : in std_logic;
      rst             : in std_logic;
      patterns       : out std_logic_vector((ARRAY_SIZE*DATA_SIZE)-1 downto 0)
	);
end pattern_gen;

architecture arch_pattern_gen of pattern_gen is

  type pattern_array is array (0 to ARRAY_SIZE-1) of std_logic_vector(DATA_SIZE-1 downto 0);
  signal pattern_w: pattern_array;
  signal pattern_source : std_logic_vector(0 to 1) := "01";
begin

	---------------------------------------------------------------------------------------
  	-- registers
  ---------------------------------------------------------------------------------------

	
	iterate_row : for i in 0 to ARRAY_SIZE-1 generate
		iterate_column : for j in 0 to DATA_SIZE-1 generate
			pattern_w(i)(j) <= pattern_source(((j/(DATA_SIZE/(2 ** i))) mod 2)*1);
		end generate; 	
	end generate; 
	
	ASIGNMENT : process(pattern_w)
	begin
		for k in 0 to (ARRAY_SIZE*DATA_SIZE)-1 loop
			patterns(k) <= pattern_w(k/DATA_SIZE)(k mod DATA_SIZE);
		end loop;
	end process ASIGNMENT;
	
	
end arch_pattern_gen;