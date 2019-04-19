--////////////////////////////////////////////////////////////////////////
--//// Author(s):                                                     ////
--//// - Matheus Lemes Ferronato                                      ////
--////                                                                ////
--////////////////////////////////////////////////////////////////////////

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Generic LSFR
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;

entity lsfr_generic_reg is
           generic( DATA_SIZE : integer := 64);
           port (
            load_seed     : in std_logic;
            parallel_reg  : in std_logic_vector(DATA_SIZE-1 downto 0);
            random        : out std_logic_vector(DATA_SIZE-1 downto 0);
            poly          : in  std_logic_vector(1 downto 0)
         );
end lsfr_generic_reg;


architecture arch_lsfr_generic of lsfr_generic_reg is
  signal intermediate: std_logic_vector(DATA_SIZE-1 downto 0);
  signal tap : std_logic;
  begin
    --provide options to xor diferent bits // change LFSR polynom
    tap <= '0' when load_seed = '0' else
           parallel_reg(30) xor parallel_reg(27) when poly="00" else
           parallel_reg(22) xor parallel_reg(17) when poly="01" else
           parallel_reg(14) xor parallel_reg(13) when poly="10" else
           parallel_reg(6)  xor parallel_reg(5);

	--shift right and concatanation of xor result at LSB
    intermediate <= parallel_reg(DATA_SIZE-2 downto 0) & tap when load_seed = '1' else (others => '0'); 

    random <= intermediate;

end arch_lsfr_generic;
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- LSFR PARALLEL
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity LFSR_MATRIX is
  generic
  (
    DATA_SIZE   : integer := 128;
    PPL_SIZE   : integer := 4
  );
  port
  (
    clock               : in  std_logic;
    load_seed           : in std_logic;
    reset_N             : in  std_logic;
    seed                : in  std_logic_vector(DATA_SIZE-1 downto 0);
    polynomial          : in  std_logic_vector(1 downto 0);
    data_in             : in  std_logic_vector(DATA_SIZE-1 downto 0);
    start               : in  std_logic;
    data_out            : out std_logic_vector(DATA_SIZE-1 downto 0)

  );
end LFSR_MATRIX;

architecture ARCH_LFSR_MATRIX of LFSR_MATRIX is

  -------------------------------------------------------------------------------
  -- Debug
  -------------------------------------------------------------------------------
  type lfsr_table is array (0 to PPL_SIZE-1, 0 to ((DATA_SIZE / PPL_SIZE)-1)) of std_logic_vector (DATA_SIZE-1 downto 0);
  signal reg_i           : std_logic_vector(DATA_SIZE-1 downto 0) := seed;
  signal linear_feedback : lfsr_table;
  type delay_barrier is array (0 to PPL_SIZE-2) of std_logic_vector (DATA_SIZE-1 downto 0);
  signal Delay_B : delay_barrier;

  begin
  
  lfsr0_0 : entity work.lsfr_generic_reg generic map (DATA_SIZE=> DATA_SIZE) port map (load_seed => load_seed, parallel_reg => reg_i, random => linear_feedback(0,0), poly => polynomial);
  
  generate_matrix_in : for i in 0 to PPL_SIZE-2 generate
	lfsr_N : entity work.lsfr_generic_reg generic map (DATA_SIZE=> DATA_SIZE) port map (load_seed => load_seed, parallel_reg => Delay_B(i), random => linear_feedback(i+1,0), poly => polynomial);
  end generate generate_matrix_in;

  generate_ppl : for i in 0 to  PPL_SIZE-1 generate
    generate_lfsr : for j in 1 to  ((DATA_SIZE / PPL_SIZE)-1)  generate
        lfsrn : entity work.lsfr_generic_reg generic map (DATA_SIZE=> DATA_SIZE)
                     port map (load_seed => load_seed, parallel_reg => linear_feedback(i,j-1), random => linear_feedback(i,j), poly => polynomial);
    end generate generate_lfsr;
  end generate generate_ppl;

 process (clock, reset_N)
 begin
   if reset_N = '0' then
      reg_i <= seed;
	  for i in 0 to PPL_SIZE-2 loop
		Delay_B(i) <= (others=>'0');
	  end loop;
    elsif rising_edge(clock) then
		if start = '1' then
		  reg_i <= data_in;
		  for i in 0 to PPL_SIZE-2 loop
			Delay_B(i) <= linear_feedback(i,(DATA_SIZE/PPL_SIZE)-1);
		  end loop;
		end if;
    end if;
  end process;

   data_out <= (others => '0') when reset_N = '0' else
               linear_feedback(3,(DATA_SIZE/PPL_SIZE)-1);


end ARCH_LFSR_MATRIX;
