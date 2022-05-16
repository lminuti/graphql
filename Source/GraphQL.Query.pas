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
unit GraphQL.Query;

interface

uses
  System.Classes, System.SysUtils, System.Rtti, System.JSON, Generics.Collections,
  GraphQL.Core, GraphQL.Resolver.Core;

type
  TGraphQLFunc = reference to function (AParams: TGraphQLParams) :TValue;

  TGraphQLSerializerFunc = reference to function (AObject: TObject) :TJSONObject;

  TGraphQLFunctionRegistry = class(TDictionary<string,TGraphQLFunc>)
  end;

  TGraphQLResolverRegistry = class(TList<IGraphQLResolver>)
  end;

  TOnNeedVariableEvent = procedure (Sender: TObject; AArgument: IGraphQLArgument; var AValue: TValue) of object;
  TOnFreeObjectEvent = procedure (Sender: TObject; AObjectToFree: TObject; var AAutoFree: Boolean) of object;

  TGraphQLQuery = class(TObject)
  private
    FFunctionRegistry: TGraphQLFunctionRegistry;
    FResolverRegistry: TGraphQLResolverRegistry;
    FSerializerFunc: TGraphQLSerializerFunc;
    FOnNeedVariable: TOnNeedVariableEvent;
    FAutoFree: Boolean;
    FOnFreeObject: TOnFreeObjectEvent;
    function GetVariable(LArgument: IGraphQLArgument; AVariables: IGraphQLVariables): TValue;
    function Resolve(AParams: TGraphQLParams; AVariables: IGraphQLVariables): TValue; overload;
    function Resolve(AField: IGraphQLField; AParent: TJSONObject; AVariables: IGraphQLVariables): TValue; overload;
    function ObjectToJSON(AObject: TObject; AGraphQLObject: IGraphQLObject; AVariables: IGraphQLVariables): TJSONValue;
    function ValueToJSON(AValue: TValue; AField: IGraphQLField; AVariables: IGraphQLVariables): TJSONValue;
  public
    procedure RegisterFunction(const AFunctionName: string; AFunc: TGraphQLFunc);
    procedure RegisterResolver(AResolver: IGraphQLResolver);
    procedure RegisterSerializer(AFunc: TGraphQLSerializerFunc);

    function Parse(const AQuery: string): IGraphQL;
    function Run(const AQuery: string; AVariables: IGraphQLVariables): string; overload;
    function Run(AGraphQL: IGraphQL; AVariables: IGraphQLVariables): string; overload;

    property OnNeedVariable: TOnNeedVariableEvent read FOnNeedVariable write FOnNeedVariable;
    property OnFreeObject: TOnFreeObjectEvent read FOnFreeObject write FOnFreeObject;
    property AutoFree: Boolean read FAutoFree write FAutoFree default True;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TGraphQLQuery }

uses
  REST.Json,
  GraphQL.Lexer.Core, GraphQL.SyntaxAnalysis.Builder, GraphQL.Utils.JSON;

constructor TGraphQLQuery.Create;
begin
  FAutoFree := True;
  FFunctionRegistry := TGraphQLFunctionRegistry.Create;
  FResolverRegistry := TGraphQLResolverRegistry.Create;
  FSerializerFunc :=
    function(AObject: TObject) :TJSONObject
    begin
      Result := TJson.ObjectToJsonObject(AObject);
    end;
end;

destructor TGraphQLQuery.Destroy;
begin
  FFunctionRegistry.Free;
  FResolverRegistry.Free;
  inherited;
end;

function TGraphQLQuery.GetVariable(LArgument: IGraphQLArgument; AVariables: IGraphQLVariables): TValue;
begin
  if AVariables.VariableExists(LArgument.Name) then
  begin
    Exit(AVariables.GetVariable(LArgument.Name));
  end;

  if Assigned(FOnNeedVariable) then
  begin
    FOnNeedVariable(Self, LArgument, Result);
    Exit;
  end;

  raise EGraphQLError.CreateFmt('Variable [%s] not found', [LArgument.Name]);
end;

procedure TGraphQLQuery.RegisterFunction(const AFunctionName: string;
  AFunc: TGraphQLFunc);
begin
  FFunctionRegistry.Add(AFunctionName, AFunc);
end;

procedure TGraphQLQuery.RegisterResolver(AResolver: IGraphQLResolver);
begin
  FResolverRegistry.Add(AResolver);
end;

procedure TGraphQLQuery.RegisterSerializer(AFunc: TGraphQLSerializerFunc);
begin
  FSerializerFunc := AFunc;
