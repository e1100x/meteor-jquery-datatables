class DataTable
  @debug: false

  @countCollection: "datatable_subscription_count"

  @isDebug: -> return DataTable.debug or false

  @log: ( message, object ) ->
    if DataTable.isDebug()
      if message.indexOf( DataTable.isDebug() ) isnt -1 or DataTable.isDebug() is "true"
        console.log "dataTable:#{ message } ->", object

  @publish: ( subscription, collection ) ->
    Match.test subscription, String
    Match.test collection, Object
    Meteor.publish subscription, ( baseQuery, filteredQuery, options ) ->
      self = @
      initialized = false
      countInitialized = false
      Match.test baseQuery, Object
      Match.test filteredQuery, Object
      Match.test options, Object
      DataTable.log "#{ subscription }:query:base", baseQuery
      DataTable.log "#{ subscription }:query:filtered", filteredQuery
      DataTable.log "#{ subscription }:options", options
      updateCount = ( ready, first = false ) ->
        if ready
          total = collection.find( baseQuery ).count()
          DataTable.log "#{ subscription }:count:total", total
          filtered = collection.find( filteredQuery ).count()
          DataTable.log "#{ subscription }:count:filtered", filtered
          if first
            self.added( DataTable.countCollection, subscription, { count: total } )
            self.added( DataTable.countCollection, "#{ subscription }_filtered", { count: filtered } )
          else
            self.changed( DataTable.countCollection, subscription, { count: total } )
            self.changed( DataTable.countCollection, "#{ subscription }_filtered", { count: filtered } )
      handle = collection.find( filteredQuery, options ).observe
        addedAt: ( doc, index, before ) ->
          updateCount initialized
          self.added collection._name, doc._id, doc
          DataTable.log "#{ subscription }:added", doc._id
        changedAt: ( newDoc, oldDoc, index ) ->
          updateCount initialized
          self.changed collection._name, newDoc._id, newDoc
          DataTable.log "#{ subscription }:changed", newDoc._id
        removedAt: ( doc, index ) ->
          updateCount initialized
          self.removed collection._name, doc._id
          DataTable.log "#{ subscription }:removed", doc._id
      initialized = true
      updateCount initialized, true
      self.ready()
      lastPage = collection.find( filteredQuery ).count() - options.limit
      if lastPage > 0
        countOptions = options
        countOptions.skip = lastPage
        countHandle = collection.find( filteredQuery, countOptions ).observe
          addedAt: -> updateCount countInitialized
          changedAt: -> updateCount countInitialized
          removedAt: -> updateCount countInitialized
        countInitialized = true
        self.onStop ->
          handle.stop()
          countHandle.stop()