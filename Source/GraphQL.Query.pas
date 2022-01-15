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

  TGraphQLQuery = class(TObject)
  private
    FFunctionRegistry: TGraphQLFunctionRegistry;
    FResolverRegistry: TGraphQLResolverRegistry;
    FSerializerFunc: TGraphQLSerializerFunc;
    function Resolve(AParams: TGraphQLParams): TValue; overload;
    function Resolve(AField: IGraphQLField; AParent: TJSONObject): TValue; overload;
    function ObjectToJSON(AObject: TObject; AGraphQLObject: IGraphQLObject): TJSONValue;
    function ValueToJSON(AValue: TValue; AField: IGraphQLField): TJSONValue;
  public
    procedure RegisterFunction(const AFunctionName: string; AFunc: TGraphQLFunc);
    procedure RegisterResolver(AResolver: IGraphQLResolver);
    procedure RegisterSerializer(AFunc: TGraphQLSerializerFunc);

    function Run(const AQuery: string): string; overload;
    function Run(AGraphQL: IGraphQL): string; overload;

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

function TGraphQLQuery.Resolve(AField: IGraphQLField; AParent: TJSONObject): TValue;
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
      LParamDictionary.Add(LArgument.Name, LArgument.Value);
    end;

    if Assigned(AField.ParentField) then
      LFieldName := AField.ParentField.FieldName + '/' + AField.FieldName
    else
      LFieldName := AField.FieldName;

    LParams := TGraphQLParams.Create(LFieldName, LParamDictionary, AParent);
    Result := Resolve(LParams);
  finally
    LParamDictionary.Free;
  end;
end;

function TGraphQLQuery.Resolve(AParams: TGraphQLParams): TValue;
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

function TGraphQLQuery.Run(AGraphQL: IGraphQL): string;
var
  LField: IGraphQLField;
  LJSONObject: TJSONObject;
begin
  LJSONObject := TJSONObject.Create;
  try
    for LField in AGraphQL.Fields do
    begin
      LJSONObject.AddPair(LField.FieldAlias, ValueToJSON(Resolve(LField, nil), LField));
    end;
    Result := LJSONObject.ToJSON;
  finally
    LJSONObject.Free;
  end;
end;

function TGraphQLQuery.ValueToJSON(AValue: TValue; AField: IGraphQLField): TJSONValue;
var
  LGraphQLObject: IGraphQLObject;
begin
  case AValue.Kind of
    tkInteger: Result := TJSONNumber.Create(AValue.AsInteger);
    tkString,
    tkLString,
    tkWString,
    tkUString: Result := TJSONString.Create(AValue.AsString);
    tkClass: begin
      if Supports(AField.Value, IGraphQLObject)  then
        LGraphQLObject := AField.Value as IGraphQLObject
      else
        LGraphQLObject := nil;

      try
        Result := ObjectToJSON(AValue.AsObject, LGraphQLObject);
      finally
        AValue.AsObject.Free;
      end;
    end;
    tkFloat: Result := TJSONNumber.Create(AValue.AsExtended);
    tkInt64: Result := TJSONNumber.Create(AValue.AsInt64);
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

function TGraphQLQuery.ObjectToJSON(AObject: TObject; AGraphQLObject: IGraphQLObject): TJSONValue;

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
            LValue := ValueToJSON(Resolve(LField, LJSONObject), LField);
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

function TGraphQLQuery.Run(const AQuery: string): string;
var
  LBuilder: TGraphQLBuilder;
  LGraphQL: IGraphQL;
begin
  inherited;
  LBuilder := TGraphQLBuilder.Create(AQuery);
  try
    LGraphQL := LBuilder.Build;
    Result := Run(LGraphQL);
  finally
    LBuilder.Free;
  end;
end;

end.