end;

function TGraphQLQuery.Resolve(AField: IGraphQLField; AParent: TJSONObject; AVariables: IGraphQLVariables): TValue;
var
  LArgument: IGraphQLArgument;
  LParams: TGraphQLParams;
  LParamDictionary: TDictionary<string, TValue>;
  LFieldName: string;
begin
  LParamDictionary := TDictionary<string, TValue>.Create;
  try
    for LArgument in AField.Arguments do
    begin
      if TGraphQLArgumentAttribute.Variable in LArgument.Attributes then
        LParamDictionary.Add(LArgument.Name, GetVariable(LArgument, AVariables))
      else
        LParamDictionary.Add(LArgument.Name, LArgument.Value);
    end;

    if Assigned(AField.ParentField) then
      LFieldName := AField.ParentField.FieldName + '/' + AField.FieldName
    else
      LFieldName := AField.FieldName;

    LParams := TGraphQLParams.Create(LFieldName, LParamDictionary, AParent);
    Result := Resolve(LParams, AVariables);
  finally
    LParamDictionary.Free;
  end;
end;

function TGraphQLQuery.Resolve(AParams: TGraphQLParams; AVariables: IGraphQLVariables): TValue;
var
  LFunc: TGraphQLFunc;
  LResolver: IGraphQLResolver;
begin
  Result := nil;
  if FFunctionRegistry.TryGetValue(AParams.FieldName, LFunc) then
    Exit(LFunc(AParams));

  for LResolver in FResolverRegistry do
  begin
    Result := LResolver.Resolve(AParams);
    if not Result.IsEmpty then
      Exit;
  end;

  raise EGraphQLError.CreateFmt('Entity [%s] not found', [AParams.FieldName]);
end;

function TGraphQLQuery.Run(AGraphQL: IGraphQL; AVariables: IGraphQLVariables): string;
var
  LField: IGraphQLField;
  LJSONObject: TJSONObject;
begin
  LJSONObject := TJSONObject.Create;
  try
    for LField in AGraphQL.Fields do
    begin
      LJSONObject.AddPair(LField.FieldAlias, ValueToJSON(Resolve(LField, nil, AVariables), LField, AVariables));
    end;
    Result := LJSONObject.ToJSON;
  finally
    LJSONObject.Free;
  end;
end;

function TGraphQLQuery.ValueToJSON(AValue: TValue; AField: IGraphQLField; AVariables: IGraphQLVariables): TJSONValue;
var
  LGraphQLObject: IGraphQLObject;
  LIndex: Integer;
  LJsonValue: TJSONValue;
  LJsonArray: TJSONArray;
  LAutoFree: Boolean;
begin
  case AValue.Kind of
    tkInteger: Result := TJSONNumber.Create(AValue.AsInteger);
    tkString,
    tkLString,
    tkWString,
    tkUString: Result := TJSONString.Create(AValue.AsString);
    tkClass: begin
      LAutoFree := FAutoFree;
      if Supports(AField.Value, IGraphQLObject)  then
        LGraphQLObject := AField.Value as IGraphQLObject
      else
        LGraphQLObject := nil;

      try
        Result := ObjectToJSON(AValue.AsObject, LGraphQLObject, AVariables);
      finally
        if Assigned(FOnFreeObject) then
          FOnFreeObject(Self, AValue.AsObject, LAutoFree);
        if LAutoFree then
          AValue.AsObject.Free;
      end;
    end;
    tkFloat: Result := TJSONNumber.Create(AValue.AsExtended);
    tkInt64: Result := TJSONNumber.Create(AValue.AsInt64);
    tkDynArray: begin
      LJsonArray := TJSONArray.Create;
      try
        for LIndex := 0 to AValue.GetArrayLength - 1 do
        begin
          LJsonValue := ValueToJSON(AValue.GetArrayElement(LIndex), AField, AVariables);
          LJsonArray.AddElement(LJsonValue);
        end;
      except
        LJsonArray.Free;
        raise;
      end;
      Result := LJsonArray;
    end;
//    tkClassRef
//    tkChar,
//    tkEnumeration,
//    tkSet,
//    tkWChar,
//    tkVariant,
//    tkArray,
//    tkRecord,
//    tkInterface,
//    tkDynArray,
//    tkPointer,
    else
      raise EGraphQLError.CreateFmt('Value [%s] not supported', [TRttiEnumerationType.GetName<TTypeKind>(AValue.Kind)]);
  end;
end;

