program RttiQuery;

uses
  Vcl.Forms,
  Demo.Form.RttiQuery in 'Demo.Form.RttiQuery.pas' {RttiQueryForm},
  GraphQL.Query.Rtti in '..\..\Source\GraphQL.Query.Rtti.pas',
  Demo.API.Test in 'Demo.API.Test.pas',
  GraphQL.Classes in '..\..\Source\GraphQL.Classes.pas',
  GraphQL.Core in '..\..\Source\GraphQL.Core.pas',
  GraphQL.Lexer.Core in '..\..\Source\GraphQL.Lexer.Core.pas',
  GraphQL.SyntaxAnalysis.Builder in '..\..\Source\GraphQL.SyntaxAnalysis.Builder.pas',
  GraphQL.SyntaxAnalysis.Core in '..\..\Source\GraphQL.SyntaxAnalysis.Core.pas',
  GraphQL.Utils.JSON in '..\..\Source\GraphQL.Utils.JSON.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TRttiQueryForm, RttiQueryForm);
  Application.Run;
end.
