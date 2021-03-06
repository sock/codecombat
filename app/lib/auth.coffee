{backboneFailure, genericFailure} = require 'lib/errors'
User = require 'models/User'
storage = require 'lib/storage'
BEEN_HERE_BEFORE_KEY = 'beenHereBefore'

init = ->
  module.exports.me = window.me = new User(window.userObject) # inserted into main.html
  trackFirstArrival()
  if me and not me.get('testGroupNumber')?
    # Assign testGroupNumber to returning visitors; new ones in server/routes/auth
    me.set 'testGroupNumber', Math.floor(Math.random() * 256)
    me.save()

  Backbone.listenTo(me, 'sync', Backbone.Mediator.publish('me:synced', {me:me}))

module.exports.createUser = (userObject, failure=backboneFailure, nextURL=null) ->
  user = new User(userObject)
  user.save({}, {
    error: failure,
    success: -> if nextURL then window.location.href = nextURL else window.location.reload()
  })

module.exports.loginUser = (userObject, failure=genericFailure) ->
  jqxhr = $.post('/auth/login',
    {
      username:userObject.email,
      password:userObject.password
    },
    (model) -> window.location.reload()
  )
  jqxhr.fail(failure)

module.exports.logoutUser = ->
  FB?.logout?()
  res = $.post('/auth/logout', {}, -> window.location.reload())
  res.fail(genericFailure)

onSetVolume = (e) ->
  return if e.volume is me.get('volume')
  me.set('volume', e.volume)
  me.save()

Backbone.Mediator.subscribe('level-set-volume', onSetVolume, module.exports)

trackFirstArrival = ->
  # will have to filter out users who log in with existing accounts separately
  # but can at least not track logouts as first arrivals using local storage
  beenHereBefore = storage.load(BEEN_HERE_BEFORE_KEY)
  return if beenHereBefore
  window.tracker?.trackEvent 'First Arrived'
  storage.save(BEEN_HERE_BEFORE_KEY, true)

init()
