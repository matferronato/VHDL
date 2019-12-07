
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;


entity F_DIVISOR is
port(
	clk : in std_logic;
	rst : in std_logic;
	add : in std_logic;
	sub : in std_logic;
	led : out std_logic_vector(6 downto 0);
	mux : out std_logic_vector(3 downto 0);
	dbg : out std_logic_vector(1 downto 0);
	cko : out std_logic
);

end F_DIVISOR;

architecture Behavioral of F_DIVISOR is
CONSTANT ZERO  : std_logic_vector(6 downto 0) := "1000000";
CONSTANT ONE   : std_logic_vector(6 downto 0) := "1111001";
CONSTANT TWO   : std_logic_vector(6 downto 0) := "0100100";
CONSTANT THREE : std_logic_vector(6 downto 0) := "0110000";
CONSTANT FOUR  : std_logic_vector(6 downto 0) := "0011001";
CONSTANT FIVE  : std_logic_vector(6 downto 0) := "0010010";
CONSTANT SIX   : std_logic_vector(6 downto 0) := "0000011";
CONSTANT SEVEN : std_logic_vector(6 downto 0) := "1111000";
CONSTANT EIGHT : std_logic_vector(6 downto 0) := "0000000";
CONSTANT NINE  : std_logic_vector(6 downto 0) := "0011000";
CONSTANT NAN   : std_logic_vector(6 downto 0) := "1111111";
CONSTANT DELAY : INTEGER := 11900000;
SIGNAL MUX_S   : std_logic_vector(1 downto 0);

type frequencies_type is array (0 to 27) of integer;
constant frequencies : frequencies_type := 
(1, 3, 5, 25, 50, 100 , 250, 313, 500 , 1000,
2500, 3125,  5000, 10000, 25000, 31250, 50000,
100000, 250000, 312500, 500000, 1000000, 2500000,
3125000, 5000000, 6250000, 12500000, 25000000);
signal clk_2  : std_logic;
signal clkmin : std_logic;
signal clk25  : std_logic;

signal unidade : integer range 0 to 9;
signal dezena  : integer range 0 to 9;
signal centena : integer range 0 to 9;
signal base    : integer range 0 to 9;
signal index   : integer range 0 to 27;

signal counter_delay_add : integer range 0 to DELAY;
signal counter_delay_sub : integer range 0 to DELAY;
signal state_add         : std_logic;
signal state_sub         : std_logic;
signal add_h				 : std_logic;
signal sub_h				 : std_logic;

procedure LED_ASSIGNMENT
   (signal VALUE_IN  : in integer range 0 to 9;
    signal VALUE_OUT : out std_logic_vector(6 downto 0)) is
  variable TMP : std_logic_vector(6 downto 0);
begin
	case VALUE_IN is 
		when 0 => TMP := ZERO;
		when 1 => TMP := ONE;
		when 2 => TMP := TWO;
		when 3 => TMP := THREE;
		when 4 => TMP := FOUR;
		when 5 => TMP := FIVE;
		when 6 => TMP := SIX;
		when 7 => TMP := SEVEN;
		when 8 => TMP := EIGHT;
		when 9 => TMP := NINE;
		when others => TMP := NAN;	
	end case;
  VALUE_OUT <= TMP;
end LED_ASSIGNMENT;


procedure UNIDADE_ATTR
   (signal UNI_IN   : in integer range 0 to 27;
    signal UNI_OUT : out integer range 0 to 9) is
  variable TMP : integer range 0 to 9;
begin
	case UNI_IN is 
		when 0 => TMP := 5;
		when 2 => TMP := 5;
		when 3 => TMP := 1;
		when 11 => TMP := 8;
		when 12 => TMP := 5;
		when 13 => TMP := 2;
		when 14 => TMP := 1;
		when 21 => TMP := 5;
		when 23 => TMP := 8;
		when 24 => TMP := 5;
		when 25 => TMP := 4;
		when 26 => TMP := 2;
		when 27 => TMP := 1;
		when others => TMP := 0;	
	end case;
  UNI_OUT <= TMP;
end UNIDADE_ATTR;

procedure DEZENA_ATTR
   (signal DEC_IN   : in integer range 0 to 27;
    signal DEC_OUT : out integer range 0 to 9) is
  variable TMP : integer range 0 to 9;
begin
	case DEC_IN is 
		when 0  => TMP := 2;
		when 1  => TMP := 1;
		when 7  => TMP := 8;
		when 8  => TMP := 5;
		when 9  => TMP := 2;
		when 10 => TMP := 1;
		when 17 => TMP := 5;
		when 19 => TMP := 8;
		when 20 => TMP := 5;
		when 21 => TMP := 2;
		when 22 => TMP := 1;
		when others => TMP := 0;	
	end case;
  DEC_OUT <= TMP;
end DEZENA_ATTR;

procedure CENTENA_ATTR
   (signal CENT_IN   : in integer range 0 to 27;
    signal CENT_OUT : out integer range 0 to 9) is
  variable TMP : integer range 0 to 9;
