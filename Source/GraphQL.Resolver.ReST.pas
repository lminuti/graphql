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
unit GraphQL.Resolver.ReST;

interface

uses
  System.Classes, System.SysUtils, System.Rtti, System.TypInfo, System.JSON, System.NetEncoding, Generics.Collections,
  GraphQL.Core, GraphQL.Resolver.Core, IdHttp, System.RegularExpressions;

type
  IGraphQLHTTPResponse = interface
    ['{F7DDEEE1-13B7-4EAA-927F-55F680B0FBFC}']
    function Header(const AName: string): string;
    function ContentText: string;
  end;

  TGraphQLHTTPRequestEvent = procedure (AContext: TObject; AHttpClient: TIdHttp) of object;

  TGraphQLHTTPResponse = class(TInterfacedObject, IGraphQLHTTPResponse)
  protected
    FHeaders: TDictionary<string,string>;
    FContextText: string;
  public
    { IGraphQLHTTPResponse }
    function ContentText: string; virtual;
    function Header(const AName: string): string; virtual;

    constructor Create;
    destructor Destroy; override;
  end;

  TGraphQLReSTEntity = class
  private
    FEntity: string;
    FIdProperty: string;
    FUrl: string;
    FParentEntityName: string;
  public
    property Entity: string read FEntity;
    property Url: string read FUrl;
    property IdProperty: string read FIdProperty;
    property ParentEntityName: string read FParentEntityName;

    constructor Create(AEntity, AUrl, AIdProperty: string);
  end;

  TGraphQLReSTResolver = class(TInterfacedObject, IGraphQLResolver)
  private
    FEntityMap: TObjectDictionary<string,TGraphQLReSTEntity>;
    FHTTPRequestBuilder: TFunc<string, TObject, IGraphQLHTTPResponse>;
    FBeforeRequestEvent: TGraphQLHTTPRequestEvent;
    FAfterRequestEvent: TGraphQLHTTPRequestEvent;
    function BuildUrl(AEntity: TGraphQLReSTEntity; AParams: TGraphQLParams): string;
    function ValueToString(LValue: TValue): string;
    function MakeHTTPRequest(const AUrl: string; AContext: TObject): IGraphQLHTTPResponse;
    procedure InitRequestBuilder;
  public
    { IGraphQLResolver }
    function Resolve(AContext: TObject; AParams: TGraphQLParams): TValue;
    procedure MapEntity(const AEntity, AUrl: string; const AIdProperty: string = 'id');

    property BeforeRequestEvent: TGraphQLHTTPRequestEvent read FBeforeRequestEvent write FBeforeRequestEvent;
    property AfterRequestEvent: TGraphQLHTTPRequestEvent read FAfterRequestEvent write FAfterRequestEvent;
    property HTTPRequestBuilder: TFunc<string, TObject, IGraphQLHTTPResponse> read FHTTPRequestBuilder write FHTTPRequestBuilder;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

type
  TGraphQLHTTPResponseIndy = class(TGraphQLHTTPResponse)
  public
    constructor Create(const AContentText: string; AResponse: TIdHTTPResponse);
  end;

{ TGraphQLReSTResolver }

constructor TGraphQLReSTResolver.Create;
begin
  inherited Create;
  FEntityMap := TObjectDictionary<string,TGraphQLReSTEntity>.Create([doOwnsValues]);
  InitRequestBuilder;
end;

destructor TGraphQLReSTResolver.Destroy;
begin
  FEntityMap.Free;
  inherited;
end;

procedure TGraphQLReSTResolver.InitRequestBuilder;
begin
  FHTTPRequestBuilder :=
    function (AUrl: string; AContent: TObject): IGraphQLHTTPResponse
    var
      LHttpClient: TIdHttp;
      LResponseText: string;
    begin
      LHttpClient := TIdHTTP.Create(nil);
      try
        if Assigned(FBeforeRequestEvent) then
          FBeforeRequestEvent(AContent, LHttpClient);
        LResponseText := LHttpClient.Get(AUrl);
        if Assigned(FAfterRequestEvent) then
          FAfterRequestEvent(AContent, LHttpClient);
        Result := TGraphQLHTTPResponseIndy.Create(LResponseText, LHttpClient.Response);
      finally
        LHttpClient.Free;
      end;
    end;

end;

procedure TGraphQLReSTResolver.MapEntity(const AEntity,
  AUrl, AIdProperty: string);
begin
  FEntityMap.Add(AEntity, TGraphQLReSTEntity.Create(AEntity, AUrl, AIdProperty));
end;

function TGraphQLReSTResolver.ValueToString(LValue: TValue): string;
const
  BoolStr: array [Boolean] of string = ('false', 'true');
