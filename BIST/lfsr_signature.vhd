library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity signature is
  generic
  (
    DATA_SIZE  : integer := 128
  );
  port
  (
	clk      : in std_logic;
	rst      : in std_logic;
	en       : in std_logic;
	data_in  : in std_logic_vector(DATA_SIZE-1 downto 0);
	data_out : out std_logic_vector(DATA_SIZE-1 downto 0)
  );
end signature;

architecture arch_signature of signature is
  signal data_aux  : std_logic_vector(DATA_SIZE-1 downto 0);
  begin

	process(clk, rst)
	begin
		if rst = '1' then
			data_aux <= data_in;
		elsif rising_edge(clk) then
			if (en = '1') then
				data_aux(0) <= data_aux(DATA_SIZE-1) xor data_in(0);
				for i in 1 to DATA_SIZE-1 loop
					data_aux(i) <= data_aux(DATA_SIZE-1) xor data_aux(i-1) xor data_in(i);
				end loop;
			end if;
		end if;
	end process;

	data_out <= data_aux;
end arch_signature;