function TGraphQLQuery.ObjectToJSON(AObject: TObject; AGraphQLObject: IGraphQLObject; AVariables: IGraphQLVariables): TJSONValue;

  function CloneObject(LJSONObject: TJSONObject; AGraphQLObject: IGraphQLObject): TJSONObject; forward;

  function CloneValue(LValue: TJSONValue; AGraphQLValue: IGraphQLValue): TJSONValue;
  var
    LGraphQLSubObject: IGraphQLObject;
    LSubArray: TJSONArray;
    LItem: TJSONValue;
    LSubObject: TJSONObject;
  begin
    //Result := nil;
    if LValue is TJSONArray then
    begin
      LGraphQLSubObject := nil;
      if Supports(AGraphQLValue, IGraphQLObject) then
        LGraphQLSubObject := AGraphQLValue as IGraphQLObject;

      LSubArray := TJSONArray.Create;
      for LItem in (LValue as TJSONArray) do
      begin
        LSubObject := CloneObject(LItem as TJSONObject, LGraphQLSubObject);
        LSubArray.AddElement(LSubObject);
      end;
      Result := LSubArray;
    end
    else if LValue is TJSONObject then
    begin
      LGraphQLSubObject := nil;
      if Supports(AGraphQLValue, IGraphQLObject) then
        LGraphQLSubObject := AGraphQLValue as IGraphQLObject;
      LSubObject := CloneObject(LValue as TJSONObject, LGraphQLSubObject);
      Result := LSubObject;
    end
    else if LValue is TJSONNull then
      Result := TJSONNull.Create
    else if LValue is TJSONBool then
      Result := TJSONBool.Create(TJSONBool(LValue).AsBoolean)
    else if LValue is TJSONNumber then
      Result := TJSONNumber.Create(TJSONNumber(LValue).AsDouble)
    else if LValue is TJSONString then
      Result := TJSONString.Create(LValue.Value)
    else
      raise Exception.CreateFmt('Value [%s] not suppported', [LValue.ClassName]);
  end;

  function CloneObject(LJSONObject: TJSONObject; AGraphQLObject: IGraphQLObject): TJSONObject;
  var
    LClonedObject: TJSONObject;
    LField: IGraphQLField;
    LValue: TJSONValue;
    LClonedValue: TJSONValue;
    LFreeValue: Boolean;
  begin
    if not Assigned(AGraphQLObject) then
      Exit(nil);

    LClonedObject := TJSONObject.Create;
    try

      for LField in AGraphQLObject.Fields do
      begin
        LFreeValue := False;
        LValue := LJSONObject.Values[LField.FieldName];
        try

          if not Assigned(LValue) then
          begin
            LValue := ValueToJSON(Resolve(LField, LJSONObject, AVariables), LField, AVariables);
            LFreeValue := True;
          end;

          if Assigned(LValue) then
          begin
            LClonedValue := CloneValue(LValue, LField.Value);
            if Assigned(LClonedValue) then
              LClonedObject.AddPair(LField.FieldAlias, LClonedValue);
          end;
        finally
          if LFreeValue and Assigned(LValue) then
            LValue.Free;
        end;
      end;
      Result := LClonedObject;
    except
      LClonedObject.Free;
      raise;
    end;
  end;

var
  LJSONObject: TJSONObject;
  LJSONFilteredObject: TJSONValue;
begin
  if AObject is TJSONArray then
  begin
    LJSONFilteredObject := CloneValue(TJSONArray(AObject), AGraphQLObject);
    Exit(LJSONFilteredObject);
  end;

  if AObject is TJSONObject then
  begin
    LJSONObject := TJSONObject(AObject)
  end
  else
  begin
    LJSONObject := FSerializerFunc(AObject);
  end;

  if not Assigned(AGraphQLObject) then
  begin
    LJSONFilteredObject := LJSONObject;
  end
  else
  begin
    try
      LJSONFilteredObject := CloneObject(LJSONObject, AGraphQLObject);
    finally
      if LJSONObject <> AObject then
        LJSONObject.Free;
    end;
  end;
  Result := LJSONFilteredObject;
end;

function TGraphQLQuery.Parse(const AQuery: string): IGraphQL;
var
  LBuilder: TGraphQLBuilder;
begin
  inherited;
  LBuilder := TGraphQLBuilder.Create(AQuery);
  try
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

function TGraphQLQuery.Run(const AQuery: string; AVariables: IGraphQLVariables): string;
var
  LGraphQL: IGraphQL;
begin
  inherited;
  LGraphQL := Parse(AQuery);
  Result := Run(LGraphQL, AVariables);
end;

end.
