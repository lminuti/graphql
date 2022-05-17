unit Demo.Form.Parameters;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Json, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, GraphQL.Core, GraphQL.Resolver.Core,
  Vcl.ExtCtrls, Vcl.Grids, Vcl.StdCtrls, System.Rtti;

type
  TParametersForm = class(TForm)
    ParamsGrid: TStringGrid;
    Toolbar: TPanel;
    OkButton: TButton;
    CancelButton: TButton;
    procedure CancelButtonClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
    procedure ParamsGridSelectCell(Sender: TObject; ACol, ARow: Integer; var
        CanSelect: Boolean);
  private
    FVariables: string;
    FGraphQL: IGraphQL;
  public
    class function GetVariables(const AGraphQL: string): string;
  end;

implementation

{$R *.dfm}

uses
  GraphQL.SyntaxAnalysis.Builder;

procedure TParametersForm.CancelButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TParametersForm.FormShow(Sender: TObject);
var
  LIndex: Integer;
  LDefaultValue: TValue;
begin
  ParamsGrid.RowCount := FGraphQL.ParamCount + 1;
  ParamsGrid.Cells[1, 0] := 'Name';
  ParamsGrid.Cells[2, 0] := 'Type';
  ParamsGrid.Cells[3, 0] := 'Value';
  for LIndex := 0 to FGraphQL.ParamCount - 1 do
  begin
    LDefaultValue := FGraphQL.Params[LIndex].DefaultValue;

    ParamsGrid.Cells[1, LIndex + 1] := FGraphQL.Params[LIndex].ParamName;
    ParamsGrid.Cells[2, LIndex + 1] := VariableTypeToStr(FGraphQL.Params[LIndex].ParamType);
    if LDefaultValue.IsEmpty then
      ParamsGrid.Cells[3, LIndex + 1] := ''
    else
      ParamsGrid.Cells[3, LIndex + 1] := LDefaultValue.ToString;
  end;
end;

{ TParametersForm }

class function TParametersForm.GetVariables(const AGraphQL: string): string;
var
  LBuilder: TGraphQLBuilder;
  LGraphQL: IGraphQL;
  ParametersForm: TParametersForm;
begin
  Result := '';
  LBuilder := TGraphQLBuilder.Create(AGraphQL);
  try
    LGraphQL := LBuilder.Build;

    if LGraphQL.ParamCount > 0 then
    begin
      ParametersForm := TParametersForm.Create(nil);
      try
        ParametersForm.FGraphQL := LGraphQL;
        if ParametersForm.ShowModal <> mrOk then
          Abort;

        Result := ParametersForm.FVariables;

      finally
        ParametersForm.Free;
      end;
    end;

  finally
    LBuilder.Free;
  end;

end;

procedure TParametersForm.OkButtonClick(Sender: TObject);
var
  LIndex: Integer;
  LVariablesJson: TJSONObject;
  LJsonValue: TJSONValue;
  LValue: string;
begin
  LVariablesJson := TJSONObject.Create;
  try
    for LIndex := 0 to FGraphQL.ParamCount - 1 do
    begin
      LValue := ParamsGrid.Cells[3, LIndex + 1];
      case FGraphQL.Params[LIndex].ParamType of
        TGraphQLVariableType.StringType: LJsonValue := TJSONString.Create(LValue);
        TGraphQLVariableType.IntType: LJsonValue := TJSONNumber.Create(StrToInt(LValue));
        TGraphQLVariableType.FloatType: LJsonValue := TJSONNumber.Create(StrToFloat(LValue));
        TGraphQLVariableType.BooleanType: LJsonValue := TJSONBool.Create(StrToBool(LValue)) ;
        TGraphQLVariableType.IdType: LJsonValue := TJSONString.Create(LValue);
        else
          raise Exception.Create('Unsupported datatype');
      end;
      LVariablesJson.AddPair(FGraphQL.Params[LIndex].ParamName, LJsonValue);
    end;
    FVariables := LVariablesJson.ToJSON;
  finally
    LVariablesJson.Free;
  end;

  ModalResult := mrOk;
end;

procedure TParametersForm.ParamsGridSelectCell(Sender: TObject; ACol, ARow:
    Integer; var CanSelect: Boolean);
begin
  if ACol = 3 then
    ParamsGrid.Options := ParamsGrid.Options + [goEditing]
  else
    ParamsGrid.Options := ParamsGrid.Options - [goEditing];
end;

end.
