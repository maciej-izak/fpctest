{$ifdef fpc}
{$mode delphi}
{$endif fpc}

{$ifdef FPC_COMP_IS_INT64}
type 
  comp = double;
{$endif FPC_COMP_IS_INT64}
procedure test(a: currency); overload;
  begin
    writeln('currency called instead of shortstring');
    writeln('XXX')
  end;

procedure test(a: shortstring); overload;
  begin
    writeln('shortstring called instead of currency');
    halt(1)
  end;

var
  v: variant;
  x: currency;
  y: shortstring;

begin
  try
    v := x;
    test(v);
  except
    on E : TObject do
      halt(1);
  end;

  try
    v := y;
    test(v);
  except
    on E : TObject do
      writeln('VVV');
  end;
end.
