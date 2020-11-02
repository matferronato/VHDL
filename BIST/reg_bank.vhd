
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity regbank is
	generic(DATA_SIZE : integer := 8;
			  REG_N     : integer := 32;
			  BITS      : integer := 5);
  	port
  	(
      clk             : in std_logic;
      rst             : in std_logic;

      reg_wadrr       : in std_logic_vector(BITS-1 downto 0);
      reg_raddr       : in std_logic_vector(BITS-1 downto 0);
      reg_wdata       : in std_logic_vector(DATA_SIZE-1 downto 0);
      reg_rdata       : out std_logic_vector(DATA_SIZE-1 downto 0);
      reg_wen         : in std_logic

	);
end regbank;

architecture arch_regbank of regbank is
  signal currentValue : std_logic_vector(DATA_SIZE-1 downto 0) := (others => '0');

  type regnbits is array (0 to REG_N-1) of std_logic_vector(DATA_SIZE-1 downto 0);
  signal reg_bank: regnbits;

begin

	---------------------------------------------------------------------------------------
  	-- registers
  ---------------------------------------------------------------------------------------

  process(clk, rst)
  begin
    if rst = '1' then
		for i in 0 to REG_N-1 loop
			reg_bank(i) <= currentValue;
		end loop;
    elsif rising_edge(clk) then
      for i in 0 to REG_N-1 loop
        if i = to_integer(unsigned(reg_wadrr)) then
          if reg_wen = '1' then
            reg_bank(i) <= reg_wdata;
          end if;
        end if;
      end loop;
    end if;
  end process;

  reg_rdata <= reg_bank(to_integer(unsigned(reg_raddr)));

end arch_regbank;