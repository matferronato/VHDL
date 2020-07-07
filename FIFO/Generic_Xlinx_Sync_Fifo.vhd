--This architecture provides a generic sync fifo 
--For a more complete generic architecture, please use the entity provided
--in Generic_Xilinx_Fifo.vhd which can provide a dual clock or a one clock
--fifo, and is able to run any number of input bits


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- GENERIC SYNC FIFO
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

library UNISIM;
  use UNISIM.vcomponents.all;
library UNIMACRO;
  use unimacro.Vcomponents.all;

entity GENERIC_SYNC_FIFO is
           generic( FIFO_N       : integer := 4;
                    TARGET_SIZE  : integer := 64;
                    CTRL_SIZE    : integer := 9;
                    CURRENT_SIZE : integer := 256);
           port (
              CLK         : IN  std_logic;
              RST         : IN  std_logic;
              DATA_IN     : IN  std_logic_vector(CURRENT_SIZE-1 downto 0);
              DATA_OUT    : OUT std_logic_vector(CURRENT_SIZE-1 downto 0);
              CTRL_IN     : IN  std_logic_vector(CTRL_SIZE-1 downto 0);
              CTRL_OUT    : OUT  std_logic_vector(CTRL_SIZE-1 downto 0);
              READ_DATA   : IN  std_logic;
              WRITE_DATA  : IN  std_logic;
              EMPTY       : OUT std_logic;
              FULL        : OUT std_logic;
              A_FULL      : OUT std_logic;
              A_EMPTY     : OUT std_logic
         );
end GENERIC_SYNC_FIFO;


architecture ARCH_GENERIC_SYNC_FIFO of GENERIC_SYNC_FIFO is
  signal ALL_ZEROS    : std_logic_vector((TARGET_SIZE - CTRL_SIZE)-1 downto 0) := (others=>'0');

  type   ctrl_table is array (0 to FIFO_N) of std_logic;
  signal fifo_empty   : ctrl_table;
  signal fifo_full    : ctrl_table;
  signal fifo_a_full  : ctrl_table;
  signal fifo_a_empty : ctrl_table;

  signal wire_empty : std_logic;
  signal wire_full : std_logic;
  signal wire_a_full : std_logic;
  signal wire_a_empty : std_logic;

  type   data_table is array (0 to FIFO_N-1) of std_logic_vector(TARGET_SIZE-1 downto 0);
  signal data_in_slipt    : data_table;
  signal data_out_slipt   : data_table;
  signal data_out_concat  : std_logic_vector(CURRENT_SIZE-1 downto 0);

  type   counter_table is array (0 to 1) of std_logic_vector(8 downto 0);
  signal fifo_data_counter    : counter_table;

  signal fifo_ctrl_in         : std_logic_vector(TARGET_SIZE-1 downto 0);
  signal fifo_ctrl_out        : std_logic_vector(TARGET_SIZE-1 downto 0);
  signal fifo_ctrl_counter_r  :std_logic_vector(8 downto 0);
  signal fifo_ctrl_counter_w  : std_logic_vector(8 downto 0);

BEGIN

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- BREAK DATA
-- split bus data in to chunks of Target size
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  break : for i in 0 to  FIFO_N-1 generate
    data_in_slipt(i) <= DATA_IN( ((TARGET_SIZE)*(i+1))-1 downto (TARGET_SIZE)*(i));
  end generate break;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- GENERATE DATA FIFOS
