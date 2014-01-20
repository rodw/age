path            = require('path')
fs              = require('fs')
HOMEDIR         = path.join(__dirname,'..')
IS_INSTRUMENTED = fs.existsSync(path.join(HOMEDIR,'lib-cov'))
LIB_DIR         = if IS_INSTRUMENTED then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
GameEngine      = require(path.join(LIB_DIR,'game-engine')).GameEngine
AchievementRule = require(path.join(LIB_DIR,'achievement-rule')).AchievementRule
should          = require 'should'

describe 'GameEngine',=>

  beforeEach (done)=>
    @engine = new GameEngine()
    done()

  afterEach (done)=>
    @engine = null
    done()

  it 'can add and get a player object',(done)=>
    player = {
      id:12346
      name: {
        first: 'John'
        last: 'Doe'
      }
    }
    @engine.add_player player, (err)=>
      should.not.exist err
      @engine.get_player player, (err,found)=>
        should.not.exist err
        should.exist found
        should.exist found.data
        found.data.id.should.equal player.id
        found.data.name.first.should.equal player.name.first
        found.data.name.last.should.equal player.name.last
        done()


  it 'can add and return an event',(done)=>
    player = {
      id:12346
      name: {
        first: 'John'
        last: 'Doe'
      }
    }
    event = "Some Event"
    @engine.add_event player, event, (err)=>
      should.not.exist err
      @engine.get_player_history player, (err,history)=>
        should.not.exist err
        should.exist history
        history.length.should.equal 1
        history[0].should.equal event
        done()

  it 'can add and return multiple events',(done)=>
    player1 = { id:12346, name: { first: 'John', last: 'Doe' } }
    player2 = { id:6789, name: { first: 'Jane', last: 'Smith' } }
    event1 = "Some Event"
    event2 = "Another Event"
    @engine.add_event player1, event1, (err)=>
      should.not.exist err
      @engine.add_event player1, event2, (err)=>
        should.not.exist err
        @engine.add_event player2, event2, (err)=>
          should.not.exist err
          @engine.get_player_history player1, (err,history)=>
            should.not.exist err
            should.exist history
            history.length.should.equal 2
            (event1 in history).should.be.ok
            (event2 in history).should.be.ok
            @engine.get_player_history player2, (err,history)=>
              should.not.exist err
              should.exist history
              history.length.should.equal 1
              (event2 in history).should.be.ok
              done()

  it 'can add and return an achievement',(done)=>
    player = {
      id:12346
      name: {
        first: 'John'
        last: 'Doe'
      }
    }
    achievement = "Some Achievement"
    @engine.add_achievement player, achievement, (err)=>
      should.not.exist err
      @engine.get_player_achievements player, (err,achievements)=>
        should.not.exist err
        should.exist achievements
        achievements.length.should.equal 1
        achievements[0].should.equal achievement
        done()

  it 'can add and return multiple achievements',(done)=>
    player1 = { id:12346, name: { first: 'John', last: 'Doe' } }
    player2 = { id:6789, name: { first: 'Jane', last: 'Smith' } }
    achievement1 = "Some Achievement"
    achievement2 = "Another Achievement"
    @engine.add_achievement player1, achievement1, (err)=>
      should.not.exist err
      @engine.add_achievement player1, achievement2, (err)=>
        should.not.exist err
        @engine.add_achievement player2, achievement2, (err)=>
          should.not.exist err
          @engine.get_player_achievements player1, (err,achievements)=>
            should.not.exist err
            should.exist achievements
            achievements.length.should.equal 2
            (achievement1 in achievements).should.be.ok
            (achievement2 in achievements).should.be.ok
            @engine.get_player_achievements player2, (err,achievements)=>
              should.not.exist err
              should.exist achievements
              achievements.length.should.equal 1
              (achievement2 in achievements).should.be.ok
              done()

  it 'emits  \"event-occurred\" events',(done)=>
    player = { id:12346, name: { first: 'John', last: 'Doe' } }
    event = "Some Event"
    listener = (e)->
      e.type.should.equal 'event-occurred'
      e.player.id.should.equal player.id
      e.event.should.equal event
      e.engine.should.exist
      done()
    @engine.on 'event-occurred', listener
    @engine.add_event player,event, ((err)=>should.not.exist(err))


  it 'emits  \"event-occurred\" events (again)',(done)=>
    player = { id:7890, name: { first: 'Jane', last: 'Smith' } }
    event = "Another Event"
    listener = (e)->
      e.type.should.equal 'event-occurred'
      e.player.id.should.equal player.id
      e.event.should.equal event
      e.engine.should.exist
      done()
    @engine.on 'event-occurred', listener
    @engine.add_event player,event, ((err)=>should.not.exist(err))

  it 'emits \"achievement-achieved\" events',(done)=>
    player = { id:12346, name: { first: 'John', last: 'Doe' } }
    achievement = "Some Achievement"
    listener = (e)->
      e.type.should.equal 'achievement-achieved'
      e.player.id.should.equal player.id
      e.achievement.should.equal achievement
      e.engine.should.exist
      done()
    @engine.on 'achievement-achieved', listener
    @engine.add_achievement player,achievement, ((err)=>should.not.exist(err))

  it 'evaluates achievements',(done)=>
    player = { id:12346, name: { first: 'John', last: 'Doe' } }
    achievement_rule = new AchievementRule {
      key: "Two Events"
      predicate:(key,engine,player,callback)->
        engine.get_player_history player, (err,history)->
          if history?.length >= 2
            callback(err,true)
          else
            callback(err,false)
      multiplicity: 2
    }
    @engine.add_achievement_rule(achievement_rule)

    @engine.get_player_achievements player, (err,achievements)=>
      should.not.exist(err)
      achievements.length.should.equal 0
      @engine.add_event player,"An Event", (err)=>
        should.not.exist(err)
        @engine.get_player_achievements player, (err,achievements)=>
          should.not.exist(err)
          achievements.length.should.equal 0
          @engine.add_event player,"Another Event", (err)=>
            should.not.exist(err)
            @engine.get_player_achievements player, (err,achievements)=>
              should.not.exist(err)
              achievements.length.should.equal 1
              achievements[0].should.equal achievement_rule.key
              @engine.add_event player,"Yet Another Event", (err)=>
                should.not.exist(err)
                @engine.get_player_achievements player, (err,achievements)=>
                  should.not.exist(err)
                  achievements.length.should.equal 2
                  achievements[0].should.equal achievement_rule.key
                  achievements[1].should.equal achievement_rule.key
                  @engine.add_event player,"And Yet Another Event", (err)=>
                    should.not.exist(err)
                    @engine.get_player_achievements player, (err,achievements)=>
                      should.not.exist(err)
                      achievements.length.should.equal 2
                      achievements[0].should.equal achievement_rule.key
                      achievements[1].should.equal achievement_rule.key
                      done()
