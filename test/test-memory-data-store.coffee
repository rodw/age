path            = require('path')
fs              = require('fs')
HOMEDIR         = path.join(__dirname,'..')
IS_INSTRUMENTED = fs.existsSync(path.join(HOMEDIR,'lib-cov'))
LIB_DIR         = if IS_INSTRUMENTED then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
MemoryDataStore = require(path.join(LIB_DIR,'memory-data-store')).MemoryDataStore
should          = require 'should'

describe 'MemoryDataStore',=>

  beforeEach (done)=>
    @datastore = new MemoryDataStore()
    done()

  afterEach (done)=>
    @datastore = null
    done()

  it 'can record and return a player object',(done)=>
    player = {
      id:12346
      name: {
        first: 'John'
        last: 'Doe'
      }
    }
    @datastore.record_player player, (err)=>
      should.not.exist err
      @datastore.get_player player, (err,found)=>
        should.not.exist err
        should.exist found
        should.exist found.data
        found.data.id.should.equal player.id
        found.data.name.first.should.equal player.name.first
        found.data.name.last.should.equal player.name.last
        done()


  it 'can record and return an event',(done)=>
    player = {
      id:12346
      name: {
        first: 'John'
        last: 'Doe'
      }
    }
    event = "Some Event"
    @datastore.record_event player, event, (err)=>
      should.not.exist err
      @datastore.get_player_history player, (err,history)=>
        should.not.exist err
        should.exist history
        history.length.should.equal 1
        history[0].should.equal event
        done()

  it 'can record and return multiple events',(done)=>
    player1 = { id:12346, name: { first: 'John', last: 'Doe' } }
    player2 = { id:6789, name: { first: 'Jane', last: 'Smith' } }
    event1 = "Some Event"
    event2 = "Another Event"
    @datastore.record_event player1, event1, (err)=>
      should.not.exist err
      @datastore.record_event player1, event2, (err)=>
        should.not.exist err
        @datastore.record_event player2, event2, (err)=>
          should.not.exist err
          @datastore.get_player_history player1, (err,history)=>
            should.not.exist err
            should.exist history
            history.length.should.equal 2
            (event1 in history).should.be.ok
            (event2 in history).should.be.ok
            @datastore.get_player_history player2, (err,history)=>
              should.not.exist err
              should.exist history
              history.length.should.equal 1
              (event2 in history).should.be.ok
              done()

  it 'can record and return an achievement',(done)=>
    player = {
      id:12346
      name: {
        first: 'John'
        last: 'Doe'
      }
    }
    achievement = "Some Achievement"
    @datastore.record_achievement player, achievement, (err)=>
      should.not.exist err
      @datastore.get_player_achievements player, (err,achievements)=>
        should.not.exist err
        should.exist achievements
        achievements.length.should.equal 1
        achievements[0].should.equal achievement
        done()

  it 'can record and return multiple achievements',(done)=>
    player1 = { id:12346, name: { first: 'John', last: 'Doe' } }
    player2 = { id:6789, name: { first: 'Jane', last: 'Smith' } }
    achievement1 = "Some Achievement"
    achievement2 = "Another Achievement"
    @datastore.record_achievement player1, achievement1, (err)=>
      should.not.exist err
      @datastore.record_achievement player1, achievement2, (err)=>
        should.not.exist err
        @datastore.record_achievement player2, achievement2, (err)=>
          should.not.exist err
          @datastore.get_player_achievements player1, (err,achievements)=>
            should.not.exist err
            should.exist achievements
            achievements.length.should.equal 2
            (achievement1 in achievements).should.be.ok
            (achievement2 in achievements).should.be.ok
            @datastore.get_player_achievements player2, (err,achievements)=>
              should.not.exist err
              should.exist achievements
              achievements.length.should.equal 1
              (achievement2 in achievements).should.be.ok
              done()
