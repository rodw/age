# **MemoryDataStore** is a `DataStore` that stores
# the saved data as in-memory JavaScript objects.
# It does not provide a persistence mechanism.
path            = require('path')
fs              = require('fs')
HOMEDIR         = path.join(__dirname,'..')
IS_INSTRUMENTED = fs.existsSync(path.join(HOMEDIR,'lib-cov'))
LIB_DIR         = if IS_INSTRUMENTED then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
DataStore       = require(path.join(LIB_DIR,'data-store')).DataStore
Util            = require(path.join(LIB_DIR,'util')).Util

class MemoryDataStore extends DataStore

  # The `MemoryDataStore` constructor accepts no arguments.
  constructor:()->
    super()
    @game_states = {}

  # See `DataStore.record_player`.
  record_player:(player,callback)=>
    @game_states[player.id] ?= @make_player(player)
    callback?()

  # See `DataStore.record_event`.
  record_event:(player,event,callback)=>
    @game_states[player.id] ?= @make_player(player)
    @game_states[player.id].history.push event
    callback?()

  # See `DataStore.record_achievement`.
  record_achievement:(player,achievement,callback)=>
    @game_states[player.id] ?= @make_player(player)
    @game_states[player.id].achievements.push achievement
    callback?()

  # See `DataStore.get_player`.
  get_player:(player,callback)=>
    p = Util.deep_clone(@game_states[player.id])
    unless p?
      p = {id:player.id,achievements:[],history:[]}
      @game_states[p.id] = p
    callback?(null,p)

# The MemoryDataStore type is exported as `MemoryDataStore`.
exports = exports ? this
exports.MemoryDataStore = MemoryDataStore
