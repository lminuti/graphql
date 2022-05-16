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
unit GraphQL.Resolver.Core;

interface

uses
  System.Classes, System.SysUtils, System.Rtti, System.JSON, Generics.Collections;

type
  TGraphQLParams = record
  private
    FFieldName: string;
    FParams: TDictionary<string, TValue>;
    FParent: TJSONObject;
  public
    function Get(const AName: string): TValue;
    function Exists(const AName: string): Boolean;
    function Count: Integer;
    function GetEnumerator: TDictionary<string, TValue>.TPairEnumerator;

    property FieldName: string read FFieldName;
    property Parent: TJSONObject read FParent;

    constructor Create(const AFieldName: string; AParams: TDictionary<string, TValue>; AParent: TJSONObject);
  end;

  IGraphQLResolver = interface
    ['{31891A84-FC2B-479A-8D35-8E5EDD3CC359}']
    function Resolve(AParams: TGraphQLParams): TValue;
  end;

  IGraphQLVariables = interface
    ['{6DF8CDD1-B969-49AD-96EC-F555A08C9576}']
    procedure Clear;
    function SetVariable(const AName: string; AValue: TValue): IGraphQLVariables;
    function GetVariable(const AName: string): TValue;
    function VariableExists(const AName: string): Boolean;
  end;

  TGraphQLVariables = class(TInterfacedObject, IGraphQLVariables)
  private
    FVariables: TDictionary<string,TValue>;
    procedure Clear;
    function SetVariable(const AName: string; AValue: TValue): IGraphQLVariables;
    function GetVariable(const AName: string): TValue;
    function VariableExists(const AName: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TGraphQLParams }

function TGraphQLParams.Count: Integer;
begin
  Result := FParams.Count;
end;

constructor TGraphQLParams.Create(const AFieldName: string;
  AParams: TDictionary<string, TValue>; AParent: TJSONObject);
begin
  FFieldName := AFieldName;
  FParams := AParams;
  FParent := AParent;
end;

function TGraphQLParams.Exists(const AName: string): Boolean;
begin
  Result := FParams.ContainsKey(AName);
end;

function TGraphQLParams.Get(const AName: string): TValue;
begin
  Result := FParams.Items[AName];
end;

function TGraphQLParams.GetEnumerator: TDictionary<string, TValue>.TPairEnumerator;
begin
  Result := FParams.GetEnumerator;
end;

{ TGraphQLVariables }

procedure TGraphQLVariables.Clear;
begin
  FVariables.Clear;
end;

constructor TGraphQLVariables.Create;
begin
  inherited;
  FVariables := TDictionary<string,TValue>.Create;
end;

destructor TGraphQLVariables.Destroy;
begin
  FVariables.Free;
  inherited;
end;

function TGraphQLVariables.GetVariable(const AName: string): TValue;
begin
  Result := FVariables[AName];
end;

function TGraphQLVariables.SetVariable(const AName: string;
  AValue: TValue): IGraphQLVariables;
begin
  FVariables.AddOrSetValue(AName, AValue);
  Result := Self;
end;

function TGraphQLVariables.VariableExists(const AName: string): Boolean;
begin
  Result := FVariables.ContainsKey(AName);
end;

end.
