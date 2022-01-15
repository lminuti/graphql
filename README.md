# GraphQL for Delphi

[![License](https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg)](https://opensource.org/licenses/Apache-2.0)

Simple implementation for GraphQL, a query language for APIs created by Facebook.

GraphQL is a query language for your API and a server-side runtime for executing queries using a type system you define for your data. GraphQL isn't tied to any specific database or storage engine and is instead backed by your existing code and data.

See more complete documentation at https://graphql.org/.

## Table of Contents

- [Features](#features)
  - [GraphQL tree navigation](#graphql-tree-navigation)
  - [Query your API with GraphQL](#query-your-api-with-graphql)
    - [Basic API](#basic-api)
    - [Run methods from a class using RTTI](#run-methods-from-a-class-using-rtti)
  - [Use API from a ReST server](#use-api-from-a-rest-server)
- [Todo](#todo)

<!-- /code_chunk_output -->

## Features

*GraphQL for Delphi* supports only a basic part of the [GraphQL specifications](https://spec.graphql.org/draft/):

* Fields
* Arguments
* Aliases

Other parts like *variables*, *schema* and *validation* are under development.

### GraphQL tree navigation

The more basic feature of *GraphQL for Delphi* is the possibility to explore the GraphQL query. 

With a code like this you can build the GraphQL tree:

```pascal
  LBuilder := TGraphQLBuilder.Create(SourceMemo.Text);
  try
    // This will create the tree
    LGraphQL := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
```

Then you will have a struture like this:

```
IGraphQL
├── Name
└── Fields
    ├── IGraphQLField (first entity)
    │   ├── Name
    │   ├── Alias
    │   ├── Arguments / Parameters
    │   │   ├─ IGraphQLArgument 
    │   │   └─ IGraphQLArgument 
    │   │
    │   └── IGraphQLValue (IGraphQLNull | IGraphQLObject)
    │       └─ Fields
    │          ├─ ...
    │          ├─ ...
    │
    └── IGraphQLField (second entity)
        ├── Name
        ├── Alias
        ├── ...
```

You can see the demo to have an idea of the capabilities of this library.

![](https://raw.githubusercontent.com/wiki/lminuti/graphql/demo1.png)

### Query your API with GraphQL

First of all you need an `API` to query. At this moment *GraphQL for Delphi* supports `classes` or simple `procedures and functions`. In either case you have to tell the library how to call your API.

#### Basic API

If you have a simple API made of classic functions like this:

```pascal
function RollDice(NumDices, NumSides: Integer): Integer;

function ReverseString(const Value: string): string;

function StarWarsHero(const Id: string): TStarWarsHero;
```

Then you need to register your API in this way:

```pascal
  FQuery := TGraphQLQuery.Create;

  FQuery.RegisterFunction('rollDice',
    function (AParams: TGraphQLParams) :TValue
    begin
      Result := RollDice(AParams.Get('numDice').AsInteger, AParams.Get('numSides').AsInteger);
    end
  );

  FQuery.RegisterFunction('reverseString',
    function (AParams: TGraphQLParams) :TValue
    begin
      Result := ReverseString(AParams.Get('value').AsString);
    end
  );

  FQuery.RegisterFunction('hero',
    function (AParams: TGraphQLParams) :TValue
    begin
      Result := StarWarsHero(AParams.Get('id').AsString);
    end
  );
```

Eventually you can query your API: 

```pascal

json := FQuery.Run(MyQuery);

```

#### Run methods from a class using RTTI

If you have a class you need to tell the library:

* how to create the instance;
* if the class is a *singleton* (or if the library should create a new instance for every method call);
* which methods GraphQL should query.

For example if you have a class like this:

```pascal
  TTestApi = class(TObject)
  private
    FCounter: Integer;
  public
    [GraphQLEntity]
    function Sum(a, b: Integer): Integer;

    [GraphQLEntity('mainHero')]
    function MainHero: TStarWarsHero;

  end;
```

You need to add the `GraphQLEntity` to every method queryable by GraphQL and register the class:

```pascal
  FQuery := TGraphQLQuery.Create;
  FQuery.RegisterResolver(TGraphQLRttiResolver.Create(TTestApi, True));
```

The `RegisterResolver` method can add a resolver (any class that implements `IGraphQLResolver`) to the GraphQL engine. A resolver is a simple object that explains to GraphQL how to get the data from the API. You can build your own resolvers or use the resolvers build-in with the library.

The `TGraphQLRttiResolver` is capable of running methods from a class using the [RTTI](https://docwiki.embarcadero.com/RADStudio/Sydney/en/Working_with_RTTI).

Then you can query your API: 

```pascal

json := FQuery.Run(MyQuery);

```

A simple query:

![](https://raw.githubusercontent.com/wiki/lminuti/graphql/GraphQL-Basic.gif)

How to use GraphQL aliases:

![](https://raw.githubusercontent.com/wiki/lminuti/graphql/GraphQL-Alias.gif)

How to call simple functions:

![](https://raw.githubusercontent.com/wiki/lminuti/graphql/GraphQL-RollDice.gif)

A more complex example:

![](https://raw.githubusercontent.com/wiki/lminuti/graphql/GraphQL-complex.gif)


### Use API from a ReST server

If you need to use GraphQL to queries a ReST API you can see the `ProxyDemo`. This simple project creates a basic HTTP server that responds to GraphQL query and uses a remote ReST API (https://jsonplaceholder.typicode.com/) as a data source.

The project uses a `TGraphQLReSTResolver` to map the GraphQL fields to the ReST API in this way:

```pascal
  FQuery := TGraphQLQuery.Create;

  LResolver := TGraphQLReSTResolver.Create;

  // Basic entities
  LResolver.MapEntity('posts', 'https://jsonplaceholder.typicode.com/posts/{id}');
  LResolver.MapEntity('comments', 'https://jsonplaceholder.typicode.com/comments/{id}');
  LResolver.MapEntity('albums', 'https://jsonplaceholder.typicode.com/albums/{id}');
  LResolver.MapEntity('todos', 'https://jsonplaceholder.typicode.com/todos/{id}');
  LResolver.MapEntity('users', 'https://jsonplaceholder.typicode.com/users/{id}');

  // Entity details
  LResolver.MapEntity('users/posts', 'https://jsonplaceholder.typicode.com/users/{parentId}/posts');
  LResolver.MapEntity('users/comments', 'https://jsonplaceholder.typicode.com/users/{parentId}/comments');
  LResolver.MapEntity('users/todos', 'https://jsonplaceholder.typicode.com/users/{parentId}/todos');

  FQuery.RegisterResolver(LResolver);

```

When you define an `entity` you can specify the name of the `id property` (default "id"). The id propery will be used if your entity as a detail. For example you have a resource like:

```url
https://jsonplaceholder.typicode.com/users/1
```

```json
{
  "userId": 1,
  "name": "Luca"
}
```

and a detail resource like:

```url
https://jsonplaceholder.typicode.com/users/1/todos
```

```json
[{
  "id": 1,
  "userId": 1,
  "title": "Something to do"
},{
  "id": 2,
  "userId": 1,
  "title": "Another thing to do"
}]
```

You must define the entities in this way:

```pascal
  LResolver.MapEntity('users', 'https://jsonplaceholder.typicode.com/users/{id}', 'userId');
  LResolver.MapEntity('users/todos', 'https://jsonplaceholder.typicode.com/users/{parentId}/todos');
```

Then, when you run the query with `FQuery.Run(...)`, the resolver can call the right ReST API.

![](https://raw.githubusercontent.com/wiki/lminuti/graphql/demo4.png)

## Todo

* :fire: `Variables`. GraphQL has a first-class way to factor dynamic values out of the query, and pass them as a separate dictionary. These values are called variables.
* :fire: `Schemas`, `types` and `validation`. Every GraphQL service defines a set of types which completely describe the set of possible data you can query on that service. Then, when queries come in, they are validated and executed against that schema.
* :thumbsup: `Fragments`. Fragments let you construct sets of fields, and then include them in queries where you need to.
* :question: `Directives`. A directive can be attached to a field or fragment inclusion, and can affect execution of the query in any way the server desires.
* :question: `Mutations`. Just like ReST any query can might end up causing some side-effects. However, it's useful to establish a convention that any operations that cause writes should be sent explicitly via a mutation.
