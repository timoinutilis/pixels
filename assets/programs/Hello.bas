REM SHOWS TEXT WITH EFFECT

DO
  CLS 0

  REM DRAWS SOME PIXELS IN A LINE
  COLOR 1
  FOR A=1 TO 20
    PLOT RND*64,31
  NEXT

  REM DRAWS TEXT WITH RANDOM COLOR
  COLOR RND*15
  TEXT 31,29,"HELLO",1

  WAIT 0.1
LOOP