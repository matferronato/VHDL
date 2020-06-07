
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity tester_regbank is
  	port
  	(
      clk             : in std_logic;
      rst_n           : in std_logic;

      reg_wadrr       : in std_logic_vector(6 downto 0);
      reg_raddr       : in std_logic_vector(6 downto 0);
      reg_wdata       : in std_logic_vector(31 downto 0);
      reg_rdata       : out std_logic_vector(31 downto 0);
      reg_wen         : in std_logic

	);
end tester_regbank;

architecture arch_tester_regbank of tester_regbank is

  CONSTANT NUMBER_OF_REGS : integer := 33;
  type regnbits is array (0 to NUMBER_OF_REGS) of std_logic_vector(31 downto 0);
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
      for i in 0 to NUMBER_OF_REGS loop
        if i = to_integer(unsigned(reg_wadrr)) then
          if reg_wen = '1' then
            reg_bank(i) <= reg_wdata;
          end if;
        end if;
      end loop;
    end if;
  end process;

  reg_rdata <= reg_bank(to_integer(unsigned(reg_raddr)));

end arch_tester_regbank;
