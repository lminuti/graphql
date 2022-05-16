{******************************************************************************}
{                                                                              }
{  Delphi GraphQL                                                              }
{  Copyright (c) 2022 Luca Minuti                                              }
{  https://github.com/lminuti/graphql                                          }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit GraphQL.Lexer.Core;

interface

uses
  System.Classes, System.SysUtils, System.Math, Generics.Collections;

type
  {$SCOPEDENUMS ON}
  TTokenKind = (
    EndOfStream,
    StringLiteral,
    IntegerLiteral,
    FloatLiteral,
    Identifier,
    Plus,
    Minus,
    Mult,
    Divide,
    Power,
    Assignment,
    Semicolon,
    Colon,
    LeftParenthesis,
    RightParenthesis,
    LeftSquareBracket,
    RightSquareBracket,
    LeftCurlyBracket,
    RightCurlyBracket,
    Comma,
    Ellipsis,
    Variable,
    Directive,
    KeywordFalse,
    KeywordTrue,
    Equivalence,
    NotEqual,
    LessThan,
    LessThanOrEqual,
    GreaterThan,
    GreaterThanOrEqual,
    IdentifierNot,
    BinaryAnd,
    LogicalAnd,
    BinaryOr,
    LogicalOr,
    Dollar
  );
  {$SCOPEDENUMS OFF}

  EScannerError = class(Exception)
  private
    FCol: Integer;
    FLine: Integer;
  public
    property Line: Integer read FLine;
    property Col: Integer read FCol;
    constructor Create(const AMessage: string; ALine, ACol: Integer);
  end;

  TToken = record
    LineNumber: Integer;
    ColumnNumber: Integer;
    Kind: TTokenKind;
    StringValue: string;
    FloatValue: Double;
    IntegerValue: Integer;
    function ToString: string;
    function IsIdentifier(const Value: string = ''): Boolean;
  end;

  TBufferReader = class(TObject)
  strict private
    FStreamReader: TStreamReader;
    FColumnNumber: Integer;
    FLineNumber: Integer;
    FBuffer: string;
    FBufferIndex: Integer;
    function ReadRawChar: Char;
    procedure StartScan;
  public
    const EOF_CHAR = #$ffff;
    const CR = #$0d;
    const LF = #$0a;
    const TAB = #$09;

    function ReadChar: Char;
    function ReadNextChar(Position: Integer = 1): Char;

    property ColumnNumber: Integer read FColumnNumber;
    property LineNumber: Integer read FLineNumber;

    constructor Create(AStream: TStream; AEncoding: TEncoding; AOwnStream: Boolean);
    destructor Destroy; override;
  end;

  TScanner = class(TObject)
  private
    FBufferReader: TBufferReader;
    FCurrentChar: Char;
    FKeywords: TDictionary<string, TTokenKind>;

    procedure InitKeywords;
    function IsKeyword(const AIdentifier: string; out ATokenKind: TTokenKind): Boolean;

    procedure SkipBlankAndComment;
    procedure SkipSingleLineComment;

    function GetWord: TToken;
    function GetString: TToken;
    function GetNumber: TToken;
    function GetSpecial: TToken;
    function GetDirective: TToken;
    function GetVariable: TToken;
    function GetEllipsis: TToken;
  public
    function NextToken: TToken;

    constructor CreateFromFile(const AFileName: TFileName; AEncoding: TEncoding);
    constructor CreateFromString(const AValue: string);
    constructor CreateFromStream(AStream: TStream; AEncoding: TEncoding; AOwnStream: Boolean);
    destructor Destroy; override;
  end;

function KindToString(Kind: TTokenKind): string;

implementation

{ Utils }

const
  MAX_EXPONENT = 308;

function KindToString(Kind: TTokenKind): string;
const
  KindStr: array [TTokenKind] of string = (
    'EOF',                 //  EndOfStream,
    'String',              //  StringLiteral,
    'Integer',             //  IntegerLiteral,
    'Double',              //  FloatLiteral,
    'Identifier',          //  Identifier,
    'Plus',                //  Plus,
    'Minus',               //  Minus,
    'Mult',                //  Mult,
    'Divide',              //  Divide,
    'Power',               //  Power,
    'Assignment',          //  Assignment,
    'Semicolon',           //  Semicolon,
    'Colon',               //  Colon,
    'LeftParenthesis',     //  LeftParenthesis,
    'RightParenthesis',    //  RightParenthesis,
    'LeftSquareBracket',   //  LeftSquareBracket,
    'RightSquareBracket',  //  RightSquareBracket,
    'LeftCurlyBracket',    //  LeftCurlyBracket,
    'RightCurlyBracket',   //  RightCurlyBracket,
    'Comma',               //  Comma,
    'Ellipsis',            //  Ellipsis,
    'Variable',            //  Variable,
    'Directive',           //  Directive,
    'KeywordFalse',        //  KeywordFalse,
    'KeywordTrue',         //  KeywordTrue,
    'Equivalence',         //  Equivalence,
    'NotEqual',            //  NotEqual,
    'LessThan',            //  LessThan,
    'LessThanOrEqual',     //  LessThanOrEqual,
    'GreaterThan',         //  GreaterThan,
    'GreaterThanOrEqual',  //  GreaterThanOrEqual,
    'Not',                 //  IdentifierNot,
    'BinaryAnd',           //  BinaryAnd,
    'LogicalAnd',          //  LogicalAnd,
    'BinaryOr',            //  BinaryOr,
    'LogicalOr',           //  LogicalOr
    'Dollar'               //  Dollar
  );
begin
  Result := KindStr[Kind];
end;

function KindToType(Kind: TTokenKind): Integer;
const
  KindType: array [TTokenKind] of Integer = (
    varUnknown,           //  EndOfStream,
    varUString,           //  StringLiteral,
    varInteger,           //  IntegerLiteral,
    varDouble,            //  FloatLiteral,
    varUString,           //  Identifier,
    varUnknown,           //  Plus,
    varUnknown,           //  Minus,
    varUnknown,           //  Mult,
    varUnknown,           //  Divide,
    varUnknown,           //  Power,
    varUnknown,           //  Assignment,
    varUnknown,           //  Semicolon,
    varUnknown,           //  Colon,
    varUnknown,           //  LeftParenthesis,
    varUnknown,           //  RightParenthesis,
    varUnknown,           //  LeftSquareBracket,
    varUnknown,           //  RightSquareBracket,
    varUnknown,           //  LeftCurlyBracket,
    varUnknown,           //  RightCurlyBracket,
    varUnknown,           //  Comma,
    varUnknown,           //  Ellipsis,
    varUString,           //  Variable,
    varUString,           //  Directive,
    varUString,           //  KeywordFalse,
    varUString,           //  KeywordTrue,
    varUnknown,           //  Equivalence,
    varUnknown,           //  NotEqual,
    varUnknown,           //  LessThan,
    varUnknown,           //  LessThanOrEqual,
    varUnknown,           //  GreaterThan,
    varUnknown,           //  GreaterThanOrEqual,
    varUnknown,           //  IdentifierNot,
    varUnknown,           //  BinaryAnd,
    varUnknown,           //  LogicalAnd,
    varUnknown,           //  BinaryOr,
    varUnknown,           //  LogicalOr
    varUnknown            //  Dollar
  );
begin
  Result := KindType[Kind];
end;

function IsBlank(const AChar: Char): Boolean; inline;
begin
  Result := CharInSet(AChar, [' ', TBufferReader.TAB, TBufferReader.CR, TBufferReader.LF]);
end;

function IsLetter(const AChar: Char): Boolean; inline;
begin
  Result := CharInSet(AChar, ['a'..'z', 'A'..'Z', '_']);
end;

function IsDigit(const AChar: Char): Boolean; inline;
begin
  Result := CharInSet(AChar, ['0'..'9', '.']);
end;

function IsInteger(const AChar: Char): Boolean; inline;
begin
  Result := CharInSet(AChar, ['0'..'9']);
end;

function IsEof(const AChar: Char): Boolean; inline;
begin
  Result := AChar = TBufferReader.EOF_CHAR;
end;

{ TBufferReader }

destructor TBufferReader.Destroy;
begin
  FreeAndNil(FStreamReader);
  inherited;
end;

function TBufferReader.ReadChar: Char;
begin
  if FBufferIndex > 0 then
  begin
    Dec(FBufferIndex);
    Exit(FBuffer[FBufferIndex + 1]);
  end;

  Result := ReadRawChar;
  if Result = LF then
  begin
    Inc(FLineNumber);
    FColumnNumber := 0;
    //Result := ' ';
  end;
end;

function TBufferReader.ReadNextChar(Position: Integer = 1): Char;
begin
  Result := EOF_CHAR;
  SetLength(FBuffer, FBufferIndex);
  while Position > 0 do
  begin
    Result := ReadChar;
    FBuffer := FBuffer + Result;
    Inc(FBufferIndex);
    Dec(Position);
  end;
end;

function TBufferReader.ReadRawChar: Char;

  function InternalReadChar: Char;
  begin
    if not Assigned(FStreamReader) then
    begin
      Exit(EOF_CHAR);
    end;

    if FStreamReader.EndOfStream then
    begin
      FreeAndNil(FStreamReader);
      Exit(EOF_CHAR);
    end;

    Inc(FColumnNumber);
    Result := Char(FStreamReader.Read);
  end;

var
  LCurrentChar: Char;
begin
  LCurrentChar := InternalReadChar;
  if (LCurrentChar = CR) or (LCurrentChar = LF) then
  begin
    if LCurrentChar = CR then
    begin
      LCurrentChar := InternalReadChar;
      if LCurrentChar = LF then
        Exit(LCurrentChar);
      raise EScannerError.Create('Expecting line feed character', FLineNumber, FColumnNumber);
    end;
    Exit(LCurrentChar);
  end
  else
    Result := LCurrentChar;
end;

constructor TBufferReader.Create(AStream: TStream; AEncoding: TEncoding; AOwnStream: Boolean);
begin
  FStreamReader := TStreamReader.Create(AStream, AEncoding);
  if AOwnStream then
    FStreamReader.OwnStream;

  StartScan;
end;

procedure TBufferReader.StartScan;
begin
  FLineNumber := 1;
  FColumnNumber := 0;
end;

{ TScanner }

destructor TScanner.Destroy;
begin
  FKeywords.Free;
  FBufferReader.Free;
  inherited;
end;

function TScanner.GetNumber: TToken;
var
  HasLeftSide, HasRightSide: Boolean;
  SingleDigit: Integer;
  Scale: Double;
  ExponentSign: Integer;
  Evalue: Integer;
begin
  HasLeftSide := False;
  HasRightSide := False;

  Result.IntegerValue := 0;
  Result.FloatValue := 0.0;

  Result.Kind := TTokenKind.IntegerLiteral;

  if FCurrentChar <> '.' then
  begin
    HasLeftSide := True;
    repeat
      SingleDigit := Ord(FCurrentChar) - Ord('0');
      if Result.IntegerValue > (MaxInt - SingleDigit) div 10 then
        raise EScannerError.Create('Integer overflow', FBufferReader.LineNumber, FBufferReader.ColumnNumber);

      Result.IntegerValue := 10 * Result.IntegerValue + SingleDigit;
      FCurrentChar := FBufferReader.ReadChar;

    until not IsInteger(FCurrentChar);
  end;

  Scale := 1;
  if FCurrentChar = '.' then
  begin
    Result.Kind := TTokenKind.FloatLiteral;
    Result.FloatValue := Result.IntegerValue;
    FCurrentChar := FBufferReader.ReadChar;
    if IsInteger(FCurrentChar) then
      HasRightSide := True;
    while IsDigit(FCurrentChar) do
    begin
      Scale := Scale * 0.1;
      SingleDigit := Ord(FCurrentChar) - Ord('0');
      Result.FloatValue := Result.FloatValue + (SingleDigit * Scale);
      FCurrentChar := FBufferReader.ReadChar;
    end;

  end;

  if (not HasLeftSide) and (not HasRightSide) then
    raise EScannerError.Create('Invalid number', FBufferReader.LineNumber, FBufferReader.ColumnNumber);

  ExponentSign := 1;
  // Next check for scientific notation
  if (FCurrentChar = 'e') or (FCurrentChar = 'E') then
  begin
    // Then it's a float. Start collecting exponent part
    if Result.Kind = TTokenKind.IntegerLiteral then
    begin
      Result.Kind := TTokenKind.FloatLiteral;
      Result.FloatValue := Result.IntegerValue;
    end;
    FCurrentChar := FBufferReader.ReadChar;
    if (FCurrentChar = '-') or (FCurrentChar = '+') then
    begin
      if FCurrentChar = '-' then
        ExponentSign := -1;
      FCurrentChar := FBufferReader.ReadChar;
    end;

    // accumulate exponent, check that first ch is a digit
    if not IsDigit (FCurrentChar) then
      raise EScannerError.Create ('Number expected in exponent', FBufferReader.LineNumber, FBufferReader.ColumnNumber);

    Evalue := 0;
    repeat

      SingleDigit := Ord(FCurrentChar) - Ord('0');
      if Evalue > (MAX_EXPONENT - SingleDigit) div 10 then
        raise EScannerError.Create ('Exponent overflow, maximum value for exponent is ' + IntToStr(MAX_EXPONENT), FBufferReader.LineNumber, FBufferReader.ColumnNumber);

      Evalue := 10*evalue + singleDigit;
      FCurrentChar := FBufferReader.ReadChar;

    until not IsDigit(FCurrentChar);

    evalue := evalue * ExponentSign;
    if Result.Kind = TTokenKind.IntegerLiteral then
      Result.FloatValue := Result.IntegerValue * IntPower(10, Evalue)
    else
      Result.FloatValue := Result.FloatValue * Power(10.0, Evalue);

  end;

end;

function TScanner.GetSpecial: TToken;
begin
  case FCurrentChar of
    '&':
    begin
      if FBufferReader.ReadNextChar = '&' then
      begin
        Result.Kind := TTokenKind.LogicalAnd;
        FCurrentChar := FBufferReader.ReadChar;
      end
      else
        Result.Kind := TTokenKind.BinaryAnd;
    end;
    '|':
    begin
      if FBufferReader.ReadNextChar = '|' then
      begin
        Result.Kind := TTokenKind.LogicalOr;
        FCurrentChar := FBufferReader.ReadChar;
      end
      else
        Result.Kind := TTokenKind.BinaryOr;
    end;

    '>':
    begin
      if FBufferReader.ReadNextChar = '=' then
      begin
        Result.Kind := TTokenKind.GreaterThanOrEqual;
        FCurrentChar := FBufferReader.ReadChar;
      end
      else
        Result.Kind := TTokenKind.GreaterThan;
    end;
    '<':
    begin
      if FBufferReader.ReadNextChar = '=' then
      begin
        Result.Kind := TTokenKind.LessThanOrEqual;
        FCurrentChar := FBufferReader.ReadChar;
      end
      else
        Result.Kind := TTokenKind.LessThan;
    end;
    '!':
    begin
      if FBufferReader.ReadNextChar = '=' then
      begin
        Result.Kind := TTokenKind.NotEqual;
        FCurrentChar := FBufferReader.ReadChar;
      end
      else
        Result.Kind := TTokenKind.IdentifierNot;
    end;
    '+': Result.Kind := TTokenKind.Plus;
    '-': Result.Kind := TTokenKind.Minus;
    '*': Result.Kind := TTokenKind.Mult;
    '/': Result.Kind := TTokenKind.Divide;
    '^': Result.Kind := TTokenKind.Power;
    '=':
    begin
      if FBufferReader.ReadNextChar = '=' then
      begin
        Result.Kind := TTokenKind.Equivalence;
        FCurrentChar := FBufferReader.ReadChar;
      end
      else
        Result.Kind := TTokenKind.Assignment;
    end;
    ';': Result.Kind := TTokenKind.Semicolon;
    ':': Result.Kind := TTokenKind.Colon;
    '(': Result.Kind := TTokenKind.LeftParenthesis;
    ')': Result.Kind := TTokenKind.RightParenthesis;
    '[': Result.Kind := TTokenKind.LeftSquareBracket;
    ']': Result.Kind := TTokenKind.RightSquareBracket;
    '{': Result.Kind := TTokenKind.LeftCurlyBracket;
    '}': Result.Kind := TTokenKind.RightCurlyBracket;
    ',': Result.Kind := TTokenKind.Comma;
    '$': Result.Kind := TTokenKind.Dollar;
    else
      raise EScannerError.Create(Format('Invalid symbol "%s"', [FCurrentChar]), FBufferReader.LineNumber, FBufferReader.ColumnNumber);
  end;
  FCurrentChar := FBufferReader.ReadChar;
end;

function TScanner.GetString: TToken;
begin
  Result.Kind := TTokenKind.StringLiteral;
  Result.StringValue := '';

  FCurrentChar := FBufferReader.ReadChar;
  while not IsEof(FCurrentChar) do
  begin
    if FCurrentChar = '"' then
    begin
      FCurrentChar := FBufferReader.ReadChar;
      Exit;
    end;
    if FCurrentChar = '\' then
    begin
      FCurrentChar := FBufferReader.ReadChar;
      case FCurrentChar of
        '\': Result.StringValue := Result.StringValue + '\';
        'n': Result.StringValue := Result.StringValue + sLineBreak;
        'r': Result.StringValue := Result.StringValue + TBufferReader.CR;
        't': Result.StringValue := Result.StringValue + TBufferReader.TAB;
        else
          raise EScannerError.Create(Format('Invalid escape char [%s]', [FCurrentChar]), FBufferReader.LineNumber, FBufferReader.ColumnNumber);
      end;
    end
    else
      Result.StringValue := Result.StringValue + FCurrentChar;
    FCurrentChar := FBufferReader.ReadChar;
  end;
  raise EScannerError.Create('Unterminated string', FBufferReader.LineNumber, FBufferReader.ColumnNumber);
end;

function TScanner.GetWord: TToken;
var
  LTokenKind: TTokenKind;
begin
  Result.Kind := TTokenKind.Identifier;
  Result.StringValue := '';

  while IsDigit(FCurrentChar) or IsLetter(FCurrentChar) do
  begin
    Result.StringValue := Result.StringValue + FCurrentChar;
    FCurrentChar := FBufferReader.ReadChar;
  end;

  if IsKeyword(Result.StringValue, LTokenKind) then
    Result.Kind := LTokenKind;
end;

function TScanner.GetVariable: TToken;
var
  LTokenKind: TTokenKind;
begin
  Result.Kind := TTokenKind.Variable;
  Result.StringValue := '';

  FCurrentChar := FBufferReader.ReadChar;
  while IsDigit(FCurrentChar) or IsLetter(FCurrentChar) do
  begin
    Result.StringValue := Result.StringValue + FCurrentChar;
    FCurrentChar := FBufferReader.ReadChar;
  end;

  if IsKeyword(Result.StringValue, LTokenKind) then
    Result.Kind := LTokenKind;
end;

function TScanner.GetDirective: TToken;
var
  LTokenKind: TTokenKind;
begin
  Result.Kind := TTokenKind.Directive;
  Result.StringValue := '';

  FCurrentChar := FBufferReader.ReadChar;
  while IsDigit(FCurrentChar) or IsLetter(FCurrentChar) do
  begin
    Result.StringValue := Result.StringValue + FCurrentChar;
    FCurrentChar := FBufferReader.ReadChar;
  end;

  if IsKeyword(Result.StringValue, LTokenKind) then
    Result.Kind := LTokenKind;
end;

function TScanner.GetEllipsis: TToken;
begin
  Result.Kind := TTokenKind.Ellipsis;
  FCurrentChar := FBufferReader.ReadChar;
  FCurrentChar := FBufferReader.ReadChar;
  FCurrentChar := FBufferReader.ReadChar;
end;

procedure TScanner.InitKeywords;
begin
//  FKeywords.Add('true', TTokenKind.KeywordTrue);
//  FKeywords.Add('false', TTokenKind.KeywordFalse);
end;

function TScanner.IsKeyword(const AIdentifier: string; out ATokenKind: TTokenKind): Boolean;
begin
  Result := FKeywords.TryGetValue(AIdentifier, ATokenKind);
end;

constructor TScanner.CreateFromFile(const AFileName: TFileName; AEncoding: TEncoding);
begin
  CreateFromStream(TBufferedFileStream.Create(AFileName, fmOpenRead), AEncoding, True);
end;

constructor TScanner.CreateFromStream(AStream: TStream; AEncoding: TEncoding; AOwnStream: Boolean);
begin
  FBufferReader := TBufferReader.Create(AStream, AEncoding, AOwnStream);
  FKeywords := TDictionary<string, TTokenKind>.Create;
  InitKeywords;

  FCurrentChar := FBufferReader.ReadChar;
end;

constructor TScanner.CreateFromString(const AValue: string);
begin
  CreateFromStream(TStringStream.Create(AValue, TEncoding.UTF8), TEncoding.UTF8, True);
end;

procedure TScanner.SkipBlankAndComment;
begin
  while IsBlank(FCurrentChar) or (FCurrentChar = '#') do
  begin
    if IsBlank(FCurrentChar) then
    begin
      FCurrentChar := FBufferReader.ReadChar;
    end
    else if FCurrentChar = '#' then
    begin
      SkipSingleLineComment;
    end;
  end;
end;

procedure TScanner.SkipSingleLineComment;
begin
  while (FCurrentChar <> TBufferReader.LF) and (not IsEof(FCurrentChar)) do
    FCurrentChar := FBufferReader.ReadChar;
  if not IsEof(FCurrentChar) then
    FCurrentChar := FBufferReader.ReadChar;
end;

function TScanner.NextToken: TToken;
begin
  if not Assigned(FBufferReader) then
    raise EScannerError.Create('Parsing not yet started', FBufferReader.LineNumber, FBufferReader.ColumnNumber);

  SkipBlankAndComment;

  Result.LineNumber := FBufferReader.LineNumber;
  Result.ColumnNumber := FBufferReader.ColumnNumber;

  if IsLetter(FCurrentChar) then
  begin
    Result := GetWord;
    Exit;
  end;

  if (FCurrentChar = '.') and (FBufferReader.ReadNextChar(1) = '.') and (FBufferReader.ReadNextChar(2) = '.') then
  begin
    Result := GetEllipsis;
    Exit;
  end;

  if IsDigit(FCurrentChar) then
  begin
    Result := GetNumber;
    Exit;
  end;

  if FCurrentChar = '"' then
  begin
    Result := GetString;
    Exit;
  end;

  if (FCurrentChar = '$') and (IsLetter(FBufferReader.ReadNextChar)) then
  begin
    Result := GetVariable;
    Exit;
  end;

  if (FCurrentChar = '@') and (IsLetter(FBufferReader.ReadNextChar)) then
  begin
    Result := GetDirective;
    Exit;
  end;

  if IsEof(FCurrentChar) then
  begin
    Result.Kind := TTokenKind.EndOfStream;
    Exit;
  end;

  Result := GetSpecial;
end;

{ TToken }

function TToken.IsIdentifier(const Value: string): Boolean;
begin
  Result := True;
  if Kind <> TTokenKind.Identifier then
    Exit(False);

  if Value <> '' then
    Exit(Value = StringValue);
end;

function TToken.ToString: string;
begin
  Result := '(' + KindToString(Kind) + ')';
  case KindToType(Kind) of
    varInteger: Result := Result + IntToStr(IntegerValue);
    varUString: Result := Result + StringValue;
    varDouble: Result := Result + FloatToStr(FloatValue);
  end;
end;

{ EScannerError }

constructor EScannerError.Create(const AMessage: string; ALine, ACol: Integer);
begin
  FLine := ALine;
  FCol := ACol;
  inherited CreateFmt(AMessage + ' at line %d', [ALine]);
end;

end.
