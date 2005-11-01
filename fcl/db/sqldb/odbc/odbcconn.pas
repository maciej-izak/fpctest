(******************************************************************************
 *                                                                            *
 *  (c) 2005 Hexis BV                                                         *
 *                                                                            *
 *  File:        odbcconn.pas                                                 *
 *  Author:      Bram Kuijvenhoven (bkuijvenhoven@eljakim.nl)                 *
 *  Description: ODBC SQLDB unit                                              *
 *  License:     (modified) LGPL                                              *
 *                                                                            *
 ******************************************************************************)

unit odbcconn;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, odbcsql;

type

  // forward declarations
  TODBCConnection = class;

  { TODBCCursor }

  TODBCCursor = class(TSQLCursor)
  protected
    FSTMTHandle:SQLHSTMT; // ODBC Statement Handle
    FQuery:string;        // last prepared query, with :ParamName converted to ?
    FParamIndex:array of integer; // maps the i-th parameter in the query to the TParams passed to PrepareStatement
    FParamBuf:array of pointer; // buffers that can be used to bind the i-th parameter in the query
  public
    constructor Create(Connection:TODBCConnection);
    destructor Destroy; override;
  end;

  { TODBCHandle } // this name is a bit confusing, but follows the standards for naming classes in sqldb

  TODBCHandle = class(TSQLHandle)
  protected
  end;

  { TODBCEnvironment }

  TODBCEnvironment = class
  protected
    FENVHandle:SQLHENV; // ODBC Environment Handle
  public
    constructor Create;
    destructor Destroy; override;
  end;

  { TODBCConnection }

  TODBCConnection = class(TSQLConnection)
  private
    FDataSourceName: string;
    FDriver: string;
    FEnvironment:TODBCEnvironment;
    FDBCHandle:SQLHDBC; // ODBC Connection Handle
    FFileDSN: string;

    procedure SetParameters(ODBCCursor:TODBCCursor; AParams:TParams);
    procedure FreeParamBuffers(ODBCCursor:TODBCCursor);
  protected
    // Overrides from TSQLConnection
    function GetHandle:pointer; override;
    // - Connect/disconnect
    procedure DoInternalConnect; override;
    procedure DoInternalDisconnect; override;
    // - Handle (de)allocation
    function AllocateCursorHandle:TSQLCursor; override;
    procedure DeAllocateCursorHandle(var cursor:TSQLCursor); override;
    function AllocateTransactionHandle:TSQLHandle; override;
    // - Statement handling
    procedure PrepareStatement(cursor:TSQLCursor; ATransaction:TSQLTransaction; buf:string; AParams:TParams); override;
    procedure UnPrepareStatement(cursor:TSQLCursor); override;
    // - Transaction handling
    function GetTransactionHandle(trans:TSQLHandle):pointer; override;
    function StartDBTransaction(trans:TSQLHandle; AParams:string):boolean; override;
    function Commit(trans:TSQLHandle):boolean; override;
    function Rollback(trans:TSQLHandle):boolean; override;
    procedure CommitRetaining(trans:TSQLHandle); override;
    procedure RollbackRetaining(trans:TSQLHandle); override;
    // - Statement execution
    procedure Execute(cursor:TSQLCursor; ATransaction:TSQLTransaction; AParams:TParams); override;
    // - Result retrieving
    procedure AddFieldDefs(cursor:TSQLCursor; FieldDefs:TFieldDefs); override;
    function Fetch(cursor:TSQLCursor):boolean; override;
    function LoadField(cursor:TSQLCursor; FieldDef:TFieldDef; buffer:pointer):boolean; override;
    function CreateBlobStream(Field:TField; Mode:TBlobStreamMode):TStream; override;
    procedure FreeFldBuffers(cursor:TSQLCursor); override;
    // - UpdateIndexDefs
    procedure UpdateIndexDefs(var IndexDefs:TIndexDefs; TableName:string); override;
    // - Schema info
    function GetSchemaInfoSQL(SchemaType:TSchemaType; SchemaObjectName, SchemaObjectPattern:string):string; override;

    // Internal utility functions
    function CreateConnectionString:string;
  public
    property Environment:TODBCEnvironment read FEnvironment;
  published
    property Driver:string read FDriver write FDriver;                         // will be passed as DRIVER connection parameter
    property FileDSN:string read FFileDSN write FFileDSN;                      // will be passed as FILEDSN parameter
    // Redeclare properties from TSQLConnection
    property Password;     // will be passed as PWD connection parameter
    property Transaction;
    property UserName;     // will be passed as UID connection parameter
    property CharSet;
    property HostName;     // ignored
    // Redeclare properties from TDatabase
    property Connected;
    property Role;
    property DatabaseName; // will be passed as DSN connection parameter
    property KeepConnection;
    property LoginPrompt;  // if true, ODBC drivers might prompt for more details that are not in the connection string
    property Params;       // will be added to connection string
    property OnLogin;
  end;

  EODBCException = class(Exception)
    // currently empty; perhaps we can add fields here later that describe the error instead of one simple message string
  end;

