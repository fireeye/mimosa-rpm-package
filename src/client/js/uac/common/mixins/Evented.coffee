###
  Adds eventing to a class.
###
define (require)->
  vent = require 'uac/common/vent'
  reqres = require 'uac/common/reqres'

  {
    #Must close over the vent and req/res singletons so new objects aren't created
    _getVent: -> vent
    _getReqRes: -> reqres

    #Generate a topic by convention. Should look like Class Name: Instance Name: Method Name
    _topicGenerator: (options = {})->
      {constructorName, instanceName, eventName} = options
      unless _.isString constructorName then constructorName = @constructor.name
      unless _.isString instanceName then instanceName = @instanceName

      "#{constructorName}:#{instanceName}:#{eventName}"

    ###
      Verify that the arguments are valid... most can be defaulted to something reasonable if omitted
      The expected set of arguments should look like this:

      options
        constructorName   #optional override used in topic generator
        instanceName      #optional override used in topic generator
        eventName         #required name of the event being registered
        handler           #required if registering a listener, the function to call when the event is triggered
        payload           #required if firing an event, the data that will be sent in the event
    ###
    _validArguments: (options = {})->
      unless _.isFunction(options.handler) || _.isObject(options.payload)
        throw "Evented::_validateArguments must specify either a handler or payload"
      unless _.isString options.eventName
        throw "Evented::_validateArguments must specify an event name"
      return true

    #You can override the default topic generator, and this is how the appropriate method is chosen
    _getTopicGenerator: (options = {})->
      if _.isFunction @topicGenerator then @topicGenerator(options)
      else if _.isFunction options.topicGenerator then options.topicGenerator(options)
      else @_topicGenerator(options)

    ###
      Register a new request / response listener. These events are point-to-point, meaning that only the component that
      fired the event will get a response. They will immediately return a value when called so they are most useful
      when proxying getters.
    ###
    registerReqRes: (options = {})->
      if @_validArguments(options) then @_getReqRes().setHandler @_getTopicGenerator(options), -> options.handler.apply(this,arguments)

    ###
      Register a new vent topic, which is analogous to pub / sub in GOF. These events are global, so every component
      registered as a listener will receive the event. They are asynchronous and do not return a value, so they are more
      useful for toggling state on a component

    ###
    registerVent: (options={})->
      if @_validArguments(options) then @listenTo @_getVent(), @_getTopicGenerator(options), -> options.handler.apply(this,arguments)

    ###
      Fire a vent event. These events are global, so every component
      registered as a listener will receive the event. They are asynchronous and do not return a value, so they are more
      useful for toggling state on a component
    ###
    fireVent: (options={})->
      if @_validArguments(options) then @_getVent().trigger @_getTopicGenerator(options), options.payload

    ###
      Fire a req/res event. These events are point-to-point, meaning they will not be observable
      to any other components on the page. They will immediately return a value when called so they are most useful
      when proxying getters.
    ###
    fireReqRes: (options={})->
      if @_validArguments(options) then @_getVent().trigger @_getTopicGenerator(options), options.payload

  }