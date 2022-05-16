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
  IEditableList<T> = interface
    ['{E88973EB-46E0-4CF5-8DEE-A86CA4F095F7}']
    procedure Add(AItem: T);
  end;

  TInterfacedList<T> = class(TInterfacedObject, IGraphQLList<T>, IEditableList<T>)
  private
    FItems: TList<T>;
  public
    function Count: Integer;
    function GetItem(LIndex: Integer): T;
    function GetEnumerator: TEnumerator<T>;
    property Items[LIndex: Integer]: T read GetItem;
    procedure Add(AItem: T);

    constructor Create;
    destructor Destroy; override;
  end;

  TGraphQLArgument = class(TInterfacedObject, IGraphQLArgument)
  private
    FName: string;
    FArgumentType: TGraphQLVariableType;
    FAttributes: TGraphQLArgumentAttributes;
    FValue: TValue;
  public
    { IGraphQLArgument }
    function GetName: string;
    function GetArgumentType: TGraphQLVariableType;
    function GetAttributes: TGraphQLArgumentAttributes;
    function GetValue: TValue;

    constructor Create(const AName: string; AArgumentType: TGraphQLVariableType; AAttributes: TGraphQLArgumentAttributes; AValue: TValue);
  end;

  TGraphQLObject = class(TInterfacedObject, IGraphQLObject, IGraphQLValue)
  private
    FFields: IGraphQLList<IGraphQLField>;
  public
    { IGraphQLObject }
    procedure Add(AField: IGraphQLField);
    function FieldCount: Integer;
    function GetFields: IGraphQLList<IGraphQLField>;
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
    FArguments: IGraphQLList<IGraphQLArgument>;
    [unsafe]
    FParentField: IGraphQLField;
  public
    { IGraphQLField }
    function GetFieldName: string;
    function GetFieldAlias: string;
    function GetValue: IGraphQLValue;
    function GetArguments: IGraphQLList<IGraphQLArgument>;
    function ArgumentCount: Integer;
    function ArgumentByName(const AName: string): IGraphQLArgument;
    function GetParentField: IGraphQLField;

    procedure SetValue(AValue: IGraphQLValue);

    constructor Create(AParentField: IGraphQLField; const AFieldName, AFieldAlias: string; AArguments: IGraphQLList<IGraphQLArgument>);
    destructor Destroy; override;
  end;

  TGraphQLParam = class(TInterfacedObject, IGraphQLParam)
  private
    FParamName: string;
    FParamType: TGraphQLVariableType;
    FRequired: Boolean;
  public
    { IGraphQLParam }
    function GetParamName: string;
    procedure SetParamName(const LValue: string);
    function GetParamType: TGraphQLVariableType;
    procedure SetParamType(LValue: TGraphQLVariableType);
    function GetRequired: Boolean;
    procedure SetRequired(LValue: Boolean);

    constructor Create(const AParamName: string; AParamType: TGraphQLVariableType; ARequired: Boolean);
  end;

  TGraphQL = class(TInterfacedObject, IGraphQL)
  private
    FName: string;
    FFields: IGraphQLList<IGraphQLField>;
    FParams: IGraphQLList<IGraphQLParam>;
  public
    { IGraphQL }
    function GetName: string;
    procedure SetName(const AName: string);
    procedure AddField(AField: IGraphQLField);
    function FieldCount: Integer;
    function GetFields: IGraphQLList<IGraphQLField>;

    function GetParams: IGraphQLList<IGraphQLParam>;
    procedure AddParam(AParam: IGraphQLParam);
    function ParamCount: Integer;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TGraphQL }

procedure TGraphQL.AddField(AField: IGraphQLField);
begin
  (FFields as IEditableList<IGraphQLField>).Add(AField);
end;

procedure TGraphQL.AddParam(AParam: IGraphQLParam);
begin
  (FParams as IEditableList<IGraphQLParam>).Add(AParam);
end;

constructor TGraphQL.Create;
begin
  FFields := TInterfacedList<IGraphQLField>.Create();
  FParams := TInterfacedList<IGraphQLParam>.Create();
end;

destructor TGraphQL.Destroy;
begin
  //FFields.Free;
  inherited;
end;

