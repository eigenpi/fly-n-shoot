-- simple counter with rollover on 10 bits;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_rollover is
  port(
    clk, reset: in std_logic;
    sample_now: in std_logic;
    z: out unsigned(9 downto 0) -- what is value of counter when sampling is requested
  );
end counter_rollover;

architecture arch of counter_rollover is
  signal counter_reg, counter_next: unsigned(9 downto 0); 
  signal sampled_count_reg, sampled_count_next: unsigned(9 downto 0);
begin
  -- registers
  process (clk,reset)
  begin
    if reset='1' then
      counter_reg <= (others=>'0');
      sampled_count_reg <= (others=>'1');
    elsif (clk'event and clk='1') then
      counter_reg <= counter_next;
      sampled_count_reg <= sampled_count_next;
    end if;
  end process;
  
  -- next-state logic for counter
  process(counter_reg, sampled_count_reg, sample_now)
  begin
    counter_next <= counter_reg;
    sampled_count_next <= sampled_count_reg;
    if (counter_reg="1111111111") then
      counter_next <= (others=>'0');
    else
      counter_next <= counter_reg + 1;
    end if;
    if (sample_now='1') then
      sampled_count_next <= counter_reg;
    end if;
  end process;
  
  z <= sampled_count_reg;
end arch;
