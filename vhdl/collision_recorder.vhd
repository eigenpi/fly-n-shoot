-- used to record if at least a pixel of say Tunnel and Ship
-- overlap during one Frame sweep (1/30 of second);
-- if at least one pixel x,y has overlap, that is a 
-- collision detection! I do not need to detect more
-- pixels overlap - one sufices
-- IMPORTANT NOTES:
-- clk is the same as the clk of sweeping the pixels, so, pixels
-- overlaps are detected as pixels_overlap_event events, so, they could
-- actually be counted too; but, their number is unimportant
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
       
entity collision_recorder is
   port(
      clk, reset: in std_logic;
      clear: in std_logic;
      pixels_overlap_event: in std_logic;
      collision_detected: out std_logic
   );
end collision_recorder;

architecture arch_behavioral of collision_recorder is
   signal counter_reg, counter_next: std_logic; -- initially was a counter
begin
   -- registers
   process (clk,reset)
   begin
      if reset='1' then
         counter_reg <= '0';
      elsif (clk'event and clk='1') then
         counter_reg <= counter_next;
      end if;
   end process;
   
   -- next-state logic 
   process(clear, counter_reg, pixels_overlap_event)
   begin
      counter_next <= counter_reg;     
      if (clear='1') then 
        counter_next <= '0';
      elsif (counter_reg='0' and pixels_overlap_event='1') then
        counter_next <= '1'; -- record the first pixel overlap denoting a collision
      end if; 
   end process;
   
   collision_detected <= counter_reg;
end arch_behavioral;
