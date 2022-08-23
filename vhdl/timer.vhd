-- Listing 13.9
-- I changed it to be a 4 sec timer
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
   
entity timer is
  generic(
    W: integer:=7 -- number of bits for counter variable
  );
  port(
    clk, reset: in std_logic;
    timer_start, timer_tick: in std_logic;
    timer_up: out std_logic
  );
end timer;


architecture arch of timer is
  signal timer_reg, timer_next: unsigned(W downto 0);
  -- NOTE: 
  -- when W=7, timer will start from 11111111 = 255 and count-down
  -- clock cycles of 60 Hz tick; so, we create a timer of 4 sec;
  -- for W=6 timer will be for 2 seconds;
begin
  -- registers
  process (clk, reset)
  begin
    if reset='1' then
      timer_reg <= (others=>'1');
    elsif (clk'event and clk='1') then
      timer_reg <= timer_next;
    end if;
  end process;
  -- next-state logic
  process(timer_start,timer_reg,timer_tick)
  begin
    if (timer_start='1') then
      timer_next <= (others=>'1');
    elsif timer_tick='1' and timer_reg/=0 then
      timer_next <= timer_reg - 1;
    else
      timer_next <= timer_reg;
    end if;
  end process;
  timer_up <='1' when timer_reg=0 else '0';
end arch;