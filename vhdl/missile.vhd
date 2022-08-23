library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity missile is
  port(
    reset: in std_logic;
    clk: in std_logic; -- 50 MHz clock; used for count-down timers only
    countdown_timer_tick: in std_logic; -- used by 2 sec and 4 sec countdown timers
    TIME_TICK: in std_logic; -- clock of 30 cycles per second
    MISSILE_FIRE: in std_logic;
    x0, y0: in std_logic_vector(9 downto 0); -- initial coordinates of missile same as of Ship
    x, y: out std_logic_vector(9 downto 0); -- coordinates passed with events posted by missile 
    missile_flying: out std_logic; -- true when missile in flight
    DESTROYED_EITHER_MINE: in std_logic; -- event posted by Tunnel
    HIT_MINE: in std_logic; -- event posted by Tunnel
    score_from_mine: in std_logic_vector(19 downto 0); -- score value comes with event HIT_MINE 
    HIT_MINE2_1ST_TIME: in std_logic; -- event posted by Tunnel
    HIT_WALL: in std_logic; -- event posted by Tunnel
    MISSILE_IMG: out std_logic; -- event posted to Tunnel; includes x,y too
    DESTROYED_MINE: out std_logic; -- event posted to Ship
    score_val: out std_logic_vector(19 downto 0); -- score value passed with event SCORE 
    EXPLOSION_MISSILE: out std_logic; -- event posted to Tunnel
    missile_explosion_size: out std_logic_vector(9 downto 0) -- passed with event EXPLOSION_MISSILE    
  );
end missile;


architecture UML_ARCHITECTURE of missile is

	type STATE_TYPE_MISSILE is (Armed, Flying, Exploding);
	signal state_reg, state_next: STATE_TYPE_MISSILE;
  -- coordinates of missile
  signal x_reg, x_next: unsigned(9 downto 0);
  signal y_reg, y_next: unsigned(9 downto 0); 
  -- explosion cunter
  signal exp_ctr_reg, exp_ctr_next: unsigned(9 downto 0);
  signal timer_2sec_start, timer_2sec_up: std_logic;
  
  constant MAX_X: integer:=640;
  constant MAX_Y: integer:=480;
  constant GAME_MISSILE_SPEED_X: integer:=4;
  constant GAME_SPEED_X: integer:=1;
  
	begin
  
		-- state register; process #1
		process (TIME_TICK, reset)
		begin
			if (reset = '1') then 
				state_reg <= Armed;
        x_reg <= (OTHERS=>'0');
        y_reg <= (OTHERS=>'0');
        exp_ctr_reg <= (OTHERS=>'0');
			elsif (TIME_TICK' event and TIME_TICK = '1') then 
				state_reg <= state_next;
        x_reg <= x_next;
        y_reg <= y_next;
        exp_ctr_reg <= exp_ctr_next;
			end if;
	  end process;
    
		-- next state and output logic; process #2
		process (state_reg, exp_ctr_reg, MISSILE_FIRE, HIT_MINE, HIT_WALL, x_reg, y_reg)
		begin
			state_next <= state_reg;
			x_next <= x_reg;
      y_next <= y_reg;
      exp_ctr_next <= exp_ctr_reg; 
      MISSILE_IMG <= '0';
      DESTROYED_MINE <= '0';
      EXPLOSION_MISSILE <= '0';
      missile_explosion_size <= (OTHERS=>'0');
      score_val <= (OTHERS=>'0');
      missile_flying<='0';      
      timer_2sec_start <='0';
      
			case state_reg is 
				when Armed =>
					if MISSILE_FIRE = '1' then
						state_next <= Flying;
						x_next <= unsigned(x0);
            y_next <= unsigned(y0);
					end if;
				when Flying =>
          missile_flying<='1'; 
          x_next <= x_reg + GAME_MISSILE_SPEED_X; -- advance missile
          -- post event MISSILE_IMG to the Tunnel; this amounts to just asserting MISSILE_IMG;
          -- event includes also the coordinates x,y information
          MISSILE_IMG <= '1';
          if (x_reg >= MAX_X) then           
            state_next <= Armed;
					end if;
          if (DESTROYED_EITHER_MINE = '1') then -- in this case, missile does not explode, just vanishes; mines explode on screen
            state_next <= Armed;
            DESTROYED_MINE <= '1'; -- post event to Ship
            score_val <= score_from_mine; -- passed to Ship
          end if;
          if (HIT_MINE = '1') then -- in this case, missile does not explode, just vanishes; mines explode on screen
            state_next <= Armed;
          end if;
          if (HIT_WALL = '1' or HIT_MINE2_1ST_TIME='1') then
            state_next <= Exploding;
            exp_ctr_next <= (OTHERS=>'0'); -- clear explosion counter
            timer_2sec_start <='1'; -- start cowntdown counter 2 sec
          end if;           
        when Exploding =>
          EXPLOSION_MISSILE <= '1'; -- post event to Tunnel
          -- wait for 2 sec to display exploding ship
          if timer_2sec_up='1' then
            state_next <= Armed; 
          end if;
			end case;
		end process;

  -- coordinates passed with events 
  x <= std_logic_vector(x_reg);
  y <= std_logic_vector(y_reg); 
  
  -- instantiate countdown timer
  timer_2sec_missile_U0: entity work.timer
    generic map(W=>6) -- 2 seconds timer
    port map(clk=>clk, reset=>reset,
            timer_tick=>countdown_timer_tick,
            timer_start=>timer_2sec_start,
            timer_up=>timer_2sec_up);
             
end UML_ARCHITECTURE;	
