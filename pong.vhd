----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:10:28 11/22/2019 
-- Design Name: 
-- Module Name:    pingpong - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pingpong is
port (
			 clk : in  STD_LOGIC;
          H : out  STD_LOGIC;
          V : out  STD_LOGIC;
          DAC_CLK : out  STD_LOGIC;
          Bout : out  STD_LOGIC_VECTOR (7 downto 0);
          Gout : out  STD_LOGIC_VECTOR (7 downto 0);
          Rout : out  STD_LOGIC_VECTOR (7 downto 0);
          SW : in  STD_LOGIC_VECTOR (3 downto 0)
);
end pingpong;

architecture Behavioral of pingpong is

--Core Signals
signal control0 : STD_LOGIC_VECTOR(35 downto 0);
signal ila_data : std_logic_vector(21 downto 0);
signal trig0 : std_logic_vector(7 downto 0);

signal hsync_temp, vsync_temp : std_logic; --temp hsync and vsync signals 

--Horizontal and Vertical Counters
signal hcounter : integer range 0 to 799;
signal vcounter : integer range 0 to 524;

--Pixel Clock and Refresh Clock
signal pixel_clk : std_logic; 
signal refresh_clk : std_logic;
signal refresh_cntr : integer := 0;

--R, G and B signals
signal R, G, B : std_logic_vector (7 downto 0);

--The game field can be separated into 6 sections 

signal topX1: integer := 0; --Vertical 1
signal topX2: integer := 30;
signal topY1: integer := 10;
signal topY2: integer := 160;

signal topX3: integer := 0; --Horizontal 1
signal topX4: integer := 640;
signal topY3: integer := 0;
signal topY4: integer := 30;

signal topX5: integer := 610; --Vertical 2 
signal topX6: integer := 640;
signal topY5: integer := 0;
signal topY6: integer := 160;

signal bottomX1  : integer := 0; --Vertical 3
signal bottomX2  : integer := 30;
signal bottomY1  : integer := 320;
signal bottomY2  : integer := 480;

signal bottomX3  : integer := 0; --Horizontal 2
signal bottomX4  : integer := 640;
signal bottomY3  : integer := 450;
signal bottomY4  : integer := 480;

signal bottomX5  : integer := 610; --Vertical 4 
signal bottomX6  : integer := 640;
signal bottomY5  : integer := 320;
signal bottomY6  : integer := 480;

signal midfieldX1	  : integer := 318; --Midfield 
signal midfieldX2	  : integer := 322;
signal midfieldY1	  : integer := 30;
signal midfieldY2	  : integer := 450;

signal midfieldWX1: integer := 300; --Midfield White
signal midfieldWX2: integer := 340;
signal midfieldWY1: integer := 220;
signal midfieldWY2: integer := 260;

signal midfieldGX1: integer := 305; --Midfield Green
signal midfieldGX2: integer := 335;
signal midfieldGY1: integer := 225;
signal midfieldGY2: integer := 255;

signal redpadX1	: integer := 590; --Red Paddle
signal redpadX2	: integer := 605;
signal redpadY1	: integer := 200;
signal redpadY2	: integer := 275;
signal redpadXINC: integer := 0;
signal redpadYINC: integer := 0;

signal bluepadX1	: integer := 35; --Blue Paddle
signal bluepadX2	: integer := 50;
signal bluepadY1	: integer := 200;
signal bluepadY2	: integer := 275;
signal bluepadXINC: integer := 0;
signal bluepadYINC: integer := 0;

signal X1ball			: integer := 310; --Ball
signal X2ball			: integer := 325;
signal Y1ball			: integer := 230;
signal Y2ball			: integer := 245;

signal redGoalX		    : integer := 620; --Goal Dimension
signal blueGoalX		: integer := 20;
signal Y1goal			: integer := 160;
signal Y2goal			: integer := 320;

signal score			: std_logic; --keep track of score
signal reset			: std_logic; --reset

signal ballXINC		: std_logic; --increments ball left or right if it touches a border 
signal ballYINC		: std_logic;

--SPEEEEEDDDD
signal speed			: integer := 0; 

component DAC --DAC Clock component
Port (
	clk : in std_logic;
	DClk : out std_logic
);
end component;
 
component Sync  --Sync component 
Port (
	pclk : in std_logic;
	hcounter, vcounter : out integer);
end component;
	
