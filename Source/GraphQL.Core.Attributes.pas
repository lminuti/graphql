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
