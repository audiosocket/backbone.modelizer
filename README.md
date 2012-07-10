backbone.modelizer
==================

backbone.modelizer adds two features to [Backbone](http://backbonejs.org/):

* Identity map on all models
* Optional modelizing routines

Identity map
============

Identity map wraps around all models. When instantiating a model such as:

    model = new Backbone.Model({id: 8})

Additionaly, you can also do:

    model = new Backbone.Model(8)

All models also have `retain` and `release` methods, which should be called
by the views in order to retain/release their model.

The global function `Backbone.IdentityMap.gc()` removes all mappings that
have not been retained by any view.

Modelizer
=========

Models can define associations:

```
  Model.prototype.associations: {
    account: {
      model: Account
    }
  
    licenses: {
      collection: Licenses
      url:        "base/url" (optional)
      scope:      "foo" (optional)
    }
  }
```

`Model.prototype.associations` can also be a function.

If model `model` has association `account: { model: Account }` then
`model.account` will be defined as an instance of `Account` and any `account`
attribute returned for `model` is set on `model.account`. Meanwhile, `model.attributes.account`
is set to `model.account.id`

If model `model` has association `licenses: { collection: Licenses }` then 
`model.licenses` will be defined as an instance of `Licenses` and any `licenses`
attribute returned for `model` is set on `model.licenses`. Meanwhile, `model.attributes.licenses`
is set to `_.pluck account.licenses, "id"`.
 
Url parameter sets the url property on the associated collection.

Scope parameter tells the model to add a reference to itself on the collection, e.g.
`licenses.foo = model`

Using
=====

You should include `backbone.modelizer.js` after including `jquery`, `underscore` and `backbone.js`
and before including any of your model classes.