implementation

uses
  Math; // for the Min proc

const
  DefaultEnvironment:TODBCEnvironment = nil;
  ODBCLoadCount:integer = 0; // ODBC is loaded when > 0; modified by TODBCEnvironment.Create/Destroy

{ Generic ODBC helper functions }

function ODBCSucces(const Res:SQLRETURN):boolean;
begin
  Result:=(Res=SQL_SUCCESS) or (Res=SQL_SUCCESS_WITH_INFO);
end;

procedure ODBCCheckResult(HandleType:SQLSMALLINT; AHandle: SQLHANDLE; ErrorMsg: string);

  // check return value from SQLGetDiagField/Rec function itself
  procedure CheckSQLGetDiagResult(const Res:SQLRETURN);
  begin
    case Res of
      SQL_INVALID_HANDLE:
        raise EODBCException.Create('Invalid handle passed to SQLGetDiagRec/Field');
      SQL_ERROR:
        raise EODBCException.Create('An invalid parameter was passed to SQLGetDiagRec/Field');
      SQL_NO_DATA:
        raise EODBCException.Create('A too large RecNumber was passed to SQLGetDiagRec/Field');
    end;
  end;

var
  NativeError:SQLINTEGER;
  TextLength:SQLSMALLINT;
  Res,LastReturnCode:SQLRETURN;
  SqlState,MessageText,TotalMessage:string;
  RecNumber:SQLSMALLINT;
begin
  // check result
  Res:=SQLGetDiagField(HandleType,AHandle,0,SQL_DIAG_RETURNCODE,@LastReturnCode,0,TextLength);
  CheckSQLGetDiagResult(Res);
  if ODBCSucces(LastReturnCode) then
    Exit; // no error; all is ok

  // build TotalMessage for exception to throw
  TotalMessage:=Format('%s ODBC error details:',[ErrorMsg]);
  // retrieve status records
  SetLength(SqlState,5); // SqlState buffer
  RecNumber:=1;
  repeat
    // dummy call to get correct TextLength
    Res:=SQLGetDiagRec(HandleType,AHandle,RecNumber,@(SqlState[1]),NativeError,@(SqlState[1]),0,TextLength);
    if Res=SQL_NO_DATA then
      Break; // no more status records
    CheckSQLGetDiagResult(Res);
    if TextLength>0 then // if TextLength=0 we don't need another call; also our string buffer would not point to a #0, but be a nil pointer
    begin
      // allocate large enough buffer
      SetLength(MessageText,TextLength); // note: ansistrings of Length>0 are always terminated by a #0 character, so this is safe
      // actual call
      Res:=SQLGetDiagRec(HandleType,AHandle,RecNumber,@(SqlState[1]),NativeError,@(MessageText[1]),Length(MessageText)+1,TextLength);
      CheckSQLGetDiagResult(Res);
    end;
    // add to TotalMessage
    TotalMessage:=TotalMessage + Format(' Record %d: SqlState: %s; NativeError: %d; Message: %s;',[RecNumber,SqlState,NativeError,MessageText]);
    // incement counter
    Inc(RecNumber);
  until false;
  // raise error
  raise EODBCException.Create(TotalMessage);
end;

{ TODBCConnection }

// Creates a connection string using the current value of the fields
function TODBCConnection.CreateConnectionString: string;

  // encloses a param value with braces if necessary, i.e. when any of the characters []{}(),;?*=!@ is in the value
  function EscapeParamValue(const s:string):string;
  var
    NeedEscape:boolean;
    i:integer;
  begin
    NeedEscape:=false;
    for i:=1 to Length(s) do
      if s[i] in ['[',']','{','}','(',')',',','*','=','!','@'] then
      begin
        NeedEscape:=true;
        Break;
      end;
    if NeedEscape then
      Result:='{'+s+'}'
    else
      Result:=s;
  end;

var
  i: Integer;
  Param: string;
  EqualSignPos:integer;
begin
  Result:='';
  if DatabaseName<>'' then Result:=Result + 'DSN='+EscapeParamValue(DatabaseName)+';';
  if Driver      <>'' then Result:=Result + 'DRIVER='+EscapeParamValue(Driver)+';';
  if UserName    <>'' then Result:=Result + 'UID='+EscapeParamValue(UserName)+';PWD='+EscapeParamValue(Password)+';';
  if FileDSN     <>'' then Result:=Result + 'FILEDSN='+EscapeParamValue(FileDSN)+'';
  for i:=0 to Params.Count-1 do
  begin
    Param:=Params[i];
    EqualSignPos:=Pos('=',Param);
    if EqualSignPos=0 then
      raise EODBCException.CreateFmt('Invalid parameter in Params[%d]; can''t find a ''='' in ''%s''',[i, Param])
    else if EqualSignPos=1 then
      raise EODBCException.CreateFmt('Invalid parameter in Params[%d]; no identifier before the ''='' in ''%s''',[i, Param])
    else
      Result:=Result + EscapeParamValue(Copy(Param,1,EqualSignPos-1))+'='+EscapeParamValue(Copy(Param,EqualSignPos+1,MaxInt));
  end;
