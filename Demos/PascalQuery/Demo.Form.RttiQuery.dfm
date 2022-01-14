object RttiQueryForm: TRttiQueryForm
  Left = 0
  Top = 0
  Caption = 'RTTI Demo'
  ClientHeight = 450
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
    450)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 63
    Width = 62
    Height = 13
    Caption = 'Choose a file'
  end
  object SourceMemo: TMemo
    Left = 8
    Top = 85
    Width = 433
    Height = 303
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
    Top = 394
    Width = 169
    Height = 47
    Anchors = [akLeft, akBottom]
    Caption = 'Execute GrapgQL query (F5)'
    TabOrder = 1
    OnClick = RunQueryButtonClick
  end
  object ResultMemo: TMemo
    Left = 459
    Top = 85
    Width = 433
    Height = 303
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
    Top = 58
    Width = 353
    Height = 21
    TabOrder = 3
    OnChange = FilesComboBoxChange
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 905
    Height = 52
    Align = alTop
    BevelOuter = bvNone
    Caption = 'Panel1'
    Color = clWhite
    ParentBackground = False
    ShowCaption = False
    TabOrder = 4
    ExplicitLeft = -6
    ExplicitWidth = 911
    object Label2: TLabel
      Left = 8
      Top = 4
      Width = 156
      Height = 25
      Caption = 'Graph for Delphi'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object Label3: TLabel
      Left = 8
      Top = 31
      Width = 65
      Height = 16
      Caption = 'RTTI Demo'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
  end
end
