{$ifdef fpc}
{$mode delphi}
{$endif fpc}

{$ifdef FPC_COMP_IS_INT64}
type 
  comp = double;
{$endif FPC_COMP_IS_INT64}
procedure test(a: comp); overload;
  begin
    writeln('comp called instead of smallint');
    halt(1)
  end;

procedure test(a: smallint); overload;
  begin
    writeln('smallint called instead of comp');
    writeln('YYY')
  end;

var
  v: variant;
  x: comp;
  y: smallint;

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
      halt(1);
  end;
end.
