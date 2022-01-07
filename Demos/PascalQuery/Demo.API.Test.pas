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
unit Demo.API.Test;

interface

uses
  System.Classes, System.SysUtils, System.StrUtils;

type
  TStarWarsHero = class;

  TStarWarsHeros = TArray<TStarWarsHero>;

  TStarWarsHero = class(TObject)
  private
    FName: string;
    FHeight: Double;
    FFriends: TStarWarsHeros;
  public
    property Name: string read FName write FName;
    property Height: Double read FHeight write FHeight;
    property Friends: TStarWarsHeros read FFriends;

    procedure AddFriend(AHero: TStarWarsHero);

    constructor Create(const AName: string; AHeight: Double);
    destructor Destroy; override;
  end;

function RollDice(NumDices, NumSides: Integer): Integer;

function ReverseString(const Value: string): string;

function StarWarsHero(const Id: string): TStarWarsHero;

implementation

function RollDice(NumDices, NumSides: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to NumDices - 1 do
    Result := Result + (Random(NumSides) + 1);
end;

function ReverseString(const Value: string): string;
begin
  Result := System.StrUtils.ReverseString(Value);
end;

function StarWarsHero(const Id: string): TStarWarsHero;
begin
  if Id = '1000' then
  begin
    Result := TStarWarsHero.Create('Luke Skywalker', 1.72);
    Result.AddFriend(TStarWarsHero.Create('Han Solo', 1.8));
    Result.AddFriend(TStarWarsHero.Create('R2-D2', 1.08));
  end
  else if Id = '1001' then
    Result := TStarWarsHero.Create('Han Solo', 1.8)
  else if Id = '1002' then
    Result := TStarWarsHero.Create('Leia Organa', 1.55)
  else if Id = '1003' then
    Result := TStarWarsHero.Create('R2-D2', 1.08)
  else if Id = '1004' then
    Result := TStarWarsHero.Create('Darth Sidious', 1.73)
  else
    raise Exception.CreateFmt('Hero [%s] not found', [Id]);
end;

{ TStarWarsHero }

procedure TStarWarsHero.AddFriend(AHero: TStarWarsHero);
var
  LIndex: Integer;
begin
  LIndex := Length(FFriends);
  SetLength(FFriends, LIndex + 1);
  FFriends[LIndex] := AHero;
end;

constructor TStarWarsHero.Create(const AName: string; AHeight: Double);
begin
  inherited Create;

//  FFriends := TStarWarsHeros.Create;
  FName := AName;
  FHeight := AHeight;
end;

destructor TStarWarsHero.Destroy;
var
  LHero: TStarWarsHero;
begin
  for LHero in FFriends do
    LHero.Free;
  inherited;
end;

end.
