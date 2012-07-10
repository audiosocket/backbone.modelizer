Backbone.IdentityMap =
  # Global map
  kinds: {}
  maps:  {}

  # Get the identity map for a specific `kind` of model.

  for: (kind) ->
    id = null

    _.any @kinds, (value, key) ->
      if value == kind
        id = key
        return true

    unless id?
      @kinds[id = _.uniqueId("___identity_map")] = kind

    @maps[id] ||= {}

  # get an instance of `kind` with `id` if it exists.

  retrieve: (kind, id) ->
    map = @for kind
    map[id]

  # Store a new instance. Throw an error if it already exists.

  store: (kind, id, obj) ->
    map = @for kind
    throw new Error "Model already cached!" if map[id]? and map[id] isnt obj

    map[id] = obj

  # Garbage-collect: delete all instances with refCount == 0

  gc: ->
    _.each @maps, (map) ->
      _.each map, (obj, key) ->
        delete map[key] if obj.refCount == 0

class Backbone.Model extends Backbone.Model
  constructor: (attributes) ->
    attributes = { id: attributes } if _.isNumber attributes

    if attributes?.id?
      cached = Backbone.IdentityMap.retrieve @constructor, attributes.id

      if cached?
        cached.set attributes if _.keys(attributes).length > 1

        return cached

      Backbone.IdentityMap.store @constructor, attributes.id, this

    super attributes

  initialize: (attributes) ->
    super

    @modelize attributes

  # Like Backbone's normal `sync`, but run `modelize` after.

  sync: (method, model, options) ->
    success = options.success
    options.success = (attributes, status, xhr) =>
      if attributes?
        @modelize attributes, options, -> success attributes, status, xhr
      else
        success attributes, status, xhr

    (this._sync || Backbone.sync).call this, method, model, options

  # Attributes, meet associations. `modelize` is called after `sync`
  # and handles all the `associations` declared for this class.

  # Subclasses can define associations:
  #
  # associations:
  #   account:
  #     model: App.Model.Account
  #
  #   licenses:
  #     collection: App.Model.License
  #     url:        "base/url" (optional)
  #     scope:      "foo" (optional)
  #
  #
  #  scope parameter tells the model to add a reference
  #  to the calling model in the collection, e.g.
  #  collection.foo = this

  modelize: (attributes, options, success) =>
    if _.isFunction @associations
      associations = @associations()
    else
      associations = @associations

    success = success || ->

    # _.after 0, fn actually executes fn immediatly and returns `undefined`
    # but we may as well bail out right away..
    return success() if _.isEmpty associations

    cb = _.after _.size(associations), success

    _.each associations, (association, name) =>
      if association.model?
        obj = attributes[name]
        obj = { id: obj } if _.isNumber obj

        @[name] = new association.model(obj)

        attributes[name] = @[name].id
      else
        if @[name]?
          @[name].reset attributes[name] if _.isArray(attributes[name])
        else
          self = this

          class constructor extends association.collection
            constructor: ->
              if association.url?
                @url = association.url

              if association.scope?
                @[association.scope] = self

              super

          @[name] = new constructor attributes[name]

          if attributes[name]?
            attributes[name] = _.compact _.pluck(attributes[name], "id")

      cb()

  # Views use refcounting to expire things in the identity map.

  refCount: 0

  # Increase this model's refCount. Returns `this`.

  retain: ->
    ++@refCount

    this

  # Decrease this model's refCount.

  release: ->
    --@refCount

    this

  # With ID map, a model can belong to several collections
  # at once. Thus, we should never use the model's collection.url
  # like backbone does..
  url: ->
    base = if _.isFunction(@urlRoot) then @urlRoot() else @urlRoot

    throw new Error('A "urlRoot" property or function must be specified') unless base?

    return base if @isNew()

    sep = if base.charAt(base.length - 1) == "/" then "" else "/"

    "#{base}#{sep}#{encodeURIComponent(@id)}"