component VGAcontroller --VGA controller component
Port (
	--refclk: in std_logic;
	hcounter, vcounter : in integer;
	redpadX1, redpadX2, redpadY1, redpadY2: in integer;
	bluepadX1, bluepadX2, bluepadY2, bluepadY1: in integer;
	X1ball, X2ball, Y1ball, Y2ball: in integer;
	score	: in std_logic;
	R_out : out std_logic_vector(7 downto 0);
	G_out : out std_logic_vector(7 downto 0);
	B_out : out std_logic_vector(7 downto 0)
	
);
end component;

component refresh --refresh clock component
Port (
	pixclk : in std_logic;
	refreshcount: out integer;
	refreshclk : out std_logic);
end component;

component icon  --icon 
PORT (
  CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));
end component;

component ila  --ila
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(21 DOWNTO 0);
    TRIG0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0));

end component;

begin
--Port Maps

icon_instance : icon
  port map (
    CONTROL0 => control0);
	 
ila_instance : ila
  port map (
    CONTROL => control0,
    CLK => clk,
    DATA => ila_data,
    TRIG0 => trig0);

DACCLK : DAC
PORT MAP (
	clk => clk,
	DClk => pixel_clk
	);
	
DAC_CLK <= pixel_clk;

Sinc : Sync
PORT MAP (
	pclk => pixel_clk,
	hcounter => hcounter,
	vcounter => vcounter
	);
	
--	H <= '0' when hcounter <= 96 else '1';
--	V <= '0' when vcounter <= 2 else '1';

hsync_temp <= '0' when hcounter <= 96 else '1';  
vsync_temp <= '0' when vcounter <= 2 else '1';
	
H <= hsync_temp;  --putting temp signals to H and V and portmapping it 
v <= vsync_temp;
	
process 
begin
--
---- Active image region values are calculated as follows:
---- Beginning active region = sync pulse + back porch - 1
---- End active region = end of line - front porch - 1
----// For H-sync:
---- Beginning active region = 96 + 48 - 1 = 143
---- End of active region = 800 - 16 - 1 = 783
----// For V-sync:
---- Beginning of active region = 2 + 33 - 1 = 34
---- End of active region = 525 - 10 - 1  = 514

	if(hcounter >= 143 and hcounter <= 783 and vcounter >= 34 and vcounter <= 514) then --basically considers active region for hsync and vsync respectively and sets R, G, B colours accordingly
		Rout <= R;
		Gout <= G;
		Bout <= B;
	else
		Rout <= (others => '0');
		Gout <= (others => '0');
		Bout <= (others => '0');
	end if;
end process;

--more Port Maps
rfshclk : refresh
PORT MAP (
	pixclk => pixel_clk,
	refreshcount => refresh_cntr,
	refreshclk => refresh_clk
	);
	
process(refresh_clk)
	begin
		if refresh_clk'event and refresh_clk = '1' then 
-- ball and wall collision detection	
	--right/left border
			if (X1ball <= topX2 and (Y1ball >= topY4 and Y2ball<= topY6)) then --ball hits an object on the left, ball goes to positive x direction
				ballXINC <= '1'; --hit top left border
				speed <= speed + 1;
			elsif(X1ball <= bottomX2 and (Y1ball >= bottomY5 and Y2ball<= bottomY6)) then 
				ballXINC <= '1'; --hit bottom left border 
				speed <= speed + 1;
				

			elsif (X2ball >= topX5 and (Y2ball >= topY4 and Y1ball<= topY6)) then --Ball hits object on the right, ball goes to negative x direction
				ballXINC <= '0'; --hits top right border
				speed <= speed + 1;
			elsif (X2ball >= bottomX5 and (Y2ball >= bottomY1 and Y1ball<= bottomY6)) then
				ballXINC <= '0'; --hits bottom right border
				speed <= speed + 1;
			end if;
			
--Ball and paddle collision detection
			if (X1ball <= bluepadX2 and (Y1ball >= bluepadY1 and Y2ball <= bluepadY2)) then --ball hits left paddle (blue), ball goes to positive x direction
					ballXINC <= '1';
					speed <= speed + 1;
			elsif (X2ball >= redpadX1 and (Y1ball >= redpadY1 and Y2ball <= redpadY2)) then --ball hits right paddle (red), ball goes to negative x direction
					ballXINC <= '0';
					speed <= speed + 1;				
			end if;