begin
  case LValue.Kind of
    tkEnumeration: begin
      if LValue.TypeInfo = TypeInfo(Boolean) then
        Result := BoolStr[LValue.AsBoolean]
      else
        Result := LValue.ToString;
    end;
    else
      Result := LValue.ToString;
  end;
end;

function TGraphQLReSTResolver.BuildUrl(AEntity: TGraphQLReSTEntity; AParams: TGraphQLParams): string;
var
  LParamPair: TPair<string, TValue>;
  LQueryParams: string;
  LMatches: TMatchCollection;
  LMatch: TMatch;
  LValue: string;
  LParentIdProperty: string;
  LParentEntity: TGraphQLReSTEntity;
begin
  Result := AEntity.Url;
  LQueryParams := '';
  for LParamPair in AParams do
  begin
    LValue := ValueToString(LParamPair.Value);
    if Pos('{' + LParamPair.Key + '}', Result) > 0 then
      Result := StringReplace(Result, '{' + LParamPair.Key + '}', TNetEncoding.URL.EncodeQuery(LValue), [])
    else
    begin
      LQueryParams := LQueryParams + TNetEncoding.URL.EncodeQuery(LParamPair.Key) + '=' + TNetEncoding.URL.EncodeQuery(LValue) + '&';
    end;
  end;

  if Assigned(AParams.Parent) then
  begin
    LParentIdProperty := 'id';
    if FEntityMap.TryGetValue(AEntity.ParentEntityName, LParentEntity) then
      LParentIdProperty := LParentEntity.IdProperty;
    Result := StringReplace(Result, '{parentId}', TNetEncoding.URL.EncodeQuery(AParams.Parent.GetValue<string>(LParentIdProperty)), []);
  end;

  // Strip templates
  LMatches := TRegEx.Matches(Result, '\{.+\}');
  for LMatch in LMatches do
  begin
    Result := StringReplace(Result, LMatch.Value, '', []);
  end;

  if LQueryParams <> '' then
    Result := Result + '?' + LQueryParams;

end;

function TGraphQLReSTResolver.MakeHTTPRequest(const AUrl: string; AContext: TObject): IGraphQLHTTPResponse;
begin
  if not Assigned(FHTTPRequestBuilder) then
    raise EGraphQLError.Create('FHTTPRequestBuilder not assigned');

  Result := FHTTPRequestBuilder(AUrl, AContext);
end;

function TGraphQLReSTResolver.Resolve(AContext: TObject; AParams: TGraphQLParams): TValue;
var
  LEntity: TGraphQLReSTEntity;
  LHTTPResponse: IGraphQLHTTPResponse;
  LUrl: string;
begin
  if FEntityMap.TryGetValue(AParams.FieldName, LEntity) then
  begin
    LUrl := BuildUrl(LEntity, AParams);

    LHTTPResponse := MakeHTTPRequest(LUrl, AContext);

    if LHTTPResponse.Header('Content-Type').Contains('application/json') then
      Result := TJSONObject.ParseJSONValue(LHTTPResponse.ContentText)
    else
      Result := LHTTPResponse.ContentText;
  end;
end;

{ TGraphQLHTTPResponse }

function TGraphQLHTTPResponse.ContentText: string;
begin
  Result := FContextText;
end;

constructor TGraphQLHTTPResponse.Create;
begin
  inherited;
  FHeaders := TDictionary<string,string>.Create;
end;

destructor TGraphQLHTTPResponse.Destroy;
begin
  FHeaders.Free;
  inherited;
end;

function TGraphQLHTTPResponse.Header(const AName: string): string;
begin
  if not FHeaders.TryGetValue(AName, Result) then
    Result := '';
end;

{ TGraphQLHTTPResponseIndy }

constructor TGraphQLHTTPResponseIndy.Create(const AContentText: string; AResponse: TIdHTTPResponse);
var
  LIndex: Integer;
  LHeaderName: string;
begin
  inherited Create;
  FContextText := AContentText;
  for LIndex := 0 to AResponse.RawHeaders.Count - 1 do
  begin
    LHeaderName := AResponse.RawHeaders.Names[LIndex];
    FHeaders.Add(LHeaderName, AResponse.RawHeaders.Values[LHeaderName]);
  end;
end;

{ TGraphQLReSTEntity }

constructor TGraphQLReSTEntity.Create(AEntity, AUrl, AIdProperty: string);
var
  LEntityNamePair: TArray<string>;
begin
  inherited Create;
  FEntity := AEntity;
  FUrl := AUrl;
  FIdProperty := AIdProperty;

  LEntityNamePair := FEntity.Split(['/']);
  if Length(LEntityNamePair) > 1 then
    FParentEntityName := LEntityNamePair[0]
  else
    FParentEntityName := '';
end;

end.
