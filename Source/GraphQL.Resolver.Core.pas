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

end.
