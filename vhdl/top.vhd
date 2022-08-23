-- cristinel ababei, 2022
-- this is the top level design entity of the fly-n-shoot game;
-- see the README file for more information;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity fly_n_shoot is
  port(
    clk_50mhz: in std_logic; -- 50 MHz clock from on-board oscillator; 
    reset_sw: in std_logic; -- SW(9)
    sw: in std_logic_vector(3 downto 0); -- SW(3:0) used by color mapper
    btn_user: in std_logic_vector (2 downto 0); -- KEY2: fire Missile; KEY1,0: Ship down/up;
    nes_data: in std_logic; -- from NES CONTROLLER
    nes_clock, nes_latch: out std_logic;
    hsync, vsync: out std_logic;
    vga_r, vga_g, vga_b: out std_logic_vector(7 downto 0);
    vga_clk: out std_logic;
    vga_sync: out std_logic;
    vga_blank: out std_logic;
    led_red: out std_logic -- drive LEDR(9) with 1Hz clock from clock divider; 
  );
end fly_n_shoot;


architecture arch_top of fly_n_shoot is

  component my_altpll is
    port (
      refclk   : in  std_logic := '0'; --  refclk.clk
      rst      : in  std_logic := '0'; --   reset.reset
      outclk_0 : out std_logic;        -- outclk0.clk
      outclk_1 : out std_logic         -- outclk1.clk
    );
  end component;
 
  signal reset_initial: std_logic;
  signal reset, clk, clk_2MHz, clk_10Hz: std_logic;
  signal countdown_timer_tick: std_logic; -- timer_4sec_start, timer_4sec_up
  signal in_state_new_game: std_logic; 
  signal in_state_game_over_message: std_logic;
  signal video_on, pixel_tick: std_logic;
  signal pixel_x, pixel_y: std_logic_vector (9 downto 0);
  signal graph_on: std_logic; -- graphics to display?
  signal text_on: std_logic_vector(3 downto 0);
  signal graph_rgb, text_rgb: std_logic_vector(2 downto 0);
  signal rgb_reg, rgb_next: std_logic_vector(2 downto 0); 
  signal score_from_tunnel: std_logic_vector(19 downto 0); -- from Tunnel passed to game_text unit
  signal vsync_reg: std_logic;
  
  signal btn: std_logic_vector (2 downto 0); -- KEY2: fire Missile; KEY1,0: Ship down/up;
  signal nes_latch_reg: std_logic;
  signal nes_clock_reg: std_logic;
  signal nes_button: std_logic_vector(7 downto 0);
  
