library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity mine1 is
  generic(ID: integer := 0);
  port(
    reset: in std_logic; 
    clk: in std_logic; -- 50 MHz clock; used for count-down timers only
    countdown_timer_tick: in std_logic; -- used by 2 sec and 4 sec countdown timers
    TIME_TICK: in std_logic; -- clock of 30 cycles per second
    x0, y0: in std_logic_vector(9 downto 0); -- location where mine is planted
    MINE1_PLANT: in std_logic;
    MINE1_RECYCLE: in std_logic;
    MINE1_IMG: out std_logic; -- event generated to Tunnel
    mine1_bmp_overlaps_ship_bmp: in std_logic; -- from checker of collision with ship, from Tunnel
    HIT_MINE1: out std_logic; -- event generated to Ship
    mine1_bmp_overlaps_missile_bmp: in std_logic; -- from checker of collision with missile
    DESTROYED_MINE1: out std_logic; -- event generated to Missile
    EXPLOSION_MINE1: out std_logic; -- event generated to Tunnel
    exit_action: in std_logic; -- from Player
    MINE1_DISABLED: out std_logic; -- event generated to Tunnel
    mine1_id: out std_logic_vector(2 downto 0); -- info passed with event MINE1_DISABLED
    x, y: out std_logic_vector(9 downto 0); -- coordinates passed with events posted
    mine1_explosion_size: out std_logic_vector(9 downto 0) -- passed with event EXPLOSION_MINE1
  );
end mine1;


architecture UML_ARCHITECTURE of mine1 is

  type SUPERSTATE_TYPE_MINE1 is (USED, UNUSED);
  type STATE_TYPE_MINE1 is (Planted, Exploding);
  signal superstate_reg, superstate_next: SUPERSTATE_TYPE_MINE1;
  signal state_reg, state_next: STATE_TYPE_MINE1;
  -- coordinates where mine is planted;
  signal x_reg, x_next: unsigned(9 downto 0);
  signal y_reg, y_next: unsigned(9 downto 0);
  signal local_ctr_reg, local_ctr_next: unsigned(7 downto 0); -- local counter; count TIME_TICK 30 times (i.e., 1 sec) and increment score
  signal exp_ctr_reg, exp_ctr_next: unsigned(9 downto 0); -- explosion counter
  
  constant MAX_X: integer:=640;
  constant MAX_Y: integer:=480;
  constant MINE1_WIDTH: integer:=24;
  constant MINE1_HEIGHT: integer:=24;
  constant MINE1_DELTA_V: integer:=1;  
  signal timer_2sec_start, timer_2sec_up: std_logic;
  
  
  begin
    
    -- state register; process #1
    process (TIME_TICK, reset)
    begin
      if (reset = '1') then 
        superstate_reg <= UNUSED;
        state_reg <= Planted;
        --x_reg <= to_unsigned((MAX_X-MINE1_WIDTH)/2,10); -- place mine10 in the middle of screen on x axis;
        --y_reg <= to_unsigned((MAX_Y-MINE1_HEIGHT)/2,10); -- place mine10 in the middle of screen on y axis;  
        x_reg <= unsigned(x0);
        y_reg <= unsigned(y0);        
        local_ctr_reg <= (OTHERS=>'0');
      elsif (TIME_TICK' event and TIME_TICK = '1') then 
        superstate_reg <= superstate_next;
        state_reg <= state_next;
        x_reg <= x_next;
        y_reg <= y_next;
        local_ctr_reg <= local_ctr_next;
      end if;
    end process;   
    
    
    -- next state and output logic; process #2
    process (superstate_reg, state_reg, MINE1_PLANT, MINE1_RECYCLE, 
      mine1_bmp_overlaps_ship_bmp, mine1_bmp_overlaps_missile_bmp, 
      exit_action)
    begin
      -- default initializations
      superstate_next <= superstate_reg;
      state_next <= state_reg;
      x_next <= x_reg;
      y_next <= y_reg;
      local_ctr_next <= local_ctr_reg;
      MINE1_IMG <= '0';
      HIT_MINE1 <= '0';
      DESTROYED_MINE1 <= '0';
      EXPLOSION_MINE1 <= '0';
      MINE1_DISABLED <= '0';
      timer_2sec_start <='0';      
  
      case superstate_reg is  
        --=====================================================================
        when UNUSED => -- superstate
          if MINE1_PLANT = '1' then
            superstate_next <= USED;
            state_next <= Planted;
            x_next <= unsigned(x0);
            y_next <= unsigned(y0);
          end if; 
        --=====================================================================
        when USED => -- superstate; 
          if exit_action = '1' then 
            MINE1_DISABLED <= '1'; -- tell the Tunnel object
            superstate_next <= UNUSED;
          end if;
          if MINE1_RECYCLE = '1' then
            superstate_next <= UNUSED;
          end if;
          -- [case statement] for the inner states of "USED" superstate
          case state_reg is 
            --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            when Planted =>
              MINE1_IMG <= '1';
              if (x_reg >= MINE1_DELTA_V) then -- I can continue to move to the left a "delta v" on screen          
                x_next <= x_reg - MINE1_DELTA_V; -- moving to the left with Tunnel creates the illusion of Ship moving to right
              else -- if I subtractd MINE1_DELTA_V pixels I would place left edge of mine outside screen on left; I work with unsigned!
                superstate_next <= UNUSED; -- mine out of boundary of screen
              end if;          
              if (mine1_bmp_overlaps_missile_bmp = '1') then 
                DESTROYED_MINE1 <= '1'; -- generate event to Missile
                state_next <= Exploding; 
                exp_ctr_next <= (OTHERS=>'0'); -- clear explosion counter
                timer_2sec_start <='1'; -- start cowntdown counter 2 sec
              end if;
              if (mine1_bmp_overlaps_ship_bmp = '1') then 
                HIT_MINE1 <= '1'; -- generate event to Ship
                superstate_next <= UNUSED; 
              end if;
            --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                
            when Exploding =>
              EXPLOSION_MINE1 <= '1'; -- post event to Tunnel
              -- wait for 2 sec to display exploding ship
              if timer_2sec_up='1' then
                superstate_next <= UNUSED; 
              end if; 
            --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
          end case;    
        --=====================================================================  
      end case;
    end process;
 
  -- coordinates passed with events 
  x <= std_logic_vector(x_reg);
  y <= std_logic_vector(y_reg); 
    
  mine1_id <= std_logic_vector(to_unsigned(ID,3));
  
  -- instantiate countdown timer
  timer_2sec_mine1_U0: entity work.timer
    generic map(W=>6) -- 2 seconds timer
    port map(clk=>clk, reset=>reset,
            timer_tick=>countdown_timer_tick,
            timer_start=>timer_2sec_start,
            timer_up=>timer_2sec_up);
            
end UML_ARCHITECTURE;  
