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
unit GraphQL.SyntaxAnalysis.Core;

interface

uses
  System.Classes, System.SysUtils, System.Rtti, Generics.Collections,
  GraphQL.Lexer.Core;

type
  ESyntaxError = class(Exception)
  private
    FCol: Integer;
    FLine: Integer;
  public
    property Line: Integer read FLine;
    property Col: Integer read FCol;
    constructor Create(const AMessage: string; ALine, ACol: Integer);
  end;

  TReadTokenEvent = procedure (ASender: TObject; AToken: TToken) of object;

  TSyntaxAnalysis = class(TObject)
  private
    FTokenQueue: TQueue<TToken>;
    FOnReadToken: TReadTokenEvent;
  protected
    FScanner: TScanner;
    FToken: TToken;
    procedure Expect(ATokenKind: TTokenKind; MoveNext: Boolean = True);
    procedure NextToken; virtual;
    function Lookahead: TToken; virtual;
  public
    property OnReadToken: TReadTokenEvent read FOnReadToken write FOnReadToken;

    constructor Create(AScanner: TScanner); virtual;
    destructor Destroy; override;
  end;

implementation

{ ESyntaxError }

constructor ESyntaxError.Create(const AMessage: string; ALine, ACol: Integer);
begin
  FLine := ALine;
  FCol := ACol;
  inherited CreateFmt(AMessage + ' at line %d', [ALine]);
end;

{ TSyntaxAnalysis }

constructor TSyntaxAnalysis.Create(AScanner: TScanner);
begin
  inherited Create;
  FScanner := AScanner;
  FTokenQueue := TQueue<TToken>.Create;
end;

procedure TSyntaxAnalysis.NextToken;
begin
  if FTokenQueue.Count > 0 then
    FToken := FTokenQueue.Dequeue
  else
    FToken := FScanner.NextToken;

  if Assigned(FOnReadToken) then
    FOnReadToken(Self, FToken);
end;

function TSyntaxAnalysis.Lookahead: TToken;
begin
  Result := FScanner.NextToken;
  FTokenQueue.Enqueue(Result);
end;

destructor TSyntaxAnalysis.Destroy;
begin
  FTokenQueue.Free;
  inherited;
end;

procedure TSyntaxAnalysis.Expect(ATokenKind: TTokenKind; MoveNext: Boolean);
begin
  if ATokenKind <> FToken.Kind then
    raise ESyntaxError.Create(
      Format('Expected [%s] but found [%s]', [KindToString(ATokenKind), KindToString(FToken.Kind)]),
      FToken.LineNumber,
      FToken.ColumnNumber
    );
  if MoveNext then
    NextToken;
end;

end.
