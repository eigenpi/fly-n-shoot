-- cristinel.ababei
-- I use LFSR's to generate (pseudo)random numbers
-- this one is on 10 bits; uses a primitive polynomial with minimum # of XORs:
-- x^10 + x^3 + 1
-- NOTE: implemented here is Type 2 or "1-to-many topology" LFSR
-- should generate random numbers between 0-1024 on 10 bits
-- I use unsigned and not std_logic_vector to simplify things 
-- where I instantiate this entity...
  
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
  
entity LFSR10 is
  port(
    clk : in std_logic; 
    reset : in std_logic;
    seed : in unsigned(9 downto 0);
    z : out unsigned(9 downto 0)
  );
end entity;
 
ARCHITECTURE my_functional OF LFSR10 IS
  --CONSTANT seed : unsigned(9 DOWNTO 0) := (OTHERS  => '1'); -- I used to hardcode it here;
  SIGNAL q : unsigned(9 DOWNTO 0); 
   
BEGIN
  z <= q;

  PROCESS(clk, reset)
  BEGIN
    IF (reset = '1') THEN 
      q <= seed;                       -- set seed value on reset
    ELSIF (clk'EVENT AND clk='1') THEN -- clock with rising edge
      q(0) <= q(9);                    -- feedback to LS bit
      q(1) <= q(0);                                
      q(2) <= q(1);
      q(3) <= q(2);
      q(4) <= q(3) XOR q(9);          -- tap at stage 3
      q(9 DOWNTO 5) <= q(8 DOWNTO 4); -- others bits shifted
    END IF;
  END PROCESS;
END ARCHITECTURE;