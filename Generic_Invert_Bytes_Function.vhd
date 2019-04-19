library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;


entity invertBytes is
  generic (Size => 128);
  port( Data : in std_logic_vector (Size-1 downto 0));
end invertBytes;

architecture arch_invertBytes of invertBytes is

    function invert_bytes(bytes : std_logic_vector(Size-1 DOWNTO 0)) return std_logic_vector
      is
        variable bytes_N : std_logic_vector(Size-1 downto 0) := (others => '0');
        begin
          for i in 1 to 16 loop
            bytes_N(((i*8)-1) downto ((i-1)*8)) := bytes(((Size-1)-(8*(i-1))) downto ((Size-1)-((8*(i-1))+7)));
        end loop;
        return bytes_N;
    end function invert_bytes;


BEGIN

end arch_invertBytes;
