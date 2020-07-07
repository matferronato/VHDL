--////////////////////////////////////////////////////////////////////////
--//// Author(s):                                                     ////
--//// - Matheus Lemes Ferronato                                      ////
--////                                                                ////
--////                                                                ////
--//// Reg architecture provided by professors                        ////
--////  Fernando Moraes / Ney Calazans from theirs invision of        ////
--////  MIPS architecture                                             ////
--////////////////////////////////////////////////////////////////////////

library IEEE;
use IEEE.std_logic_1164.all;

entity generic_registers is
           generic( SIZE : integer :=  32 );
           port(  ck, rst, ce, wen : in std_logic;
                  D : in  STD_LOGIC_VECTOR (SIZE-1 downto 0);
                  Q : out STD_LOGIC_VECTOR (SIZE-1 downto 0)
               );
end generic_registers;

architecture arch_generic_registers of generic_registers is
begin

  process(ck, rst)
  begin
       if rst = '0' then
              Q <= (others=> '0');
       elsif ck'event and ck = '1' then
           if (ce and wen) = '1' then
              Q <= D;
           end if;
       end if;
  end process;

end arch_generic_registers;


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity RegisterBank is
    generic( DATA_SIZE : integer :=  32;
             REG_N  : integer :=  8;
             BITS_N : integer := 3);
  	port
  	(
		clk                : in std_logic;
		reset		   : in std_logic;
		waddr		   : in std_logic_vector(BITS_N-1 downto 0);
		raddr		   : in std_logic_vector(BITS_N-1 downto 0);
		wdata		   : in std_logic_vector(DATA_SIZE-1 downto 0);
		rdata		   : out std_logic_vector(DATA_SIZE-1 downto 0);
		ce		   : in std_logic

	);
end RegisterBank;

architecture arch_RegisterBank of RegisterBank is

  signal wen : std_logic_vector(REG_N-1 downto 0); 
  type regnbits_out is array (0 to REG_N-1) of std_logic_vector(DATA_SIZE-1 downto 0);
  signal registers_q_out: regnbits_out;
  
begin

  reg_bank: for i in 0 to REG_N-1 generate
        registers: entity work.generic_registers 
		generic map(SIZE => DATA_SIZE)
		port map(ck=>clk, rst=>reset, ce=>ce, wen=>wen(i), D=>wdata, Q=>registers_q_out(i));
  end generate reg_bank;

   decoder: process(waddr)
   begin
     wen <= (others => '0');
      for i in 0 to REG_N-1 loop
        if i = to_integer(unsigned(waddr)) then
          wen(i) <= '1';
        else
          wen(i) <= '0';
        end if;
      end loop;
   end process;

   rdata <= registers_q_out(to_integer(unsigned(raddr)));

end arch_RegisterBank;
