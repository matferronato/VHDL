library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity TB is
end TB;

architecture Behavioral of TB is

	signal data_in    : std_logic_vector(255 downto 0) := (others => '1');
	signal idle_value : std_logic_vector(255 downto 0) := (others => '0');
	signal data_out   : std_logic_vector(255 downto 0);
	signal muxCtrl    : std_logic_vector(4 downto 0);
	signal clk_312    : std_logic := '0';  
	signal rst_n      : std_logic;  
begin
   clk_312    <= not clk_312 after 1.602564105 ns;
	rst_n <= '0','1' after 35 ns;
	
	mux_data : process(rst_n, clk_312)
	begin
		if rst_n = '0' then
			muxCtrl <= (others => '0');
		 elsif clk_312'event and clk_312 = '1' then
			muxCtrl <= muxCtrl + 1;
		 end if;
	end process;


   INST_genericMux: entity work.genericMux
   generic map (Size => 256, ctrlSize =>5, ctrlValue => 32)
   port map(
	 muxCtrl		 =>muxCtrl,
	 data_in  	 =>data_in,
	 data_out 	 =>data_out,	  
    idle_value	 =>idle_value
   );

end Behavioral;

