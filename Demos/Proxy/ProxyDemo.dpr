program ProxyDemo;

uses
  Vcl.Forms,
  Demo.Form.ProxyClient in 'Demo.Form.ProxyClient.pas' {MainProxyForm},
  Demo.ProxyServer in 'Demo.ProxyServer.pas',
  GraphQL.Query in '..\..\Source\GraphQL.Query.pas',
  GraphQL.Core in '..\..\Source\GraphQL.Core.pas',
  GraphQL.Resolver.Core in '..\..\Source\GraphQL.Resolver.Core.pas',
  GraphQL.Lexer.Core in '..\..\Source\GraphQL.Lexer.Core.pas',
  GraphQL.Utils.JSON in '..\..\Source\GraphQL.Utils.JSON.pas',
  GraphQL.Utils.Rtti in '..\..\Source\GraphQL.Utils.Rtti.pas',
  GraphQL.Classes in '..\..\Source\GraphQL.Classes.pas',
  GraphQL.SyntaxAnalysis.Core in '..\..\Source\GraphQL.SyntaxAnalysis.Core.pas',
  GraphQL.Resolver.ReST in '..\..\Source\GraphQL.Resolver.ReST.pas',
  Demo.Form.Parameters in 'Demo.Form.Parameters.pas' {ParametersForm},
  GraphQL.SyntaxAnalysis.Builder in '..\..\Source\GraphQL.SyntaxAnalysis.Builder.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainProxyForm, MainProxyForm);
  Application.Run;
end.
