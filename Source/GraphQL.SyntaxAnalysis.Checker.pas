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
unit GraphQL.SyntaxAnalysis.Checker;

interface

uses
  System.Classes, System.SysUtils, System.Rtti,
  GraphQL.Lexer.Core, GraphQL.SyntaxAnalysis.Core;

type
  TSyntaxChecker = class(TSyntaxAnalysis)
  private
    { Rules }
    procedure ArgumentStamement;
    procedure ArgumentsStatement;
    procedure FieldStatement;
    procedure NodeStatement;
    procedure ObjectStatement;
    procedure Query;
    procedure GraphQL;
  public
    procedure Execute;
  end;

implementation

{ TSyntaxAnalysis }

// arguments = '(' argument [ ',' argument [...] ] } '}'
procedure TSyntaxChecker.ArgumentsStatement;
begin
  Expect(TTokenKind.LeftParenthesis);

  ArgumentStamement;
  while FToken.Kind = TTokenKind.Comma do
    ArgumentStamement;

  Expect(TTokenKind.RightParenthesis);
end;

// argument = identified : ( string | number | identifier )
procedure TSyntaxChecker.ArgumentStamement;
begin
  Expect(TTokenKind.Identifier);
  Expect(TTokenKind.Colon);

  if (FToken.Kind <> TTokenKind.StringLiteral) and
     (FToken.Kind <> TTokenKind.IntegerLiteral) and
     (FToken.Kind <> TTokenKind.FloatLiteral) and
     (FToken.Kind <> TTokenKind.Identifier)
  then
    raise ESyntaxError.Create('String or number expected', FToken.LineNumber, FToken.ColumnNumber);

  NextToken;
end;

procedure TSyntaxChecker.Execute;
begin
  inherited;
  GraphQL;
end;

// field = fieldname [ arguments ]
procedure TSyntaxChecker.FieldStatement;
begin
  Expect(TTokenKind.Identifier);
  if FToken.Kind = TTokenKind.LeftParenthesis then
    ArgumentsStatement;
end;

// GraphQL = 'query' queryname query | query
procedure TSyntaxChecker.GraphQL;
begin
  NextToken;

  if FToken.IsIdentifier('query') then
  begin
    NextToken;
    if not FToken.IsIdentifier then
      raise ESyntaxError.Create('Identifier expected', FToken.LineNumber, FToken.ColumnNumber);

    NextToken;
    Query;
  end
  else
  begin
    Query;
  end;

end;

// node = object | field
procedure TSyntaxChecker.NodeStatement;
begin
  if FToken.Kind = TTokenKind.LeftCurleyBracket then
    ObjectStatement
  else
    FieldStatement;
end;

// object = '{' { node } '}'
procedure TSyntaxChecker.ObjectStatement;
begin
  Expect(TTokenKind.LeftCurleyBracket);

  repeat
    NodeStatement;
  until FToken.Kind = TTokenKind.RightCurleyBracket;

  Expect(TTokenKind.RightCurleyBracket);
end;

// query = '{' field object '}'
procedure TSyntaxChecker.Query;
begin
  Expect(TTokenKind.LeftCurleyBracket);

  FieldStatement;

  ObjectStatement;

  Expect(TTokenKind.RightCurleyBracket);
end;

end.
