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
unit GraphQL.Core.Attributes;

interface

uses
  System.Classes, System.SysUtils, System.Rtti;

type
  GraphQLEntityAttribute = class(TCustomAttribute)
  private
    FValue: string;
  public
    constructor Create(const AValue: string = '');
    property Value: string read FValue write FValue;
  end;

implementation

{ GraphQLEntityAttribute }

constructor GraphQLEntityAttribute.Create(const AValue: string);
begin
  inherited Create;
  FValue := AValue;
end;

end.
