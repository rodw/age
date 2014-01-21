# The **GameEngine** fulfills two primary roles:
#
# 1. It offers a centralized API that used by internal and external
#    clients to inspect or act on the current game state.
#
# 2. It implements the logic that drives the game itself--evaluating
#    whether achievements have been achieved, etc.
#
# The GameEngine is an `EventEmitter`, emitting events when an
# event has occured or an achievement has been achieved.

path            = require('path')
fs              = require('fs')
HOMEDIR         = path.join(__dirname,'..')
IS_INSTRUMENTED = fs.existsSync(path.join(HOMEDIR,'lib-cov'))
LIB_DIR         = if IS_INSTRUMENTED then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
MemoryDataStore = require(path.join(LIB_DIR,'memory-data-store')).MemoryDataStore
Util            = require(path.join(LIB_DIR,'util')).Util
EventEmitter    = require('events').EventEmitter

class GameEngine extends EventEmitter

  # `GameEngine.EET_ACHIEVED` is the EventEmitter event type used
  # when a player has earned an achievement.  The corresponding
  # EventEmitter event object will contain four properities:
  #
  # 1. `player` -- the player that earned this achievement
  # 2. `achievement`-- the achievement that was earned
  # 3. `engine` -- this GameEngine instance
  # 4. `type` -- a string `GameEngine.EET_ACHIEVED`
  @EET_ACHIEVED: 'achievement-achieved'

  # `GameEngine.EET_OCCURRED` is the EventEmitter event type used
  # when an event has occurred.  The corresponding EventEmitter
  # event object will contain four properities:
  #
  # 1. `player` -- the player to which to the event occurred
  # 2. `event`-- the event
  # 3. `engine` -- this GameEngine instance
  # 4. `type` -- a string `GameEngine.EET_OCCURRED`
  @EET_OCCURRED: 'event-occurred'

  # The GameEngine constructor accepts two optional
  # arguments: a DataStore instance and an array of
  # achievement rules.
  #
  # The first defaults to `MemoryDataStore`, the
  # second to an empty array.
  constructor:(datastore,achievement_rules)->
    @datastore = datastore ? new MemoryDataStore()
    @achievement_rules = achievement_rules ? []

  # `add_player` ensures that a player object exists
  # for the given `player`.  (The `player` MUST have
  # an `id` property.)
  #
  # The `callback` function should accept one argument,
  # an error object (that will be `null` when no error
  # occurred and the player was succesfully added).
  add_player:(player,callback)=>
    @datastore.record_player(player,callback)

  # `add_event` reports that the given `event` occurred
  # for the given `player`.
  #
  # The `callback` function should accept one argument,
  # an error object (that will be `null` when no error
  # occurred and the event was succesfully recorded).
  #
  # This method will emit a `GameEngine.EET_OCCURRED`
  # message to any registered listeners.
  add_event:(player,event,callback)=>
    @datastore.record_event player, event, (err)=>
      if err?
        callback?(err)
      else
        @emit(GameEngine.EET_OCCURRED, {player:player,event:event,engine:this,type:GameEngine.EET_OCCURRED})
        callback?()

  # `add_event` reports that the given `player` earned
  # for specified `achievement`.
  #
  # The `callback` function should accept one argument,
  # an error object (that will be `null` when no error
  # occurred and the achievement was succesfully recorded).
  #
  # This method will emit a `GameEngine.EET_ACHIEVED`
  # message to any registered listeners.
  add_achievement:(player,achievement,callback)=>
    @datastore.record_achievement player,achievement, (err)=>
      if err?
        callback?(err)
      else
        @emit(GameEngine.EET_ACHIEVED, {player:player,achievement:achievement,engine:this,type:GameEngine.EET_ACHIEVED})
        callback?()

  # `add_achievement_rule` registers a new achievement
  # rule with the GameEngine.  Subsequent invocations of
  # `get_player_achievements` will evaluate the given
  # achievement rule.
  #
  # See the `AchievementRule` type for more details.
  add_achievement_rule:(rule)=>
    @achievement_rules.push rule

  # `get_player` will fetch the player object specified by
  # `player.id`.  The `callback` function should accept
  # two arguments: an error object (which will be `null`
  # when no error occurred) and the fetched player object.
  get_player:(player,callback)=>
    @datastore.get_player(player,callback)

  # `get_player_history` will fetch the event history for the player
  # specified by `player.id`.  The `callback` function should
  # accept two arguments: an error object (which will be `null`
  # when no error occurred) and an array of events.
  get_player_history:(player,callback)=>
    @get_player player, (err,player)=>
      callback?(err,player?.history ? [])

  # `get_player_achievements` will fetch the achievements for the player
  # specified by `player.id`.  The `callback` function should
  # accept two arguments: an error object (which will be `null`
  # when no error occurred) and an array of achievements.
  get_player_achievements:(player,callback)=>
    @get_player player, (err,player)=>
      action = (rule,index,list,next)=>
        @_evaluate_achievement_rule player,rule,(err)=>
          if err?
            callback?(err,player?.achievements)
          else
            next()
      Util.for_each_async @achievement_rules, action, ()=>
        callback?(null,player?.achievements)

  _evaluate_single_achievement:(key,player,rule,callback)=>
    if rule.multiplicity? and rule.multiplicity > 0
      count = Util.count(player.achievements,key,rule.multiplicity)
      if count >= rule.multiplicity
        callback?()
        return
    rule.predicate key, this, player, (err,achieved)=>
      if err?
        callback?(err)
      else if achieved
        player.achievements.push(key)
        if rule.transient? and rule.transient
          callback?()
        else
          @add_achievement(player,key,callback)
      else
        callback?()

  # `_evaluate_achievement_rule` is a private utility method.
  # This method will evaluate the given `rule` for the given
  # `player`, make the requisite changes to the game state
  # and then invoke the `callback` method.
  _evaluate_achievement_rule:(player,rule,callback)=>
    if typeof rule.key is 'function'
      keyfn = rule.key
    else
      keyfn = (e,p,c)->c(null,rule.key)
    keyfn this, player, (err,keys)=>
      if err?
        callback?(err)
        return
      else unless keys?
        callback?()
        return
      else
        keys = [ keys ] if (not (Array.isArray(keys)))
        for_each = (key,index,list,next)=>
          @_evaluate_single_achievement key, player, rule, (err)=>
            if err?
              callback?(err)
            else
              next()
        Util.for_each_async(keys,for_each,callback)


  # (not a guaranteed part of the GameEngine interface)
  achievements_by_player:(callback)=>
    unless @datastore.enumerate_player_ids?
      callback?(new Error("Method not supported"))
    else
      @datastore.enumerate_player_ids (err,players)=>
        map = {}
        for_each = (id,index,list,next)=>
          @get_player_achievements {id:id}, (err,achievements)=>
            if err?
              callback?(err)
            else
              map[id] = achievements
              next()
        when_done = ()=>callback?(null,map)
        Util.for_each_async(players,for_each,when_done)



# The GameEngine is exported under the name `GameEngine`.
exports = exports ? this
exports.GameEngine = GameEngine
