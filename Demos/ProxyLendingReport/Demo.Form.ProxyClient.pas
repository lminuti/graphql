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
unit Demo.Form.ProxyClient;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Winapi.ShellAPI, Demo.ProxyServer,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  Vcl.ExtCtrls, Vcl.Imaging.pngimage, IdContext, IdCustomTCPServer,
  IdCustomHTTPServer, IdHTTPServer, IdAuthentication;

type
  TMainProxyForm = class(TForm)
    SourceMemo: TMemo;
    RunQueryButton: TButton;
    ResultMemo: TMemo;
    Label1: TLabel;
    btnStart: TButton;
    btnStop: TButton;
    Label2: TLabel;
    edtPort: TEdit;
    IdHTTP1: TIdHTTP;
    memLog: TMemo;
    Panel1: TPanel;
    Image1: TImage;
    Label4: TLabel;
    Label5: TLabel;
    TokenEdit: TEdit;
    IdHTTPServer1: TIdHTTPServer;
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure IdHTTP1Authorization(Sender: TObject; Authentication:
        TIdAuthentication; var Handled: Boolean);
    procedure RunQueryButtonClick(Sender: TObject);
  private
    FProxyServer: TProxyServer;
    procedure HandleAsyncLog(ASender: TObject; const AMessage: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MainProxyForm: TMainProxyForm;

implementation

{$R *.dfm}

uses
  GraphQL.Utils.JSON;

{ TMainProxyForm }

constructor TMainProxyForm.Create(AOwner: TComponent);
begin
  inherited;
  FProxyServer := TProxyServer.Create;
  FProxyServer.OnAsyncLog := HandleAsyncLog;
end;

destructor TMainProxyForm.Destroy;
begin
  FProxyServer.Free;
  inherited;
end;

procedure TMainProxyForm.btnStartClick(Sender: TObject);
begin
  FProxyServer.Port := StrToIntDef(edtPort.Text, 8081);
  FProxyServer.Connect;
end;

procedure TMainProxyForm.btnStopClick(Sender: TObject);
begin
  FProxyServer.Disconnect;
end;

procedure TMainProxyForm.FormKeyUp(Sender: TObject; var Key: Word; Shift:
    TShiftState);
begin
  if Key = VK_F5 then
    RunQueryButton.Click;
end;

procedure TMainProxyForm.HandleAsyncLog(ASender: TObject;
  const AMessage: string);
begin
  TThread.Queue(nil, procedure
  begin
    memLog.Lines.Add(AMessage);
  end);
end;

procedure TMainProxyForm.IdHTTP1Authorization(Sender: TObject; Authentication:
    TIdAuthentication; var Handled: Boolean);
begin
  Handled := True;
end;

procedure TMainProxyForm.RunQueryButtonClick(Sender: TObject);
var
  LStringStream: TStringStream;
begin
  if not FProxyServer.Active then
  begin
    btnStart.Click;
  end;

  memLog.Clear;

  LStringStream := TStringStream.Create('{"query":' + TJSONHelper.QuoteString(SourceMemo.Text) + '}', TEncoding.UTF8);
  try
    IdHTTP1.Request.CustomHeaders.Values['Authorization'] := 'Bearer ' + TokenEdit.Text;
    ResultMemo.Text := TJSONHelper.PrettyPrint(IdHTTP1.Post('http://localhost:' + edtPort.Text, LStringStream));
  finally
    LStringStream.Free;
  end;
end;

end.
