unit Demo.Form.Parameters;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
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
    FGraphQLVariables: IGraphQLVariables;
    FGraphQL: IGraphQL;
  public
    class function GetVariables(AGraphQL: IGraphQL): IGraphQLVariables;
  end;

implementation

{$R *.dfm}

procedure TParametersForm.CancelButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TParametersForm.FormShow(Sender: TObject);
var
  LIndex: Integer;
begin
  ParamsGrid.RowCount := FGraphQL.ParamCount + 1;
  ParamsGrid.Cells[1, 0] := 'Name';
  ParamsGrid.Cells[2, 0] := 'Type';
  ParamsGrid.Cells[3, 0] := 'Value';
  for LIndex := 0 to FGraphQL.ParamCount - 1 do
  begin
    ParamsGrid.Cells[1, LIndex + 1] := FGraphQL.Params[LIndex].ParamName;
    ParamsGrid.Cells[2, LIndex + 1] := VariableTypeToStr(FGraphQL.Params[LIndex].ParamType);
    if FGraphQL.Params[LIndex].DefaultValue.IsEmpty then
      ParamsGrid.Cells[3, LIndex + 1] := ''
    else
      ParamsGrid.Cells[3, LIndex + 1] := FGraphQL.Params[LIndex].DefaultValue.ToString;
  end;
end;

{ TParametersForm }

class function TParametersForm.GetVariables(
  AGraphQL: IGraphQL): IGraphQLVariables;
var
  ParametersForm: TParametersForm;
begin
  Result := TGraphQLVariables.Create;

  if AGraphQL.ParamCount > 0 then
  begin
    ParametersForm := TParametersForm.Create(nil);
    try
      ParametersForm.FGraphQLVariables := Result;
      ParametersForm.FGraphQL := AGraphQL;
      if ParametersForm.ShowModal <> mrOk then
        Abort;
    finally
      ParametersForm.Free;
    end;
  end;
end;

procedure TParametersForm.OkButtonClick(Sender: TObject);

  function GetParamValue(const AValue: string; AParamType: TGraphQLVariableType): TValue;
  begin
    case AParamType of
      TGraphQLVariableType.StringType: Result := AValue;
      TGraphQLVariableType.IntType: Result := StrToInt(AValue);
      TGraphQLVariableType.FloatType: Result := StrToFloat(AValue);
      TGraphQLVariableType.BooleanType: Result := StrToBool(AValue);
      TGraphQLVariableType.IdType: Result := AValue;
      else
        raise Exception.Create('GetParamValue: unsupported data type');
    end;
  end;

var
  LIndex: Integer;
begin
  for LIndex := 0 to FGraphQL.ParamCount - 1 do
  begin
    //FGraphQLVariables.Clear;
    FGraphQLVariables.SetVariable(FGraphQL.Params[LIndex].ParamName, GetParamValue(ParamsGrid.Cells[3, LIndex + 1], FGraphQL.Params[LIndex].ParamType))
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
