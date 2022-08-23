-- Power-On Reset (POR) generator
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reset_generator is
  port(
    clk: in std_logic;
    reset: out std_logic
  );
end reset_generator;

architecture arch of reset_generator is
  signal counter_next: unsigned(3 downto 0) := (OTHERS=>'0');
  signal counter_reg: unsigned(3 downto 0) := (OTHERS=>'0');
  signal reset_local: std_logic;
  
begin

  -- registers
  process (clk)
  begin
    if (clk'event and clk='1') then
       counter_reg <= counter_next;
    end if;
  end process;
  
  -- logic 
  process(counter_reg)
  begin
    if counter_reg = 15 then
      counter_next <= counter_reg;
      reset_local <= '0'; -- keep it like this after first 4 cycles
    else
      counter_next <= counter_reg + 1;
      reset_local <= '1';
    end if;          
  end process;
  
  -- output port
  reset <= '0' when (counter_reg = 15) else '1';
  --reset <= reset_local;
end arch;
