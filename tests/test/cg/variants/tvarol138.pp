{$ifdef fpc}
{$mode delphi}
{$endif fpc}

{$ifdef FPC_COMP_IS_INT64}
type 
  comp = currency;
{$endif FPC_COMP_IS_INT64}
procedure test(a: shortstring); overload;
  begin
    writeln('shortstring called instead of double');
    halt(1)
  end;

procedure test(a: double); overload;
  begin
    writeln('double called instead of shortstring');
    writeln('YYY')
  end;

var
  v: variant;
  x: shortstring;
  y: double;

begin
  try
    v := x;
    test(v);
  except
    on E : TObject do
      writeln('QQQ');
  end;

  try
    v := y;
    test(v);
  except
    on E : TObject do
      halt(1);
  end;
end.