end;

procedure TODBCConnection.SetParameters(ODBCCursor: TODBCCursor; AParams: TParams);
var
  ParamIndex:integer;
  Buf:pointer;
  I:integer;
  IntVal:longint;
  StrVal:string;
  StrLen:SQLINTEGER;
begin
  // Note: it is assumed that AParams is the same as the one passed to PrepareStatement, in the sense that
  //       the parameters have the same order and names

  if Length(ODBCCursor.FParamIndex)>0 then
    if not Assigned(AParams) then
      raise EODBCException.CreateFmt('The query has parameter markers in it, but no actual parameters were passed',[]);

  SetLength(ODBCCursor.FParamBuf, Length(ODBCCursor.FParamIndex));
  for i:=0 to High(ODBCCursor.FParamIndex) do
  begin
    ParamIndex:=ODBCCursor.FParamIndex[i];
    if (ParamIndex<0) or (ParamIndex>=AParams.Count) then
      raise EODBCException.CreateFmt('Parameter %d in query does not have a matching parameter set',[i]);
    case AParams[ParamIndex].DataType of
      ftInteger:
        begin
          Buf:=GetMem(4);
          IntVal:=AParams[ParamIndex].AsInteger;
          Move(IntVal,Buf^,4);
          ODBCCursor.FParamBuf[i]:=Buf;
          SQLBindParameter(ODBCCursor.FSTMTHandle, // StatementHandle
                           i+1,                    // ParameterNumber
                           SQL_PARAM_INPUT,        // InputOutputType
                           SQL_C_LONG,             // ValueType
                           SQL_INTEGER,            // ParameterType
                           10,                     // ColumnSize
                           0,                      // DecimalDigits
                           Buf,                    // ParameterValuePtr
                           0,                      // BufferLength
                           nil);                   // StrLen_or_IndPtr
          ODBCCheckResult(SQL_HANDLE_STMT, ODBCCursor.FSTMTHandle, Format('Could not bind parameter %d',[i]));
        end;
      ftString:
        begin
          StrVal:=AParams[ParamIndex].AsString;
          StrLen:=Length(StrVal);
          Buf:=GetMem(SizeOf(SQLINTEGER)+StrLen);
          Move(StrLen,    buf^,                    SizeOf(SQLINTEGER));
          Move(StrVal[1],(buf+SizeOf(SQLINTEGER))^,StrLen);
          ODBCCursor.FParamBuf[i]:=Buf;
          SQLBindParameter(ODBCCursor.FSTMTHandle, // StatementHandle
                           i+1,                    // ParameterNumber
                           SQL_PARAM_INPUT,        // InputOutputType
                           SQL_C_CHAR,             // ValueType
                           SQL_CHAR,               // ParameterType
                           StrLen,                 // ColumnSize
                           0,                      // DecimalDigits
                           buf+SizeOf(SQLINTEGER), // ParameterValuePtr
                           StrLen,                 // BufferLength
                           Buf);                   // StrLen_or_IndPtr
          ODBCCheckResult(SQL_HANDLE_STMT, ODBCCursor.FSTMTHandle, Format('Could not bind parameter %d',[i]));
        end;
    else
      raise EDataBaseError.CreateFmt('Parameter %d is of type %s, which not supported yet',[ParamIndex, Fieldtypenames[AParams[ParamIndex].DataType]]);
    end;
  end;
end;

procedure TODBCConnection.FreeParamBuffers(ODBCCursor: TODBCCursor);
var
  i:integer;
begin
  for i:=0 to High(ODBCCursor.FParamBuf) do
    FreeMem(ODBCCursor.FParamBuf[i]);
end;

function TODBCConnection.GetHandle: pointer;
begin
  // I'm not sure whether this is correct; perhaps we should return nil
  // note that FDBHandle is a LongInt, because ODBC handles are integers, not pointers
  // I wonder how this will work on 64 bit platforms then (FK)
  Result:=pointer(PtrInt(FDBCHandle));
end;

procedure TODBCConnection.DoInternalConnect;
const
  BufferLength = 1024; // should be at least 1024 according to the ODBC specification
var
  ConnectionString:string;
  OutConnectionString:string;
  ActualLength:SQLSMALLINT;