-- generates N-1 fifos
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  FIFO_SYNC_MACRO_DATA : for i in 0 to  FIFO_N-1 generate
    FIFO_SYNC_MACRO_INST : FIFO_SYNC_MACRO
    generic map (
      DEVICE => "7SERIES", -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES"
      ALMOST_FULL_OFFSET => X"0002", -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET => X"0002", -- Sets the almost empty threshold
      DATA_WIDTH => TARGET_SIZE, -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE => "36Kb") -- Target BRAM, "18Kb" or "36Kb"
    port map (
      ALMOSTEMPTY => fifo_a_empty(i), -- 1-bit output almost empty
      ALMOSTFULL => fifo_a_full(i), -- 1-bit output almost full
      DO => data_out_slipt(i), -- Output data, width defined by DATA_WIDTH parameter
      EMPTY => fifo_empty(i), -- 1-bit output empty
      FULL => fifo_full(i), -- 1-bit output full
      RDCOUNT => fifo_data_counter(0), -- Output read count, width determined by FIFO depth
      RDERR => open, -- 1-bit output read error
      WRCOUNT => fifo_data_counter(1), -- Output write count, width determined by FIFO depth
      WRERR => open, -- 1-bit output write error
      CLK => CLK, -- 1-bit input clock
      DI => data_in_slipt(i), -- Input data, width defined by DATA_WIDTH parameter
      RDEN => READ_DATA, -- 1-bit input read enable
      RST => RST,-- 1-bit input reset
      WREN => WRITE_DATA -- 1-bit input write enable
      );
    end generate FIFO_SYNC_MACRO_DATA;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- GENERATE CTRL FIFOS
-- generates 1 ctrl fifos
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    fifo_ctrl_in <= ALL_ZEROS & CTRL_IN;
    CTRL_OUT     <= fifo_ctrl_out(CTRL_SIZE-1 downto 0);

    FIFO_SYNC_MACRO_CTRL : FIFO_SYNC_MACRO
    generic map (
      DEVICE => "7SERIES", -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES"
      ALMOST_FULL_OFFSET => X"0002", -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET => X"0002", -- Sets the almost empty threshold
      DATA_WIDTH => TARGET_SIZE, -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE => "36Kb") -- Target BRAM, "18Kb" or "36Kb"
    port map (
      ALMOSTEMPTY => fifo_a_empty(FIFO_N), -- 1-bit output almost empty
      ALMOSTFULL => fifo_a_full(FIFO_N), -- 1-bit output almost full
      DO => fifo_ctrl_out, -- Output data, width defined by DATA_WIDTH parameter
      EMPTY => fifo_empty(FIFO_N), -- 1-bit output empty
      FULL => fifo_full(FIFO_N), -- 1-bit output full
      RDCOUNT => fifo_ctrl_counter_r , -- Output read count, width determined by FIFO depth
      RDERR => open, -- 1-bit output read error
      WRCOUNT => fifo_ctrl_counter_w, -- Output write count, width determined by FIFO depth
      WRERR => open, -- 1-bit output write error
      CLK => CLK, -- 1-bit input clock
      DI => fifo_ctrl_in, -- Input data, width defined by DATA_WIDTH parameter
      RDEN => READ_DATA, -- 1-bit input read enable
      RST => RST,-- 1-bit input reset
      WREN => WRITE_DATA -- 1-bit input write enable
      );

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- DATA OUT REBUILD
-- concatenate data from fifo
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    DATA_OUT <= data_out_concat;

    concat : for i in 0 to  FIFO_N-1 generate
      data_out_concat( ((TARGET_SIZE)*(i+1))-1 downto (TARGET_SIZE)*(i)) <=  data_out_slipt(i);
    end generate concat;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FIFO CTRL SIGNALS
-- execute bitwise or of the 4 fifos ctrl output signals
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    EMPTY   <= wire_empty;
    FULL    <= wire_full;
    A_EMPTY <= wire_a_full;
    A_FULL  <= wire_a_empty;

    opertation_or : for i in 0 to  FIFO_N-1 generate
      wire_empty   <= wire_empty or fifo_empty(i);
      wire_full    <= wire_full or fifo_full(i);
      wire_a_full  <= wire_a_full or fifo_a_empty(i);
      wire_a_empty <= wire_a_empty or fifo_a_full(i);
    end generate;

end ARCH_GENERIC_SYNC_FIFO;
