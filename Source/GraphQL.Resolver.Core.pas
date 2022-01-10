unit GraphQL.Resolver.Core;

interface

uses
  System.Classes, System.SysUtils, System.Rtti, Generics.Collections;

type
  TGraphQLParams = record
  private
    FFieldName: string;
    FParams: TDictionary<string, TValue>;
  public
    function Get(const AName: string): TValue;
    function Exists(const AName: string): Boolean;

    property FieldName: string read FFieldName;

    constructor Create(const AFieldName: string; AParams: TDictionary<string, TValue>);
  end;

  IGraphQLResolver = interface
    ['{31891A84-FC2B-479A-8D35-8E5EDD3CC359}']
    function Resolve(AParams: TGraphQLParams): TValue;
  end;

implementation

{ TGraphQLParams }

constructor TGraphQLParams.Create(const AFieldName: string;
  AParams: TDictionary<string, TValue>);
begin
  FFieldName := AFieldName;
  FParams := AParams;
end;

function TGraphQLParams.Exists(const AName: string): Boolean;
begin
  Result := FParams.ContainsKey(AName);
end;

function TGraphQLParams.Get(const AName: string): TValue;
begin
  Result := FParams.Items[AName];
end;

end.
