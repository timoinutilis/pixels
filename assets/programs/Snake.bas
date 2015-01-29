REM SNAKE GAME
REM COLLECT BLINKING DOTS AND DON'T HIT YOURSELF!

GAMEPAD 1

D=1

DO
  REM THE TITLE SCREEN

  GOSUB BG

  COLOR 10
  TEXT 31,11,"LOWRES SNAKE",1
  COLOR 1
  TEXT 31,10,"LOWRES SNAKE",1

  REPEAT
    GOSUB BLINK
    TEXT 31,40,"PRESS BUTTON",1
    WAIT 0.1
  UNTIL BUTTON(0)

  REM THE GAME

  GOSUB BG

  X=31
  Y=31
  SCORE=0

  GOSUB PUTDOT

  DO
    REM CHECKS FOR DIRECTION CHANGES
    IF LEFT(0) AND D<>2 THEN
      D=1
    ELSE IF RIGHT(0) AND D<>1 THEN
      D=2
    ELSE IF UP(0) AND D<>4 THEN
      D=3
    ELSE IF DOWN(0) AND D<>3 THEN
      D=4
    END IF

    REM MOVES SNAKE IN CURRENT DIRECTION
    IF D=1 THEN X=X-1
    IF D=2 THEN X=X+1
    IF D=3 THEN Y=Y-1
    IF D=4 THEN Y=Y+1

    REM CHECKS FOR COLLISION
    IF POINT(X,Y)=1 THEN EXIT

    REM CHECKS FOR COLLECT
    IF X=DX AND Y=DY THEN
      SCORE=SCORE+1
      GOSUB PUTDOT
    END IF

    REM DRAWS HEAD OF SNAKE AT CURRENT POSITION
    COLOR 1
    PLOT X,Y

    REM DRAWS BLINKING DOT TO COLLECT
    GOSUB BLINK
    PLOT DX,DY

    WAIT 0.08
  LOOP

  REM GAME OVER!

  COLOR 7
  BOX 0,0 TO 63,63

  REPEAT
    GOSUB BLINK
    TEXT 31,29,SCORE,1
    WAIT 0.1
  UNTIL BUTTON(0)
  
  REM WAITS FOR RELEASING THE BUTTON
  WHILE BUTTON(0)
  WEND

LOOP

PUTDOT:
REM SETS NEW POSITION FOR DOT
DX=INT(1+RND*61)
DY=INT(1+RND*61)
RETURN

BG:
REM PAINTS GREEN SCREEN WITH WHITE BORDER
CLS 9
COLOR 10
FOR I=1 TO 20
  PLOT RND*64,RND*64
NEXT I
COLOR 1
BOX 0,0 TO 63,63
RETURN

BLINK:
REM TOGGLES BETWEEN COLORS
IF C=6 THEN C=7 ELSE C=6
COLOR C
RETURN
