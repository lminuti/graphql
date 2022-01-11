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
unit Demo.ProxyServer;

interface

uses
  System.Classes, System.SysUtils, System.Rtti,
  IdHttpServer, IdContext, IdCustomHTTPServer, IdHeaderList,
  GraphQL.Resolver.Core, GraphQL.Query;

type
  TAsyncLogEvent = procedure (ASender: TObject; const AMessage: string) of object;

  TProxyServer = class(TObject)
  private
    FPort: Integer;
    FHttpServer: TIdHTTPServer;
    FQuery: TGraphQLQuery;
    FOnAsyncLog: TAsyncLogEvent;

    procedure HandleCreatePostStream(AContext: TIdContext; AHeaders: TIdHeaderList; var VPostStream: TStream);
    procedure HandleCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure HandleDoneWithPostStream(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; var VCanFree: Boolean);
    function GetActive: Boolean;
    procedure SetActive(const Value: Boolean);

    function CreateResolver: IGraphQLResolver;
    procedure AsyncLog(const AMessage: string);
  public
    property Port: Integer read FPort write FPort;
    property Active: Boolean read GetActive write SetActive;
    property OnAsyncLog: TAsyncLogEvent read FOnAsyncLog write FOnAsyncLog;

    procedure Connect;
    procedure Disconnect;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TProxyServer }

uses
  GraphQL.Resolver.ReST;

procedure TProxyServer.AsyncLog(const AMessage: string);
var
  LMessage: string;
begin
  if Assigned(FOnAsyncLog) then
  begin

    LMessage := StringReplace(AMessage, #13, '', [rfReplaceAll]);
    LMessage := StringReplace(LMessage, #10, '', [rfReplaceAll]);
    LMessage := Copy(LMessage, 1, 200);

    FOnAsyncLog(Self, LMessage);
  end;
end;

procedure TProxyServer.Connect;
begin
  FHttpServer.DefaultPort := FPort;
  FHttpServer.Active := True;
end;

constructor TProxyServer.Create;
begin
  FHttpServer := TIdHTTPServer.Create(nil);
  FHttpServer.OnCommandGet := HandleCommandGet;
  FHttpServer.OnCreatePostStream := HandleCreatePostStream;
  FHttpServer.OnDoneWithPostStream := HandleDoneWithPostStream;

  FQuery := TGraphQLQuery.Create;

  FQuery.RegisterFunction('test',
    function (AParams: TGraphQLParams) :TValue
    begin
      Result := 'ok';
    end
  );

  FQuery.RegisterResolver(CreateResolver);
end;

function TProxyServer.CreateResolver: IGraphQLResolver;
var
  LResolver: TGraphQLReSTResolver;
begin
  LResolver := TGraphQLReSTResolver.Create;

  LResolver.MapEntity('posts', 'https://jsonplaceholder.typicode.com/posts/{id}');
  LResolver.MapEntity('comments', 'https://jsonplaceholder.typicode.com/comments/{id}');
  LResolver.MapEntity('albums', 'https://jsonplaceholder.typicode.com/albums/{id}');
  LResolver.MapEntity('todos', 'https://jsonplaceholder.typicode.com/todos/{id}');
  LResolver.MapEntity('users', 'https://jsonplaceholder.typicode.com/users/{id}');

  Result := LResolver;
end;

destructor TProxyServer.Destroy;
begin
  FQuery.Free;
  FHttpServer.Free;
  inherited;
end;

procedure TProxyServer.Disconnect;
begin
  FHttpServer.Active := False;
end;

function TProxyServer.GetActive: Boolean;
begin
  Result := FHttpServer.Active;
end;

procedure TProxyServer.HandleCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  LQuery: UTF8String;
  LPostStream: TStream;
begin
  LPostStream := TStream(AContext.Data);
  try

    AResponseInfo.ContentType := 'application/json';
    LQuery := '';
    if LPostStream.Size > 0 then
    begin
      LPostStream.Position := 0;
      SetLength(LQuery, LPostStream.Size);
      LPostStream.Read(LQuery[1], LPostStream.Size);
    end;
    AsyncLog('Request: ' + ARequestInfo.Command + ' ' + ARequestInfo.Document + ' body>>> ' + string(LQuery));
    AResponseInfo.ContentText := FQuery.Run(string(LQuery));

  finally
    LPostStream.Free;
    AContext.Data := nil;
  end;
  AsyncLog('Response: ' + AResponseInfo.ResponseNo.ToString + ' ' + AResponseInfo.ResponseText + ' body>>> ' + AResponseInfo.ContentText);
end;

procedure TProxyServer.HandleCreatePostStream(AContext: TIdContext;
  AHeaders: TIdHeaderList; var VPostStream: TStream);
begin
  VPostStream := TMemoryStream.Create;
  AContext.Data := VPostStream;
end;

procedure TProxyServer.HandleDoneWithPostStream(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; var VCanFree: Boolean);
begin
  VCanFree := False;
end;

procedure TProxyServer.SetActive(const Value: Boolean);
begin
  if Value then
    Connect
  else
    Disconnect;
end;

end.