function TGraphQL.FieldCount: Integer;
begin
  Result := FFields.Count;
end;

function TGraphQL.GetFields: IGraphQLList<IGraphQLField>;
begin
  Result := FFields;
end;

function TGraphQL.GetName: string;
begin
  Result := FName;
end;

function TGraphQL.GetParams: IGraphQLList<IGraphQLParam>;
begin
  Result := FParams;
end;

function TGraphQL.ParamCount: Integer;
begin
  Result := FParams.Count;
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

constructor TGraphQLField.Create(AParentField: IGraphQLField; const AFieldName, AFieldAlias: string; AArguments: IGraphQLList<IGraphQLArgument>);
begin
  inherited Create;
  if Assigned(AArguments) then
    FArguments := AArguments
  else
    FArguments := TInterfacedList<IGraphQLArgument>.Create;
  FFieldName := AFieldName;
  FFieldAlias := AFieldAlias;
  FParentField := AParentField;
end;

destructor TGraphQLField.Destroy;
begin
  inherited;
end;

function TGraphQLField.GetArguments: IGraphQLList<IGraphQLArgument>;
begin
  Result := FArguments;
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
  (FFields as IEditableList<IGraphQLField>).Add(AField);
end;

constructor TGraphQLObject.Create;
begin
  FFields := TInterfacedList<IGraphQLField>.Create;
end;

destructor TGraphQLObject.Destroy;
begin
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

function TGraphQLObject.GetFields: IGraphQLList<IGraphQLField>;
begin
  Result := FFields;
end;

function TGraphQLObject.GetFieldByName(const AName: string): IGraphQLField;
begin
  Result := FindFieldByName(AName);
  if not Assigned(Result) then
    raise EGraphQLFieldNotFound.CreateFmt('Field [%s] not found', [AName]);
end;

{ TGraphQLArgument }

constructor TGraphQLArgument.Create(const AName: string; AArgumentType: TGraphQLVariableType; AAttributes: TGraphQLArgumentAttributes; AValue: TValue);
begin
  inherited Create;
  FName := AName;
  FArgumentType := AArgumentType;
  FAttributes := AAttributes;
  FValue := AValue;
end;

function TGraphQLArgument.GetArgumentType: TGraphQLVariableType;
begin
  Result := FArgumentType;
end;

function TGraphQLArgument.GetAttributes: TGraphQLArgumentAttributes;
begin
  Result := FAttributes;
end;

function TGraphQLArgument.GetName: string;
begin
  Result := FName;
end;

function TGraphQLArgument.GetValue: TValue;
begin
  Result := FValue;
end;

{ TInterfacedList<T> }

procedure TInterfacedList<T>.Add(AItem: T);
begin
  FItems.Add(AItem);
end;

function TInterfacedList<T>.Count: Integer;
begin
  Result := FItems.Count;
end;

constructor TInterfacedList<T>.Create;
begin
  inherited Create;
  FItems := TList<T>.Create;
end;

destructor TInterfacedList<T>.Destroy;
begin
  inherited;
  FItems.Free;
end;

function TInterfacedList<T>.GetEnumerator: TEnumerator<T>;
begin
  Result := FItems.GetEnumerator;
end;

function TInterfacedList<T>.GetItem(LIndex: Integer): T;
begin
  Result := FItems[LIndex];
end;

{ TGraphQLParam }

constructor TGraphQLParam.Create(const AParamName: string;
  AParamType: TGraphQLVariableType; ARequired: Boolean);
begin
  inherited Create;
  FParamName := AParamName;
  FParamType := AParamType;
  FRequired := ARequired;
end;

function TGraphQLParam.GetParamName: string;
begin
  Result := FParamName;
end;

function TGraphQLParam.GetParamType: TGraphQLVariableType;
begin
  Result := FParamType;
end;

function TGraphQLParam.GetRequired: Boolean;
begin
  Result := FRequired;
end;

procedure TGraphQLParam.SetParamName(const LValue: string);
begin
  FParamName := LValue;
end;

procedure TGraphQLParam.SetParamType(LValue: TGraphQLVariableType);
begin
  FParamType := LValue;
end;

procedure TGraphQLParam.SetRequired(LValue: Boolean);
begin
  FRequired := LValue;
end;

end.
