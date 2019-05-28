--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- GENERIC FIFO
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

library UNISIM;
  use UNISIM.vcomponents.all;
library UNIMACRO;
  use unimacro.Vcomponents.all;

entity GENERIC_FIFO is
           generic(
                    CTRL_SIZE    : integer := 9;
                    CURRENT_SIZE : integer := 256;
                    SYNC         : boolean := true);
           port (
              CLKA        : IN  std_logic;
              CLKB        : IN  std_logic;
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
end GENERIC_FIFO;


architecture ARCH_GENERIC_FIFO of GENERIC_FIFO is
  function or_reduce(a : std_logic_vector(5 downto 0)) return std_logic is
      variable ret : std_logic := '0';
  begin
      for i in a'range loop
          ret := ret or a(i);
      end loop;

      return ret;
  end function or_reduce;


  constant FIFO_N     : integer := CURRENT_SIZE/64;
  constant MOD_FIFO : integer := CURRENT_SIZE mod 64;
  signal ALL_ZEROS_CTRL    : std_logic_vector((64 - CTRL_SIZE)-1 downto 0) := (others=>'0');
  signal ALL_ZEROS_DATA    : std_logic_vector((64 - MOD_FIFO)-1 downto 0) := (others=>'0');

  signal std_logic_mod       : std_logic_vector(5 downto 0) :=  std_logic_vector(to_unsigned(MOD_FIFO, 6));
  signal reduced_mod         : std_logic := or_reduce(std_logic_mod);
  signal reduced_mod_vector  : std_logic_vector(31 downto 0) := x"0000000" & "000" & reduced_mod;
  signal reduced_mod_integer : integer := to_integer(unsigned(reduced_mod_vector));

  type   ctrl_table is array (0 to FIFO_N) of std_logic;
  signal fifo_empty   : ctrl_table;
  signal fifo_full    : ctrl_table;
  signal fifo_a_full  : ctrl_table;
  signal fifo_a_empty : ctrl_table;

  signal wire_empty : std_logic := '0';
  signal wire_full : std_logic := '0';
  signal wire_a_full : std_logic := '0';
  signal wire_a_empty : std_logic := '0';

  type   data_table is array (0 to FIFO_N-1 + reduced_mod_integer) of std_logic_vector(63 downto 0);
  signal data_in_slipt    : data_table;
  signal data_out_slipt   : data_table;
  signal data_out_concat  : std_logic_vector(CURRENT_SIZE-1 downto 0);

  type   counter_table is array (0 to 1) of std_logic_vector(8 downto 0);
  type   counter_fifos is array (0 to FIFO_N-1 + reduced_mod_integer) of counter_table;
  signal fifo_data_counter    : counter_fifos;

  signal fifo_ctrl_in         : std_logic_vector(63 downto 0);
  signal fifo_ctrl_out        : std_logic_vector(63 downto 0);
  signal fifo_ctrl_counter_r  :std_logic_vector(8 downto 0);
  signal fifo_ctrl_counter_w  : std_logic_vector(8 downto 0);



BEGIN

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- BREAK DATA
-- split bus data in to chunks of Target size
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  break : for i in 0 to  FIFO_N-1 generate
    data_in_slipt(i) <= DATA_IN( ((64)*(i+1))-1 downto (64)*(i));
  end generate break;

  break_extra_data : if (MOD_FIFO /= 0) generate
    data_in_slipt(FIFO_N) <= ALL_ZEROS_DATA & DATA_IN((((64)*FIFO_N-1)-1)+MOD_FIFO downto (64)*FIFO_N-1);
  end generate break_extra_data;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- GENERATE DATA FIFOS
-- generates N-1 fifos
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Xilinx_Sync : if (SYNC) generate
  FIFO_SYNC_MACRO_DATA : for i in 0 to  (FIFO_N-1)+ reduced_mod_integer  generate
    FIFO_SYNC_MACRO_INST : FIFO_SYNC_MACRO
    generic map (
      DEVICE => "7SERIES", -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES"
      ALMOST_FULL_OFFSET => X"0002", -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET => X"0002", -- Sets the almost empty threshold
      DATA_WIDTH => 64, -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE => "36Kb") -- Target BRAM, "18Kb" or "36Kb"
    port map (
      ALMOSTEMPTY => fifo_a_empty(i), -- 1-bit output almost empty
      ALMOSTFULL => fifo_a_full(i), -- 1-bit output almost full
      DO => data_out_slipt(i), -- Output data, width defined by DATA_WIDTH parameter
      EMPTY => fifo_empty(i), -- 1-bit output empty
      FULL => fifo_full(i), -- 1-bit output full
      RDCOUNT => fifo_data_counter(i)(0), -- Output read count, width determined by FIFO depth
      RDERR => open, -- 1-bit output read error
      WRCOUNT => fifo_data_counter(i)(1), -- Output write count, width determined by FIFO depth
      WRERR => open, -- 1-bit output write error
      CLK => CLKA, -- 1-bit input clock
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
  ctrl_sync_fifo : if (CTRL_SIZE /= 0) generate
    fifo_ctrl_in <= ALL_ZEROS_CTRL & CTRL_IN;
    CTRL_OUT     <= fifo_ctrl_out(CTRL_SIZE-1 downto 0);

      FIFO_SYNC_MACRO_CTRL : FIFO_SYNC_MACRO
      generic map (
        DEVICE => "7SERIES", -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES"
        ALMOST_FULL_OFFSET => X"0002", -- Sets almost full threshold
        ALMOST_EMPTY_OFFSET => X"0002", -- Sets the almost empty threshold
        DATA_WIDTH => 64, -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
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
        CLK => CLKA, -- 1-bit input clock
        DI => fifo_ctrl_in, -- Input data, width defined by DATA_WIDTH parameter
        RDEN => READ_DATA, -- 1-bit input read enable
        RST => RST,-- 1-bit input reset
        WREN => WRITE_DATA -- 1-bit input write enable
        );
      end generate ctrl_sync_fifo;
end generate Xilinx_Sync;


Xilinx_Dual_Clock : if (not SYNC) generate
    FIFO_DUAL_CLOCK_MACRO_DATA : for i in 0 to  (FIFO_N-1)+reduced_mod_integer generate
      FIFO_DUAL_CLOCK_MACRO_INST : FIFO_DUALCLOCK_MACRO
      generic map (
        DEVICE => "7SERIES",              -- Target Device: "VIRTEX5", "VIRTEX6", "7SERIES"
        ALMOST_FULL_OFFSET => X"0002",    -- Sets almost full threshold
        ALMOST_EMPTY_OFFSET => X"0002",   -- Sets the almost empty threshold
        DATA_WIDTH => 64,                 -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
        FIFO_SIZE => "36Kb",              -- Target BRAM, "18Kb" or "36Kb"
        FIRST_WORD_FALL_THROUGH => FALSE) -- Sets the FIFO FWFT to TRUE or FALSE
      port map (
        ALMOSTEMPTY => fifo_a_empty(i),       -- 1-bit output almost empty
        ALMOSTFULL => fifo_a_full(i),         -- 1-bit output almost full
        DO => data_out_slipt(i),              -- Output data, width defined by DATA_WIDTH parameter
        EMPTY => fifo_empty(i),               -- 1-bit output empty
        FULL =>  fifo_full(i),                -- 1-bit output full
        RDCOUNT => fifo_data_counter(i)(0),           -- Output read count, width determined by FIFO depth
        RDERR => open,                    -- 1-bit output read error
        WRCOUNT => fifo_data_counter(i)(1),           -- Output write count, width determined by FIFO depth
        WRERR => open,                    -- 1-bit output write error
        DI =>  data_in_slipt(i),  -- Input data, width defined by DATA_WIDTH parameter
        RDCLK => CLKA,                   -- 1-bit input read clock
        RDEN => READ_DATA,                -- 1-bit input read enable
        RST => RST,                       -- 1-bit input reset
        WRCLK => CLKB,                   -- 1-bit input write clock
        WREN => WRITE_DATA                -- 1-bit input write enable
      );
    end generate FIFO_DUAL_CLOCK_MACRO_DATA;

  ctrl_dual_clock_fifo : if (CTRL_SIZE /= 0) generate
      fifo_ctrl_in <= ALL_ZEROS_CTRL & CTRL_IN;
      CTRL_OUT     <= fifo_ctrl_out(CTRL_SIZE-1 downto 0);

    FIFO_DUAL_CLOCK_MACRO_CTRL : FIFO_DUALCLOCK_MACRO
    generic map (
      DEVICE => "7SERIES",              -- Target Device: "VIRTEX5", "VIRTEX6", "7SERIES"
      ALMOST_FULL_OFFSET => X"0002",    -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET => X"0002",   -- Sets the almost empty threshold
      DATA_WIDTH => 64,                 -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE => "36Kb",              -- Target BRAM, "18Kb" or "36Kb"
      FIRST_WORD_FALL_THROUGH => FALSE) -- Sets the FIFO FWFT to TRUE or FALSE
    port map (
      ALMOSTEMPTY => fifo_a_empty(FIFO_N),       -- 1-bit output almost empty
      ALMOSTFULL => fifo_a_full(FIFO_N),         -- 1-bit output almost full
      DO => fifo_ctrl_out,              -- Output data, width defined by DATA_WIDTH parameter
      EMPTY => fifo_empty(FIFO_N),               -- 1-bit output empty
      FULL =>  fifo_full(FIFO_N),                -- 1-bit output full
      RDCOUNT => fifo_ctrl_counter_r,           -- Output read count, width determined by FIFO depth
      RDERR => open,                    -- 1-bit output read error
      WRCOUNT => fifo_ctrl_counter_w,           -- Output write count, width determined by FIFO depth
      WRERR => open,                    -- 1-bit output write error
      DI =>  fifo_ctrl_in,  -- Input data, width defined by DATA_WIDTH parameter
      RDCLK => CLKA,                   -- 1-bit input read clock
      RDEN => READ_DATA,                -- 1-bit input read enable
      RST => RST,                       -- 1-bit input reset
      WRCLK => CLKB,                   -- 1-bit input write clock
      WREN => WRITE_DATA                -- 1-bit input write enable
      );
    end generate ctrl_dual_clock_fifo;
end generate Xilinx_Dual_Clock;
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- DATA OUT REBUILD
-- concatenate data from fifo
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    DATA_OUT <= data_out_concat;

    concat : for i in 0 to  FIFO_N-1 generate
      data_out_concat( ((64)*(i+1))-1 downto (64)*(i)) <=  data_out_slipt(i);
    end generate concat;

    concat_extra_data : if (MOD_FIFO /= 0) generate
      data_out_concat((((64)*FIFO_N)-1)+MOD_FIFO downto ((64)*FIFO_N)) <= data_out_slipt(FIFO_N)(MOD_FIFO-1 downto 0);
    end generate concat_extra_data;

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

end ARCH_GENERIC_FIFO;