begin
  inherited DoInternalConnect;

  // make sure we have an environment
  if not Assigned(FEnvironment) then
  begin
    if not Assigned(DefaultEnvironment) then
      DefaultEnvironment:=TODBCEnvironment.Create;
    FEnvironment:=DefaultEnvironment;
  end;

  // allocate connection handle
  SQLAllocHandle(SQL_HANDLE_DBC,Environment.FENVHandle,FDBCHandle);
  ODBCCheckResult(SQL_HANDLE_ENV,Environment.FENVHandle,'Could not allocate ODBC Connection handle.');

  // connect
  ConnectionString:=CreateConnectionString;
  SetLength(OutConnectionString,BufferLength-1); // allocate completed connection string buffer (using the ansistring #0 trick)
  SQLDriverConnect(FDBCHandle,               // the ODBC connection handle
                   0,                        // no parent window (would be required for prompts)
                   PChar(ConnectionString),  // the connection string
                   Length(ConnectionString), // connection string length
                   @(OutConnectionString[1]),// buffer for storing the completed connection string
                   BufferLength,             // length of the buffer
                   ActualLength,             // the actual length of the completed connection string
                   SQL_DRIVER_NOPROMPT);     // don't prompt for password etc.
  ODBCCheckResult(SQL_HANDLE_DBC,FDBCHandle,Format('Could not connect with connection string "%s".',[ConnectionString]));
  if ActualLength<BufferLength-1 then
    SetLength(OutConnectionString,ActualLength); // fix completed connection string length

  // set connection attributes (none yet)
end;

procedure TODBCConnection.DoInternalDisconnect;
begin
  inherited DoInternalDisconnect;

  // disconnect
  SQLDisconnect(FDBCHandle);
  ODBCCheckResult(SQL_HANDLE_DBC,FDBCHandle,'Could not disconnect.');

  // deallocate connection handle
  if SQLFreeHandle(SQL_HANDLE_DBC, FDBCHandle)=SQL_ERROR then
    ODBCCheckResult(SQL_HANDLE_DBC,FDBCHandle,'Could not free connection handle.');
end;

function TODBCConnection.AllocateCursorHandle: TSQLCursor;
begin
  Result:=TODBCCursor.Create(self);
end;

procedure TODBCConnection.DeAllocateCursorHandle(var cursor: TSQLCursor);
begin
  FreeAndNil(cursor); // the destructor of TODBCCursor frees the ODBC Statement handle
end;

function TODBCConnection.AllocateTransactionHandle: TSQLHandle;
begin
  Result:=nil; // not yet supported; will move connection handles to transaction handles later
end;

procedure TODBCConnection.PrepareStatement(cursor: TSQLCursor; ATransaction: TSQLTransaction; buf: string; AParams: TParams);
type
  // used for ParamPart
  TStringPart = record
    Start,Stop:integer;
  end;
const
  ParamAllocStepSize = 8;
var
  ODBCCursor:TODBCCursor;
  p,ParamNameStart,BufStart:PChar;
  ParamName:string;
  QuestionMarkParamCount,ParameterIndex,NewLength:integer;
  ParamCount:integer; // actual number of parameters encountered so far;
                      // always <= Length(ParamPart) = Length(ODBCCursor.FParamIndex)
                      // ODBCCursor.FParamIndex will have length ParamCount in the end
  ParamPart:array of TStringPart; // describe which parts of buf are parameters
  NewQueryLength:integer;
  NewQuery:string;
  NewQueryIndex,BufIndex,CopyLen,i:integer;
