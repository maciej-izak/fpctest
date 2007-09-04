program Example;

{$mode objfpc}{$H+}

uses
  sCheck;

var
  i, j, n: Integer;
  s: TSuggestionArray; { in case the word is wrong, this array contains
                         a list of suggestions }
begin
  if Paramcount < 2 then // check if user has used valid input
    Writeln('Usage: ', ParamStr(0), ' <lang> <word1> <word2> ...')
  else for i := 2 to ParamCount do begin // go for each word specified
    n := SpellCheck(ParamStr(i), ParamStr(1), s); // spellcheck each word
    if n > 0 then begin // if n > 0 then the word is wrong and we need to write suggestions
      Write(ParamStr(i), ' is wrong. Here are some suggestions: ');
      for j := 0 to High(s) do
        Write(s[j], ' '); // write out the suggestions
      Writeln; // to keep format
    end else
      Writeln(ParamStr(i), ' is spelled correctly!');
  end;
end.

