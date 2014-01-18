# **Util** provides some internal utility methods.
class Util

 # **clone** creates a shallow copy of the given object.
 clone:(x)->
   if x?
     switch (typeof x)
       when 'null','undefined'
         return x
       when 'string', 'number', 'function', 'boolean'
         return x
       when 'object','array'
         if Array.isArray(x) or x instanceof Array
           return [].concat(x)
         else
           clone = {}
           for name,value of x
             clone[name] = value
           return clone
       else
         return x # generally shouldn't get here
   else
     return x

  # **deep_clone** creates a deep copy of the given
  # object (recursively cloning any array or map values).
  deep_clone:(x)->
    if x?
      switch (typeof x)
        when 'null','undefined'
          return x
        when 'string', 'number', 'function', 'boolean'
          return x
        when 'object','array'
          if Array.isArray(x) or x instanceof Array
            clone = []
            for e in x
              clone.push @deep_clone(e)
            return clone
          else
            clone = {}
            for name,value of x
              clone[name] = @deep_clone(value)
            return clone
        else
          return x # generally shouldn't get here
    else
      return x


  # **count** returns the number of elements in
  # `array` that equal `value` (stopping at
  # `max` if specified)
  count:(array,value,max)->
    count = 0
    for elt in array
      if elt is value
        count++
        if max? and count >= max
          break
    return count

  # **for** implements a functor-based for-loop.
  #
  # Accepts 5 function-valued parameters:
  #  * `initialize` - an initialization function (no arguments passed, no return value is expected)
  #  * `condition` - a predicate that indicates whether we should continue looping (no arguments passed, a boolean value is expected to be returned)
  #  * `action` - the action to take (no arguments passed, no return value is expected)
  #  * `step` - called at the end of every `action`, prior to `condition`  (no arguments passed, no return value is expected)
  #  * `whendone` - called at the end of the loop (when `condition` returns `false`), (no arguments passed, no return value is expected)
  #
  # This method largely exists for symmetry with `for_async`.
  for:(init,cond,action,step,done)->
    init() if init?
    while cond()
      action() if action?
      step() if step?
    done() if done?

  # **for_async** implements an asynchronous for loop.
  #
  # Accepts 5 function-valued parameters:
  #  * `initialize` - an initialization function (no arguments passed, no return value is expected)
  #  * `condition` - a predicate that indicates whether we should continue looping (no arguments passed, a boolean value is expected to be returned)
  #  * `action` - the action to take (a single callback function is passed and should be invoked at the end of the action, no return value is expected)
  #  * `increment` - called at the end of every `action`, prior to `condition`  (no arguments passed, no return value is expected)
  #  * `whendone` - called at the end of the loop (when `condition` returns `false`), (no arguments passed, no return value is expected)
  #
  # For example, the loop:
  #
  #     for(var i=0; i<10; i++) { console.log(i); }
  #
  # could be implemented as:
  #
  #     var i = 0;
  #     init = function() { i = 0; }
  #     cond = function() { return i < 10; }
  #     actn = function(next) { console.log(i); next(); }
  #     incr = function() { i = i + 1; }
  #     done = function() { }
  #     for_async(init,cond,actn,incr,done)
  #
  for_async:(initialize,condition,action,increment,whendone)->
    looper = ()->
      if condition()
        action ()->
          increment()
          looper()
      else
        whendone() if whendone?
    initialize()
    looper()

  # **for_each** implements a functor-based forEach loop.
  #
  # Accepts 3 parameters:
  #  * `list` - the array to iterate over
  #  * `action` - the function with the signature (value,index,list) indicating the action to take
  #  * `whendone` - called at the end of the loop
  #
  # This method doesn't add much value over the built-in Array.forEach, but exists for symmetry with `for_each_async`.
  for_each:(list,action,done)->
    list.forEach(action) if list? and action?
    done() if done?


  # **for_each_async** implements an asynchronous forEach loop.
  #
  # Accepts 3 parameters:
  #  * `list` - the array to iterate over
  #  * `action` - the function with the signature (value,index,list,next) indicating the action to take; the provided function `next` *must* be called at the end of processing
  #  * `whendone` - called at the end of the loop
  #
  # For example, the loop:
  #
  #     [0..10].foreach (elt,index,array)->
  #       console.log elt
  #
  # could be implemented as:
  #
  #     for_each_async [0..10], (elt,index,array,next)->
  #       console.log elt
  #       next()
  #
  for_each_async:(list,action,whendone)->
    i = m = null
    init = ()-> i = 0
    cond = ()-> (i < list.length)
    incr = ()-> i += 1
    act  = (next)-> action(list[i],i,list,next)
    @for_async(init, cond, act, incr, whendone)



  # **for_each_of** implements a functor-based for-of loop
  # (i.e., the `for k,v of map` equivalent of `for_each`'s
  # `for e in array`).
  #
  # Accepts 3 parameters:
  #  * `map` - the map to iterate over
  #  * `action` - the function with the signature (key,value,map) indicating the action to take
  #  * `whendone` - called at the end of the loop
  #
  for_each_of:(map,action,whendone)->
    if map? and action?
      for key,value of map
        action(key,value,map)
    whendone() if whendone?

  # `for_each_of_async` implements an asynchronous for-of loop
  # (i.e., the `for k,v of map` equivalent of `for_each`'s
  # `for e in array`).
  #
  # Accepts 3 parameters:
  #  * `map` - the mao to iterate over
  #  * `action` - the function with the signature (key,value,map,next) indicating the action to take; the provided function `next` *must* be called at the end of processing
  #  * `whendone` - called at the end of the loop
  #
  for_each_of_async:(map,action,whendone)->
    keys = Object.keys(map)
    i = m = null
    init = ()-> i = 0
    cond = ()-> (i < keys.length)
    incr = ()-> i += 1
    act  = (next)-> action(keys[i],map[keys[i]],map,next)
    @for_async(init, cond, act, incr, whendone)


# A "singleton" Util instance is exported under the name `Util`.
exports = exports ? this
exports.Util = new Util()
