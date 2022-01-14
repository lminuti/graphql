program MainDemo;

uses
  Vcl.Forms,
  Demo.Form.Main in 'Demo.Form.Main.pas' {MainForm},
  GraphQL.Classes in '..\..\Source\GraphQL.Classes.pas',
  GraphQL.Core in '..\..\Source\GraphQL.Core.pas',
  GraphQL.Lexer.Core in '..\..\Source\GraphQL.Lexer.Core.pas',
  GraphQL.SyntaxAnalysis.Builder in '..\..\Source\GraphQL.SyntaxAnalysis.Builder.pas',
  GraphQL.SyntaxAnalysis.Core in '..\..\Source\GraphQL.SyntaxAnalysis.Core.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
