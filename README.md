# APIcasso Brush [![Build Status](https://travis-ci.com/ErvalhouS/apicasso_brush.svg?branch=master)](https://travis-ci.com/ErvalhouS/apicasso_brush) [![Maintainability](https://api.codeclimate.com/v1/badges/5286908f324e1446e1ac/maintainability)](https://codeclimate.com/github/ErvalhouS/apicasso_brush/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/5286908f324e1446e1ac/test_coverage)](https://codeclimate.com/github/ErvalhouS/apicasso_brush/test_coverage) [![Inline docs](http://inch-ci.org/github/ErvalhouS/apicasso_brush.svg?branch=master)](http://inch-ci.org/github/ErvalhouS/apicasso_brush)
## Consume your APIcasso microservices
This is a client to consume data from microservices built upon [APIcasso](https://github.com/ErvalhouS/apicasso). It makes PORO classes supercharged by injecting Rails-like behavior through the methods:

 - `find()`
 - `all()`
 - `where()`
 - `save`

Instead of translating those calls into ORM **APIcasso Brush** retrieves it's data from your configured service. This makes it possible to make a convergent application, that gets data from multiple API sources.

## Usage
To start consuming from your services just create a class inheriting from `Apicasso::Brush` and declare how APIcasso should stroke the brush. First declare the base for current class, which is a index action from your API for the given resource, then pass a token that has access into that resource.

```ruby
class ModelFromService < Apicasso::Brush
  brush_on 'http://my.service.com/model',
           token: '5e1057e7a51ee7a55',
           include: :a_relation, :a_method # Optional
end
```
You can also by default include relations or methods that should get built into your `ModelFromService` objects.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'apicasso_brush'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install apicasso_brush
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
