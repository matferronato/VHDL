library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity mem_checker is
	generic(DATA_SIZE : integer := 16;
			SRAM_N     : integer := 32;
			BITS      : integer := 5);
  	port
  	(
      clk             : in std_logic;
      rst             : in std_logic;
	  run             : in std_logic;
	  flag            : out std_logic
	);
end mem_checker;

architecture arch_mem_checker of mem_checker is


	--constant MAX_TIMER : integer := (100000000-1);
	constant MAX_TIMER : integer := (1000);
	type state is (IDLE, MARCH_FW, MARCH_FR, MARCH_NEG, MARCH_BR, MARCH_BW, RETENTION, RESULT, PANIC);
	signal current_s : state ;

	signal patterns_gen : std_logic_vector((BITS*DATA_SIZE)-1 downto 0);
	type pattern_array is array (0 to BITS-1) of std_logic_vector(DATA_SIZE-1 downto 0);
	signal pattern: pattern_array;
	signal w_addr : std_logic_vector(BITS-1 downto 0);			      
	signal r_addr : std_logic_vector(BITS-1 downto 0);			      
	signal w_data : std_logic_vector(DATA_SIZE-1 downto 0);	 		      
	signal r_data : std_logic_vector(DATA_SIZE-1 downto 0);	
	signal en : std_logic;
	
	signal signature_en : std_logic;
	signal signature_test : std_logic_vector(DATA_SIZE-1 downto  0) := (others => '0');
 	signal signature_dataout : std_logic_vector(DATA_SIZE-1 downto  0);
	
	signal i : integer range 0 to BITS;
	signal j : integer range 0 to SRAM_N;
	signal timer : integer range 0 to MAX_TIMER;
	signal t_retention_test : std_logic;

	function Log2(temp : natural) return natural is
	begin
		for i in 0 to integer'high loop
			 if (2**i >= temp) then
				  return i;
			 end if;
		end loop;
		return 0;
	end function Log2;
	
begin

	data_out <= r_data when (current_s = MARCH_FR or current_s = MARCH_NEG or current_s = MARCH_BR) else (others => '0');   
	signature_en <= '1' when (current_s = MARCH_FR or current_s = MARCH_NEG or current_s = MARCH_BR) else '0';

  process(clk, rst)
  begin
    if rst = '1' then
		t_retention_test <= '0';
		j <= 0;
		i <= 0;
		timer <= 0;
		current_s <= IDLE;
    elsif rising_edge(clk) then
		case current_s is
			when IDLE =>
				if run = '1' then
					current_s <= MARCH_FW;
				end if;
--##############################################################				
			when MARCH_FW => null;
				if j = SRAM_N then
					j <= 1;
					current_s <= MARCH_FR;
					r_addr <= std_logic_vector(to_signed(0, w_addr'length));
				else
					j <= j + 1;
					w_addr  <= std_logic_vector(to_signed(j, w_addr'length));
					w_data  <= pattern(i);
				end if;
--##############################################################				
			when MARCH_FR => 
				if r_data = pattern(i) then
					if j = SRAM_N then
						if t_retention_test = '0' then
							current_s <= MARCH_NEG;
						else 	
							current_s <= RESULT;
						end if;
					else
						j <= j + 1;
						r_addr  <= std_logic_vector(to_signed(j, w_addr'length));
						w_addr  <= std_logic_vector(to_signed(j, w_addr'length));
						w_data  <= not(pattern(i));						
					end if;								
				else 
					current_s <= PANIC;
				end if;
--##############################################################				
			when MARCH_NEG => 
				if r_data = not(pattern(i)) then
					if j = SRAM_N then
						current_s <= MARCH_BW;
					else
						j <= j + 1;
						r_addr  <= std_logic_vector(to_signed(j, w_addr'length));
						w_addr  <= std_logic_vector(to_signed(j, w_addr'length));
						w_data  <= pattern(i);						
					end if;								
				else 
					current_s <= PANIC;
				end if;				
				
--##############################################################
			when MARCH_BW => null;
				if j = 0 then
					j <= SRAM_N-2;
					current_s <= MARCH_BR;
					r_addr <= std_logic_vector(to_signed(SRAM_N-1, w_addr'length));
				else
					j <= j - 1;
					w_addr  <= std_logic_vector(to_signed(j, w_addr'length));
					w_data  <= pattern(i);
				end if;
--##############################################################				
			when MARCH_BR => 
				if r_data = pattern(i) then
					if j = 0 then
						if i = BITS-1 then
							current_s <= RETENTION;
						else 
							i <= i + 1;
							current_s <= MARCH_FW;
						end if;
					else
						j <= j - 1;
						r_addr  <= std_logic_vector(to_signed(j, w_addr'length));
					end if;								
				else 
					current_s <= PANIC;
				end if;
--##############################################################	
			when RETENTION => null;
				if timer = MAX_TIMER then
					t_retention_test <= '1';
					current_s <= MARCH_FR;
				else 
					timer <= timer + 1;
				end if;
				
			when RESULT => 
				if (signature_dataout = signature_test) then
					flag <= '1';
				else 
					flag <= '0';
				end if;
			when PANIC => flag <= '0';
		end case;
	end if;
  end process;


--##############################################################
--###SRAM                                                   ####
--###                                                       ####
--##############################################################


	INST_REGISTER_BANK: entity work.regbank
	generic map (DATA_SIZE => DATA_SIZE, REG_N => SRAM_N, BITS => LOG2(SRAM_N))
	port map(
		clk       => clk,           
		rst 	  => rst,   
		reg_wadrr => w_addr,			      
		reg_raddr => r_addr,			      
		reg_wdata => w_data,	 		      
		reg_rdata => r_data,
		reg_wen	  => '1'		         
	);

--##############################################################
--###PATTERN GEN                                            ####
--###                                                       ####
--##############################################################

	INST_PATTERN: entity work.pattern_gen
	generic map (DATA_SIZE => DATA_SIZE, ARRAY_SIZE => LOG2(SRAM_N))
	port map(
		clk       => clk,           
		rst 	  => rst,   
		patterns  => patterns_gen
	);
	
	ASIGNMENT : process(patterns_gen)
	begin
		for k in 0 to (BITS*DATA_SIZE)-1 loop
			pattern(k/DATA_SIZE)(k mod DATA_SIZE) <= patterns_gen(k);
		end loop;
	end process ASIGNMENT;	
	
--##############################################################
--###SIGNATURE                                              ####
--###                                                       ####
--##############################################################
	
    INST_SIGNATURE : entity work.signature
    generic map (DATA_SIZE => WORD_SIZE)  
    port map(
		clk      => clk, 
		rst      => rst,
		en       => signature_en,
		data_in  => r_data,
		data_out => signature_dataout
    );		
	
end arch_mem_checker;