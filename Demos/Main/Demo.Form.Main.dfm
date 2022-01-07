object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'MainDemo'
  ClientHeight = 520
  ClientWidth = 911
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    911
    520)
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
    Height = 288
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
    Top = 366
    Width = 893
    Height = 146
    Anchors = [akLeft, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Consolas'
    Font.Style = []
    Lines.Strings = (
      '...')
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
  object RunLexerButton: TButton
    Left = 8
    Top = 326
    Width = 150
    Height = 34
    Anchors = [akLeft, akBottom]
    Caption = 'Read token'
    TabOrder = 2
    OnClick = Button1Click
  end
  object SyntaxCheckButton: TButton
    Left = 164
    Top = 326
    Width = 150
    Height = 34
    Anchors = [akLeft, akBottom]
    Caption = 'Syntax check'
    TabOrder = 3
    OnClick = SyntaxCheckButtonClick
  end
  object btnTreeBuilder: TButton
    Left = 320
    Top = 326
    Width = 150
    Height = 34
    Anchors = [akLeft, akBottom]
    Caption = 'GraphBuilder'
    TabOrder = 4
    OnClick = btnTreeBuilderClick
  end
  object SyntaxTreeView: TTreeView
    Left = 458
    Top = 8
    Width = 445
    Height = 312
    Anchors = [akLeft, akTop, akRight, akBottom]
    Indent = 19
    ReadOnly = True
    TabOrder = 5
  end
  object FilesComboBox: TComboBox
    Left = 88
    Top = 5
    Width = 353
    Height = 21
    TabOrder = 6
    OnChange = FilesComboBoxChange
  end
end
