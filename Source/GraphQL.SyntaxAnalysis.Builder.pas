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
unit GraphQL.SyntaxAnalysis.Builder;

interface

uses
  System.Classes, System.SysUtils, System.Rtti,
  GraphQL.Core, GraphQL.Classes, GraphQL.Lexer.Core, GraphQL.SyntaxAnalysis.Core;

type
  TGraphQLBuilder = class(TSyntaxAnalysis)
  private
    FOwnsScanner: Boolean;

    { Rules }
    function ArgumentStamement: IGraphQLArgument;
    procedure ArgumentsStatement(AArguments: IGraphQLArguments);
    function FieldStatement(AParentField: IGraphQLField): IGraphQLField;
    function ObjectStatement(AParentField: IGraphQLField): IGraphQLObject;
    procedure Query(AGraphQL: IGraphQL);
    procedure GraphQL(AGraphQL: IGraphQL);
  public
    function Build: IGraphQL;
    constructor Create(const ASourceCode :string); reintroduce;
    destructor Destroy; override;
  end;

implementation

{ TSyntaxAnalysis }

// arguments = '(' argument [ ',' argument [...] ] } '}'
procedure TGraphQLBuilder.ArgumentsStatement(AArguments: IGraphQLArguments);
begin
  Expect(TTokenKind.LeftParenthesis);

  AArguments.Add(ArgumentStamement);
  while FToken.Kind = TTokenKind.Comma do
  begin
    NextToken;
    AArguments.Add(ArgumentStamement);
  end;

  Expect(TTokenKind.RightParenthesis);
end;

// argument = identified : ( string | number | identifier )
function TGraphQLBuilder.ArgumentStamement: IGraphQLArgument;
var
  LName: string;
  LValue: TValue;
begin
  Expect(TTokenKind.Identifier, False);
  LName := FToken.StringValue;
  NextToken;

  Expect(TTokenKind.Colon);

  case FToken.Kind of
    TTokenKind.StringLiteral: LValue := FToken.StringValue;
    TTokenKind.IntegerLiteral: LValue := FToken.IntegerValue;
    TTokenKind.FloatLiteral: LValue := FToken.FloatValue;
    TTokenKind.Identifier: begin
      if FToken.StringValue = 'true' then
        LValue := True
      else if FToken.StringValue = 'false' then
        LValue := False
      else
        LValue := FToken.StringValue;
    end
    else
      raise ESyntaxError.Create('String or number expected', FToken.LineNumber, FToken.ColumnNumber);

  end;

  NextToken;

  Result := TGraphQLArgument.Create(LName, LValue);
end;

function TGraphQLBuilder.Build: IGraphQL;
begin
  inherited;
  Result := TGraphQL.Create;
  GraphQL(Result);
end;

constructor TGraphQLBuilder.Create(const ASourceCode: string);
begin
  inherited Create(TScanner.CreateFromString(ASourceCode));
  FOwnsScanner := True;
end;

destructor TGraphQLBuilder.Destroy;
begin
  if FOwnsScanner then
    FScanner.Free;
  inherited;
end;

// field = [alias ':' ] fieldname [ arguments ] [object]
function TGraphQLBuilder.FieldStatement(AParentField: IGraphQLField): IGraphQLField;
var
  LFieldName: string;
  LFieldAlias: string;
  LValue: IGraphQLValue;
  LArguments: IGraphQLArguments;
  LGraphQLField: TGraphQLField;
begin
  Expect(TTokenKind.Identifier, False);

  LFieldName := FToken.StringValue;
  LFieldAlias := LFieldName;

  NextToken;

  if FToken.Kind = TTokenKind.Colon then
  begin
    NextToken;
    LFieldName := FToken.StringValue;
    NextToken;
  end;

  LArguments := TGraphQLArguments.Create;
  if FToken.Kind = TTokenKind.LeftParenthesis then
    ArgumentsStatement(LArguments);

  LGraphQLField := TGraphQLField.Create(AParentField, LFieldName, LFieldAlias, LArguments);
  try

    if FToken.Kind = TTokenKind.LeftCurlyBracket then
      LValue := ObjectStatement(LGraphQLField as IGraphQLField)
    else
      LValue := TGraphQLNull.Create;

    LGraphQLField.SetValue(LValue);

  except
    LGraphQLField.Free;
    raise;
  end;
  Result := LGraphQLField;
end;

// GraphQL = 'query' queryname query | query
procedure TGraphQLBuilder.GraphQL(AGraphQL: IGraphQL);
begin
  NextToken;

  if FToken.IsIdentifier('query') then
  begin
    NextToken;
    if not FToken.IsIdentifier then
      raise ESyntaxError.Create('Identifier expected', FToken.LineNumber, FToken.ColumnNumber);

    AGraphQL.Name := FToken.StringValue;
    NextToken;
    Query(AGraphQL);
  end
  else
  begin
    AGraphQL.Name := 'Anonymous';
    Query(AGraphQL);
  end;

end;

// object = '{' { field [,] } '}'
function TGraphQLBuilder.ObjectStatement(AParentField: IGraphQLField): IGraphQLObject;
var
  LValue: TGraphQLObject;
begin
  Expect(TTokenKind.LeftCurlyBracket);

  LValue := TGraphQLObject.Create;
  Result := LValue;

  repeat
    LValue.Add(FieldStatement(AParentField));
    if FToken.Kind = TTokenKind.Comma then
      NextToken;

  until FToken.Kind = TTokenKind.RightCurlyBracket;

  Expect(TTokenKind.RightCurlyBracket);
end;

// query = '{' objectpair [ [','] objectpair [ [','] objectpair ] ] '}'
procedure TGraphQLBuilder.Query(AGraphQL: IGraphQL);
var
  LField: IGraphQLField;
begin
  Expect(TTokenKind.LeftCurlyBracket);

  repeat
    LField := FieldStatement(nil);
    AGraphQL.AddField(LField);

    if FToken.Kind = TTokenKind.Comma then
      NextToken;

  until FToken.Kind = TTokenKind.RightCurlyBracket;

  Expect(TTokenKind.RightCurlyBracket);
end;

end.