-top/bottom border			
			if (Y1ball <= topY4) then --ball hit top border, goes to negative y direction
				ballYINC <= '0';
				speed <= speed + 1;
			elsif (Y2ball >= bottomY3) then --ball hit bottom border, goes to positive y direction
				ballYINC <= '1';
				speed <= speed + 1;
			end if;
			
--Goal collision detection
			if (X1ball < blueGoalX and Y1ball >= Y1goal and Y2ball <= Y2goal) then --ball goes to left goal line, right scores
				score <= '1';
				speed <= 0;
			elsif (X2ball > redGoalX and Y1ball >= Y1goal and Y2ball <= Y2goal) then --ball goes to right goal line, left scores
				score <= '1';
				speed <= 0;
			else --no score, game continues
				score <= '0';
			end if;
			
			if (X1ball <= 0) then --end of screen on the left, reset ball to midfield 
				X1ball <= 310;
				X2ball <= 325;
				Y1ball <= 230;
				Y2ball <= 245;
				ballXINC <= '1';
				ballYINC <= '1';
			elsif (X2ball >= 640) then --end of screen on the right, reset ball to midfield 
				X1ball <= 310;
				X2ball <= 325;
				Y1ball <= 230;
				Y2ball <= 245;
				ballXINC <= '0';
				ballYINC <= '1';
			else

				if (ballXINC = '1') then --increments ball to move in positive x direction
					X1ball <= X1ball + 3;
					X2ball <= X2ball + 3;
				else					  --increments ball to move in negative x direction
					X1ball <= X1ball - 3;
					X2ball <= X2ball - 3;
					
				 end if;
				if ( ballYINC = '1') then --increments ball to move in positive y direction
					Y1ball <= Y1ball - 3;
					Y2ball <= Y2ball - 3;
				else					  --increments ball to move in negative x direction
					Y1ball <= Y1ball + 3;
					Y2ball <= Y2ball + 3;
				end if;			
			end if;			
		end if;
end process;

--Paddle movement and collision detection
process(refresh_clk)
	begin
		--Once a switch input has been set for up or down movement, it cannot be interrupted by another switch for the opposite 
		--movement direction. For example, if the red paddle is set to move upward, it will keep moving upward, even if the down movement switch is pressed. Once the switch is set to
		--0, the paddle can move in the opposite direction.
		
		if refresh_clk'event and refresh_clk = '1' then
			if (SW(1) = '1') then --Move red paddle up
				if (redpadY1 > topY4) then
					redpadY1 <= redpadY1 - 6;
					redpadY2 <= redpadY2 - 6;
				end if;
			elsif(SW(0) = '1') then --Move red paddle down
				if (redpadY2 < bottomY3) then
					redpadY1 <= redpadY1 + 6;
					redpadY2 <= redpadY2 + 6;
				end if;
			end if;	
			if (SW(3) = '1') then --Move blue paddle up
				if (bluepadY1 > topY4) then
					bluepadY1 <= bluepadY1 - 6;
					bluepadY2 <= bluepadY2 - 6;		
				end if;			
			elsif(SW(2) = '1') then --Move blue paddle down
				if (bluepadY2 < bottomY3) then
					bluepadY1 <= bluepadY1 + 6;
					bluepadY2 <= bluepadY2 + 6;				
				end if;
			end if;		
		end if;
end process;
	
--more Port Maps
VGACon : VGAcontroller
PORT MAP (
	hcounter => hcounter,
	vcounter => vcounter,
	redpadX1 => redpadX1,
	redpadX2 => redpadX2,
	redpadY1 => redpadY1,
	redpadY2 => redpadY2,
	bluepadX1 => bluepadX1,
	bluepadX2 => bluepadX2,
	bluepadY2 => bluepadY2,
	bluepadY1 => bluepadY1,
	X1ball => X1ball, 
	X2ball => X2ball,
	Y1ball => Y1ball,
	Y2ball => Y2ball,
	score => score,
	R_out => R,
	G_out => G,
	B_out => B
);


ila_data(9 downto 0) <= std_logic_vector(to_unsigned(hcounter, 10));
ila_data(19 downto 10) <= std_logic_vector(to_unsigned(vcounter, 10));
ila_data(20) <= hsync_temp;
ila_data(21) <= vsync_temp;
end Behavioral;

