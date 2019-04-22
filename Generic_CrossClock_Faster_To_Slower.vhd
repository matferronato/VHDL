--This architecture provides a synthesizable way to cross from a faster clock domain to a slower one
--without the use of a dual clock FIFO.
--This generic architecture works for a writing-clock(datain) that is the double frquency of the 
--reading-clock (dataout). 
--It should also works for different multiples of datain frequency with some tweaks

--This architecture is based on the streching approach from NANDLAND videos
--The next step would be the inclusion of a more robust and reliable circuit to 
--implement custom frequencies.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity CC_Faster_Slower is
    generic(DATA_SIZE : integer := 8;
				COUNTER_STAGES : integer := 2); -- 2, 4, 8
	 port
    (
	 clk_faster  : in  std_logic;
	 clk_slower  : in  std_logic;
	 rst_n		 : in  std_logic;
	 data_in  	 : in  std_logic_vector(DATA_SIZE-1 downto 0);
	 data_out 	 : out std_logic_vector((DATA_SIZE*2)-1 downto 0)
    );
  end CC_Faster_Slower;

  architecture Arch_CC_Faster_Slower of CC_Faster_Slower is

  type unstable_data is array (DATA_SIZE-1 downto 0)     of std_logic;
  type stretcher_counter is array (DATA_SIZE-1 downto 0) of integer range 0 to COUNTER_STAGES;

  signal unstable_bus    : unstable_data;
  signal unstable_wire   : std_logic_vector(DATA_SIZE-1 downto 0);
  signal metastable_bus  : std_logic_vector((DATA_SIZE*2)-1 downto 0);
  signal stable_bus      : std_logic_vector((DATA_SIZE*2)-1 downto 0);
  signal stc_counter_bus : stretcher_counter;
  signal parity          : std_logic := '0';


begin
   parity_ctrl :process (clk_faster) -- allows spare time for counters to zero
   begin
     if clk_faster'event and clk_faster = '1' then
      if parity = '0' then
        parity <= '1';
      else
        parity <= '0';
      end if;
     end if;
  end process;

	 DATA_OUT_ATTRIBUTION : for i in 0 to (DATA_SIZE*2)-1 generate
		data_out(i) <= stable_bus(i);
	 end generate;

	 FASTER_TO_SLOWER : for i in 0 to DATA_SIZE-1 generate

		faster : process(clk_faster)
		begin
		  if rising_edge(clk_faster) then
			 if data_in(i) = '1' and parity = '1' then
				stc_counter_bus(i) <= COUNTER_STAGES;
			 elsif stc_counter_bus(i) > 0 then
				stc_counter_bus(i) <= stc_counter_bus(i) - 1;
			 end if;
		  end if;
		end process;

		unstable_bus(i)  <= '1' when stc_counter_bus(i) > 0 else '0';
		unstable_wire(i) <= unstable_bus(i);

	 end generate;

		slower : process(clk_slower)
		begin
			 if rising_edge(clk_slower) then
				metastable_bus <= unstable_wire & data_in;
				stable_bus <= metastable_bus;
			 end if;
		end process;

end Arch_CC_Faster_Slower;
