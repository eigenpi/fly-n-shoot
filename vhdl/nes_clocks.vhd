library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nes_clocks is
  port(
    clk: in std_logic;
    nes_clk: out std_logic := '0';
    nes_latch: out std_logic := '0'
  );
end nes_clocks;

architecture arch of nes_clocks is
  signal clk_count: integer := 1;
  signal counter: integer := 0;
  signal clk_6us: std_logic := '0';
  
begin

  -- divide 50 MHz clock by 600 to give ~ 83kHz clock used for NES controller
  process(clk)
    begin
    if rising_edge(clk) then
      clk_count <= clk_count + 1;
      if (clk_count = 300) then
        clk_6us <= not clk_6us;
        clk_count <= 1;
      end if;
    end if;
  end process;
	
	process(clk_6us)
	begin
    if rising_edge(clk_6us) then
      if counter < 20 then
        counter <= counter + 1;
      else
        counter <= 0;
      end if;
    end if;
    
    if counter = 0 then
      nes_latch <= '1';
    else
      nes_latch <= '0';
    end if;
   
    if counter >= 1 and counter <= 8 then
      nes_clk <= not clk_6us;
    else
      nes_clk <= '0';
    end if;	
  end process;

end arch;