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
unit GraphQL.Query.Rtti;

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

  TGraphQLRttiQuery = class(TObject)
  private
    FFunctionRegistry: TGraphQLFunctionRegistry;
    FResolverRegistry: TGraphQLResolverRegistry;
    FSerializerFunc: TGraphQLSerializerFunc;
    function Serialize(AValue: TValue; AField: IGraphQLField): string;
    function SerializeObject(AObject: TObject; AGraphQLObject: IGraphQLObject): string;
    function Resolve(AParams: TGraphQLParams): TValue;
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

{ TGraphQLRttiQuery }

uses
  REST.Json,
  GraphQL.Lexer.Core, GraphQL.SyntaxAnalysis.Builder, GraphQL.Utils.JSON;

var
  JSONFormatSettings: TFormatSettings;

constructor TGraphQLRttiQuery.Create;
begin
  FFunctionRegistry := TGraphQLFunctionRegistry.Create;
  FResolverRegistry := TGraphQLResolverRegistry.Create;
  FSerializerFunc :=
    function(AObject: TObject) :TJSONObject
    begin
      Result := TJson.ObjectToJsonObject(AObject);
    end;
end;

destructor TGraphQLRttiQuery.Destroy;
begin
  FFunctionRegistry.Free;
  FResolverRegistry.Free;
  inherited;
end;

procedure TGraphQLRttiQuery.RegisterFunction(const AFunctionName: string;
  AFunc: TGraphQLFunc);
begin
  FFunctionRegistry.Add(AFunctionName, AFunc);
end;

procedure TGraphQLRttiQuery.RegisterResolver(AResolver: IGraphQLResolver);
begin
  FResolverRegistry.Add(AResolver);
end;

procedure TGraphQLRttiQuery.RegisterSerializer(AFunc: TGraphQLSerializerFunc);
begin
  FSerializerFunc := AFunc;
end;

function TGraphQLRttiQuery.Resolve(AParams: TGraphQLParams): TValue;
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

function TGraphQLRttiQuery.Run(AGraphQL: IGraphQL): string;
var
  LFieldIndex: Integer;
  LArgumentIndex: Integer;
  LField: IGraphQLField;
  LArgument: IGraphQLArgument;
  LParams: TGraphQLParams;
  LParamDictionary: TDictionary<string, TValue>;
begin
  Result := '';
  for LFieldIndex := 0 to AGraphQL.FieldCount - 1 do
  begin
    LField := AGraphQL.Fields[LFieldIndex];

    LParamDictionary := TDictionary<string, TValue>.Create;
    try
      for LArgumentIndex := 0 to LField.ArgumentCount - 1 do
      begin
        LArgument := LField.Arguments[LArgumentIndex];
        LParamDictionary.Add(LArgument.Name, LArgument.Value);
      end;

      if Result <> '' then
      begin
        Result := Result + ',' + sLineBreak;
      end;
      LParams := TGraphQLParams.Create(LField.FieldName, LParamDictionary);
      Result := Result + '  "' + LField.FieldAlias + '": ' + Serialize(Resolve(LParams), LField);
    finally
      LParamDictionary.Free;
    end;
  end;
  Result := '{' + sLineBreak + Result + sLineBreak + '}';
end;

function TGraphQLRttiQuery.Serialize(AValue: TValue; AField: IGraphQLField): string;
var
  LGraphQLObject: IGraphQLObject;
begin
  case AValue.Kind of
    tkInteger: Result := AValue.AsInteger.ToString;
    tkString,
    tkLString,
    tkWString,
    tkUString: Result := TJSONHelper.QuoteString(AValue.AsString);
    tkClass: begin
      if Supports(AField.Value, IGraphQLObject)  then
        LGraphQLObject := AField.Value as IGraphQLObject
      else
        LGraphQLObject := nil;

      Result := SerializeObject(AValue.AsObject, LGraphQLObject);
      AValue.AsObject.Free;
    end;
    tkFloat: Result := FloatToStr(AValue.AsExtended, JSONFormatSettings);
    tkInt64: Result := IntToStr(AValue.AsInt64);
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

function TGraphQLRttiQuery.SerializeObject(AObject: TObject; AGraphQLObject: IGraphQLObject): string;

  function CloneObject(LJSONObject: TJSONObject; AGraphQLObject: IGraphQLObject): TJSONObject; forward;

  function CloneValue(LValue: TJSONValue; AGraphQLValue: IGraphQLValue): TJSONValue;
  var
    LGraphQLSubObject: IGraphQLObject;
    LSubArray: TJSONArray;
    LItem: TJSONValue;
    LSubObject: TJSONObject;
  begin
    Result := nil;
    if LValue is TJSONArray then
    begin
      if Supports(AGraphQLValue, IGraphQLObject) then
      begin
        LGraphQLSubObject := AGraphQLValue as IGraphQLObject;
        LSubArray := TJSONArray.Create;
        for LItem in (LValue as TJSONArray) do
        begin
          LSubObject := CloneObject(LItem as TJSONObject, LGraphQLSubObject);
          LSubArray.AddElement(LSubObject);
        end;
        Result := LSubArray;
      end;
    end
    else if LValue is TJSONObject then
    begin
      if Supports(AGraphQLValue, IGraphQLObject) then
      begin
        LGraphQLSubObject := AGraphQLValue as IGraphQLObject;
        LSubObject := CloneObject(LValue as TJSONObject, LGraphQLSubObject);
        Result := LSubObject;
      end;
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
    LJSONPair: TJSONPair;
    LField: IGraphQLField;
    LValue: TJSONValue;
  begin
    LClonedObject := TJSONObject.Create;
    for LJSONPair in LJSONObject do
    begin
      LField := AGraphQLObject.FindFieldByName(LJSONPair.JsonString.Value);
      if Assigned(LField) then
      begin
         LValue := CloneValue(LJSONPair.JsonValue, LField.Value);
         if Assigned(LValue) then
           LClonedObject.AddPair(LField.FieldAlias, LValue);
      end;
    end;
    Result := LClonedObject;
  end;

var
  LJSONObject: TJSONObject;
  LJSONFilteredObject: TJSONObject;
begin
    LJSONObject := FSerializerFunc(AObject);
    try

      if not Assigned(AGraphQLObject) then
      begin
        Result := LJSONObject.ToJSON;
      end
      else
      begin
        LJSONFilteredObject := CloneObject(LJSONObject, AGraphQLObject);
        try
          Result := LJSONFilteredObject.ToJSON;
        finally
          LJSONFilteredObject.Free;
        end;
      end;

    finally
      LJSONObject.Free;
    end;
end;

function TGraphQLRttiQuery.Run(const AQuery: string): string;
var
  LScanner: TScanner;
  LBuilder: TGraphQLBuilder;
  LGraphQL: IGraphQL;
begin
  inherited;
  LScanner := TScanner.CreateFromString(AQuery);
  try
    LBuilder := TGraphQLBuilder.Create(LScanner);
    try
      LGraphQL := LBuilder.Build;
      Result := Run(LGraphQL);
    finally
      LBuilder.Free;
    end;
  finally
    LScanner.Free;
  end;
end;

initialization

  JSONFormatSettings := TFormatSettings.Invariant;

end.
