object ParametersForm: TParametersForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Parameters'
  ClientHeight = 354
  ClientWidth = 423
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ParamsGrid: TStringGrid
    Left = 0
    Top = 0
    Width = 423
    Height = 317
    Align = alClient
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing]
    TabOrder = 0
    OnSelectCell = ParamsGridSelectCell
  end
  object Toolbar: TPanel
    Left = 0
    Top = 317
    Width = 423
    Height = 37
    Align = alBottom
    BevelOuter = bvNone
    Caption = 'Toolbar'
    ShowCaption = False
    TabOrder = 1
    object OkButton: TButton
      Left = 15
      Top = 6
      Width = 75
      Height = 25
      Caption = 'OK'
      Default = True
      TabOrder = 0
      OnClick = OkButtonClick
    end
    object CancelButton: TButton
      Left = 96
      Top = 6
      Width = 75
      Height = 25
      Cancel = True
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = CancelButtonClick
    end
  end
end
