library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity lsfr_generic_reg is
         generic( DATA_SIZE : integer := 8;
            tap0 : integer := 4;
            tap1 : integer := 6);
         port (
			      clock  		   : in std_logic;
			      reset		     : in std_logic;
			      enable        : in std_logic;
			      seed          : in std_logic_vector(DATA_SIZE-1 downto 0);
            in_value      : in std_logic_vector(DATA_SIZE-1 downto 0);
            out_value     : out std_logic_vector(DATA_SIZE-1 downto 0)
         );
end lsfr_generic_reg;


architecture arch_lsfr_generic of lsfr_generic_reg is
  signal intermediate: std_logic_vector(DATA_SIZE-1 downto 0);
  signal tap : std_logic;
  begin
  
	process(clock, reset)
	begin
	if reset = '1' then
		intermediate <= seed;
	elsif rising_edge(clock) then
		if enable = '1' then
			intermediate <= intermediate(DATA_SIZE-2 downto 0) & tap;
		end if;
	end if;
	end process;
	
    --provide options to xor diferent bits // change LFSR polynom
    tap <= '0' when reset = '1' else
            in_value(tap1) xor in_value(tap0);

    out_value <= seed when reset = '1' else 
				  intermediate;

end arch_lsfr_generic;