begin
	case CENT_IN is 
		when 4  => TMP := 5;
		when 5  => TMP := 2;
		when 6  => TMP := 1;
		when 15  => TMP := 8;
		when 16  => TMP := 5;
		when 17  => TMP := 2;
		when 18  => TMP := 1;
		when others => TMP := 0;	
	end case;
  CENT_OUT <= TMP;
end CENTENA_ATTR;

procedure BASE_ATTR
   (signal BASE_IN   : in integer range 0 to 27;
    signal BASE_OUT : out integer range 0 to 9) is
  variable TMP : integer range 0 to 9;
begin
	if BASE_IN < 4 then
		TMP := 6;
	elsif BASE_IN < 15 then
		TMP := 3;
	else
		TMP := 0;
	end if;
	BASE_OUT <= TMP;
end BASE_ATTR;

	signal a : integer range 0 to 9 := 0;
	signal b : integer range 0 to 9 := 0;
	signal c : integer range 0 to 9 := 0;
	signal d : integer range 0 to 9 := 0;

begin
dbg(0) <= add;
dbg(1) <= sub;

divisormin: process(clk, rst)
variable conta: integer range 0 to 3125;
begin
	if rst = '1' then
		clkmin <= '0';
	elsif rising_edge(clk) then
		if(conta<3125)then
			conta := conta+1;
		else
			conta := 0;
			clkmin <= not(clkmin);
		end if;
	end if;
end process divisormin;

frequency_divisor : process(clk,rst)
	variable count : integer;
	begin
	if rst = '1' then
		count := 0;
	elsif rising_edge(clk) then
		if(count<frequencies(index))then
			count := count+1;
		else
			count := 0;
			clk_2 <= not(clk_2);
		end if;
	end if;
end process;

cko <= clk_2 when rst = '0' else clk;

next_add : process(clk,rst)
	begin
	if rst = '1' then
		counter_delay_add <= 0;
		state_add         <= '0';
		add_h             <= '0';
	elsif rising_edge(clk) then
		if state_add = '0' then
			if(add = '1')then
				add_h <= '1';
				state_add <= '1';
			else 
				add_h <= '0';
			end if;
			counter_delay_add <= 0;
		else
			add_h <= '0';
			if(counter_delay_add > DELAY-1)then
				state_add <= '0';
			else 
				counter_delay_add <= counter_delay_add + 1;
			end if;
		end if;
	end if;
end process;

next_sub : process(clk,rst)
	begin
	if rst = '1' then
		counter_delay_sub <= 0;
		state_sub         <= '0';
		sub_h             <= '0';
	elsif rising_edge(clk) then
		if state_sub = '0' then
			if(sub = '1')then
				sub_h <= '1';
				state_sub <= '1';
			else 
				sub_h <= '0';
			end if;
			counter_delay_sub <= 0;
		else
			sub_h <= '0';
			if(counter_delay_sub > DELAY-1)then
				state_sub <= '0';
			else 
				counter_delay_sub <= counter_delay_sub + 1;
			end if;
		end if;
	end if;
end process;

index_ctrl : process(clk,rst)
	begin
	if rst = '1' then
		index <= 27;
	elsif rising_edge(clk) then
		if sub_h = '1' then
			if index = 0 then
				index <= 0;
			else
				index <= index-1;
			end if;
		elsif add_h = '1' then
			if index = 27 then
				index <= 27;
			else
				index <= index+1;
			end if;
		else 
			index <= index;
		end if;
	end if;
end process;

assignment: process(clk,rst)
	begin
	if rst = '1' then
	unidade <= 0;
	dezena  <= 0;
	centena <= 0;
	base <= 0;
	elsif rising_edge(clk) then
		UNIDADE_ATTR(INDEX, UNIDADE);
		DEZENA_ATTR(INDEX, DEZENA);
		CENTENA_ATTR(INDEX, CENTENA);
		BASE_ATTR(INDEX, BASE);
	end if;
end process;

multiplexation: process(clkmin,rst)


	begin
	if rst = '1' then
		mux   <= "1110";
		led   <= "1000000";
		MUX_S <= "00";
	elsif rising_edge(clkmin) then
		--if (clkmin = '1') then
		 if (MUX_S = "00") then
			mux   <= "1110";
			a <= 0;
			LED_ASSIGNMENT(base, led);	
			MUX_S <= "01";
		elsif (MUX_S = "01") then
			mux   <= "1101";
			MUX_S <= "10";
			b <= 1;
			LED_ASSIGNMENT(unidade, led);
		elsif (MUX_S = "10") then
			mux   <= "1011";
			MUX_S <= "11";
			c <= 2;
			LED_ASSIGNMENT(dezena, led);	
		else
			mux   <= "0111";
			MUX_S <= "00";
			d <= 3;
			LED_ASSIGNMENT(centena, led);	
		end if;
	  --end if;
	end if;
	end process multiplexation;
end Behavioral;

