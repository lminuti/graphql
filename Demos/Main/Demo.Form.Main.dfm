object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Syntax analysis Demo'
  ClientHeight = 588
  ClientWidth = 911
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
    911
    588)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 64
    Width = 62
    Height = 13
    Caption = 'Choose a file'
  end
  object SourceMemo: TMemo
    Left = 8
    Top = 88
    Width = 433
    Height = 261
    Anchors = [akLeft, akTop, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object LogMemo: TMemo
    Left = 8
    Top = 395
    Width = 893
    Height = 185
    Anchors = [akLeft, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Consolas'
    Font.Style = []
    Lines.Strings = (
      '...')
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
    ExplicitTop = 327
  end
  object TreeBuilderButton: TButton
    Left = 8
    Top = 355
    Width = 150
    Height = 34
    Anchors = [akLeft, akBottom]
    Caption = 'Build syntax tree (F5)'
    TabOrder = 2
    OnClick = TreeBuilderButtonClick
    ExplicitTop = 287
  end
  object SyntaxTreeView: TTreeView
    Left = 458
    Top = 88
    Width = 445
    Height = 261
    Anchors = [akLeft, akTop, akRight, akBottom]
    Indent = 19
    ReadOnly = True
    TabOrder = 3
  end
  object FilesComboBox: TComboBox
    Left = 88
    Top = 59
    Width = 353
    Height = 21
    TabOrder = 4
    OnChange = FilesComboBoxChange
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 911
    Height = 52
    Align = alTop
    BevelOuter = bvNone
    Caption = 'Panel1'
    Color = clWhite
    ParentBackground = False
    ShowCaption = False
    TabOrder = 5
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
      Width = 87
      Height = 16
      Caption = 'Syntax analysis'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
  end
end
