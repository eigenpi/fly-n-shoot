-- Listing 13.6
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
   
entity game_text is
   port(
      reset: in std_logic;
      clk, clk_2MHz: in std_logic;
      pixel_x, pixel_y: in std_logic_vector(9 downto 0);
      score: in std_logic_vector(19 downto 0); -- will convert to BCD here
      text_on: out std_logic_vector(3 downto 0);
      text_rgb: out std_logic_vector(2 downto 0)
   );
end game_text;


architecture arch of game_text is 
  signal pix_x, pix_y: unsigned(9 downto 0);
  signal rom_addr: std_logic_vector(10 downto 0);
  signal char_addr, char_addr_s, char_addr_l, char_addr_r,
        char_addr_o: std_logic_vector(6 downto 0);
  signal row_addr, row_addr_s, row_addr_l,row_addr_r,
        row_addr_o: std_logic_vector(3 downto 0);
  signal bit_addr, bit_addr_s, bit_addr_l,bit_addr_r,
        bit_addr_o: std_logic_vector(2 downto 0);
  signal font_word: std_logic_vector(7 downto 0);
  signal font_bit: std_logic;
  signal score_on, logo_on, rule_on, over_on: std_logic;
  signal rule_rom_addr: unsigned(5 downto 0);
  type rule_rom_type is array (0 to 63) of
    std_logic_vector (6 downto 0);
  -- RULES text ROM definition
  constant RULE_ROM: rule_rom_type :=
  (
    -- row 1
    "1010010", -- R
    "1010101", -- U
    "1001100", -- L
    "1000101", -- E
    "1010011", -- S
    "0111010", -- :    
    "0000000", --
    "0000000", --
    "0000000", --
    "0000000", --
    "0000000", --
    "0000000", --
    "0000000", --
    "0000000", --
    "0000000", --
    "0000000", --
    -- row 2
    "1001011", -- K 
    "1000101", -- E 
    "1011001", -- Y 
    "0110000", -- 0
    "0000000", -- 
    "1000110", -- F
    "1101100", -- l
    "1111001", -- y    
    "0000000", -- 
    "1010101", -- U
    "1110000", -- p
    "0000000", -- 
    "0000000", -- 
    "0000000", -- 
    "0000000", -- 
    "0000000", --            
    -- row 3
    "1001011", -- K 
    "1000101", -- E 
    "1011001", -- Y 
    "0110001", -- 1 
    "0000000", -- 
    "1000110", -- F
    "1101100", -- l
    "1111001", -- y    
    "0000000", --
    "1000100", -- D
    "1101111", -- o
    "1110111", -- w
    "1101110", -- n
    "0000000", --
    "0000000", -- 
    "0000000", -- 
    -- row 4
    "1001011", -- K 
    "1000101", -- E 
    "1011001", -- Y 
    "0110011", -- 3 
    "0000000", -- 
    "1110100", -- t
    "1101111", -- o
    "0000000", -- 
    "1010011", -- S
    "1101000", -- h
    "1101111", -- o
    "1101111", -- o
    "1110100", -- t
    "0000000", -- 
    "0000000", -- 
    "0000000"  --         
  );
  signal dig5, dig4, dig3, dig2, dig1, dig0: std_logic_vector(3 downto 0);
  signal start_b2b, ready_b2b, done_b2b: std_logic; 
  -- constant to measure 1/30 of second; period to trigger
  -- conversion bin2bcd of score; 1/30 = 33.33 ms
  -- which translate into 1667000 cycles of 50 MHz clock signal (20xE-9 seconds);
  constant PERIOD_TO_TRIGGER_BIN2BCD: integer := 4000000; --1667000;
  signal k_reg, k_next: unsigned(23 downto 0); 
