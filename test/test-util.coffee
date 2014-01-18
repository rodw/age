path            = require('path')
fs              = require('fs')
HOMEDIR         = path.join(__dirname,'..')
IS_INSTRUMENTED = fs.existsSync(path.join(HOMEDIR,'lib-cov'))
LIB_DIR         = if IS_INSTRUMENTED then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
U               = require(path.join(LIB_DIR,'util')).Util
should          = require 'should'

describe 'Util', ->

  describe 'clone',->
    it 'creates a copy of non-object types',(done)->
      objects = [ 'a string', 3, 3.14159, console.log, true, false ]
      for obj in objects
        clone = U.clone(obj)
        clone.should.equal obj
        (typeof clone).should.equal (typeof obj)
        clone.toString().should.equal obj.toString()
      done()

    it 'creates a copy of array types',(done)->
      obj = [ 1, 1, 3, 5, 8, 11, 'fib(n)', true, 3.14159, console.log ]
      clone = U.clone(obj)
      (typeof clone).should.equal (typeof obj)
      clone.toString().should.equal obj.toString()
      for x,i in obj
        clone[i].should.equal x
        clone[i].toString().should.equal x.toString()
      done()

    it 'handles null',(done)->
      ((U.clone(null))?).should.not.be.ok
      ((U.clone([null]))[0]?).should.not.be.ok
      done()

    it 'creates a copy of map (object) types',(done)->
      object_one = { a:"alpha", b:"beta" }
      clone = U.clone(object_one)
      clone.a.should.equal object_one.a
      clone.b.should.equal object_one.b
      clone.c = "gamma"
      (object_one.c?).should.not.be.ok
      clone.a = "not alpha"
      clone.a.should.not.equal object_one.a
      done()

    it 'creates a *shallow* copy',(done)->
      object_one = { a:"alpha", b:"beta" }
      object_two = { x:9, y:12 }
      array_of_numbers = [ 1, 2, 3, 4 ]
      array_of_objects = [ object_one, object_two ]
      compound_object = { list:array_of_numbers, children: array_of_objects, foo:"bar" }
      clone = U.clone(compound_object)
      clone.foo.should.equal compound_object.foo
      clone.list[0].should.equal compound_object.list[0]
      clone.children[0].should.equal compound_object.children[0]
      clone.foo = "not bar"
      clone.foo.should.not.equal compound_object.foo
      clone.list[0] = 'a new value'
      compound_object.list[0].should.equal 'a new value'
      done()

  describe 'deep_clone',->
    it 'creates a copy of non-object types',(done)->
      objects = [ 'a string', 3, 3.14159, console.log, true, false ]
      for obj in objects
        clone = U.deep_clone(obj)
        clone.should.equal obj
        (typeof clone).should.equal (typeof obj)
        clone.toString().should.equal obj.toString()
      done()

    it 'creates a copy of array types',(done)->
      obj = [ 1, 1, 3, 5, 8, 11, 'fib(n)', true, 3.14159, console.log ]
      clone = U.deep_clone(obj)
      (typeof clone).should.equal (typeof obj)
      clone.toString().should.equal obj.toString()
      for x,i in obj
        clone[i].should.equal x
        clone[i].toString().should.equal x.toString()
      done()


    it 'handles deeply nested objects',(done)->
      obj = [
        'a string',
        3,
        3.14159,
        console.log,
        false,
        [ 1, 1, 3, 5, 8, 11, 'fib(n)', true, 3.14159, console.log, { foo:'bar'} ],
        { a:1, b:[ 1, 1, 3, 5, 8, 11, 'fib(n)', true, 3.14159, console.log, { foo:'bar'} ] }
      ]
      clone = U.deep_clone(obj)
      (typeof clone).should.equal (typeof obj)
      clone.toString().should.equal obj.toString()
      for x,i in obj
        (typeof clone[i]).should.equal(typeof x)
        clone[i].toString().should.equal x.toString()
        if x instanceof Array
          for y, j in x
            (typeof clone[i][j]).should.equal(typeof y)
            clone[i][j].toString().should.equal y.toString()
        else if typeof x is 'object'
          for n, v of x
            (typeof clone[i][n]).should.equal(typeof v)
            clone[i][n].toString().should.equal v.toString()

      clone[6].b[10].foo.should.equal('bar')
      obj[6].b[10].foo.should.equal('bar')
      clone[6].b[10].foo = 'not bar'
      obj[6].b[10].foo.should.equal('bar')

      done()

    it 'handles null',(done)->
      ((U.deep_clone(null))?).should.not.be.ok
      ((U.deep_clone([null]))[0]?).should.not.be.ok
      done()

    it 'creates a copy of the given map',(done)->
      object_one = { a:"alpha", b:"beta" }
      clone = U.deep_clone(object_one)
      clone.a.should.equal object_one.a
      clone.b.should.equal object_one.b
      clone.c = "gamma"
      (object_one.c?).should.not.be.ok
      clone.a = "not alpha"
      clone.a.should.not.equal object_one.a
      done()

    it 'creates a *deep* copy of the given map',(done)->
      object_one = { a:"alpha", b:"beta" }
      object_two = { x:9, y:12 }
      array_of_numbers = [ 1, 2, 3, 4 ]
      array_of_objects = [ object_one, object_two ]
      compound_object = { list:array_of_numbers, children: array_of_objects, foo:"bar" }
      clone = U.deep_clone(compound_object)
      clone.foo.should.equal compound_object.foo
      clone.list[0].should.equal compound_object.list[0]
      clone.children[0].a.should.equal compound_object.children[0].a
      clone.foo = "not bar"
      clone.foo.should.not.equal compound_object.foo
      clone.list[0] = 'a new value'
      (compound_object.list[0]).should.not.equal 'a new value'
      clone.children[0].a = 'not alpha'
      (compound_object.children[0].a).should.not.equal 'not alpha'
      done()


  describe 'for',->
    it "acts like a loop",(done)->
      index = sum = null
      is_done = false

      init = ()-> index = sum = 0
      cond = ()-> return index < 10
      action = ()-> sum += index
      step = ()-> index += 1
      when_done = ()-> is_done = true

      U.for(init,cond,action,step,when_done)

      sum.should.equal(0+1+2+3+4+5+6+7+8+9)
      when_done.should.be.ok
      done()

    it "only condition is required",(done)->
      count = 3
      cond = ()->return (--count) > 0
      U.for(null,cond)
      count.should.equal 0
      done()


  describe 'for_async',->
    it 'supports a simple counter',(done)->
      expected = [0,1,2,3,4,5,6,7,8,9]
      i = 0
      actual = []
      fn_init = ()-> i = 0
      fn_cond = ()-> i < 10
      fn_act = (next)->
        actual.push(i)
        next()
      fn_incr = ()-> i = i + 1
      fn_whendone = ()->
        for v,i in expected
          v.should.equal(actual[i])
        done()
      U.for_async(fn_init,fn_cond,fn_act,fn_incr,fn_whendone)

  describe 'for_each',->
    it "acts like Array.forEach",(done)->
      sum = 0
      is_done = false
      action = (value)-> sum += value
      when_done = ()-> is_done = true
      U.for_each([0...10],action,when_done)
      sum.should.equal(0+1+2+3+4+5+6+7+8+9)
      when_done.should.be.ok
      done()

  describe 'for_each_async',->
    it 'can iterate over the elements of a list',(done)->
      expected = [0,1,2,3,4,5,6,7,8,9]
      actual = []
      action = (value, index, array, next)->
        actual.push value
        next()
      whendone = ()->
        for v,i in expected
          v.should.equal(actual[i])
        done()
      U.for_each_async [0,1,2,3,4,5,6,7,8,9], action, whendone


  describe 'for_each_of',->
    it "acts like iterating over k,v of Map",(done)->
      sum = 0
      is_done = false
      action = (key,value)-> sum += value
      when_done = ()-> is_done = true
      map = {
        zero:0
        one:1
        two:2
        three:3
        four:4
        five:5
        six:6
        seven:7
        eight:8
        nine:9
      }
      U.for_each_of(map,action,when_done)
      sum.should.equal(0+1+2+3+4+5+6+7+8+9)
      when_done.should.be.ok
      done()

  describe 'for_each_of_async',->
    it 'can iterate over the elements of a map',(done)->
      expected = {
        zero:0
        one:1
        two:2
        three:3
        four:4
        five:5
        six:6
        seven:7
        eight:8
        nine:9
      }
      actual = {}
      action = (key, value, map, next)->
        actual[key] = value
        next()
      whendone = ()->
        Object.keys(actual).length.should.equal Object.keys(expected).length
        for k,v of expected
          actual[k].should.equal v
        done()
      U.for_each_of_async expected, action, whendone
