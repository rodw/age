# **DataStore** defines an abstract API by which the `GameEngine`
# can save, persist and retrieve information about players and
# game states.
class DataStore

  # `make_player` creates a new player object based on the
  # given `player_data` object, if any.  The returned object
  # has up to four properties:
  #  1. `id` -- the `player_data.id` value, if any
  #  2. `achievements` -- an array of achievements achieved by
  #     this player.
  #  3. `history` -- an array of events and/or actions perfored
  #     by this player
  #  4. `data` -- any additional meta-data originally stored in
  #     `player_data`
  make_player:(player_data)=>
    return {
      id: player_data?.id
      achievements: []
      history: []
      data: player_data
    }

  # `record_player` ensures that the datastore contains
  # a player object for the specified `player` data.
  # The `callback` function should accept one argument--an
  # error object or message (if any).
  #
  # This method is not implemented in the base DataStore object.
  # Subclasses must override and implement this method.
  record_player:(player,callback)->
    throw new Error('Method not implemented.')

  # `record_event` registers that the given `player`
  # encountered the given `event`
  # The `callback` function should accept one argument--an
  # error object or message (if any).
  #
  # This method is not implemented in the base DataStore object.
  # Subclasses must override and implement this method.
  record_event:(player,event,callback)->
    throw new Error('Method not implemented.')

  # `record_achievement` registers that the given `player`
  # achieved the given `achievement`
  # The `callback` function should accept one argument--an
  # error object or message (if any).
  #
  # This method is not implemented in the base DataStore object.
  # Subclasses must override and implement this method.
  record_achievement:(player,achievement,callback)->
    throw new Error('Method not implemented.')

  # `get_player` returns the player object for the player
  # with the given `player.id`.
  #
  # This method is not implemented in the base DataStore object.
  # Subclasses must override and implement this method.
  get_player:(player,callback)->
    throw new Error('Method not implemented.')

  # `get_player_history` returns an array of events
  # experienced by the player with the given `player.id`.
  #
  # By default this method simply invokes `.history` on the
  # value obtained from `get_player`.
  get_player_history:(player,callback)=>
    @get_player player, (err,player)=>
      callback?(err,player?.history)


  # `get_player_achievements` returns an array of achievements
  # achieved by the player with the given `player.id`.
  #
  # By default this method simply invokes `.achievements` on the
  # value obtained from `get_player`.
  get_player_achievements:(player,callback)=>
    @get_player player, (err,player)=>
      callback?(err,player?.achievements)

# The DataStore type is exported as `DataStore`.
exports = exports ? this
exports.DataStore = DataStore
