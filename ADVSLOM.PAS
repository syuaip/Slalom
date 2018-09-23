(* --------------------------------------------------- *)
(*   Program Name     :  SLALOM R1.0                   *)
(*   Program Type     :  Game (And Demo too...)        *)
(*   Programmer       :  Arief Wahyu Nugraha           *)
(*                       ZeroBit Tech. Research & Dev. *)
(*   Compiler         :  Turbo Pascal 5.50             *)
(*   Program Code     :  #M04.93E02.93E04.16.$05.4EVA  *)
(*   Hardware Config. :  AT/286-16MHz, CGA             *)
(* --------------------------------------------------- *)

{$M 65520,0,0,R-}

Program Slalom;

Uses Dos, Crt;

Const
  Passed   : Boolean = False;
  Noise    : Boolean = True;
  HighScr  : Word    = 0;
  RgArrow  =  77;          { Scan Code }
  LfArrow  =  75;
  UpArrow  =  72;
  DnArrow  =  80;
  F1       =  59;
  Esc      =   1;
  Width    =  57;          { Lebar Area }
  Road     =  12;          { Lebar Jalan }
  MaxDly   = 100;
  MinDly   =  15;
  StepDly  =   5;          { Pakemnya Rem }

Var
  Int1Ch   : Pointer;
  Dly,
  Pos,
  XPos,
  Tree,
  Inp,
  Scan     : Byte;
  Quit,
  RgArrP,
  LfArrP,
  UpArrP,
  DnArrP,
  F1P,
  EscP,
  Press    : Boolean;
  Dummy    : Char;
  H,
  M,
  S,
  SD,
  Score    : Word;
  Start,
  Stop     : Real;

Procedure KeyBoardHandler; Interrupt;
Begin
  Inp   := Port[$60];
  Scan  := Inp AND $7F;
  Press := Inp < $80;
  Case Scan of
    RgArrow : RgArrP   := Press;
    LfArrow : LfArrP   := Press;
    UpArrow : UpArrP   := Press;
    DnArrow : DnArrP   := Press;
    F1      : F1P      := Press;
    Esc     : EscP     := Press;
  End;
  While KeyPressed do Dummy := ReadKey;
  If EscP then Quit := True;
    If F1P then
      Begin
        NoSound;
        Noise := NOT Noise;
      End;
End;

Procedure Init;
Begin
  DirectVideo := False;
  CheckBreak := False;
  GetIntVec($1C,Int1Ch);
  SetIntVec($1C,@KeyBoardHandler);
  If Mem[0:$449] <> CO80 then TextMode(CO80);
  TextAttr := $1F;
  ClrScr;
  InLine($b4/1/           { mov ah,1    ; kursor hilang }
         $b9/32/32/       { mov cx,2020h }
         $cd/$10);        { int 10h      }
  Randomize;
End;

Procedure Done;
Begin
  SetIntVec($1C,Int1Ch);
  NoSound;
  Window(01,01,80,25);
  TextAttr := $1F;
  ClrScr;
  InLine($b4/1/           { mov ah,1  ; kursor ada lagi }
         $b9/7/0/         { mov cx,7 }
         $cd/$10);        { int 10h  }
End;

Procedure WriteXY(X, Y : Byte; St : String);
Begin
  GotoXY(X,Y);
  Write(St);
End;

Procedure Box(X1, Y1, X2, Y2, Attr, Back : Byte);
Begin
  Window(X1+2,Y1+1,X2+2,Y2+1);
  TextAttr := Back;
  ClrScr;
  Window(X1,Y1,X2,Y2);
  TextAttr := Attr;
  ClrScr;
  Window(01,01,80,25);
End;

Procedure Draw;
Var X : Byte;
Begin
  Port[985] := Blue;        { BORDER Biru pada CGA }
  Box(60,02,78,13,$2F,$07);
  WriteXY(62,04,'TOMBOL-TOMBOL :');
  WriteXY(64,06,#27'   : KIRI');
  WriteXY(64,07,#26'   : KANAN');
  WriteXY(64,08,#24'   : GAS');
  WriteXY(64,09,#25'   : REM');
  WriteXY(64,10,'F1  : SUARA');
  WriteXY(64,11,'Esc : KELUAR');
  Box(60,17,78,24,$4E,$07);
  WriteXY(62,18,'® SLALOM R1.0 ¯');
  WriteXY(63,20,'NTT   :'); Write(HighScr:6);
  WriteXY(63,21,'WAKTU :'); Write(20.0:6:1);
  WriteXY(63,22,'LAJU  :'); Write(0:6);
  WriteXY(63,23,'NILAI :'); Write(0:6);
  Window(01,01,Width+1,25);
  TextAttr := $F;
  ClrScr;
  Window(01,01,80,25);
  For X := 1 to 25 do
    Begin
      WriteXY(20,X,#178#178);
      WriteXY(19+Road,X,#178#178);
    End;
  WriteXY(22,15,#234);
  WriteXY(01,15,'SIAP ?');
  For X := 3 downto 1 do
    Begin
      If Noise then Sound(1000);
      Delay(100); NoSound; Delay(900);
      GotoXY(01,15); Write('....',X:2);
    End;
  If Noise then Sound(1000);
  Delay(1000);
  WriteXY(06,15,'GO !!!');
  NoSound;
End;

Procedure WriteInfo(Score, Gas : Word);
Var T : Byte;
Begin
  T := TextAttr;
  TextAttr := $4E;
  GotoXY(72,21); Write(20.0 + Start - Stop:4:1);
  GotoXY(70,22); Write(Gas:6);
  GotoXY(70,23); Write(Score:6);
  TextAttr := T;
End;

Function Enough : Boolean;
Var C : Char;
Begin
  Box(07,08,51,12,$4F,$1E);
  WriteXY(10,10,'ENTER UNTUK MAIN LAGI, ESC UNTUK KELUAR');
  While KeyPressed do C := ReadKey;
  Repeat
    C := ReadKey;
  Until C IN [#13,#27];
  Enough := C = #27;
End;

Procedure Run;
Begin
  Draw;
  Dly    := 50;
  Pos    := 20;
  XPos   := 22;
  Score  := 0;
  Quit   := False;
  RgArrP := False;
  LfArrP := False;
  UpArrP := False;
  DnArrP := False;
  F1P    := False;
  EscP   := False;
  GetTime(H,M,S,SD);
  Start := 3600*H+60*M+S+SD/100;
  Repeat
    GetTime(H,M,S,SD);
    Stop := 3600*H+60*M+S+SD/100;
    Passed := ((Stop - Start) > 20.0);
    If NOT ((Stop - Start) > 19.0) then
      Case Random(20) of
        0..7  : If (Pos > 1) then Dec(Pos);
        8..16 : If (Pos < (Width-Road)) then Inc(Pos);
      End;
    WriteXY(Pos,1,#178#178);
    WriteXY(Pos+Road-1,1,#178#178);
    Tree := Random(Width);
    If (Tree < Pos) OR (Tree > (Pos+Road)) then
      Begin
        TextAttr := 9+Random(7);
        WriteXY(Tree,1,#177);
        TextAttr := $F;
      End;
    If UpArrP then
      Begin
        If (Dly > MinDly) then Dec(Dly)
      End
    else
      If (Dly < MaxDly) then Inc(Dly);
    If DnArrP AND (Dly < (MaxDly-StepDly)) then
      Begin
        Inc(Dly,StepDly);
        If Noise then Sound(3951); { Suara Rem }
      End;
    WriteXY(XPos,15,#32);
    If (LfArrP AND (XPos > 1)) then Dec(XPos);
    If (RgArrP AND (XPos < Width)) then Inc(XPos);
    InLine($B8/1/7/       { mov ax,701h ; scroll down }
           $31/$C9/       { xor cx,cx    }
           $B6/24/        { mov dh,24    }
           $B2/<Width/    { mov dl,Width }
           $B7/$f/        { mov bh,0fh   }
           $cd/$10);      { int 10h      }
    WriteXY(XPos,15,#234);
    If Noise then Sound(20+(MaxDly-Dly)*2); { Suara Mesin }
    Delay(Dly);
    Inc(Score);
    WriteInfo(Score,MinDly+MaxDly-Dly);
    If Passed then
      Begin
        Box(17,18,40,22,$4E,$2F);
        GotoXY(72,21); Write(0.0:4:1);
        If Score > 200 then
          Begin
            WriteXY(20,20,'SUKSES ! NILAI ');
            Write(Score);
          End
        else
          WriteXY(20,20,'TERLALU LAMBAT !');
        If Score > HighScr then
          Begin
            If HighScr <> 0 then
              Begin
                Sound(500); Delay(200);
                WriteXY(20,21,'NILAI TERTINGGI !!!');
                Sound(200); Delay(200);
              End;
            HighScr := Score;
          End;
        Sound(500); Delay(200);
        Sound(200); Delay(500);
        NoSound;
      End;
    If (Mem[$B800:(XPos-1)*2+13*160] <> 32) then
      Begin
        Mem[$B800:(XPos-1)*2+14*160+1] := $8C;
        Box(17,18,40,22,$4E,$2F);
        WriteXY(23,20,'TABRAKAN !!!');
        For Dly := 1 to 150 do
          Begin
            If Noise then Sound(50+Random(700));
            Delay(5);
          End;             { Mobil Meledak ! }
        Quit := True;
        NoSound;
      End;
  Until Quit OR Passed;
End;

BEGIN
  Init;
  Repeat
    Run
  Until Enough;
  Done;
END.
