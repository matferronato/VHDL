COUNT ONES UNARY APPROACH
This is a stable and non generic(yet!) version of a count ones circuit that 
receives a 128 bits word and outputs an 8 bit value.
The unary aproach showed a great reduce in area, shrinking the overall architecture 
in 97% of íts original size, although it slowed the critical path in 50%.

The ideia is to use a fulladder as a unary converter, reading 3 bit chuncks of 
the 128 bit word, and outputing an X number of 2 bit values. The result of the 
unary conversion is added in cascate to provide the correct output at the end.

The next step shall be the adition of a pipeline barrier to improve timing, 
and the reconding of the architecture, in order to transform it in a generic 
vhdl using 'if generate' statments




library IEEE;
use IEEE.std_logic_1164.all;

entity full_adder is
           port (
            data_in:	        in std_logic_vector(2 downto 0);
            data_out:        out std_logic_vector(1 downto 0)
         );
end full_adder;
architecture arch_full_adder of full_adder is
	signal intermidiate : std_logic_vector(1 downto 0);

  begin
	intermidiate(0) <= data_in(0) xor (data_in(1) xor data_in(2));
	intermidiate(1) <= (data_in(2) and data_in(1)) or (data_in(0) and data_in(1))  or (data_in(0) and data_in(2));
	data_out <= intermidiate;

end arch_full_adder;

---#############################################

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity unary_count_ones is
	port (
			data_out : OUT std_logic_vector(7 downto 0);
			data_in : IN std_logic_vector(127 downto 0));
end unary_count_ones;

architecture Behavioral of unary_count_ones is

	   	  type array_2b is array (0 to 42) of std_logic_vector (1 downto 0);
        signal bin2_array : array_2b;

        type array_3bin is array (0 to 21) of std_logic_vector (2 downto 0);
        signal bin3_array : array_3bin;

        type array_4bin is array (0 to 10) of std_logic_vector (3 downto 0);
        signal bin4_array : array_4bin;

        type array_5bin is array (0 to 5) of std_logic_vector (4 downto 0);
        signal bin5_array : array_5bin;

        type array_6bin is array (0 to 2) of std_logic_vector (5 downto 0);
        signal bin6_array : array_6bin;

        type array_7bin is array (0 to 1) of std_logic_vector (6 downto 0);
        signal bin7_array : array_7bin;

        signal temp : std_logic_vector(128 downto 0) := (others => '0');

begin
  temp <= data_in & '0';

			   full_a0 : entity work.full_adder port map (data_in => temp(2 downto 0), data_out => bin2_array(0));
         un2bin : for i in 1 to 42 generate
          full_adr : entity work.full_adder port map (data_in => temp((i*3)+2 downto i*3), data_out => bin2_array(i));
         end generate un2bin;

         bin3_array(0) <= ('0' & bin2_array(0)) + "000";
  bin3:  for j in 1 to 21 generate
           bin3_array(j) <= ('0' & bin2_array((j*2))) + ('0' & bin2_array((j*2)-1));
         end generate bin3;

  bin4:  for k in 0 to 10 generate
           bin4_array(k) <= ('0' & bin3_array((k*2)+1)) + ('0' & bin3_array((k*2)));
         end generate bin4;

 		     bin5_array(5) <=  ('0' & bin4_array(10)) + "00000";
 bin5:   for l in 0 to 4 generate
           bin5_array(l) <= ('0' & bin4_array((l*2)+1)) + ('0' & bin4_array((l*2)));
         end generate bin5;

 bin6:   for m in 0 to 2 generate
           bin6_array(m) <= ('0' & bin5_array((m*2)+1)) + ('0' & bin5_array((m*2)));
         end generate bin6;

         bin7_array(1) <=  ('0' & bin6_array(2)) + "0000000";
         bin7_array(0) <=  ('0' & bin6_array(1)) + ('0' & bin6_array(0));

         data_out <= ('0' & bin7_array(0)) + ('0' & bin7_array(1));

 end Behavioral;
