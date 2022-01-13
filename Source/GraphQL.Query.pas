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
    function Serialize(AValue: TValue; AField: IGraphQLField): string;
    function SerializeObject(AObject: TObject; AGraphQLObject: IGraphQLObject): string;
    function Resolve(AParams: TGraphQLParams): TValue; overload;
    function Resolve(AField: IGraphQLField): TValue; overload;
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

var
  JSONFormatSettings: TFormatSettings;

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

function TGraphQLQuery.Resolve(AField: IGraphQLField): TValue;
var
  LArgument: IGraphQLArgument;
  LArgumentIndex: Integer;
  LParams: TGraphQLParams;
  LParamDictionary: TDictionary<string, TValue>;
begin
  LParamDictionary := TDictionary<string, TValue>.Create;
  try
    for LArgumentIndex := 0 to AField.ArgumentCount - 1 do
    begin
      LArgument := AField.Arguments[LArgumentIndex];
      LParamDictionary.Add(LArgument.Name, LArgument.Value);
    end;

    LParams := TGraphQLParams.Create(AField.FieldName, LParamDictionary);
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
  LFieldIndex: Integer;
  LField: IGraphQLField;
begin
  Result := '';
  for LFieldIndex := 0 to AGraphQL.FieldCount - 1 do
  begin
    LField := AGraphQL.Fields[LFieldIndex];

    if Result <> '' then
    begin
      Result := Result + ',' + sLineBreak;
    end;
    Result := Result + '  "' + LField.FieldAlias + '": ' + Serialize(Resolve(LField), LField);

  end;
  Result := '{' + sLineBreak + Result + sLineBreak + '}';
end;

function TGraphQLQuery.Serialize(AValue: TValue; AField: IGraphQLField): string;
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

function TGraphQLQuery.SerializeObject(AObject: TObject; AGraphQLObject: IGraphQLObject): string;

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
    LFieldIndex: Integer;
  begin
    if not Assigned(AGraphQLObject) then
      Exit(nil);

    LClonedObject := TJSONObject.Create;

    for LFieldIndex := 0 to AGraphQLObject.FieldCount - 1 do
    begin
      LField := AGraphQLObject.Fields[LFieldIndex];
      LValue := LJSONObject.Values[LField.FieldName];

//      if not Assigned(LValue) then
//        LValue := Resolve(LField);

      if Assigned(LValue) then
      begin
        LClonedValue := CloneValue(LValue, LField.Value);
        if Assigned(LClonedValue) then
          LClonedObject.AddPair(LField.FieldAlias, LClonedValue);
      end;
    end;
    Result := LClonedObject;
  end;

var
  LJSONObject: TJSONObject;
  LJSONFilteredObject: TJSONValue;
  LFreeJSONObject: Boolean;
begin
  LFreeJSONObject := False;
  if AObject is TJSONArray then
  begin

    LJSONFilteredObject := CloneValue(TJSONArray(AObject), AGraphQLObject);
    try
      Result := LJSONFilteredObject.ToJSON;
    finally
      LJSONFilteredObject.Free;
    end;
    Exit;
  end;

  if AObject is TJSONObject then
  begin
    LJSONObject := TJSONObject(AObject)
  end
  else
  begin
    LJSONObject := FSerializerFunc(AObject);
    LFreeJSONObject := True;
  end;
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
    if LFreeJSONObject then
      LJSONObject.Free;
  end;
end;

function TGraphQLQuery.Run(const AQuery: string): string;
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
