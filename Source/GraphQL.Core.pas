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
unit GraphQL.Core;

interface

uses
  System.Classes, System.SysUtils, System.Rtti, Generics.Collections;

type
  EGraphQLError = class(Exception)
  end;

  EGraphQLArgumentNotFound = class(EGraphQLError)
  end;

  EGraphQLFieldNotFound = class(EGraphQLError)
  end;

  {$SCOPEDENUMS ON}
  TGraphQLVariableType = (
    UnknownType,
    StringType,
    IntType,
    FloatType,
    BooleanType,
    IdType
  );

  TGraphQLArgumentAttribute = (Variable);

  TGraphQLArgumentAttributes = set of TGraphQLArgumentAttribute;
  {$SCOPEDENUMS OFF}

  IGraphQLList<T> = interface
    ['{909FA6AE-FD7D-436D-B948-F11F2A5ECBCE}']
    function Count: Integer;
    function GetItem(LIndex: Integer): T;
    function GetEnumerator: TEnumerator<T>;
    property Items[LIndex: Integer]: T read GetItem; default;
  end;

  // abstact
  IGraphQLValue = interface
    ['{0471DB6A-6810-4C29-8276-BCB2951DDCF2}']
  end;

  IGraphQLArgument = interface
    ['{9740320C-AC4E-47F4-BAA1-8C9EB7D7BEAB}']
    function GetName: string;
    function GetValue: TValue;
    function GetArgumentType: TGraphQLVariableType;
    function GetAttributes: TGraphQLArgumentAttributes;

    property Name: string read GetName;
    property ArgumentType: TGraphQLVariableType read GetArgumentType;
    property Value: TValue read GetValue;
    property Attributes: TGraphQLArgumentAttributes read GetAttributes;
  end;

  IGraphQLField = interface
    ['{9C7313F8-7953-4F9E-876B-69B2CDE60865}']
    function GetFieldName: string;
    function GetFieldAlias: string;
    function GetValue: IGraphQLValue;
    function GetArguments: IGraphQLList<IGraphQLArgument>;
    function ArgumentCount: Integer;
    function ArgumentByName(const AName: string): IGraphQLArgument;
    function GetParentField: IGraphQLField;

    property ParentField: IGraphQLField read GetParentField;
    property FieldName: string read GetFieldName;
    property FieldAlias: string read GetFieldAlias;
    property Value: IGraphQLValue read GetValue;
    property Arguments: IGraphQLList<IGraphQLArgument> read GetArguments;
  end;

  IGraphQLNull = interface(IGraphQLValue)
    ['{04FF0371-2034-49E3-9977-810A2DD54E44}']
  end;

  IGraphQLObject = interface(IGraphQLValue)
    ['{80B1FD62-50BA-4000-8C3C-79FF8F52159E}']
    function FieldCount: Integer;
    function GetFields: IGraphQLList<IGraphQLField>;
    function GetFieldByName(const AName: string): IGraphQLField;
    function FindFieldByName(const AName: string): IGraphQLField;

    property Fields: IGraphQLList<IGraphQLField> read GetFields;
    property FieldByName[const AName: string]: IGraphQLField read GetFieldByName;
  end;

  IGraphQLParam = interface
    ['{0A306CB8-F0C9-4F93-B237-2993C6370ADF}']
    function GetParamName: string;
    procedure SetParamName(const LValue: string);
    function GetParamType: TGraphQLVariableType;
    procedure SetParamType(LValue: TGraphQLVariableType);
    function GetRequired: Boolean;
    procedure SetRequired(LValue: Boolean);

    property ParamName: string read GetParamName write SetParamName;
    property ParamType: TGraphQLVariableType read GetParamType write SetParamType;
    property Required: Boolean read GetRequired write SetRequired;
  end;

  IGraphQL = interface
    ['{68BCD39F-A645-4007-8FA3-632359041A68}']
    function GetName: string;
    procedure SetName(const AName: string);
    procedure AddField(AField: IGraphQLField);
    function FieldCount: Integer;

    function GetFields: IGraphQLList<IGraphQLField>;
    function GetParams: IGraphQLList<IGraphQLParam>;
    procedure AddParam(AParam: IGraphQLParam);
    function ParamCount: Integer;

    property Fields: IGraphQLList<IGraphQLField> read GetFields;
    property Params: IGraphQLList<IGraphQLParam> read GetParams;
    property Name: string read GetName write SetName;
  end;

function VariableTypeToStr(AParamType: TGraphQLVariableType): string;

implementation

function VariableTypeToStr(AParamType: TGraphQLVariableType): string;
const
  LTypeStr: array [TGraphQLVariableType] of string = (
    'Unknown',
    'String',
    'Int',
    'Float',
    'Boolean',
    'ID'
  );
begin
  Result := LTypeStr[AParamType];
end;

end.