begin

  -- instantiate clock repeater
  clk_pll_instance: my_altpll port map(
    refclk   => clk_50mhz,
    rst      => '0',  
    outclk_0 => clk, -- repeat 50 MHz
    outclk_1 => clk_2MHz); -- 2 MHz
  
  
  --instantiate clock divider to generate 1 Hz signal to drive LEDR(9)
  inst_clk_divider: entity work.clk_divider port map (CLK_IN => clk, CLK_OUT => clk_10Hz);


  -- instantiate color mapper
  color_map_unit: entity work.color_map port map(sw, rgb_reg, vga_r, vga_g, vga_b);


  -- instantiate initial reset signal
  reset_generator_unit: entity work.reset_generator
    port map(clk=>clk_10Hz, reset=>reset_initial);
                   
  reset <= (reset_sw OR reset_initial); -- about 1-2 seconds
  
  
  led_red <= clk_10Hz;
  vga_sync <= '1';
  vga_blank <= video_on;
  vga_clk <= pixel_tick; -- comes from vga_sync entity
  -- pass vsync via vsync_reg because I do send it to out port, but also to graph
  -- to be used as 1/30 sec TIME_TICK
  vsync <= vsync_reg; 
  
  
  -- based on how the nes fsm is implemented, we need to use the following correspondence:
  -- nes_button(4) <--> btn(0) or KEY0 ---> Up
  -- nes_button(5) <--> btn(1) or KEY1 ---> Down
  -- nes_button(1) <--> btn(2) or KEY2 ---> Shoot
  btn(0) <= (not btn_user(0)) OR (nes_button(4));
  btn(1) <= (not btn_user(1)) OR (nes_button(5));
  btn(2) <= (not btn_user(2)) OR (nes_button(1));
  
  
  -- instantiate NES FSM
  nes_fsm_unit: entity work.nes_fsm
    port map(clk=>clk, 
            latch=>nes_latch_reg, pulse=>nes_clock_reg, data=>nes_data, -- inputs
            button=>nes_button); -- output
           
  -- instantiate NES clock unit
  nes_clock_unit: entity work.nes_clocks
    port map(clk=>clk, 
            nes_latch=>nes_latch_reg, nes_clk=>nes_clock_reg); -- outputs
  
  -- drive the out ports, going to the actual NEC CONTROLLER device;
  nes_latch <= nes_latch_reg;
  nes_clock <= nes_clock_reg;
  
  
  -- instantiate graphics module
  tunnel_plus_graphics_unit: entity work.tunnel_and_graph
    port map(clk=>clk, 
            clk_10Hz=>clk_10Hz,
            countdown_timer_tick=>countdown_timer_tick,
            pixel_tick=>pixel_tick, -- comes from vga_sync
            reset=>reset, 
            in_state_new_game=>in_state_new_game, -- is Tunnel in state NEW_GAME?
            in_state_game_over_message=>in_state_game_over_message, -- is Tunnel in state GAME_OVER_MESSAGE?
            vsync=>vsync_reg, -- pass vsync_reg signal, to be used as TIME_TICK
            btn=>btn,
            pixel_x=>pixel_x, pixel_y=>pixel_y,
            graph_on=>graph_on, 
            score=>score_from_tunnel, -- score passed to game_text
            rgb=>graph_rgb);


  -- instantiate text module
  text_unit: entity work.game_text
    port map(reset=>reset, 
            clk=>clk, 
            clk_2MHz=>clk_2MHz, 
            pixel_x=>pixel_x, 
            pixel_y=>pixel_y,
            score=>score_from_tunnel, -- score from Tunnel passed here to game_text
            text_on=>text_on, 
            text_rgb=>text_rgb);

             
  -- instantiate video synchonization unit
  vga_sync_unit: entity work.vga_sync
    port map(clk=>clk, 
            reset=>reset,
            video_on=>video_on, 
            p_tick=>pixel_tick,
            hsync=>hsync, 
            vsync=>vsync_reg,
            pixel_x=>pixel_x, 
            pixel_y=>pixel_y);


  -- generate timer tick used by all countdown timers 
  -- will be passed down the hierarchy to all design 
  -- entities that use countdown counters
  countdown_timer_tick <= -- 60 Hz tick
    '1' when pixel_x="0000000000" and
             pixel_y="0000000000" else
    '0';
 

  -- RGB multiplexing circuit
  -- registers
  process (clk, reset)
  begin
    if reset='1' then
       rgb_reg <= (others=>'0');
    elsif (clk'event and clk='1') then
       if (pixel_tick='1') then
         rgb_reg <= rgb_next;
       end if;
    end if;
  end process;
  
  -- logic
  process(
    in_state_new_game, in_state_game_over_message,
    video_on, graph_on, graph_rgb, text_on, text_rgb)
  begin
    if video_on='0' then
       rgb_next <= "000"; -- blank the edge/retrace "000"
    else
       -- display score, rules or game over
       if (text_on(3)='1') or -- score_on
          (in_state_new_game='1' and (text_on(1)='1' or text_on(2)='1')) or -- logo_on OR rules_on
          (in_state_game_over_message='1' and text_on(0)='1') then -- over_on
          rgb_next <= text_rgb;
       elsif graph_on='1' then -- display graph
         rgb_next <= graph_rgb;
       else
         rgb_next <= "110"; -- yellow background
       end if;
    end if;
  end process; 

end arch_top;