begin
  ODBCCursor:=cursor as TODBCCursor;

  // Parameter handling
  // Note: We can only pass ? parameters to ODBC, so we should convert named parameters like :MyID
  //       ODBCCursor.FParamIndex will map th i-th ? token in the (modified) query to an index for AParams

  // Parse the SQL and build FParamIndex
  ParamCount:=0;
  NewQueryLength:=Length(buf);
  SetLength(ParamPart,ParamAllocStepSize);
  SetLength(ODBCCursor.FParamIndex,ParamAllocStepSize);
  QuestionMarkParamCount:=0; // number of ? params found in query so far
  p:=PChar(buf);
  BufStart:=p; // used to calculate ParamPart.Start values
  repeat
    case p^ of
      '''': // single quote delimited string (not obligatory in ODBC, but let's handle it anyway)
        begin
          Inc(p);
          while not (p^ in [#0, '''']) do
          begin
            if p^='\' then Inc(p,2) // make sure we handle \' and \\ correct
            else Inc(p);
          end;
          if p^='''' then Inc(p); // skip final '
        end;
      '"':  // double quote delimited string
        begin
          Inc(p);
          while not (p^ in [#0, '"']) do
          begin
            if p^='\'  then Inc(p,2) // make sure we handle \" and \\ correct
            else Inc(p);
          end;
          if p^='"' then Inc(p); // skip final "
        end;
      '-': // possible start of -- comment
        begin
          Inc(p);
          if p='-' then // -- comment
          begin
            repeat // skip until at end of line
              Inc(p);
            until p^ in [#10, #0];
          end
        end;
      '/': // possible start of /* */ comment
        begin
          Inc(p);
          if p^='*' then // /* */ comment
          begin
            repeat
              Inc(p);
              if p^='*' then // possible end of comment
              begin
                Inc(p);
                if p^='/' then Break; // end of comment
              end;
            until p^=#0;
            if p^='/' then Inc(p); // skip final /
          end;
        end;
      ':','?': // parameter
        begin
          Inc(ParamCount);
          if ParamCount>Length(ParamPart) then
          begin
            NewLength:=Length(ParamPart)+ParamAllocStepSize;
            SetLength(ParamPart,NewLength);
            SetLength(ODBCCursor.FParamIndex,NewLength);
          end;

          if p^=':' then
          begin // find parameter name
            Inc(p);
            ParamNameStart:=p;
            while not (p^ in (SQLDelimiterCharacters+[#0])) do
              Inc(p);
            ParamName:=Copy(ParamNameStart,1,p-ParamNameStart);
          end
          else
          begin
            Inc(p);
            ParamNameStart:=p;
            ParamName:='';
          end;

          // find ParameterIndex
          if ParamName<>'' then
          begin
            if AParams=nil then
              raise EDataBaseError.CreateFmt('Found parameter marker with name %s in the query, but no actual parameters are given at all',[ParamName]);
            ParameterIndex:=AParams.ParamByName(ParamName).Index // lookup parameter in AParams
          end
          else
          begin
            ParameterIndex:=QuestionMarkParamCount;
            Inc(QuestionMarkParamCount);
          end;

          // store ParameterIndex in FParamIndex, ParamPart data
          ODBCCursor.FParamIndex[ParamCount-1]:=ParameterIndex;
          ParamPart[ParamCount-1].Start:=ParamNameStart-BufStart;
          ParamPart[ParamCount-1].Stop:=p-BufStart+1;

          // update NewQueryLength
          Dec(NewQueryLength,p-ParamNameStart);
        end;
      #0:Break;
    else
      Inc(p);
    end;
  until false;

  SetLength(ParamPart,ParamCount);
  SetLength(ODBCCursor.FParamIndex,ParamCount);

  if ParamCount>0 then
  begin
    // replace :ParamName by ? (using ParamPart array and NewQueryLength)
    SetLength(NewQuery,NewQueryLength);
    NewQueryIndex:=1;
    BufIndex:=1;
    for i:=0 to High(ParamPart) do
    begin
      CopyLen:=ParamPart[i].Start-BufIndex;
      Move(buf[BufIndex],NewQuery[NewQueryIndex],CopyLen);
      Inc(NewQueryIndex,CopyLen);
      NewQuery[NewQueryIndex]:='?';
      Inc(NewQueryIndex);
      BufIndex:=ParamPart[i].Stop;
    end;
    CopyLen:=Length(Buf)+1-BufIndex;
    Move(buf[BufIndex],NewQuery[NewQueryIndex],CopyLen);
  end
  else
    NewQuery:=buf;

  // prepare statement
  SQLPrepare(ODBCCursor.FSTMTHandle, PChar(NewQuery), Length(NewQuery));
  ODBCCheckResult(SQL_HANDLE_STMT, ODBCCursor.FSTMTHandle, 'Could not prepare statement.');

  ODBCCursor.FQuery:=NewQuery;
end;

procedure TODBCConnection.UnPrepareStatement(cursor: TSQLCursor);
begin
  // not necessary in ODBC
end;

function TODBCConnection.GetTransactionHandle(trans: TSQLHandle): pointer;
begin
  // Tranactions not implemented yet
end;

function TODBCConnection.StartDBTransaction(trans: TSQLHandle; AParams:string): boolean;
begin
  // Tranactions not implemented yet
end;

function TODBCConnection.Commit(trans: TSQLHandle): boolean;
begin
  // Tranactions not implemented yet
end;

function TODBCConnection.Rollback(trans: TSQLHandle): boolean;
begin
  // Tranactions not implemented yet
end;

procedure TODBCConnection.CommitRetaining(trans: TSQLHandle);
begin
  // Tranactions not implemented yet
end;

procedure TODBCConnection.RollbackRetaining(trans: TSQLHandle);
begin
  // Tranactions not implemented yet
end;

procedure TODBCConnection.Execute(cursor: TSQLCursor; ATransaction: TSQLTransaction; AParams: TParams);
var
  ODBCCursor:TODBCCursor;
  Res:SQLRETURN;
begin
  ODBCCursor:=cursor as TODBCCursor;

  // set parameters
  SetParameters(ODBCCursor, AParams);

  // execute the statement
  Res:=SQLExecute(ODBCCursor.FSTMTHandle);
  ODBCCheckResult(SQL_HANDLE_STMT, ODBCCursor.FSTMTHandle, 'Could not execute statement.');

  // free parameter buffers
  FreeParamBuffers(ODBCCursor);
end;

function TODBCConnection.Fetch(cursor: TSQLCursor): boolean;
var
  ODBCCursor:TODBCCursor;
  Res:SQLRETURN;
begin
  ODBCCursor:=cursor as TODBCCursor;

  // fetch new row
  Res:=SQLFetch(ODBCCursor.FSTMTHandle);
  if Res<>SQL_NO_DATA then
    ODBCCheckResult(SQL_HANDLE_STMT, ODBCCursor.FSTMTHandle, 'Could not fetch new row from result set');

  // result is true iff a new row was available
  Result:=Res<>SQL_NO_DATA;
end;

function TODBCConnection.LoadField(cursor: TSQLCursor; FieldDef: TFieldDef; buffer: pointer): boolean;
var
  ODBCCursor:TODBCCursor;
  StrLenOrInd:SQLINTEGER;
  ODBCDateStruct:SQL_DATE_STRUCT;
  ODBCTimeStruct:SQL_TIME_STRUCT;
  ODBCTimeStampStruct:SQL_TIMESTAMP_STRUCT;
  DateTime:TDateTime;
begin
  ODBCCursor:=cursor as TODBCCursor;

  // load the field using SQLGetData
  // Note: optionally we can implement the use of SQLBindCol later for even more speed
  // TODO: finish this
  case FieldDef.DataType of
    ftFixedChar,ftString: // are both mapped to TStringField
      SQLGetData(ODBCCursor.FSTMTHandle, FieldDef.Index+1, SQL_C_CHAR, buffer, FieldDef.Size, @StrLenOrInd);
    ftSmallint:           // mapped to TSmallintField
      SQLGetData(ODBCCursor.FSTMTHandle, FieldDef.Index+1, SQL_C_SSHORT, buffer, SizeOf(Smallint), @StrLenOrInd);
    ftInteger,ftWord:     // mapped to TLongintField
      SQLGetData(ODBCCursor.FSTMTHandle, FieldDef.Index+1, SQL_C_SLONG, buffer, SizeOf(Longint), @StrLenOrInd);
    ftLargeint:           // mapped to TLargeintField
      SQLGetData(ODBCCursor.FSTMTHandle, FieldDef.Index+1, SQL_C_SBIGINT, buffer, SizeOf(Largeint), @StrLenOrInd);
    ftFloat:              // mapped to TFloatField
      SQLGetData(ODBCCursor.FSTMTHandle, FieldDef.Index+1, SQL_C_DOUBLE, buffer, SizeOf(Double), @StrLenOrInd);
    ftTime:               // mapped to TTimeField
    begin
      SQLGetData(ODBCCursor.FSTMTHandle, FieldDef.Index+1, SQL_C_TYPE_TIME, @ODBCTimeStruct, SizeOf(SQL_TIME_STRUCT), @StrLenOrInd);
      DateTime:=TimeStructToDateTime(@ODBCTimeStruct);
      Move(DateTime, buffer^, SizeOf(TDateTime));
    end;
    ftDate:               // mapped to TDateField
    begin
      SQLGetData(ODBCCursor.FSTMTHandle, FieldDef.Index+1, SQL_C_TYPE_DATE, @ODBCDateStruct, SizeOf(SQL_DATE_STRUCT), @StrLenOrInd);
      DateTime:=DateStructToDateTime(@ODBCDateStruct);
      Move(DateTime, buffer^, SizeOf(TDateTime));
    end;
    ftDateTime:           // mapped to TDateTimeField
    begin
      SQLGetData(ODBCCursor.FSTMTHandle, FieldDef.Index+1, SQL_C_TYPE_TIMESTAMP, @ODBCTimeStampStruct, SizeOf(SQL_TIMESTAMP_STRUCT), @StrLenOrInd);
      DateTime:=TimeStampStructToDateTime(@ODBCTimeStampStruct);
      Move(DateTime, buffer^, SizeOf(TDateTime));
    end;
    ftBoolean:            // mapped to TBooleanField
      SQLGetData(ODBCCursor.FSTMTHandle, FieldDef.Index+1, SQL_C_BIT, buffer, SizeOf(Wordbool), @StrLenOrInd);
    ftBytes:              // mapped to TBytesField
      SQLGetData(ODBCCursor.FSTMTHandle, FieldDef.Index+1, SQL_C_BINARY, buffer, FieldDef.Size, @StrLenOrInd);
    ftVarBytes:           // mapped to TVarBytesField
      SQLGetData(ODBCCursor.FSTMTHandle, FieldDef.Index+1, SQL_C_BINARY, buffer, FieldDef.Size, @StrLenOrInd);
    // TODO: Loading of other field types
  else
    raise EODBCException.CreateFmt('Tried to load field of unsupported field type %s',[Fieldtypenames[FieldDef.DataType]]);
  end;
  ODBCCheckResult(SQL_HANDLE_STMT, ODBCCursor.FSTMTHandle, Format('Could not get field data for field ''%s'' (index %d).',[FieldDef.Name, FieldDef.Index+1]));
  Result:=StrLenOrInd<>SQL_NULL_DATA; // Result indicates whether the value is non-null

//  writeln(Format('Field.Size: %d; StrLenOrInd: %d',[FieldDef.Size, StrLenOrInd]));
end;

function TODBCConnection.CreateBlobStream(Field: TField; Mode: TBlobStreamMode): TStream;
begin
  // TODO: implement TODBCConnection.CreateBlobStream
  Result:=nil;
end;

procedure TODBCConnection.FreeFldBuffers(cursor: TSQLCursor);
var
  ODBCCursor:TODBCCursor;
begin
  ODBCCursor:=cursor as TODBCCursor;

  SQLFreeStmt(ODBCCursor.FSTMTHandle, SQL_CLOSE);
  ODBCCheckResult(SQL_HANDLE_STMT, ODBCCursor.FSTMTHandle, 'Could not close ODBC statement cursor.');
end;

procedure TODBCConnection.AddFieldDefs(cursor: TSQLCursor; FieldDefs: TFieldDefs);
const
  ColNameDefaultLength = 40; // should be > 0, because an ansistring of length 0 is a nil pointer instead of a pointer to a #0
var
  ODBCCursor:TODBCCursor;
  ColumnCount:SQLSMALLINT;
  i:integer;
  ColNameLength,DataType,DecimalDigits,Nullable:SQLSMALLINT;
  ColumnSize:SQLUINTEGER;
  ColName:string;
  FieldType:TFieldType;
  FieldSize:word;
begin
  ODBCCursor:=cursor as TODBCCursor;

  // get number of columns in result set
  SQLNumResultCols(ODBCCursor.FSTMTHandle, ColumnCount);
  ODBCCheckResult(SQL_HANDLE_STMT, ODBCCursor.FSTMTHandle, 'Could not determine number of columns in result set.');

  for i:=1 to ColumnCount do
  begin
    SetLength(ColName,ColNameDefaultLength); // also garantuees uniqueness

    // call with default column name buffer
    SQLDescribeCol(ODBCCursor.FSTMTHandle, // statement handle
                   i,                      // column number, is 1-based (Note: column 0 is the bookmark column in ODBC)
                   @(ColName[1]),          // default buffer
                   ColNameDefaultLength+1, // and its length; we include the #0 terminating any ansistring of Length > 0 in the buffer
                   ColNameLength,          // actual column name length
                   DataType,               // the SQL datatype for the column
                   ColumnSize,             // column size
                   DecimalDigits,          // number of decimal digits
                   Nullable);              // SQL_NO_NULLS, SQL_NULLABLE or SQL_NULLABLE_UNKNOWN
    ODBCCheckResult(SQL_HANDLE_STMT, ODBCCursor.FSTMTHandle, Format('Could not get column properties for column %d.',[i]));

    // truncate buffer or make buffer long enough for entire column name (note: the call is the same for both cases!)
    SetLength(ColName,ColNameLength);
    // check whether entire column name was returned
    if ColNameLength>ColNameDefaultLength then
    begin
      // request column name with buffer that is long enough
      SQLColAttribute(ODBCCursor.FSTMTHandle, // statement handle
                      i,                      // column number
                      SQL_DESC_NAME,          // the column name or alias
                      @(ColName[1]),          // buffer
                      ColNameLength+1,        // buffer size
                      @ColNameLength,         // actual length
                      nil);                   // no numerical output
      ODBCCheckResult(SQL_HANDLE_STMT, ODBCCursor.FSTMTHandle, Format('Could not get column name for column %d.',[i]));
    end;

    // convert type
    // NOTE: I made some guesses here after I found only limited information about TFieldType; please report any problems
    case DataType of
      SQL_CHAR:          begin FieldType:=ftFixedChar;  FieldSize:=ColumnSize+1; end;
      SQL_VARCHAR:       begin FieldType:=ftString;     FieldSize:=ColumnSize+1; end;
      SQL_LONGVARCHAR:   begin FieldType:=ftString;     FieldSize:=ColumnSize+1; end; // no fixed maximum length; make ftMemo when blobs are supported
      SQL_WCHAR:         begin FieldType:=ftWideString; FieldSize:=ColumnSize+1; end;
      SQL_WVARCHAR:      begin FieldType:=ftWideString; FieldSize:=ColumnSize+1; end;
      SQL_WLONGVARCHAR:  begin FieldType:=ftWideString; FieldSize:=ColumnSize+1; end; // no fixed maximum length; make ftMemo when blobs are supported
      SQL_DECIMAL:       begin FieldType:=ftFloat;      FieldSize:=0; end;
      SQL_NUMERIC:       begin FieldType:=ftFloat;      FieldSize:=0; end;
      SQL_SMALLINT:      begin FieldType:=ftSmallint;   FieldSize:=0; end;
      SQL_INTEGER:       begin FieldType:=ftInteger;    FieldSize:=0; end;
      SQL_REAL:          begin FieldType:=ftFloat;      FieldSize:=0; end;
      SQL_FLOAT:         begin FieldType:=ftFloat;      FieldSize:=0; end;
      SQL_DOUBLE:        begin FieldType:=ftFloat;      FieldSize:=0; end;
      SQL_BIT:           begin FieldType:=ftBoolean;    FieldSize:=0; end;
      SQL_TINYINT:       begin FieldType:=ftSmallint;   FieldSize:=0; end;
      SQL_BIGINT:        begin FieldType:=ftLargeint;   FieldSize:=0; end;
      SQL_BINARY:        begin FieldType:=ftBytes;      FieldSize:=ColumnSize; end;
      SQL_VARBINARY:     begin FieldType:=ftVarBytes;   FieldSize:=ColumnSize; end;
      SQL_LONGVARBINARY: begin FieldType:=ftBlob;       FieldSize:=ColumnSize; end;
      SQL_TYPE_DATE:     begin FieldType:=ftDate;       FieldSize:=0; end;
      SQL_TYPE_TIME:     begin FieldType:=ftTime;       FieldSize:=0; end;
      SQL_TYPE_TIMESTAMP:begin FieldType:=ftTimeStamp;  FieldSize:=0; end;
{      SQL_TYPE_UTCDATETIME:FieldType:=ftUnknown;}
{      SQL_TYPE_UTCTIME:   FieldType:=ftUnknown; }
{      SQL_INTERVAL_MONTH:           FieldType:=ftUnknown;}
{      SQL_INTERVAL_YEAR:            FieldType:=ftUnknown;}
{      SQL_INTERVAL_YEAR_TO_MONTH:   FieldType:=ftUnknown;}
{      SQL_INTERVAL_DAY:             FieldType:=ftUnknown;}
{      SQL_INTERVAL_HOUR:            FieldType:=ftUnknown;}
{      SQL_INTERVAL_MINUTE:          FieldType:=ftUnknown;}
{      SQL_INTERVAL_SECOND:          FieldType:=ftUnknown;}
{      SQL_INTERVAL_DAY_TO_HOUR:     FieldType:=ftUnknown;}
{      SQL_INTERVAL_DAY_TO_MINUTE:   FieldType:=ftUnknown;}
{      SQL_INTERVAL_DAY_TO_SECOND:   FieldType:=ftUnknown;}
{      SQL_INTERVAL_HOUR_TO_MINUTE:  FieldType:=ftUnknown;}
{      SQL_INTERVAL_HOUR_TO_SECOND:  FieldType:=ftUnknown;}
{      SQL_INTERVAL_MINUTE_TO_SECOND:FieldType:=ftUnknown;}
{      SQL_GUID:          begin FieldType:=ftGuid;       FieldSize:=ColumnSize; end; } // no TGuidField exists yet in the db unit
    else
      begin FieldType:=ftUnknown; FieldSize:=ColumnSize; end
    end;

    // add FieldDef
    TFieldDef.Create(FieldDefs, ColName, FieldType, FieldSize, False, i);
  end;
end;

procedure TODBCConnection.UpdateIndexDefs(var IndexDefs: TIndexDefs; TableName: string);
begin
  inherited UpdateIndexDefs(IndexDefs, TableName);
  // TODO: implement this
end;

function TODBCConnection.GetSchemaInfoSQL(SchemaType: TSchemaType; SchemaObjectName, SchemaObjectPattern: string): string;
begin
  Result:=inherited GetSchemaInfoSQL(SchemaType, SchemaObjectName, SchemaObjectPattern);
  // TODO: implement this
end;

{ TODBCEnvironment }

constructor TODBCEnvironment.Create;
begin
  // make sure odbc is loaded
  if ODBCLoadCount=0 then LoadOdbc;
  Inc(ODBCLoadCount);

  // allocate environment handle
  if SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, FENVHandle)=SQL_Error then
    raise EODBCException.Create('Could not allocate ODBC Environment handle'); // we can't retrieve any more information, because we don't have a handle for the SQLGetDiag* functions

  // set odbc version
  SQLSetEnvAttr(FENVHandle, SQL_ATTR_ODBC_VERSION, SQLPOINTER(SQL_OV_ODBC3), 0);
  ODBCCheckResult(SQL_HANDLE_ENV, FENVHandle,'Could not set ODBC version to 3.');
end;

destructor TODBCEnvironment.Destroy;
begin
  // free environment handle
  if SQLFreeHandle(SQL_HANDLE_ENV, FENVHandle)=SQL_ERROR then
    ODBCCheckResult(SQL_HANDLE_ENV, FENVHandle, 'Could not free ODBC Environment handle.');

  // free odbc if not used by any TODBCEnvironment object anymore
  Dec(ODBCLoadCount);
  if ODBCLoadCount=0 then UnLoadOdbc;
end;

{ TODBCCursor }

constructor TODBCCursor.Create(Connection:TODBCConnection);
begin
  // allocate statement handle
  SQLAllocHandle(SQL_HANDLE_STMT, Connection.FDBCHandle, FSTMTHandle);
  ODBCCheckResult(SQL_HANDLE_DBC, Connection.FDBCHandle, 'Could not allocate ODBC Statement handle.');
end;

destructor TODBCCursor.Destroy;
begin
  inherited Destroy;

  // deallocate statement handle
  if SQLFreeHandle(SQL_HANDLE_STMT, FSTMTHandle)=SQL_ERROR then
    ODBCCheckResult(SQL_HANDLE_STMT, FSTMTHandle, 'Could not free ODBC Statement handle.');
end;

{ finalization }

finalization

  if Assigned(DefaultEnvironment) then
    DefaultEnvironment.Free;

end.

