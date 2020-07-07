library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;


entity FIFO_BISYNC is
           generic( data_size : integer := 8;
		              fifo_size : integer := 64);
           port (
		clk_wr    : in std_logic;
		clk_rd    : in std_logic;
		rst       : in std_logic;
		wr_en     : in std_logic;
		wr_data   : in std_logic_vector(data_size-1 downto 0);
		rd_en     : in std_logic;
		rd_data   : out std_logic_vector(data_size-1 downto 0);
		sts_error : out std_logic;
      sts_full  : out std_logic;
		sts_high  : out std_logic;
		sts_low   : out std_logic;
		sts_empty : out std_logic
		);
end FIFO_BISYNC;


architecture arch_FIFO_BISYNC of FIFO_BISYNC is


  function Log2(temp : natural) return natural is
  begin
      for i in 0 to integer'high loop
          if (2**i >= temp) then
              return i;
          end if;
      end loop;
      return 0;
  end function Log2;



	type memory is array (0 to fifo_size-1) of std_logic_vector(data_size-1 downto 0);
	signal fifo        : memory;
	signal position_wr : std_logic_vector(Log2(fifo_size)-1 downto 0);
	signal position_rd : std_logic_vector(Log2(fifo_size)-1 downto 0);
	signal value_wr    : integer;
	signal value_rd    : integer;
	signal value_t     : integer;
	signal error_r     : std_logic;
	signal error_w     : std_logic;
	constant bottom    : integer := 0;
	constant top       : integer := fifo_size-1;

begin

write_ctrl:
process(clk_wr, rst)
begin
if rst = '1' then
	 fifo        <= (others => (others => '0'));
    position_wr <= (others => '0');
	 value_wr    <= 0;
	 error_w     <= '0';
elsif clk_wr'event and clk_wr='1' then
	if value_t > top then
		error_w <= '1';
	end if;
	if wr_en = '1' then
		position_wr <= position_wr + 1;
		value_wr    <= value_wr + 1;
		fifo(conv_integer(position_wr)) <= wr_data;
	end if;
end if;
end process;

read_ctrl:
process(clk_rd, rst)
begin
if rst = '1' then
    position_rd <= (others => '0');
	 value_rd    <= 0;
	 rd_data     <= (others => '0');
	 error_r     <= '0';
elsif clk_rd'event and clk_rd='1' then
	if value_t > top then
		error_r <= '1';
	end if;
	if rd_en = '1' then
		position_rd <= position_rd + 1;
		value_rd    <= value_rd +1;
		rd_data <= fifo(conv_integer(position_rd));
	end if;
end if;
end process;


	value_t <= value_wr - value_rd;

	sts_full  <= '1' when value_t = top        else '0';
	sts_empty <= '1' when value_t = bottom     else '0';
	sts_high  <= '1' when value_t > top - 2    else '0';
	sts_low   <= '1' when value_t < bottom + 2 else '0';
	sts_error <= error_r or error_w;

end arch_FIFO_BISYNC;
