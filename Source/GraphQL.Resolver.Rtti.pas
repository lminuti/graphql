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
unit GraphQL.Resolver.Rtti;

interface

uses
  System.Classes, System.SysUtils, System.Rtti, System.JSON, System.SyncObjs,
  GraphQL.Core, GraphQL.Resolver.Core;

type
  TGraphQLRttiResolver = class(TInterfacedObject, IGraphQLResolver)
  private
    FClass: TClass;
    FClassFactory: TFunc<TObject>;
    FSingleton: Boolean;
    FInstance: TObject;
    function CreateInstance: TObject;
  public
    { IGraphQLResolver }
    function Resolve(AParams: TGraphQLParams): TValue;

    constructor Create(AClass: TClass; AClassFactory: TFunc<TObject> = nil; ASingleton: Boolean = False); overload;
    constructor Create(AClass: TClass; ASingleton: Boolean); overload;
    destructor Destroy; override;
  end;

implementation

{ TGraphQLRttiResolver }

uses
  GraphQL.Utils.Rtti, GraphQL.Core.Attributes;

var
  CreateInstanceLock: TCriticalSection;

constructor TGraphQLRttiResolver.Create(AClass: TClass; AClassFactory: TFunc<TObject> = nil; ASingleton: Boolean = False);
begin
  FClass := AClass;
  FSingleton := ASingleton;
  FInstance := nil;
  if Assigned(AClassFactory) then
  begin
    FClassFactory := AClassFactory
  end
  else
  begin
    FClassFactory := function: TObject
    begin
      Result := TRttiHelper.CreateInstance(AClass);
    end
  end;
end;

constructor TGraphQLRttiResolver.Create(AClass: TClass; ASingleton: Boolean);
begin
  Create(AClass, nil, ASingleton);
end;

function TGraphQLRttiResolver.CreateInstance: TObject;
begin
  if FSingleton then
  begin
    // Double cheked locking:
    // Thread-safe but with lock only when the singleton has been created

    if not Assigned(FInstance) then
    begin
      CreateInstanceLock.Acquire;
      try
        if not Assigned(FInstance) then
          FInstance := FClassFactory();
      finally
        CreateInstanceLock.Release;
      end;
    end;

  end
  else
  begin
    FInstance := FClassFactory();
  end;

  Result := FInstance;

end;

destructor TGraphQLRttiResolver.Destroy;
begin
  if FSingleton then
    FreeAndNil(FInstance);
  inherited;
end;

function TGraphQLRttiResolver.Resolve(AParams: TGraphQLParams): TValue;

  function ValueArrayFromParams(ARttiMethod: TRttiMethod; AParams: TGraphQLParams): TArray<TValue>;
  var
    LRttiParam: TRttiParameter;
    LIndex: Integer;
  begin
    SetLength(Result, Length(ARttiMethod.GetParameters));
    LIndex := 0;
    for LRttiParam in ARttiMethod.GetParameters do
    begin
      if AParams.Exists(LRttiParam.Name) then
        Result[LIndex] := AParams.Get(LRttiParam.Name);
//      else
//        raise EGraphQLError.CreateFmt('Parameter [%s] for entity [%s] not found', [LRttiParam.Name, AParams.FieldName]);
      Inc(LIndex);
    end;
  end;

var
  LObject: TObject;
  LRttiType: TRttiType;
  LRttiMethod: TRttiMethod;
  LAttr: GraphQLEntityAttribute;
  LEntityName: string;
begin
  LRttiType := TRttiHelper.Context.GetType(FClass);
  for LRttiMethod in LRttiType.GetMethods do
  begin
    LAttr := TRttiHelper.FindAttribute<GraphQLEntityAttribute>(LRttiMethod);
    if Assigned(LAttr) then
    begin
      if LAttr.Value <> '' then
        LEntityName := LAttr.Value
      else
        LEntityName := LRttiMethod.Name;

      if LEntityName = AParams.FieldName then
      begin
        LObject := CreateInstance;
        try
          Result := LRttiMethod.Invoke(LObject, ValueArrayFromParams(LRttiMethod, AParams));
        finally
          if not FSingleton then
            FreeAndNil(LObject);
        end;
        Exit;
      end;
    end;
  end;
end;

initialization

  CreateInstanceLock := TCriticalSection.Create;

finalization

  CreateInstanceLock.Free;

end.
