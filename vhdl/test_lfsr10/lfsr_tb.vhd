library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr_tb is
end lfsr_tb;

architecture my_tb of lfsr_tb is

component LFSR10
  port(
    clk : in std_logic; 
    reset : in std_logic;
    seed : in unsigned(9 downto 0);
    z : out unsigned(9 downto 0)
  );
end component;

signal clk_i, reset_i: std_logic; 
signal seed_i, z_o: unsigned(9 downto 0);
 
begin
  
  -- (1) instantiate design under test (DUT);
  DUT: LFSR10 port map (
    clk => clk_i, 
    reset => reset_i,
    seed => seed_i,
    z => z_o
  );
  
  -- (2) process to generate clock signal;
  clk_gen : process
  begin
    clk_i <= '0'; wait for 1 ps;
    clk_i <= '1'; wait for 1 ps;
  end process clk_gen; 
  
  -- (3) generate desired input stimuli;
  process
  begin
    --seed_i <= (OTHERS=>'1');   
	seed_i <= "0101011111";
    reset_i <= '1';
    wait for 2 ps; -- 2 clock cycles
    reset_i <= '0';
    wait for 1100 ps;   
  end process;  
end my_tb;
