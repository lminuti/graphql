object RttiQueryForm: TRttiQueryForm
  Left = 0
  Top = 0
  Caption = 'RttiQueryForm'
  ClientHeight = 367
  ClientWidth = 905
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnCreate = FormCreate
  OnKeyUp = FormKeyUp
  DesignSize = (
    905
    367)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 10
    Width = 62
    Height = 13
    Caption = 'Choose a file'
  end
  object SourceMemo: TMemo
    Left = 8
    Top = 32
    Width = 433
    Height = 273
    Anchors = [akLeft, akTop, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object RunQueryButton: TButton
    Left = 8
    Top = 311
    Width = 153
    Height = 47
    Anchors = [akLeft, akBottom]
    Caption = 'Run GraphQL query (F5)'
    TabOrder = 1
    OnClick = RunQueryButtonClick
  end
  object ResultMemo: TMemo
    Left = 459
    Top = 32
    Width = 433
    Height = 273
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 2
    WordWrap = False
  end
  object FilesComboBox: TComboBox
    Left = 88
    Top = 5
    Width = 353
    Height = 21
    TabOrder = 3
    OnChange = FilesComboBoxChange
  end
end
