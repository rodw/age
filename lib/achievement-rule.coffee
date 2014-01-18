# **AchievementRule** is an (optional) base type for rules that
# define achievements within the GameEngine.
#
# It is not necessary to extend this class to create an achievement rule.
# Any object that provides the specified properties is sufficient.
# This base class simply provides a handy place to document these assumptions
# and to provide default properties that are sufficient for most use cases.
#
class AchievementRule

  #
  # The `AchievementRule` constructor accepts an optional map of properties.
  #
  # Four properties are recognized:
  #
  # 1. *`multiplicity`* -- an integer representing the number of times this
  #    achievement can be earned by a single player. A value of `1` indicates
  #    that the achievement can be awarded exactly once to a given player. A
  #    value of *n* indicates that the achievement can be awarded exactly *n*
  #    times to a given player. A value of `0` indicates that the achievement
  #    can be awarded an infinite number of times.  Defaults to `0`.
  #
  # 2. *`transient`* -- a boolean value indicating whether the achievement,
  #    once awarded, becomes a permanent part of the player's game state,
  #    or if the conditions must be re-evaluated each time. Defaults to `false`.
  #
  #    For example, an achievement such as "logged-in today" might be considered
  #    transient while an achievement such as "logged-in at least 10 times" might
  #    be considered permanent.
  #
  # 3. *`key`* -- either an object (typically a string) that acts as an identifier
  #    for this achievement (as stored within a player's `achievements` container) *or*
  #    a function (accepting two arguments: a GameEngine instance and a player object)
  #    that returns such an identifier.
  #
  #    The latter case (the function) can be used to create dynamic identifiers.
  #    For example, for an achievement such as "Logged in on <DATE>".
  #
  #    No default value is provided for this property.  Instances or subclasses
  #    must override this property.
  #
  # 4. *`predicate`* -- a function (accepting three arguments: a GameEngine instance,
  #    a player object and a callback function) that evaluates whether or not the
  #    given player has earned this achievement.  The callback function accepts
  #    two arguments: an error object (which should be `null` when no error has occurred)
  #    and a boolean indicating whether or not the achievement has been achieved.
  #
  #    No default value is provided for this property.  Instances or subclasses
  #    must provide a `predicate` method.
  #
  # Note that it is not necessary to pass these properties to the constructor method.
  # They could also be assigned in the subclass implementation or set after the
  # object is constructed.
  #
  constructor:(props={})->
    @multiplicity = props?.multiplicity ? 1
    @transient = props?.transient ? false
    @key = props?.key ? (engine,player)->throw new Error("Method not implemented.")
    @predicate = props?.predicate ? (engine,player,callback)->throw new Error("Method not implemented.")

# The AchievementRule type is exported under the name `AchievementRule`.
exports = exports ? this
exports.AchievementRule = AchievementRule
