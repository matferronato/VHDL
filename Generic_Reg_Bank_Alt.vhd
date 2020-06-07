
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity regbank is
	generic(DATA_SIZE : integer := 8;
			  REG_N     : integer := 32);
  	port
  	(
      clk             : in std_logic;
      rst_n           : in std_logic;

      reg_wadrr       : in std_logic_vector(Log2(REG_N)-1 downto 0);
      reg_raddr       : in std_logic_vector(Log2(REG_N)-1 downto 0);
      reg_wdata       : in std_logic_vector(DATA_SIZE-1 downto 0);
      reg_rdata       : out std_logic_vector(DATA_SIZE-1 downto 0);
      reg_wen         : in std_logic

	);
end regbank;

architecture arch_regbank of regbank is

  function Log2(temp : natural) return natural is
  begin
      for i in 0 to integer'high loop
          if (2**i >= temp) then
              return i;
          end if;
      end loop;
      return 0;
  end function Log2;

  CONSTANT NUMBER_OF_REGS : integer := 33;
  type regnbits is array (0 to REG_N) of std_logic_vector(31 downto 0);
  signal reg_bank: regnbits;

begin

	---------------------------------------------------------------------------------------
  	-- registers
  ---------------------------------------------------------------------------------------

  process(clk, rst_n)
  begin
    if rst_n = '0' then
      reg_bank <= (others=>(others => '0'));
    elsif rising_edge(clk) then
      for i in 0 to REG_N loop
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
