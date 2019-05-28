library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity TB is
end TB;

architecture Behavioral of TB is

  signal clk_156                 : std_logic := '0';
  signal clk_312                 : std_logic := '0';

  signal fifo_a_empty_0  : std_logic;
  signal fifo_a_empty_1  : std_logic;
  signal fifo_a_empty_2  : std_logic;
  signal fifo_a_empty_3  : std_logic;

  signal fifo_a_full_0   : std_logic;
  signal fifo_a_full_1   : std_logic;
  signal fifo_a_full_2   : std_logic;
  signal fifo_a_full_3   : std_logic;

  signal fifo_empty_0    : std_logic;
  signal fifo_empty_1    : std_logic;
  signal fifo_empty_2    : std_logic;
  signal fifo_empty_3    : std_logic;

  signal fifo_full_0     : std_logic;
  signal fifo_full_1     : std_logic;
  signal fifo_full_2     : std_logic;
  signal fifo_full_3     : std_logic;

  signal ctrl_empty      : std_logic_vector(-1 downto 0);
  signal fifo_ctrl_in    : std_logic_vector(8 downto 0) := (others => '1');
  signal fifo_ctrl_out_1 : std_logic_vector(8 downto 0);
  signal fifo_ctrl_out_2 : std_logic_vector(8 downto 0);
  signal fifo_ctrl_out_3 : std_logic_vector(8 downto 0);

  signal fifo_data_in_0  : std_logic_vector(127 downto 0) := (others => '1');
  signal fifo_data_in_1  : std_logic_vector(156 downto 0) := (others => '1');

  signal fifo_data_out_0 : std_logic_vector(127 downto 0);
  signal fifo_data_out_1 : std_logic_vector(156 downto 0);
  signal fifo_data_out_2 : std_logic_vector(156 downto 0);
  signal fifo_data_out_3 : std_logic_vector(156 downto 0);

  signal rd_en_sync       : std_logic;
  signal wr_en_sync       : std_logic;
  signal rd_en_dual_clock : std_logic;
  signal wr_en_dual_clock : std_logic;
  signal reset_fifo       : std_logic;
  signal fifo_state       : std_logic;

begin
   
    clk_312    <= not clk_312 after 1.6 ns;
    clock156: process (clk_312)
    begin
      if rising_edge(clk_312) then
        clk_156 <= not clk_156;
      end if;
    end process;
   
    -------------------------------------------------------------------------------
    -- FIFOS
    -------------------------------------------------------------------------------

    reset_fifo <= <= '1','0'  after 35 ns;

    SYNC_RD_WR : process(clk_312, reset_fifo)
    begin
      if reset_fifo = '1' then
        rd_en_sync <= '0';
        wr_en_sync <= '0';
      elsif rising_edge(clk_312) then
        if fifo_state = '0' then
          wr_en_sync <= '1';
          rd_en_sync <= '0';
          fifo_state <='1';
        else
          wr_en_sync <= '0';
          rd_en_sync <= '1';
          fifo_state <='0';
        end if;
      end if;
    end process;

    DUAL_CLOCK_RD : process(clk_156, reset_fifo)
    begin
      if reset_fifo = '1' then
        rd_en_dual_clock <= '0';
      elsif rising_edge(clk_156) then
        rd_en_dual_clock <= '1';
      end if;
    end process;

    DUAL_CLOCK_WR : process(clk_312, reset_fifo)
    begin
      if reset_fifo = '1' then
        wr_en_dual_clock <= '0';
      elsif rising_edge(clk_312) then
        wr_en_dual_clock <= '1';
      end if;
    end process;

    GENERIC_FIFO_SYNC: entity work.GENERIC_FIFO
    generic map (
                  CTRL_SIZE    => 0,
                  CURRENT_SIZE => 128,
                  SYNC => TRUE)
    port map (
       CLKA        => clk_312,
       CLKB        => clk_312,
       RST         => reset_fifo,
       DATA_IN     => fifo_data_in_0,
       DATA_OUT    => fifo_data_out_0,
       CTRL_IN     => ctrl_empty,
       CTRL_OUT    => open,
       READ_DATA   => rd_en_sync,
       WRITE_DATA  => wr_en_sync,
       EMPTY       => fifo_empty_0,
       FULL        => fifo_full_0,
       A_FULL      => fifo_a_full_0,
       A_EMPTY     => fifo_a_empty_0
      );

      GENERIC_FIFO_SYNC_MOD: entity work.GENERIC_FIFO
      generic map (
                    CTRL_SIZE    => 0,
                    CURRENT_SIZE => 157,
                    SYNC => TRUE)
      port map (
         CLKA        => clk_312,
         CLKB        => clk_312,
         RST         => reset_fifo,
         DATA_IN     => fifo_data_in_1,
         DATA_OUT    => fifo_data_out_1,
         CTRL_IN     => ctrl_empty,
         CTRL_OUT    => open,
         READ_DATA   => rd_en_sync,
         WRITE_DATA  => wr_en_sync,
         EMPTY       => fifo_empty_1,
         FULL        => fifo_full_1,
         A_FULL      => fifo_a_full_1,
         A_EMPTY     => fifo_a_empty_1
        );

        GENERIC_FIFO_SYNC_MOD_CTRL: entity work.GENERIC_FIFO
        generic map (
                      CTRL_SIZE    => 9,
                      CURRENT_SIZE => 157,
                      SYNC => TRUE)
        port map (
           CLKA        => clk_312,
           CLKB        => clk_312,
           RST         => reset_fifo,
           DATA_IN     => fifo_data_in_1,
           DATA_OUT    => fifo_data_out_2,
           CTRL_IN     => fifo_ctrl_in,
           CTRL_OUT    => fifo_ctrl_out_2,
           READ_DATA   => rd_en_sync,
           WRITE_DATA  => wr_en_sync,
           EMPTY       => fifo_empty_2,
           FULL        => fifo_full_2,
           A_FULL      => fifo_a_full_2,
           A_EMPTY     => fifo_a_empty_2
          );

        GENERIC_FIFO_DUALCLOCK_MOD_CTRL: entity work.GENERIC_FIFO
        generic map (
                      CTRL_SIZE    => 9,
                      CURRENT_SIZE => 157,
                      SYNC => FALSE)
        port map (
           CLKA        => clk_312,
           CLKB        => clk_156,
           RST         => reset_fifo,
           DATA_IN     => fifo_data_in_1,
           DATA_OUT    => fifo_data_out_3,
           CTRL_IN     => fifo_ctrl_in,
           CTRL_OUT    => fifo_ctrl_out_3,
           READ_DATA   => rd_en_dual_clock,
           WRITE_DATA  => wr_en_dual_clock,
           EMPTY       => fifo_empty_3,
           FULL        => fifo_full_3,
           A_FULL      => fifo_a_full_3,
           A_EMPTY     => fifo_a_empty_3
          );

end Behavioral;
