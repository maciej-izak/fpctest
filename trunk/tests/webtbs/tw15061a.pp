{$ifdef FPC}
{$mode macpas}
{$align power}
{$endif}

{$ifdef __GPC__}
{ maximum-field-alignment=16}
{$endif}

program patbug;
type
{$ifdef FPC}
    PtrWord = PtrUInt;
{$endif}
  pattern = record pat: array[0..7] of byte end;
  patrec = record b: boolean; p: pattern end;
  doublerec = record b: boolean; d: double end;
var
    gPatRec: patrec;
    gDoubleRec: doublerec;
begin
    writeln( 'SizeOf( patrec) = ', SizeOf( patrec));
    if (sizeof(patrec)<>9) then
      halt(1);
    writeln( 'Offset of p: pattern = ', PtrWord( @gPatRec.p) - PtrWord( @gPatRec));
    if ((PtrWord( @gPatRec.p) - PtrWord( @gPatRec)) <> 1) then
      halt(2);
    writeln;
    writeln( 'SizeOf( doublerec) = ', SizeOf( doublerec));
    if (sizeof(doublerec)<>12) then
      halt(3);
    writeln( 'Offset of d: double = ', PtrWord( @gDoubleRec.d) - PtrWord( @gDoubleRec));
    if ((PtrWord( @gDoubleRec.d) - PtrWord( @gDoubleRec))<>4) then
      halt(4);
    writeln;
end.

