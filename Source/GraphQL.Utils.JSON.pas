{******************************************************************************}
{                                                                              }
{  Delphi GraphQL                                                              }
{  Copyright (c) 2022 Luca Minuti                                              }
{  https://github.com/lminuti/graphql                                          }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit GraphQL.Utils.JSON;

interface

uses
  System.SysUtils, System.Classes, System.StrUtils, System.JSON;

type
  TJSONHelper = class(TObject)
  public
    class function PrettyPrint(AJSONValue: TJSONValue): string; overload; static;
    class function PrettyPrint(const AJSONString: string): string; overload; static;
    class function QuoteString(const AValue: string): string; static;
  end;

implementation

class function TJSONHelper.QuoteString(const AValue: string): string;
begin
  Result := '"' + AnsiReplaceStr(AValue, '"', '\"') + '"';
end;

class function TJSONHelper.PrettyPrint(AJSONValue: TJSONValue): string;
var
  LJSONString: string;
begin
  LJSONString := AJSONValue.ToString;
  Result := TJSONHelper.PrettyPrint(LJSONString);
end;

class function TJSONHelper.PrettyPrint(const AJSONString: string): string;
var
  LPrevousChar: Char;
  LChar: Char;
  LOffset: Integer;
  LInString: Boolean;

  function Spaces(AOffset: Integer): string;
  begin
    Result := StringOfChar(#32, AOffset * 2);
  end;

begin
  Result := '';
  LOffset := 0;
  LPrevousChar := #0;
  LInString := False;
  for LChar in AJSONString do
  begin
    if (LChar = '"') and (LPrevousChar <> '\') then
    begin
      LInString := not LInString;
      Result := Result + LChar;
    end
    else if LInString then
    begin
      Result := Result + LChar;
    end
    else if LChar = '{' then
    begin
      Inc(LOffset);
      Result := Result + LChar;
      Result := Result + sLineBreak;
      Result := Result + Spaces(LOffset);
    end
    else if LChar = '}' then
    begin
      Dec(LOffset);
      Result := Result + sLineBreak;
      Result := Result + Spaces(LOffset);
      Result := Result + LChar;
    end
    else if LChar = ',' then
    begin
      Result := Result + LChar;
      Result := Result + sLineBreak;
      Result := Result + Spaces(LOffset);
    end
    else if LChar = '[' then
    begin
      Inc(LOffset);
      Result := Result + LChar;
      Result := Result + sLineBreak;
      Result := Result + Spaces(LOffset);
    end
    else if LChar = ']' then
    begin
      Dec(LOffset);
      Result := Result + sLineBreak;
      Result := Result + Spaces(LOffset);
      Result := Result + LChar;
    end
    else
      Result := Result + LChar;
    LPrevousChar := LChar;
  end;
end;

end.
