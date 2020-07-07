--This is a synthesizable mux that works appending a standart value A
--to any part of the a generic size bus B.


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity genericMux is
    generic(Size : integer := 256;
				ctrlSize : integer := 5;
				ctrlValue : integer := 32); 
	 port
    (
		data_in    : in std_logic_vector(Size-1 downto 0);
		data_out   : out std_logic_vector(Size-1 downto 0);
		idle_value : in std_logic_vector(Size-1 downto 0);
		muxCtrl    : in std_logic_vector(ctrlSize-1 downto 0)
    );
end genericMux;

architecture Arch_genericMux of GenericMux is

signal test       : std_logic;

begin

	mux: process(muxCtrl)
	begin
	 data_out <= (others => '0');
	 test <= '0';
	 for i in 0 to ctrlValue-1 loop
		if muxCtrl = i then 
			if muxCtrl < (ctrlValue/2)-1 then
				data_out <= data_in(((i+1)*8)-1 downto 0) & idle_value(((ctrlValue-(i+1))*8)-1 downto 0);
			else
				data_out <= idle_value(((ctrlValue-(i+1))*8)-1 downto 0) & data_in(((i+1)*8)-1 downto 0);
			end if;
		end if;
	 end loop;
	end process;

end Arch_genericMux;

