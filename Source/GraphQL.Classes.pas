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
unit GraphQL.Classes;

interface

uses
  System.Classes, System.SysUtils, System.Rtti, Generics.Collections,
  GraphQL.Core;

type
  TGraphQLFields = class(TList<IGraphQLField>)
  end;

  TGraphQLArguments = class(TList<IGraphQLArgument>, IGraphQLArguments)
  private
    FRefCount: Integer;
  public
    { IInterface }
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; stdcall;

    { IGraphQLArguments }
    procedure Add(AArgument: IGraphQLArgument);
    function Count: Integer;
    function GetArgument(AIndex: Integer): IGraphQLArgument;

    procedure AfterConstruction; override;
    property RefCount: Integer read FRefCount;

    class function NewInstance: TObject; override;
  end;

  TGraphQLArgument = class(TInterfacedObject, IGraphQLArgument)
  private
    FName: string;
    FValue: TValue;
  public
    { IGraphQLArgument }
    function GetName: string;
    function GetValue: TValue;

    constructor Create(const AName: string; AValue: TValue);
  end;

  TGraphQLObject = class(TInterfacedObject, IGraphQLObject, IGraphQLValue)
  private
    FFields: TGraphQLFields;
  public
    { IGraphQLObject }
    procedure Add(AField: IGraphQLField);
    function FieldCount: Integer;
    function GetField(AIndex: Integer): IGraphQLField;
    function GetFieldByName(const AName: string): IGraphQLField;
    function FindFieldByName(const AName: string): IGraphQLField;

    constructor Create;
    destructor Destroy; override;
  end;

  TGraphQLNull = class(TInterfacedObject, IGraphQLNull, IGraphQLValue)

  end;

  TGraphQLField = class(TInterfacedObject, IGraphQLField)
  private
    FFieldName: string;
    FFieldAlias: string;
    FValue: IGraphQLValue;
    FArguments: IGraphQLArguments;
    [unsafe]
    FParentField: IGraphQLField;
  public
    { IGraphQLField }
    function GetFieldName: string;
    function GetFieldAlias: string;
    function GetValue: IGraphQLValue;
    function GetArgument(AIndex: Integer): IGraphQLArgument;
    function ArgumentCount: Integer;
    function ArgumentByName(const AName: string): IGraphQLArgument;
    function GetParentField: IGraphQLField;

    procedure SetValue(AValue: IGraphQLValue);

    constructor Create(AParentField: IGraphQLField; const AFieldName, AFieldAlias: string; AArguments: IGraphQLArguments);
    destructor Destroy; override;
  end;

  TGraphQL = class(TInterfacedObject, IGraphQL)
  private
    FName: string;
    FFields: TGraphQLFields;
  public
    { IGraphQL }
    function GetName: string;
    procedure SetName(const AName: string);
    procedure AddField(AField: IGraphQLField);
    function FieldCount: Integer;
    function GetField(AIndex: Integer): IGraphQLField;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TGraphQL }

procedure TGraphQL.AddField(AField: IGraphQLField);
begin
  FFields.Add(AField);
end;

constructor TGraphQL.Create;
begin
  FFields := TGraphQLFields.Create();
end;

destructor TGraphQL.Destroy;
begin
  FFields.Free;
  inherited;
end;

function TGraphQL.FieldCount: Integer;
begin
  Result := FFields.Count;
end;

function TGraphQL.GetField(AIndex: Integer): IGraphQLField;
begin
  Result := FFields[AIndex];
end;

function TGraphQL.GetName: string;
begin
  Result := FName;
end;

procedure TGraphQL.SetName(const AName: string);
begin
  FName := AName;
end;

{ TGraphQLField }

function TGraphQLField.ArgumentByName(const AName: string): IGraphQLArgument;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FArguments.Count - 1 do
  begin
    if FArguments[LIndex].Name = AName then
      Exit(FArguments[LIndex]);
  end;
  raise EGraphQLArgumentNotFound.CreateFmt('Argument [%s] not found', [AName]);
end;

function TGraphQLField.ArgumentCount: Integer;
begin
  Result := FArguments.Count;
end;

constructor TGraphQLField.Create(AParentField: IGraphQLField; const AFieldName, AFieldAlias: string; AArguments: IGraphQLArguments);
begin
  inherited Create;
  if Assigned(AArguments) then
    FArguments := AArguments
  else
    FArguments := TGraphQLArguments.Create;
  FFieldName := AFieldName;
  FFieldAlias := AFieldAlias;
  FParentField := AParentField;
end;

destructor TGraphQLField.Destroy;
begin
  inherited;
end;

function TGraphQLField.GetArgument(AIndex: Integer): IGraphQLArgument;
begin
  Result := FArguments[AIndex];
end;

function TGraphQLField.GetFieldAlias: string;
begin
  Result := FFieldAlias;
end;

function TGraphQLField.GetFieldName: string;
begin
  Result := FFieldName;
end;

function TGraphQLField.GetParentField: IGraphQLField;
begin
  Result := FParentField;
end;

function TGraphQLField.GetValue: IGraphQLValue;
begin
  Result := FValue;
end;

procedure TGraphQLField.SetValue(AValue: IGraphQLValue);
begin
  FValue := AValue;
end;

{ TGraphQLObject }

procedure TGraphQLObject.Add(AField: IGraphQLField);
begin
  FFields.Add(AField);
end;

constructor TGraphQLObject.Create;
begin
  FFields := TGraphQLFields.Create;
end;

destructor TGraphQLObject.Destroy;
begin
  FFields.Free;
  inherited;
end;

function TGraphQLObject.FieldCount: Integer;
begin
  Result := FFields.Count;
end;

function TGraphQLObject.FindFieldByName(const AName: string): IGraphQLField;
var
  LIndex: Integer;
begin
  Result := nil;
  for LIndex := 0 to FFields.Count - 1 do
  begin
    if FFields[LIndex].FieldName = AName then
      Result := FFields[LIndex];
  end;
end;

function TGraphQLObject.GetField(AIndex: Integer): IGraphQLField;
begin
  Result := FFields[AIndex];
end;

function TGraphQLObject.GetFieldByName(const AName: string): IGraphQLField;
begin
  Result := FindFieldByName(AName);
  if not Assigned(Result) then
    raise EGraphQLFieldNotFound.CreateFmt('Field [%s] not found', [AName]);
end;

{ TGraphQLArgument }

constructor TGraphQLArgument.Create(const AName: string; AValue: TValue);
begin
  inherited Create;
  FName := AName;
  FValue := AValue;
end;

function TGraphQLArgument.GetName: string;
begin
  Result := FName;
end;

function TGraphQLArgument.GetValue: TValue;
begin
  Result := FValue;
end;

{ TGraphQLArguments }

procedure TGraphQLArguments.Add(AArgument: IGraphQLArgument);
begin
  inherited Add(AArgument);
end;

procedure TGraphQLArguments.AfterConstruction;
begin
  inherited;
  AtomicDecrement(FRefCount);
end;

function TGraphQLArguments.Count: Integer;
begin
  Result := inherited Count;
end;

function TGraphQLArguments.GetArgument(AIndex: Integer): IGraphQLArgument;
begin
  Result := inherited Items[AIndex];
end;

class function TGraphQLArguments.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  TGraphQLArguments(Result).FRefCount := 1;
end;

function TGraphQLArguments.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TGraphQLArguments._AddRef: Integer;
begin
  Result := AtomicIncrement(FRefCount);
end;

function TGraphQLArguments._Release: Integer;
begin
  Result := AtomicDecrement(FRefCount);
  if Result = 0 then
    Destroy;
end;

end.
