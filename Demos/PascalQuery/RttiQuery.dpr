program RttiQuery;

uses
  Vcl.Forms,
  Demo.Form.RttiQuery in 'Demo.Form.RttiQuery.pas' {RttiQueryForm},
  Demo.API.Test in 'Demo.API.Test.pas',
  GraphQL.Classes in '..\..\Source\GraphQL.Classes.pas',
  GraphQL.Core in '..\..\Source\GraphQL.Core.pas',
  GraphQL.Lexer.Core in '..\..\Source\GraphQL.Lexer.Core.pas',
  GraphQL.SyntaxAnalysis.Builder in '..\..\Source\GraphQL.SyntaxAnalysis.Builder.pas',
  GraphQL.SyntaxAnalysis.Core in '..\..\Source\GraphQL.SyntaxAnalysis.Core.pas',
  GraphQL.Utils.JSON in '..\..\Source\GraphQL.Utils.JSON.pas',
  GraphQL.Resolver.Core in '..\..\Source\GraphQL.Resolver.Core.pas',
  GraphQL.Resolver.Rtti in '..\..\Source\GraphQL.Resolver.Rtti.pas',
  GraphQL.Core.Attributes in '..\..\Source\GraphQL.Core.Attributes.pas',
  GraphQL.Utils.Rtti in '..\..\Source\GraphQL.Utils.Rtti.pas',
  GraphQL.Query in '..\..\Source\GraphQL.Query.pas',
  Demo.Form.Parameters in 'Demo.Form.Parameters.pas' {ParametersForm};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TRttiQueryForm, RttiQueryForm);
  Application.Run;
end.
