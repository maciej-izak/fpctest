{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2006 by Karoly Balogh

    Keyboard unit for MorphOS and Amiga

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
unit Keyboard;
interface

{$i keybrdh.inc}

implementation

{ WARNING: Keyboard-Drivers (i.e. german) will only work under WinNT.
           95 and 98 do not support keyboard-drivers other than us for win32
           console-apps. So we always get the keys in us-keyboard layout
           from Win9x.
}


uses
   video, exec,intuition, inputevent, mouse;

{$i keyboard.inc}

var
   lastShiftState : byte;               {set by handler for PollShiftStateEvent}
   oldmousex : longint;
   oldmousey : longint;
   oldbuttons: word;


{*
const MaxQueueSize = 120;
      FrenchKeyboard = $040C040C;

var
   keyboardeventqueue : array[0..maxqueuesize] of TKeyEventRecord;
   nextkeyevent,nextfreekeyevent : longint;
   newKeyEvent    : THandle;            {sinaled if key is available}
   lockVar        : TCriticalSection;   {for queue access}
   lastShiftState : byte;               {set by handler for PollShiftStateEvent}
   altNumActive   : boolean;            {for alt+0..9}
   altNumBuffer   : string [3];
   { used for keyboard specific stuff }
   KeyBoardLayout : HKL;
   Inited : Boolean;
   HasAltGr  : Boolean = false;


procedure incqueueindex(var l : longint);

  begin
     inc(l);
     { wrap around? }
     if l>maxqueuesize then
       l:=0;
  end;

function keyEventsInQueue : boolean;
begin
  keyEventsInQueue := (nextkeyevent <> nextfreekeyevent);
end;

function rightistruealt(dw:cardinal):boolean; // inline ?
// used to wrap checks for right alt/altgr.
begin
  rightistruealt:=true;
  if hasaltgr then
    rightistruealt:=(dw and RIGHT_ALT_PRESSED)=0;
end;


{ gets or peeks the next key from the queue, does not wait for new keys }
function getKeyEventFromQueue (VAR t : TKeyEventRecord; Peek : boolean) : boolean;
begin
  if not Inited then
    begin
    getKeyEventFromQueue := false;
    exit;
    end;
  EnterCriticalSection (lockVar);
  if keyEventsInQueue then
  begin
    t := keyboardeventqueue[nextkeyevent];
    if not peek then incqueueindex (nextkeyevent);
    getKeyEventFromQueue := true;
    if not keyEventsInQueue then ResetEvent (newKeyEvent);
  end else
  begin
    getKeyEventFromQueue := false;
    ResetEvent (newKeyEvent);
  end;
  LeaveCriticalSection (lockVar);
end;


{ gets the next key from the queue, does wait for new keys }
function getKeyEventFromQueueWait (VAR t : TKeyEventRecord) : boolean;
begin
  if not Inited then
    begin
      getKeyEventFromQueueWait := false;
      exit;
    end;
  WaitForSingleObject (newKeyEvent, dword(INFINITE));
  getKeyEventFromQueueWait := getKeyEventFromQueue (t, false);
end;

{ translate win32 shift-state to keyboard shift state }
function transShiftState (ControlKeyState : dword) : byte;
var b : byte;
begin
  b := 0;
  if ControlKeyState and SHIFT_PRESSED <> 0 then  { win32 makes no difference between left and right shift }
    b := b or kbShift;
  if (ControlKeyState and LEFT_CTRL_PRESSED <> 0) or
     (ControlKeyState  and RIGHT_CTRL_PRESSED <> 0) then
    b := b or kbCtrl;
  if (ControlKeyState and LEFT_ALT_PRESSED <> 0) or
     (ControlKeyState and RIGHT_ALT_PRESSED <> 0) then
    b := b or kbAlt;
  transShiftState := b;
end;

{ The event-Handler thread from the unit event will call us if a key-event
  is available }

procedure HandleKeyboard(var ir:INPUT_RECORD);
var
   i      : longint;
   c      : word;
   altc : char;
   addThis: boolean;
begin
         with ir.Event.KeyEvent do
           begin
              { key up events are ignored (except alt) }
              if bKeyDown then
                begin
                   EnterCriticalSection (lockVar);
                   for i:=1 to wRepeatCount do
                     begin
                        addThis := true;
                        if (dwControlKeyState and LEFT_ALT_PRESSED <> 0) or
                           (dwControlKeyState and RIGHT_ALT_PRESSED <> 0) then            {alt pressed}
                          if ((wVirtualKeyCode >= $60) and (wVirtualKeyCode <= $69)) or
                             ((dwControlKeyState and ENHANCED_KEY = 0) and
                              (wVirtualKeyCode in [$C{VK_CLEAR generated by keypad 5},
                                                   $21 {VK_PRIOR (PgUp) 9},
                                                   $22 {VK_NEXT (PgDown) 3},
                                                   $23 {VK_END 1},
                                                   $24 {VK_HOME 7},
                                                   $25 {VK_LEFT 4},
                                                   $26 {VK_UP 8},
                                                   $27 {VK_RIGHT 6},
                                                   $28 {VK_DOWN 2},
                                                   $2D {VK_INSERT 0}])) then   {0..9 on NumBlock}
                          begin
                            if length (altNumBuffer) = 3 then
                              delete (altNumBuffer,1,1);
                            case wVirtualKeyCode of
                              $60..$69 : altc:=char (wVirtualKeyCode-48);
                              $c  : altc:='5';
                              $21 : altc:='9';
                              $22 : altc:='3';
                              $23 : altc:='1';
                              $24 : altc:='7';
                              $25 : altc:='4';
                              $26 : altc:='8';
                              $27 : altc:='6';
                              $28 : altc:='2';
                              $2D : altc:='0';
                            end;
                            altNumBuffer := altNumBuffer + altc;
                            altNumActive   := true;
                            addThis := false;
                          end else
                          begin
                            altNumActive   := false;
                            altNumBuffer   := '';
                          end;
                        if addThis then
                        begin
                          keyboardeventqueue[nextfreekeyevent]:=
                            ir.Event.KeyEvent;
                          incqueueindex(nextfreekeyevent);
                        end;
                     end;

                   lastShiftState := transShiftState (dwControlKeyState);  {save it for PollShiftStateEvent}
                   SetEvent (newKeyEvent);             {event that a new key is available}
                   LeaveCriticalSection (lockVar);
                end
              else
                begin
                  lastShiftState := transShiftState (dwControlKeyState);   {save it for PollShiftStateEvent}
                  {for alt-number we have to look for alt-key release}
                  if altNumActive then
                   begin
                     if (wVirtualKeyCode = $12) then    {alt-released}
                      begin
                        if altNumBuffer <> '' then       {numbers with alt pressed?}
                         begin
                           Val (altNumBuffer, c, i);
                           if (i = 0) and (c <= 255) then {valid number?}
                            begin                          {add to queue}
                              fillchar (ir, sizeof (ir), 0);
                              bKeyDown := true;
                              AsciiChar := char (c);
                                                       {and add to queue}
                              EnterCriticalSection (lockVar);
                              keyboardeventqueue[nextfreekeyevent]:=ir.Event.KeyEvent;
                              incqueueindex(nextfreekeyevent);
                              SetEvent (newKeyEvent);      {event that a new key is available}
                              LeaveCriticalSection (lockVar);
                            end;
                         end;
                        altNumActive   := false;         {clear alt-buffer}
                        altNumBuffer   := '';
                      end;
                   end;
                end;
           end;
end;
*}

{*
procedure CheckAltGr;

var ahkl : HKL;
    i    : integer;

 begin
   HasAltGr:=false;

   ahkl:=GetKeyboardLayout(0);
   i:=$20;
   while i<$100 do
     begin
       // <MSDN>
       // For keyboard layouts that use the right-hand ALT key as ashift key
       // (for example, the French keyboard layout), the shift state is
       // represented by the value 6, because the right-hand ALT key is
       // converted internally into CTRL+ALT.
       // </MSDN>
      if (HIBYTE(VkKeyScanEx(chr(i),ahkl))=6) then
        begin
          HasAltGr:=true;
          break;
        end;
     inc(i);
    end;
end;
*}



procedure SysInitKeyboard;
begin
//  writeln('sysinitkeyboard');
  lastShiftState:=0;
  oldmousex:=-1;
  oldmousey:=-1;
{*
   KeyBoardLayout:=GetKeyboardLayout(0);
   lastShiftState := 0;
   FlushConsoleInputBuffer(StdInputHandle);
   newKeyEvent := CreateEvent (nil,        // address of security attributes
                               true,       // flag for manual-reset event
                               false,      // flag for initial state
                               nil);       // address of event-object name
   if newKeyEvent = INVALID_HANDLE_VALUE then
    begin
      // what to do here ????
      RunError (217);
    end;
   InitializeCriticalSection (lockVar);
   altNumActive := false;
   altNumBuffer := '';

   nextkeyevent:=0;
   nextfreekeyevent:=0;
   checkaltgr;
   SetKeyboardEventHandler (@HandleKeyboard);
   Inited:=true;
*}
end;

procedure SysDoneKeyboard;
begin
{*
  SetKeyboardEventHandler(nil);     {hangs???}
  DeleteCriticalSection (lockVar);
  FlushConsoleInputBuffer(StdInputHandle);
  closeHandle (newKeyEvent);
  Inited:=false;
*}
end;

{$define USEKEYCODES}

{Translatetable Win32 -> Dos for Special Keys = Function Key, Cursor Keys
 and Keys other than numbers on numblock (to make fv happy) }
{combinations under dos: Shift+Ctrl: same as Ctrl
                         Shift+Alt : same as alt
 
{*                        Ctrl+Alt  : nothing (here we get it like alt)}
{ifdef USEKEYCODES}
   { use positive values for ScanCode we want to set
   0 for key where we should leave the scancode
   -1 for OEM specifc keys
   -2 for unassigned
   -3 for Kanji systems ???
   }

const
  Unassigned = -2;
  Kanji = -3;
  OEM_specific = -1;
  KeyToQwertyScan : array [0..255] of integer =
  (
  { 00 } 0,
  { 01 VK_LBUTTON } 0,
  { 02 VK_RBUTTON } 0,
  { 03 VK_CANCEL } 0,
  { 04 VK_MBUTTON } 0,
  { 05 unassigned } -2,
  { 06 unassigned } -2,
  { 07 unassigned } -2,
  { 08 VK_BACK } $E,
  { 09 VK_TAB } $F,
  { 0A unassigned } -2,
  { 0B unassigned } -2,
  { 0C VK_CLEAR ?? } 0,
  { 0D VK_RETURN } 0,
  { 0E unassigned } -2,
  { 0F unassigned } -2,
  { 10 VK_SHIFT } 0,
  { 11 VK_CONTROL } 0,
  { 12 VK_MENU (Alt key) } 0,
  { 13 VK_PAUSE } 0,
  { 14 VK_CAPITAL (Caps Lock) } 0,
  { 15 Reserved for Kanji systems} -3,
  { 16 Reserved for Kanji systems} -3,
  { 17 Reserved for Kanji systems} -3,
  { 18 Reserved for Kanji systems} -3,
  { 19 Reserved for Kanji systems} -3,
  { 1A unassigned } -2,
  { 1B VK_ESCAPE } $1,
  { 1C Reserved for Kanji systems} -3,
  { 1D Reserved for Kanji systems} -3,
  { 1E Reserved for Kanji systems} -3,
  { 1F Reserved for Kanji systems} -3,
  { 20 VK_SPACE} 0,
  { 21 VK_PRIOR (PgUp) } 0,
  { 22 VK_NEXT (PgDown) } 0,
  { 23 VK_END } 0,
  { 24 VK_HOME } 0,
  { 25 VK_LEFT } 0,
  { 26 VK_UP } 0,
  { 27 VK_RIGHT } 0,
  { 28 VK_DOWN } 0,
  { 29 VK_SELECT ??? } 0,
  { 2A OEM specific !! } -1,
  { 2B VK_EXECUTE } 0,
  { 2C VK_SNAPSHOT } 0,
  { 2D VK_INSERT } 0,
  { 2E VK_DELETE } 0,
  { 2F VK_HELP } 0,
  { 30 VK_0 '0' } 11,
  { 31 VK_1 '1' } 2,
  { 32 VK_2 '2' } 3,
  { 33 VK_3 '3' } 4,
  { 34 VK_4 '4' } 5,
  { 35 VK_5 '5' } 6,
  { 36 VK_6 '6' } 7,
  { 37 VK_7 '7' } 8,
  { 38 VK_8 '8' } 9,
  { 39 VK_9 '9' } 10,
  { 3A unassigned } -2,
  { 3B unassigned } -2,
  { 3C unassigned } -2,
  { 3D unassigned } -2,
  { 3E unassigned } -2,
  { 3F unassigned } -2,
  { 40 unassigned } -2,
  { 41 VK_A 'A' } $1E,
  { 42 VK_B 'B' } $30,
  { 43 VK_C 'C' } $2E,
  { 44 VK_D 'D' } $20,
  { 45 VK_E 'E' } $12,
  { 46 VK_F 'F' } $21,
  { 47 VK_G 'G' } $22,
  { 48 VK_H 'H' } $23,
  { 49 VK_I 'I' } $17,
  { 4A VK_J 'J' } $24,
  { 4B VK_K 'K' } $25,
  { 4C VK_L 'L' } $26,
  { 4D VK_M 'M' } $32,
  { 4E VK_N 'N' } $31,
  { 4F VK_O 'O' } $18,
  { 50 VK_P 'P' } $19,
  { 51 VK_Q 'Q' } $10,
  { 52 VK_R 'R' } $13,
  { 53 VK_S 'S' } $1F,
  { 54 VK_T 'T' } $14,
  { 55 VK_U 'U' } $16,
  { 56 VK_V 'V' } $2F,
  { 57 VK_W 'W' } $11,
  { 58 VK_X 'X' } $2D,
  { 59 VK_Y 'Y' } $15,
  { 5A VK_Z 'Z' } $2C,
  { 5B unassigned } -2,
  { 5C unassigned } -2,
  { 5D unassigned } -2,
  { 5E unassigned } -2,
  { 5F unassigned } -2,
  { 60 VK_NUMPAD0 NumKeyPad '0' } 11,
  { 61 VK_NUMPAD1 NumKeyPad '1' } 2,
  { 62 VK_NUMPAD2 NumKeyPad '2' } 3,
  { 63 VK_NUMPAD3 NumKeyPad '3' } 4,
  { 64 VK_NUMPAD4 NumKeyPad '4' } 5,
  { 65 VK_NUMPAD5 NumKeyPad '5' } 6,
  { 66 VK_NUMPAD6 NumKeyPad '6' } 7,
  { 67 VK_NUMPAD7 NumKeyPad '7' } 8,
  { 68 VK_NUMPAD8 NumKeyPad '8' } 9,
  { 69 VK_NUMPAD9 NumKeyPad '9' } 10,
  { 6A VK_MULTIPLY } 0,
  { 6B VK_ADD } 0,
  { 6C VK_SEPARATOR } 0,
  { 6D VK_SUBSTRACT } 0,
  { 6E VK_DECIMAL } 0,
  { 6F VK_DIVIDE } 0,
  { 70 VK_F1 'F1' } $3B,
  { 71 VK_F2 'F2' } $3C,
  { 72 VK_F3 'F3' } $3D,
  { 73 VK_F4 'F4' } $3E,
  { 74 VK_F5 'F5' } $3F,
  { 75 VK_F6 'F6' } $40,
  { 76 VK_F7 'F7' } $41,
  { 77 VK_F8 'F8' } $42,
  { 78 VK_F9 'F9' } $43,
  { 79 VK_F10 'F10' } $44,
  { 7A VK_F11 'F11' } $57,
  { 7B VK_F12 'F12' } $58,
  { 7C VK_F13 } 0,
  { 7D VK_F14 } 0,
  { 7E VK_F15 } 0,
  { 7F VK_F16 } 0,
  { 80 VK_F17 } 0,
  { 81 VK_F18 } 0,
  { 82 VK_F19 } 0,
  { 83 VK_F20 } 0,
  { 84 VK_F21 } 0,
  { 85 VK_F22 } 0,
  { 86 VK_F23 } 0,
  { 87 VK_F24 } 0,
  { 88 unassigned } -2,
  { 89 VK_NUMLOCK } 0,
  { 8A VK_SCROLL } 0,
  { 8B unassigned } -2,
  { 8C unassigned } -2,
  { 8D unassigned } -2,
  { 8E unassigned } -2,
  { 8F unassigned } -2,
  { 90 unassigned } -2,
  { 91 unassigned } -2,
  { 92 unassigned } -2,
  { 93 unassigned } -2,
  { 94 unassigned } -2,
  { 95 unassigned } -2,
  { 96 unassigned } -2,
  { 97 unassigned } -2,
  { 98 unassigned } -2,
  { 99 unassigned } -2,
  { 9A unassigned } -2,
  { 9B unassigned } -2,
  { 9C unassigned } -2,
  { 9D unassigned } -2,
  { 9E unassigned } -2,
  { 9F unassigned } -2,
  { A0 unassigned } -2,
  { A1 unassigned } -2,
  { A2 unassigned } -2,
  { A3 unassigned } -2,
  { A4 unassigned } -2,
  { A5 unassigned } -2,
  { A6 unassigned } -2,
  { A7 unassigned } -2,
  { A8 unassigned } -2,
  { A9 unassigned } -2,
  { AA unassigned } -2,
  { AB unassigned } -2,
  { AC unassigned } -2,
  { AD unassigned } -2,
  { AE unassigned } -2,
  { AF unassigned } -2,
  { B0 unassigned } -2,
  { B1 unassigned } -2,
  { B2 unassigned } -2,
  { B3 unassigned } -2,
  { B4 unassigned } -2,
  { B5 unassigned } -2,
  { B6 unassigned } -2,
  { B7 unassigned } -2,
  { B8 unassigned } -2,
  { B9 unassigned } -2,
  { BA OEM specific } 0,
  { BB OEM specific } 0,
  { BC OEM specific } 0,
  { BD OEM specific } 0,
  { BE OEM specific } 0,
  { BF OEM specific } 0,
  { C0 OEM specific } 0,
  { C1 unassigned } -2,
  { C2 unassigned } -2,
  { C3 unassigned } -2,
  { C4 unassigned } -2,
  { C5 unassigned } -2,
  { C6 unassigned } -2,
  { C7 unassigned } -2,
  { C8 unassigned } -2,
  { C9 unassigned } -2,
  { CA unassigned } -2,
  { CB unassigned } -2,
  { CC unassigned } -2,
  { CD unassigned } -2,
  { CE unassigned } -2,
  { CF unassigned } -2,
  { D0 unassigned } -2,
  { D1 unassigned } -2,
  { D2 unassigned } -2,
  { D3 unassigned } -2,
  { D4 unassigned } -2,
  { D5 unassigned } -2,
  { D6 unassigned } -2,
  { D7 unassigned } -2,
  { D8 unassigned } -2,
  { D9 unassigned } -2,
  { DA unassigned } -2,
  { DB OEM specific } 0,
  { DC OEM specific } 0,
  { DD OEM specific } 0,
  { DE OEM specific } 0,
  { DF OEM specific } 0,
  { E0 OEM specific } 0,
  { E1 OEM specific } 0,
  { E2 OEM specific } 0,
  { E3 OEM specific } 0,
  { E4 OEM specific } 0,
  { E5 unassigned } -2,
  { E6 OEM specific } 0,
  { E7 unassigned } -2,
  { E8 unassigned } -2,
  { E9 OEM specific } 0,
  { EA OEM specific } 0,
  { EB OEM specific } 0,
  { EC OEM specific } 0,
  { ED OEM specific } 0,
  { EE OEM specific } 0,
  { EF OEM specific } 0,
  { F0 OEM specific } 0,
  { F1 OEM specific } 0,
  { F2 OEM specific } 0,
  { F3 OEM specific } 0,
  { F4 OEM specific } 0,
  { F5 OEM specific } 0,
  { F6 unassigned } -2,
  { F7 unassigned } -2,
  { F8 unassigned } -2,
  { F9 unassigned } -2,
  { FA unassigned } -2,
  { FB unassigned } -2,
  { FC unassigned } -2,
  { FD unassigned } -2,
  { FE unassigned } -2,
  { FF unassigned } -2
  );
{$endif  USEKEYCODES}
type TTEntryT = packed record
                  n,s,c,a : byte;   {normal,shift, ctrl, alt, normal only for f11,f12}
                end;
*}
{*
CONST
 DosTT : ARRAY [$3B..$58] OF TTEntryT =
  ((n : $3B; s : $54; c : $5E; a: $68),      {3B F1}
   (n : $3C; s : $55; c : $5F; a: $69),      {3C F2}
   (n : $3D; s : $56; c : $60; a: $6A),      {3D F3}
   (n : $3E; s : $57; c : $61; a: $6B),      {3E F4}
   (n : $3F; s : $58; c : $62; a: $6C),      {3F F5}
   (n : $40; s : $59; c : $63; a: $6D),      {40 F6}
   (n : $41; s : $5A; c : $64; a: $6E),      {41 F7}
   (n : $42; s : $5B; c : $65; a: $6F),      {42 F8}
   (n : $43; s : $5C; c : $66; a: $70),      {43 F9}
   (n : $44; s : $5D; c : $67; a: $71),      {44 F10}
   (n : $45; s : $00; c : $00; a: $00),      {45 ???}
   (n : $46; s : $00; c : $00; a: $00),      {46 ???}
   (n : $47; s : $47; c : $77; a: $97),      {47 Home}
   (n : $48; s : $00; c : $8D; a: $98),      {48 Up}
   (n : $49; s : $49; c : $84; a: $99),      {49 PgUp}
   (n : $4A; s : $00; c : $8E; a: $4A),      {4A -}
   (n : $4B; s : $4B; c : $73; a: $9B),      {4B Left}
   (n : $4C; s : $00; c : $00; a: $00),      {4C ???}
   (n : $4D; s : $4D; c : $74; a: $9D),      {4D Right}
   (n : $4E; s : $00; c : $90; a: $4E),      {4E +}
   (n : $4F; s : $4F; c : $75; a: $9F),      {4F End}
   (n : $50; s : $50; c : $91; a: $A0),      {50 Down}
   (n : $51; s : $51; c : $76; a: $A1),      {51 PgDown}
   (n : $52; s : $52; c : $92; a: $A2),      {52 Insert}
   (n : $53; s : $53; c : $93; a: $A3),      {53 Del}
   (n : $54; s : $00; c : $00; a: $00),      {54 ???}
   (n : $55; s : $00; c : $00; a: $00),      {55 ???}
   (n : $56; s : $00; c : $00; a: $00),      {56 ???}
   (n : $85; s : $87; c : $89; a: $8B),      {57 F11}
   (n : $86; s : $88; c : $8A; a: $8C));     {58 F12}

 DosTT09 : ARRAY [$02..$0F] OF TTEntryT =
  ((n : $00; s : $00; c : $00; a: $78),      {02 1 }
   (n : $00; s : $00; c : $00; a: $79),      {03 2 }
   (n : $00; s : $00; c : $00; a: $7A),      {04 3 }
   (n : $00; s : $00; c : $00; a: $7B),      {05 4 }
   (n : $00; s : $00; c : $00; a: $7C),      {06 5 }
   (n : $00; s : $00; c : $00; a: $7D),      {07 6 }
   (n : $00; s : $00; c : $00; a: $7E),      {08 7 }
   (n : $00; s : $00; c : $00; a: $7F),      {09 8 }
   (n : $00; s : $00; c : $00; a: $80),      {0A 9 }
   (n : $00; s : $00; c : $00; a: $81),      {0B 0 }
   (n : $00; s : $00; c : $00; a: $82),      {0C � }
   (n : $00; s : $00; c : $00; a: $00),      {0D}
   (n : $00; s : $09; c : $00; a: $00),      {0E Backspace}
   (n : $00; s : $0F; c : $94; a: $00));     {0F Tab }

*}

{*
function TranslateKey (t : TKeyEventRecord) : TKeyEvent;
var key : TKeyEvent;
    ss  : byte;
{$ifdef  USEKEYCODES}
    ScanCode  : byte;
{$endif  USEKEYCODES}
    b   : byte;
begin
  Key := 0;
  if t.bKeyDown then
  begin
    { ascii-char is <> 0 if not a specal key }
    { we return it here otherwise we have to translate more later }
    if t.AsciiChar <> #0 then
    begin
      if (t.dwControlKeyState and ENHANCED_KEY <> 0) and
         (t.wVirtualKeyCode = $DF) then
        begin
          t.dwControlKeyState:=t.dwControlKeyState and not ENHANCED_KEY;
          t.wVirtualKeyCode:=VK_DIVIDE;
          t.AsciiChar:='/';
        end;
      {drivers needs scancode, we return it here as under dos and linux
       with $03000000 = the lowest two bytes is the physical representation}
{$ifdef  USEKEYCODES}
      Scancode:=KeyToQwertyScan[t.wVirtualKeyCode AND $00FF];
      If ScanCode>0 then
        t.wVirtualScanCode:=ScanCode;
      Key := byte (t.AsciiChar) + (t.wVirtualScanCode shl 8) + $03000000;
      ss := transShiftState (t.dwControlKeyState);
      key := key or (ss shl 16);
      if (ss and kbAlt <> 0) and rightistruealt(t.dwControlKeyState) then
        key := key and $FFFFFF00;
{$else not USEKEYCODES}
      Key := byte (t.AsciiChar) + ((t.wVirtualScanCode AND $00FF) shl 8) + $03000000;
{$endif not USEKEYCODES}
    end else
    begin
{$ifdef  USEKEYCODES}
      Scancode:=KeyToQwertyScan[t.wVirtualKeyCode AND $00FF];
      If ScanCode>0 then
        t.wVirtualScanCode:=ScanCode;
{$endif not USEKEYCODES}
      translateKey := 0;
      { ignore shift,ctrl,alt,numlock,capslock alone }
      case t.wVirtualKeyCode of
        $0010,         {shift}
        $0011,         {ctrl}
        $0012,         {alt}
        $0014,         {capslock}
        $0090,         {numlock}
        $0091,         {scrollock}
        { This should be handled !! }
        { these last two are OEM specific
          this is not good !!! }
        $00DC,         {^ : next key i.e. a is modified }
        { Strange on my keyboard this corresponds to double point over i or u PM }
        $00DD: exit;   {� and ` : next key i.e. e is modified }
      end;

      key := $03000000 + (t.wVirtualScanCode shl 8);  { make lower 8 bit=0 like under dos }
    end;
    { Handling of ~ key as AltGr 2 }
    { This is also French keyboard specific !! }
    { but without this I can not get a ~ !! PM }
    { MvdV: not rightruealtised, since it already has frenchkbd guard}
    if (t.wVirtualKeyCode=$32) and
       (KeyBoardLayout = FrenchKeyboard) and
       (t.dwControlKeyState and RIGHT_ALT_PRESSED <> 0) then
      key:=(key and $ffffff00) or ord('~');
    { ok, now add Shift-State }
    ss := transShiftState (t.dwControlKeyState);
    key := key or (ss shl 16);

    { Reset Ascii-Char if Alt+Key, fv needs that, may be we
      need it for other special keys too
      18 Sept 1999 AD: not for right Alt i.e. for AltGr+� = \ on german keyboard }
    if ((ss and kbAlt <> 0) and rightistruealt(t.dwControlKeyState)) or
    (*
      { yes, we need it for cursor keys, 25=left, 26=up, 27=right,28=down}
      {aggg, this will not work because esc is also virtualKeyCode 27!!}
      {if (t.wVirtualKeyCode >= 25) and (t.wVirtualKeyCode <= 28) then}
        no VK_ESCAPE is $1B !!
        there was a mistake :
         VK_LEFT is $25 not 25 !! *)
       { not $2E VK_DELETE because its only the Keypad point !! PM }
      (t.wVirtualKeyCode in [$21..$28,$2C,$2D,$2F]) then
      { if t.wVirtualScanCode in [$47..$49,$4b,$4d,$4f,$50..$53] then}
        key := key and $FFFFFF00;

    {and translate to dos-scancodes to make fv happy, we will convert this
     back in translateKeyEvent}

     if rightistruealt(t.dwControlKeyState) then {not for alt-gr}
     if (t.wVirtualScanCode >= low (DosTT)) and
        (t.wVirtualScanCode <= high (dosTT)) then
     begin
       b := 0;
       if (ss and kbAlt) <> 0 then
         b := DosTT[t.wVirtualScanCode].a
       else
       if (ss and kbCtrl) <> 0 then
         b := DosTT[t.wVirtualScanCode].c
       else
       if (ss and kbShift) <> 0 then
         b := DosTT[t.wVirtualScanCode].s
       else
         b := DosTT[t.wVirtualScanCode].n;
       if b <> 0 then
         key := (key and $FFFF00FF) or (longint (b) shl 8);
     end;

     {Alt-0 to Alt-9}
     if rightistruealt(t.dwControlKeyState) then {not for alt-gr}
       if (t.wVirtualScanCode >= low (DosTT09)) and
          (t.wVirtualScanCode <= high (dosTT09)) then
       begin
         b := 0;
         if (ss and kbAlt) <> 0 then
           b := DosTT09[t.wVirtualScanCode].a
         else
         if (ss and kbCtrl) <> 0 then
           b := DosTT09[t.wVirtualScanCode].c
         else
         if (ss and kbShift) <> 0 then
           b := DosTT09[t.wVirtualScanCode].s
         else
           b := DosTT09[t.wVirtualScanCode].n;
         if b <> 0 then
           key := (key and $FFFF0000) or (longint (b) shl 8);
       end;

     TranslateKey := key;
  end;
  translateKey := Key;
end;
*}

function hasMouseEvent(var x: integer; var y: integer; var btn: integer): boolean;
begin
//  if 
end;



//#define IsMsgPortEmpty(x)  (((x)->mp_MsgList.lh_TailPred) == (struct Node *)(&(x)->mp_MsgList))

function IsMsgPortEmpty(port: PMsgPort): boolean; inline;
begin
  IsMsgPortEmpty:=(port^.mp_MsgList.lh_TailPred = @(port^.mp_MsgList));
end;

var
  KeyQueue: TKeyEvent;


type 
  rawCodeEntry = record
    rc,n,s,c,a : word; { raw code, normal, shift, ctrl, alt }
  end;

const
  RCTABLE_MAXIDX = 16;
  rawCodeTable : array[0..RCTABLE_MAXIDX] of rawCodeEntry = 
    ((rc: 71; n: $5200; s: $0500; c: $0400; a: $A200; ), // Insert
     (rc: 72; n: $4900; s: $4900; c: $8400; a: $9900; ), // PgUP   // shift?
     (rc: 73; n: $5100; s: $5100; c: $7600; a: $A100; ), // PgDOWN // shift?

     (rc: 76; n: $4800; s: $4800; c: $8D00; a: $9800; ), // UP     // shift?
     (rc: 77; n: $5000; s: $5000; c: $9100; a: $A000; ), // DOWN   // shift?
     (rc: 78; n: $4D00; s: $4D00; c: $7400; a: $9D00; ), // RIGHT  // shift?
     (rc: 79; n: $4B00; s: $4B00; c: $7300; a: $9B00; ), // LEFT   // shift?
 
     (rc: 80; n: $3B00; s: $5400; c: $5E00; a: $6800; ), // F1
     (rc: 81; n: $3C00; s: $5500; c: $5F00; a: $6900; ), // F2
     (rc: 82; n: $3D00; s: $5600; c: $6000; a: $6A00; ), // F3
     (rc: 83; n: $3E00; s: $5700; c: $6100; a: $6B00; ), // F4
     (rc: 84; n: $3F00; s: $5800; c: $6200; a: $6C00; ), // F5
     (rc: 85; n: $4000; s: $5900; c: $6300; a: $6D00; ), // F6
     (rc: 86; n: $4100; s: $5A00; c: $6400; a: $6E00; ), // F7
     (rc: 87; n: $4200; s: $5B00; c: $6500; a: $6F00; ), // F8
     (rc: 88; n: $4300; s: $5C00; c: $6600; a: $7000; ), // F9
     (rc: 89; n: $4400; s: $5D00; c: $6700; a: $7100; )  // F10
    );

function rcTableIdx(rc: longint): longint;
var counter: longint;
begin
  rcTableIdx := -1;
  counter := 0;
  while (rawCodeTable[counter].rc <> rc) and (counter <= RCTABLE_MAXIDX) do inc(counter);
  if (counter <= RCTABLE_MAXIDX) then rcTableIdx:=counter;
end;


function hasShift(iMsg: PIntuiMessage) : boolean; inline;
begin
  hasShift:=false;
  if ((iMsg^.qualifier and IEQUALIFIER_LSHIFT) > 0) or
     ((iMsg^.qualifier and IEQUALIFIER_RSHIFT) > 0) then hasShift:=true;
end;

function hasCtrl(iMsg: PIntuiMessage) : boolean; inline;
begin
  hasCtrl:=false;
  if ((iMsg^.qualifier and IEQUALIFIER_CONTROL) > 0) then hasCtrl:=true;
end;

function hasAlt(iMsg: PIntuiMessage) : boolean; inline;
begin
  hasAlt:=false;
  if ((iMsg^.qualifier and IEQUALIFIER_LALT) > 0) or
     ((iMsg^.qualifier and IEQUALIFIER_RALT) > 0) then hasAlt:=true;
end;

function rcTableCode(iMsg: PIntuiMessage; Idx: longint): longint;
begin
  if (Idx < 0) or (Idx > RCTABLE_MAXIDX) then begin
    rcTableCode:=-1;
    exit;
  end;

  if hasShift(iMsg) then rcTableCode:=rawCodeTable[Idx].s else
  if hasCtrl(iMsg) then rcTableCode:=rawCodeTable[Idx].c else
  if hasAlt(iMsg) then rcTableCode:=rawCodeTable[Idx].a else
  rcTableCode:=rawCodeTable[Idx].n;
end;

procedure setShiftState(iMsg: PIntuiMessage);
begin
  lastShiftState:=0;
  if ((iMsg^.qualifier and IEQUALIFIER_LSHIFT) > 0) then lastShiftState := lastShiftState or $01;
  if ((iMsg^.qualifier and IEQUALIFIER_RSHIFT) > 0) then lastShiftState := lastShiftState or $02;
  if hasCtrl(iMsg) then lastShiftState := lastShiftState or $04;
  if hasAlt(iMsg)  then lastShiftState := lastShiftState or $08;
  if ((iMsg^.qualifier and IEQUALIFIER_NUMERICPAD) > 0) then lastShiftState := lastShiftState or $20;
  if ((iMsg^.qualifier and IEQUALIFIER_CAPSLOCK) > 0)   then lastShiftState := lastShiftState or $40;
end;


function SysPollKeyEvent: TKeyEvent;
//var t   : TKeyEventRecord;
//    k   : TKeyEvent;
var
  mouseevent : boolean;
  iMsg : PIntuiMessage;
  KeyCode: longint;
  tmpFCode: word;
  tmpIdx  : longint;
  mousex  : longint;
  mousey  : longint;
  me      : TMouseEvent;
begin
  KeyCode:=0;
  SysPollKeyEvent:=0;
  FillChar(me,sizeof(TMouseEvent),0); 

  if KeyQueue<>0 then begin
    SysPollKeyEvent:=KeyQueue;
    exit;
  end;

  repeat
    mouseevent:=false;    

    if videoWindow<>nil then begin
      if IsMsgPortEmpty(videoWindow^.UserPort) then exit;
    end;
    
    PMessage(iMsg):=GetMsg(videoWindow^.UserPort);
    if (iMsg<>nil) then begin
      
      // set Shift state qualifiers. do this for all messages we get.
      setShiftState(iMsg);

      case (iMsg^.iClass) of
        IDCMP_CLOSEWINDOW: begin
            GotCloseWindow;
          end;
        IDCMP_CHANGEWINDOW: begin
            GotResizeWindow;
          end;
        IDCMP_MOUSEBUTTONS: begin
            mouseevent:=true;
            me.x:=(iMsg^.MouseX - videoWindow^.BorderLeft) div 8;
            me.y:=(iMsg^.MouseY - videoWindow^.BorderTop) div 16;
            case iMsg^.code of
              SELECTDOWN: begin
                  writeln('left button down!');
                  me.Action:=MouseActionDown;
                  me.Buttons:=MouseLeftButton;
                  oldbuttons:=MouseLeftButton;
                  PutMouseEvent(me);
                end;
              SELECTUP: begin
                  writeln('left button up!');
                  me.Action:=MouseActionUp;
                  me.Buttons:=0;
                  oldbuttons:=0;
                  PutMouseEvent(me);
                end;
            end;
          end;
        IDCMP_MOUSEMOVE: begin
            mouseevent:=true;
            mousex:=(iMsg^.MouseX - videoWindow^.BorderLeft) div 8;
            mousey:=(iMsg^.MouseY - videoWindow^.BorderTop) div 16;
            if (mousex >= 0) and (mousey >= 0) and
               (mousex < video.ScreenWidth) and (mousey < video.ScreenHeight) and
               ((mousex <> oldmousex) or (mousey <> oldmousey))
              then begin
//              writeln('mousemove:',mousex,'/',mousey,' oldbutt:',oldbuttons);
              me.Action:=MouseActionMove;
              me.Buttons:=oldbuttons;
              me.X:=mousex;
              me.Y:=mousey;
              oldmousex:=mousex;
              oldmousey:=mousey;
              PutMouseEvent(me);
            end;
          end;
        IDCMP_VANILLAKEY: begin
            writeln('vanilla keycode: ',iMsg^.code);
            KeyCode:=iMsg^.code;
            case (iMsg^.code) of
               09: KeyCode:=$0F09; // Tab
               13: KeyCode:=$1C0D; // Enter 
               27: KeyCode:=$011B; // ESC
              
              127: KeyCode:=$5300; // Del

              164: KeyCode:=$1200; // Alt-E //XXX: conflicts with Alt-Z(?)
              174: KeyCode:=$1300; // Alt-R
              176: KeyCode:=$1100; // Alt-W
              215: KeyCode:=$2D00; // Alt-X
              229: KeyCode:=$1000; // Alt-Q
              254: KeyCode:=$1400; // Alt-T

            end;
          end;
        IDCMP_RAWKEY: begin
            writeln('raw keycode: ',iMsg^.code);
            
            case (iMsg^.code) of
               35: KeyCode:=$2100; // Alt-F

              112: KeyCode:=$4700; // HOME
              113: KeyCode:=$4F00; // END

              else
                KeyCode:=rcTableCode(iMsg,rcTableIdx(iMsg^.code));

            end;
          end;
        else begin
            KeyCode:=-1;
          end;
      end;
      ReplyMsg(PMessage(iMsg));
    end;
  until (not mouseevent);
 
  // XXX: huh :)

  if KeyCode>=0 then begin
    SysPollKeyEvent:=KeyCode or (kbPhys shl 24);
  end else begin
    SysPollKeyEvent:=0;
  end;

  KeyQueue:=SysPollKeyEvent;

{*
  SysPollKeyEvent := 0;
  if getKeyEventFromQueue (t, true) then
  begin
    { we get an enty for shift, ctrl, alt... }
    k := translateKey (t);
    while (k = 0) do
    begin
      getKeyEventFromQueue (t, false);  {remove it}
      if not getKeyEventFromQueue (t, true) then exit;
      k := translateKey (t)
    end;
    SysPollKeyEvent := k;
  end;
*}
end;


function SysGetKeyEvent: TKeyEvent;
//var t   : TKeyEventRecord;
//    key : TKeyEvent;
var
  iMsg : PIntuiMessage;
  res : TKeyEvent;
begin
{*
  key := 0;
  repeat
     if getKeyEventFromQueueWait (t) then
       key := translateKey (t);
  until key <> 0;
{$ifdef DEBUG}
  last_ir.Event.KeyEvent:=t;
{$endif DEBUG}
  SysGetKeyEvent := key;
*}

//  writeln('keyboard/SysGetKeyEvent');
  if videoWindow<>nil then begin
    if KeyQueue <> 0 then begin
      SysGetKeyEvent := KeyQueue;
      KeyQueue:=0;
      exit;
    end;
    repeat
      WaitPort(videoWindow^.UserPort);
      res:=SysPollKeyEvent;
    until res<>0;
  end;

  SysGetKeyEvent:=res;

{*
  if videoWindow<>nil then begin
    WaitPort(videoWindow^.UserPort);
    PMessage(iMsg):=GetMsg(videoWindow^.UserPort);
    if (iMsg<>nil) then begin
      writeln('got msg!');
      ReplyMsg(PMessage(iMsg));
    end;
  end;
*}
end;



function SysTranslateKeyEvent(KeyEvent: TKeyEvent): TKeyEvent;
begin
{*
  if KeyEvent and $03000000 = $03000000 then
   begin
     if KeyEvent and $000000FF <> 0 then
     begin
       SysTranslateKeyEvent := KeyEvent and $00FFFFFF;
       exit;
     end;
     {translate function-keys and other specials, ascii-codes are already ok}
     case (KeyEvent AND $0000FF00) shr 8 of
       {F1..F10}
       $3B..$44     : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdF1 + ((KeyEvent AND $0000FF00) SHR 8) - $3B + $02000000;
       {F11,F12}
       $85..$86     : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdF11 + ((KeyEvent AND $0000FF00) SHR 8) - $85 + $02000000;
       {Shift F1..F10}
       $54..$5D     : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdF1 + ((KeyEvent AND $0000FF00) SHR 8) - $54 + $02000000;
       {Shift F11,F12}
       $87..$88     : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdF11 + ((KeyEvent AND $0000FF00) SHR 8) - $87 + $02000000;
       {Alt F1..F10}
       $68..$71     : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdF1 + ((KeyEvent AND $0000FF00) SHR 8) - $68 + $02000000;
       {Alt F11,F12}
       $8B..$8C     : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdF11 + ((KeyEvent AND $0000FF00) SHR 8) - $8B + $02000000;
       {Ctrl F1..F10}
       $5E..$67     : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdF1 + ((KeyEvent AND $0000FF00) SHR 8) - $5E + $02000000;
       {Ctrl F11,F12}
       $89..$8A     : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdF11 + ((KeyEvent AND $0000FF00) SHR 8) - $89 + $02000000;

       {normal,ctrl,alt}
       $47,$77,$97  : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdHome + $02000000;
       $48,$8D,$98  : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdUp + $02000000;
       $49,$84,$99  : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdPgUp + $02000000;
       $4b,$73,$9B  : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdLeft + $02000000;
       $4d,$74,$9D  : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdRight + $02000000;
       $4f,$75,$9F  : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdEnd + $02000000;
       $50,$91,$A0  : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdDown + $02000000;
       $51,$76,$A1  : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdPgDn + $02000000;
       $52,$92,$A2  : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdInsert + $02000000;
       $53,$93,$A3  : SysTranslateKeyEvent := (KeyEvent AND $FCFF0000) + kbdDelete + $02000000;
     else
       SysTranslateKeyEvent := KeyEvent;
     end;
   end else
     SysTranslateKeyEvent := KeyEvent;
*}
end;


function SysGetShiftState: Byte;
begin
  //writeln('SysgetShiftState:',hexstr(lastShiftState,2));
  SysGetShiftState:= lastShiftState;
end;

Const
  SysKeyboardDriver : TKeyboardDriver = (
    InitDriver : @SysInitKeyBoard;
    DoneDriver : @SysDoneKeyBoard;
    GetKeyevent : @SysGetKeyEvent;
    PollKeyEvent : @SysPollKeyEvent;
    GetShiftState : @SysGetShiftState;
//    TranslateKeyEvent : @SysTranslateKeyEvent;
    TranslateKeyEvent : Nil;
    TranslateKeyEventUnicode : Nil;
  );


begin
  SetKeyBoardDriver(SysKeyBoardDriver);
end.
