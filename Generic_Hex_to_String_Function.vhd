
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;


entity Hex2Str is
  port( Data : in std_logic_vector (7 downto 0));
end Hex2Str;

architecture arch_Hex2Str of Hex2Str is
  function hex_to_string (number : std_logic_vector) return string is  -- transforma byte em string para melhor impressao no relatorio
	variable intermediate : std_logic_vector(number'length -1 downto 0);
	variable result       : string(1 to number'length/4);
	variable half_byte    : std_logic_vector(3 downto 0);

  begin
	intermediate := number;
	for i in 0 to result'length -1 loop
		half_byte := intermediate( ( ( (result'length) -i) *4)-1 downto ((result'length-1)-i )*4); 
		case half_byte is
          when x"0"   => result(i+1) := '0';
          when x"1"   => result(i+1) := '1';
          when x"2"   => result(i+1) := '2';
          when x"3"   => result(i+1) := '3';
          when x"4"   => result(i+1) := '4';
          when x"5"   => result(i+1) := '5';
          when x"6"   => result(i+1) := '6';
          when x"7"   => result(i+1) := '7';
          when x"8"   => result(i+1) := '8';
          when x"9"   => result(i+1) := '9';
          when x"A"   => result(i+1) := 'A';
          when x"B"   => result(i+1) := 'B';
          when x"C"   => result(i+1) := 'C';
          when x"D"   => result(i+1) := 'D';
          when x"E"   => result(i+1) := 'E';
          when x"F"   => result(i+1) := 'F';
          when "ZZZZ" => result(i+1) := 'Z';
          when others => result(i+1) := 'X';
        end case;
      end loop;		
	return result;
   end function hex_to_string;

BEGIN

end Hex2Str;