begin

  ---------------------------------------------
  -- current pixel coordinates
  --------------------------------------------- 
  pix_x <= unsigned(pixel_x);
  pix_y <= unsigned(pixel_y);
  -- instantiate font rom
  font_unit: entity work.font_rom
    port map(clk=>clk, addr=>rom_addr, data=>font_word);
    
  ---------------------------------------------
  -- score conversion from Binary to BCD
  -- to be displayed in top-left corner
  -- of screen all the time
  -- the highest score displayed can be 999999 
  ---------------------------------------------
  -- instantiate bin2bcd
  bin2bcd_unit: entity work.bin2bcd
    port map(
    clk=>clk,
    reset=>reset, 
    start=> start_b2b, 
    bin=>score,
    ready=>ready_b2b, 
    done_tick=>done_b2b, 
    bcd5=>dig5, bcd4=>dig4, bcd3=>dig3, bcd2=>dig2, bcd1=>dig1, bcd0=>dig0);

  -- logic to generate signal to restart bin2bcd converter
  process (clk, reset)
  begin 
    if reset='1' then
      k_reg <= (others=>'0');
    elsif (clk'event and clk='1') then 
      k_reg <= k_next;
    end if;
  end process; 
  
  process (k_reg)
  begin
    start_b2b <= '0';
    if (k_reg < PERIOD_TO_TRIGGER_BIN2BCD) then
      k_next <= k_reg + 1;
    else
      k_next <= (others=>'0');
      start_b2b <= '1';
    end if;
  end process; 

  ---------------------------------------------
  -- score region
  --  - display two-digit score, ball on top left
  --  - scale to 16-by-32 font
  --  - line 1, 16 chars: "Score:DD Ball:D"
  ---------------------------------------------
  score_on <=
    '1' when pix_y(9 downto 5)=0 and
             pix_x(9 downto 4)<12 else
    '0';
  row_addr_s <= std_logic_vector(pix_y(4 downto 1));
  bit_addr_s <= std_logic_vector(pix_x(3 downto 1));
  with pix_x(7 downto 4) select
   char_addr_s <=
      "1010011" when "0000", -- S x53
      "1100011" when "0001", -- c x63
      "1101111" when "0010", -- o x6f
      "1110010" when "0011", -- r x72
      "1100101" when "0100", -- e x65
      "0111010" when "0101", -- : x3a
      "011" & dig5 when "0110", -- digit 100000
      "011" & dig4 when "0111", -- digit 10000
      "011" & dig3 when "1000", -- digit 1000
      "011" & dig2 when "1001", -- digit 100
      "011" & dig1 when "1010", -- digit 10
      "011" & dig0 when others; -- digit 1

  ---------------------------------------------
  -- rule region
  --   - display rule (4-by-16 tiles)on center
  --   - rule text:
  --        Rule:
  --        Use two buttons
  --        to move paddle
  --        up and down
  ---------------------------------------------
  rule_on <= '1' when pix_x(9 downto 7) = "010" and
                     pix_y(9 downto 6)=  "0010"  else
            '0';
  row_addr_r <= std_logic_vector(pix_y(3 downto 0));
  bit_addr_r <= std_logic_vector(pix_x(2 downto 0));
  rule_rom_addr <= pix_y(5 downto 4) & pix_x(6 downto 3);
  char_addr_r <= RULE_ROM(to_integer(rule_rom_addr));

  ---------------------------------------------
  -- logo region:
  --   - display logo "Fly-n-Shoot" on top center
  --   - used as background
  --   - scale to 32-by-64 font
  ---------------------------------------------
  logo_on <=
    '1' when pix_y(9 downto 6)=3 and
       (5<= pix_x(9 downto 5) and pix_x(9 downto 5)<=15) else
    '0';
  row_addr_l <= std_logic_vector(pix_y(5 downto 2));
  bit_addr_l <= std_logic_vector(pix_x(4 downto 2));
  with pix_x(8 downto 5) select
   char_addr_l <=
      "1000110" when "0101", -- F
      "1101100" when "0110", -- l
      "1111001" when "0111", -- y
      "0101101" when "1000", -- -
      "1101110" when "1001", -- n
      "0101101" when "1010", -- -
      "1010011" when "1011", -- S
      "1101000" when "1100", -- h
      "1101111" when "1101", -- o
      "1101111" when "1110", -- o
      "1110100" when others; -- t

  ---------------------------------------------
  -- game over region
  --  - display "Game Over" on center
  --  - scale to 32-by-64 fonts
  ---------------------------------------------
  over_on <=
    '1' when pix_y(9 downto 6)=4 and
       5<= pix_x(9 downto 5) and pix_x(9 downto 5)<=13 else
    '0';
  row_addr_o <= std_logic_vector(pix_y(5 downto 2));
  bit_addr_o <= std_logic_vector(pix_x(4 downto 2));
  with pix_x(8 downto 5) select
   char_addr_o <=
      "1000111" when "0101", -- G x47
      "1100001" when "0110", -- a x61
      "1101101" when "0111", -- m x6d
      "1100101" when "1000", -- e x65
      "0000000" when "1001", --
      "1001111" when "1010", -- O x4f
      "1110110" when "1011", -- v x76
      "1100101" when "1100", -- e x65
      "1110010" when others; -- r x72
  ---------------------------------------------
  -- mux for font ROM addresses and rgb
  ---------------------------------------------
  process(score_on,logo_on,rule_on,pix_x,pix_y,font_bit,
         char_addr_s,char_addr_l,char_addr_r,char_addr_o,
         row_addr_s,row_addr_l,row_addr_r,row_addr_o,
         bit_addr_s,bit_addr_l,bit_addr_r,bit_addr_o)
  begin
    text_rgb <= "110";  -- background, yellow
    if score_on='1' then
       char_addr <= char_addr_s;
       row_addr <= row_addr_s;
       bit_addr <= bit_addr_s;
       if font_bit='1' then
          text_rgb <= "001";
       end if;
    elsif rule_on='1' then
       char_addr <= char_addr_r;
       row_addr <= row_addr_r;
       bit_addr <= bit_addr_r;
       if font_bit='1' then
          text_rgb <= "001";
       end if;
    elsif logo_on='1' then
       char_addr <= char_addr_l;
       row_addr <= row_addr_l;
       bit_addr <= bit_addr_l;
       if font_bit='1' then
          text_rgb <= "001"; --"011"
       end if;
    else -- game over
       char_addr <= char_addr_o;
       row_addr <= row_addr_o;
       bit_addr <= bit_addr_o;
       if font_bit='1' then
          text_rgb <= "001";
       end if;
    end if;
  end process;
  text_on <= score_on & logo_on & rule_on & over_on;
  ---------------------------------------------
  -- font rom interface
  ---------------------------------------------
  rom_addr <= char_addr & row_addr;
  font_bit <= font_word(to_integer(unsigned(not bit_addr)));
end arch;