# Stack Exchange Example

The [Stack Exchange](http://stackexchange.com/) family of websites (notably, their flagship site [StackOverflow](http://stackoverflow.com/)) makes use of an elaborate collection of [badges](http://stackoverflow.com/help/badges) designed to influence user-behavior in the typical [gamification](http://en.wikipedia.org/wiki/Gamification) ways.

Let's implement some of the StackOverflow badges to demonstrate the use of the [Abstract Gamification Engine](https://github.com/rodw/age).

## About this File

This demonstation is written in the [Literate CoffeeScript](http://coffeescript.org/#literate) format.

It is both a [Markdown](http://daringfireball.net/projects/markdown/) document and an executable [CoffeeScript](http://coffeescript.org/) source file.

To execute the CoffeeScript parts of this file, simply run:

`coffee docs/stack-exchange-example.litcoffee`

from within the module's root directory.

If everything is working properly, you should see the various `console.log` messages listed below, culminating in `Success! Done validating the achievement rules`. If there is a problem, the `coffee` invocation should return a error (non-zero) response code.

## The Domain Model

[StackOverflow](http://stackoverflow.com/) is a robust question-and-answer web-site. Users can ask and answer questions, and have various ways to edit, comment on, promote and demote both their questions and questions posted by others.

For the sake of this example, we'll create a simple "mock" data model to represent this activity and describe it to the GameEngine.

The content in this section is, by and large, not specific to the Abstract Gamification Engine.  Rather, it is scaffolding that helps us create a realistic backdrop for illustrating the use of the AGE.  If you'd like to jump directly into the AGE-specific aspects of the example, skip ahead to [Implementing the Game](#implementing-the-game)

### Use-Cases

In our simplified model, we'll support seven basic use-cases:

1. Creation of a new user.
2. Creation of a new post.
3. Viewing a post.
4. Editing a post.
5. Commenting on a post.
6. Upvoting or downvoting a post.
7. Favoriting a post.

As each use-case is exercised, we'll need to do two things:

1. Record the new or changed information in the back-end data model.

2. Report the relevant activity to the GameEngine.

#### The Base Event

In support of the latter objective, let's create a simple "event" object that our data model will use to report user activity to the GameEngine.

    class BaseEvent
      # `type` - an identifier for the type of event
      # `user` - the ID of the user involved with this event
      # `post` - the ID of the post involved with this event
      # `ts` - the timestamp at which this event occured (defaults to `Date.now`)
      constructor:(type,user,post,ts = Date.now())->
        @type = type
        @user = user
        @post = post
        @timestamp = ts

As we implement individual use-cases we can extend this BaseEvent to represent specific user activity.


#### The Mock Domain Model

In support of the former objective,  let's create a "mock" domain model to emulate the behavior of StackOverflow and other Q&A-based systems:

    class MockQandAModel

Our domain model will keep track of users and posts (questions) and notify the GameEngine of user activities as they occur.  Hence our MockQandAModel constructor will store a reference to a GameEngine instance and create containers to hold users and posts as they are created:

      constructor:(engine)->
        @engine = engine
        @posts = {}
        @users = {}
        @post_id_seq = 1
        @user_id_seq = 1

##### Publishing Events

When a relevant event occurs, our domain model will notify the GameEngine via the following private utility method:


      _publish_event:(event)=>
        @engine?.add_event({id:event.user},event)

##### Use Case 1: Creating a new user

Our basic user model requires little more than a username and a numeric identifier.  But to avoid expensive lookups, we'll store some additional information about user activity.  Specifically, for each user, we'll store:

1. An identifier for the user.
2. A username (display name) for the user.
3. A list of posts the user has created.
4. A list of posts the user has favorited.
5. A list of comments that the user has left.

The `create_user` method initializes a user object and adds it to our `@users` container:

      create_user:(name)=>
        user = { }
        user.id = @user_id_seq++
        user.name = name
        user.posts = []
        user.favorite_posts = []
        user.comments = []
        @users[user.id] = user

Once the user is created, we'll publish the corresponding event:

        @_publish_event(new BaseEvent('User Created',user.id))

and finally return the user object that was created:

        return user

Let's also add a convenience method for fetching a user by ID:

      get_user:(id)=>@users[id]

##### Use Case 2: Creating a new post

In our mock domain model, a *post* contains a "headline" or "subject", "body" content and an author.  But users have the option to upvote, downvote, comment on and favorite individual posts.  Hence each post in our framework will include attributes for:

1. An identifier for the post.
2. The author (creator) of the post.
3. The contents of the post, as "subject" and "body".
4. Lists of users that have upvoted, downvoted or favorited this post.
5. Any comments that have been added to the post.
6. The number of times the post has been viewed.

Here's a method that initializes a post object with these attributes and adds it to our `@posts` container:

      create_post:(author,subject,body)=>
        post = { }
        post.id = @post_id_seq++
        post.author = author
        post.subject = subject
        post.body = body
        post.up_voters = []
        post.down_voters = []
        post.favorited_by = []
        post.comments = []
        post.views = 0
        @posts[post.id] = post

We'll also need to update the corresponding user object to note that the user has created this post:

        user = @get_user(author)
        user.posts.push post.id

Once the post has been created, we'll publish the corresponding event:

        @_publish_event(new BaseEvent("Post Created",post.author,post.id))

and finally return the object that was created:

        return post

Let's also add a convenience method for fetching a post by ID:

      get_post:(id)=>@posts[id]

##### Use Case 3: Viewing a Post

When a user views a post, we simply increment the post's `views` counter and publish the corresponding event:

      view_post:(user_id,post_id)=>
        post = @get_post(post_id)
        unless post?
          throw new Error("Post #{post_id} not found.")
        post.views++
        @_publish_event(new BaseEvent("Post Viewed",user_id,post_id))
        return post.views

##### Use Case 4: Editing a Post

We'll allow users to edit their own posts, using the following method:

      edit_post:(author_id,post_id,new_subject,new_body)=>
        post = @get_post(post_id)
        unless post?
          throw new Error("Post #{post_id} not found.")
        unless post.author is author_id
          throw new Error("User #{author_id} cannot edit post #{post_id}.")
        if new_subject?
          post.subject = new_subject
        if new_body?
          post.body = new_body
        @_publish_event(new BaseEvent("Post Edited",author_id,post_id))
        return post

Note that once again the last thing we do is publish the corresponding event to notify the GameEngine of the activity.

##### Use Case 5: Commenting on a Post

A comment is simply a small bit of text that annotates a given post.

To create a commment, we add it to the post's `comments` container, add it to the user's `comments` container, and then notify the GameEngine of the activity.

      create_comment:(user_id,post_id,comment)=>
        post = @get_post(post_id)
        unless post?
          throw new Error("Post #{post_id} not found.")
        user = @get_user(user_id)
        unless user?
          throw new Error("User #{user_id} not found.")
        comment_obj = {
          author: user_id
          post: post_id
          comment: comment
        }
        user.comments.push comment_obj
        post.comments.push comment_obj
        event = new BaseEvent("Comment Created",user_id,post_id)
        event.comment = comment
        @_publish_event(event)
        return comment_obj

##### Use Case 6: Voting on a Post

Each user is allowed to vote (either up or down) on each post.

To ensure consistency, we'll want to make sure a user doesn't vote twice on the same post.

When a user upvotes (downvotes) a post she had previously upvoted (downvoted), we'll just ignore the action.

When a user upvotes (downvotes) a post she had previously downvoted (upvoted), we'll delete the old vote and record the new one. In support of this, we'll add the following utility function:

      _remove_by_value:(array,value)->
        for elt,index in array
          if elt is value
            array.splice(index,1)
        return array

With that function in hand, upvoting a post is as simple as:

      upvote_post:(user_id,post_id)=>
        post = @get_post(post_id)
        unless post?
          throw new Error("Post #{post_id} not found.")
        user = @get_user(user_id)
        unless user?
          throw new Error("User #{user_id} not found.")
        if user_id in post.down_voters
          post.down_voters = @_remove_by_value(post.down_voters,user_id)
        unless user_id in post.up_voters
          post.up_voters.push user_id
          @_publish_event(new BaseEvent("Post Upvoted",user_id,post_id))
        return post

and downvoting a post is the same method, with roles reversed:

      downvote_post:(user_id,post_id)=>
        post = @get_post(post_id)
        unless post?
          throw new Error("Post #{post_id} not found.")
        user = @get_user(user_id)
        unless user?
          throw new Error("User #{user_id} not found.")
        if user_id in post.up_voters
          post.up_voters = @_remove_by_value(post.up_voters,user_id)
        unless user_id in post.down_voters
          post.down_voters.push user_id
          @_publish_event(new BaseEvent("Post Downvoted",user_id,post_id))
        return post

##### Use Case 7: Favoriting a Post

Favorites are stored twice, once in the user object and once in the post object.

Favoriting a post is a little bit simpler than upvoting and downvoting. In this mock example we won't offer any mechanism for "unfavoriting", hence we only need to ensure that each user favorites a post at most once.

      favorite_post:(user_id,post_id)=>
        post = @get_post(post_id)
        unless post?
          throw new Error("Post #{post_id} not found.")
        user = @get_user(user_id)
        unless user?
          throw new Error("User #{user_id} not found.")
        unless user_id in post.favorited_by
          post.favorited_by.push user_id
          user.favorite_posts.push post_id
          @_publish_event(new BaseEvent("Post Favorited",user_id,post_id))
        return post

### Validating the Domain Model

    console.log "\nValidating the Domain Model..."

Let's put our MockQandAModel through its paces to just confirm everything is working as it should.

We'll use Node.js's built-in `assert` module for this.

    assert = require 'assert'

First, let's simply create a new instance for testing:

    test_model = new MockQandAModel()
    assert( test_model != null )

#### Use Case 1: Creating a New User

    console.log "  Use Case 1: Creating a New User"

Let's create a user:

    test_user = test_model.create_user("Jane")

and assert that it was initialized properly:

    assert( test_user != null )
    assert( test_user.name is "Jane" )
    assert( test_user.id != null )
    assert( test_user.posts.length is 0 )
    assert( test_user.favorite_posts.length is 0 )
    assert( test_user.comments.length is 0 )

and that we can fetch it effectively:

    assert( test_model.get_user(test_user.id).name is "Jane" )

#### Use Case 2: Creating a New Post

    console.log "  Use Case 2: Creating a New Post"

Now let's have that user create a post:

    test_post = test_model.create_post(test_user.id,"Headline","Body")

and assert that it was initialized properly:

    assert( test_post != null )
    assert( test_post.author is test_user.id )
    assert( test_post.subject is "Headline" )
    assert( test_post.body is "Body" )
    assert( test_post.id != null )
    assert( test_post.up_voters.length is 0 )
    assert( test_post.down_voters.length is 0 )
    assert( test_post.favorited_by.length is 0 )
    assert( test_post.comments.length is 0 )
    assert( test_post.views is 0 )

and that we can fetch it effectively:

    assert( test_model.get_post(test_post.id).subject is "Headline" )

Our user object should have been updated to indicate the newly created post:

    assert( test_model.get_user(test_user.id).posts.length is 1 )
    assert( test_model.get_user(test_user.id).posts[0] is test_post.id )

#### Use Case 3: Viewing a Post

    console.log "  Use Case 3: Viewing a Post"

Now let's visit that post a couple of times:

    test_model.view_post(test_user.id,test_post.id)
    test_model.view_post(test_user.id,test_post.id)

That should increment the post's `views` counter:

    assert( test_post.views is 2 )

#### Use Case 4: Editing a Post

    console.log "  Use Case 4: Editing a Post"

Next, we'll have the user edit the post:

    test_model.edit_post(test_user.id,test_post.id,null,"A different body")

That should have changed the body of the post:

    assert( test_model.get_post(test_post.id).body is "A different body" )

But not the subject:

    assert( test_model.get_post(test_post.id).subject is "Headline" )

#### Use Case 5: Commenting on a Post

    console.log "  Use Case 5: Commenting on a Post"

Next, we'll have the user add a comment:

    test_model.create_comment(test_user.id,test_post.id,"A comment")

That should have changed the post's `comments` array::

    assert( test_model.get_post(test_post.id).comments.length is 1 )
    assert( test_model.get_post(test_post.id).comments[0].comment is "A comment" )

And also the user's `comments` array:

    assert( test_model.get_user(test_user.id).comments.length is 1 )
    assert( test_model.get_user(test_user.id).comments[0].comment is "A comment" )

And again:

    test_model.create_comment(test_user.id,test_post.id,"Another comment")
    assert( test_model.get_post(test_post.id).comments.length is 2 )
    assert( test_model.get_post(test_post.id).comments[1].comment is "Another comment" )
    assert( test_model.get_user(test_user.id).comments.length is 2 )
    assert( test_model.get_user(test_user.id).comments[1].comment is "Another comment" )

#### Use Case 6: Voting on a Post

    console.log "  Use Case 6: Voting on a Post"

First, we'll have the user upvote her post:

    test_model.upvote_post(test_user.id,test_post.id)

And to validate:

    assert( test_model.get_post(test_post.id).up_voters.length is 1 )
    assert( test_model.get_post(test_post.id).up_voters[0] is test_user.id )
    assert( test_model.get_post(test_post.id).down_voters.length is 0 )

Upvoting again doesn't change anything:

    test_model.upvote_post(test_user.id,test_post.id)
    assert( test_model.get_post(test_post.id).up_voters.length is 1 )
    assert( test_model.get_post(test_post.id).up_voters[0] is test_user.id )
    assert( test_model.get_post(test_post.id).down_voters.length is 0 )

but downvoting will swap the votes:

    test_model.downvote_post(test_user.id,test_post.id)
    assert( test_model.get_post(test_post.id).up_voters.length is 0 )
    assert( test_model.get_post(test_post.id).down_voters.length is 1 )
    assert( test_model.get_post(test_post.id).down_voters[0] is test_user.id )

#### Use Case 7: Favoriting a Post

    console.log "  Use Case 7: Favoriting a Post"

Finally, we'll have the user mark the post as her favorite:

    test_model.favorite_post(test_user.id,test_post.id)

And to validate:

    assert( test_model.get_post(test_post.id).favorited_by.length is 1 )
    assert( test_model.get_post(test_post.id).favorited_by[0] is test_user.id )
    assert( test_model.get_user(test_user.id).favorite_posts.length is 1 )
    assert( test_model.get_user(test_user.id).favorite_posts[0] is test_post.id )

#### End of the Domain Model Tests

And with that, we've validated that the domain model is working as expected.

    console.log "...Success! Done validating the Domain Model.\n"

## Implementing the Game

With our infrastructure in place, let's turn our attention to the [Abstract Gamification Engine](https://github.com/rodw/age)-specific logic we'll need to implement some of the StackOverflow badges.

StackOverflow supports a large number of badges (as described at [stackoverflow.com/help/badges](http://stackoverflow.com/help/badges)). As a representative sample, we'll implement the following:

 1. **Favorite Question** - awarded to a user when one of her questions has been favorited by 25 others. This badge can be awarded multiple times.

 2. **Good Question** - awarded to a user when one of her questions has achieved a net score of 25 upvotes (as determined by the subtracting the number of "downvoted" the question from the number of users that "upvoted" it).  This badge can be awarded multiple times.

 3. **Commentator** - awarded to a user that has left 10 comments. This badge is only awarded once per user.

 4. **Editor** - awarded to a user the first time she edits a post. This badge is only awarded once per user.

 5. **Supporter** - awarded to a user the the first time she upvotes a question. This badge is only awarded once per user.

 6. **Sufferage** - awarded to a user that has voted 30 times in one day. This badge can be awarded multiple times.

### Importing the Library

When using AGE, you'll typically import the library using something like this:

    # This is what you'll typically do:
    # AGE             = new (require('age'))
    # GameEngine      = AGE.GameEngine
    # AchievementRule = AGE.AchievementRule

but since the file you are reading is found *within* [the AGE repository](https://github.com/rodw/age) itself, we'll do things a little differently.  Most readers can safely ignore these next few lines and use the simple `require` statement above instead.

    # You WON'T do the following. We're only doing it here because we
    # want to use the "local" implementation of AGE.
    fs              = require 'fs'
    path            = require 'path'
    HOMEDIR         = path.join(__dirname,'..')
    LIB_COV_DIR     = path.join(HOMEDIR,'lib-cov')
    LIB_DIR         = if fs.existsSync(LIB_COV_DIR) then LIB_COV_DIR else path.join(HOMEDIR,'lib')
    AGE             = require(path.join(LIB_DIR,'index'))
    GameEngine      = AGE.GameEngine
    AchievementRule = AGE.AchievementRule


### Initializing the Engine

By default, the GameEngine uses an in-memory persitence mechansim (implemented in `MemoryDataSource`).  That's sufficient for our demonstration, so we can use the default constructor:

    engine = new GameEngine()

We'll also need an instance of our `MockQandAModel`, with a reference to the GameEngine we just created (so that it can publish events):

    model = new MockQandAModel(engine)

For ease of reference, we'll add a property to the GameEngine that contains a reference to our domain model.

    engine.model = model

That will be our model instance readily accessible to our achivement rules.

### AGE Achievement Rules

What StackOverflow calls "badges", the Abstract Gamification Engine calls "achivements".

In AGE, achievements are defined by "achievement rules" that describe (among other things) the condtions that a "player" (user) must meet in order to earn a given achivement.

Achievement rules are simply JavaScript objects with a specific collection of attributes.  A base class, named `AchievementRule` is provided as a convenience for implementors. We loaded this class above, in the section entitled [Importing the Library](#importing-the-library).

The base `AchievementRule` class is helpful, but we are not *required* to use it.   Any JavaScript object with the appropritate attributes can be used as an achievement rule.  The `AchievementRule` type simply adds an easy way to leverage default values (and as a reminder of the achievement rule contract).

Specifically, every AGE achievement rule must define two properties:

1. **predicate** - A function that determines whether or not a given player (user) has earned the achivement represented by this object. The `predicate` method accepts four parameters: a key value, a `GameEngine` instance, a player object and a callback function.  The callback method expects two parameters: an error object (only non-`null` if an error occurred during the `predicate`'s processing) and a boolean (`true` or `false`) value indicating whether or not this achievement was earned.

2. **key** - An identifier for this achievement. When an achievement is earned, this identifier will be included in the player's `achievements` array (as returned by `GameEngine.get_player_achievements`).

   The achievement rule's `key` attribute can take several forms:

   * a static JavaScript number or string
   * a static array of JavaScript numbers or strings, indicating several achievements that can be awarded by this single rule. The `predicate` function is invoked once for each element of this array.
   * a *function* that returns a scalar value or an array (presumably in some context sensitive way). As a function, the `key` attribute will be passed three arguments: a `GameEngine` instance, a player object, and a callback function.  The callback function accepts an optional error parameter and the corresponding key value(s).

In addition, each AGE achievement rule *can* include additional properties that modify the GameEngine's behavior:

3. **multiplicity** - A number that indicates how many times this achievement can be earned by a given player.  When `multiplicity` is `1`, the achievement can only be earned one time.  When `multiplicity` is some other positive integer `n`, the achievement can be earned at most `n` times.  When  `multiplicity` is `0` (or `null` or undefined), an achievement can be earned an infinite number of times.

   Note that an achievement rule implementation is free to set `multiplicity` to `0` and enforce its own "mulitiplicity" logic. But when `multiplicity` is a positive integer, the GameEngine will ensure that the achievement is awarded at most `multiplicity` times by any individual player, and can use this information to shortcut rule evaluation.

4. **transient** - By default, once a player has earned an achievement, recognition of that fact can be recorded in the persistence data store.  (And when the achievement has been awarded `multiplicity` times, the GameEngine doesn't even bother to re-evaluate the `predicate`.)  Setting `transient` to `true` overrides this default behavior, preventing the achievement from being peristently saved in player's `achievements` list.  When a rule is `transient`, the corresponding `predicate` will be evaluated every time `GameEngine.get_player_achievements` is invoked.

   This allows, among other features, time-sensitive achievements.  For example, an achievement might be based on whether the user (player) has visited a specific page *today*.

### Implementing the StackOverflow Badges

#### The *Favorite Question* Badge

Recall that the "Favorite Question" badge is awarded to a user when one of her questions has been favorited by 25 others.

Assuming questions cannot be "unfavorited", this achivement is persistent.  Hence we'll start with a non-transient AchievementRule.

This badge can be awarded multiple times, but only once for each question. Hence we'll set `multiplicity` to `1`, and use a different `key` value for each of the user's questions.

    favorite_question = new AchievementRule(multiplicity:1, transient:false)

Our `favorite_question.key` function will return an array of values, one for each question that the user has posted.  Hence we interrogate the domain model to determine the questions posted by the specified user:

    favorite_question.key = (engine,player,callback)->
      keys = []
      user = engine.model.get_user(player.id)
      posts = user.posts
      for post_id in posts
        keys.push "Favorite Question (#{post_id})"
      callback(null,keys)

Our `favorite_question.predicate` function must determine how many users have favorited the specified question and return the appropriate value:

    favorite_question.predicate = (key,engine,player,callback)->
      # parse the post id from the key string
      id_str = key.substring( "Favorite Question (".length, key.length-1 )
      # convert it to a number
      id = parseInt(id_str)
      post = engine.model.get_post(id)
      if post.favorited_by.length >= 25
        callback(null,true)
      else
        callback(null,false)

#### The *Good Question* Badge

Recall that the "Good Question" badge is awarded to a user when one of her questions has achieved a net score of 25 upvotes.

This achivement is transient, because questions can be upvoted or downvoted at any time.  Hence we'll start with a transient AchievementRule.

This badge can be awarded multiple times, but only once for each question. As above, we'll set `multiplicity` to `1`, and use a different `key` value for each of the user's questions.

    good_question = new AchievementRule(multiplicity:1, transient:true)

Our `key` function will return an array of values, one for each question that the user has posted.  Hence we interrogate the domain model to determine the questions posted by the specified user:

    good_question.key = (engine,player,callback)->
      keys = []
      user = engine.model.get_user(player.id)
      posts = user.posts
      for post_id in posts
        keys.push "Good Question (#{post_id})"
      callback(null,keys)

Our `predicate` function must determine the net score for the specified question and return the appropriate value:

    good_question.predicate = (key,engine,player,callback)->
      # parse the post id from the key string
      id_str = key.substring( "Good Question (".length, key.length-1 )
      # convert it to a number
      id = parseInt(id_str)
      post = engine.model.get_post(id)
      if (post.up_voters.length - post.down_voters.length) >= 25
        callback(null,true)
      else
        callback(null,false)


#### The *Commentor* Badge

Recall that the "Commentor" badge is awarded to a user that has submitted at least 10 comments.

This achivement is permanent, and can only be awarded once. Hence we'll start with a non-transient AchievementRule with a `multiplicity` of `1`.

    commentor = new AchievementRule(multiplicity:1, transient:false)

Unlike our previous examples, for the commentor badge a single key value suffices:

    commentor.key = "Commentor"

Our `predicate` function must determine the number of times the given user has submitted a comment:

    commentor.predicate = (key,engine,player,callback)->
      user = engine.model.get_user(player.id)
      if user.comments.length >= 10
        callback(null,true)
      else
        callback(null,false)


#### The *Editor* Badge

Recall that the "Editor" badge is awarded to a user the first time she edits a post.

This achivement is permanent, and can only be awarded once. Hence we'll start with a non-transient AchievementRule with a `multiplicity` of `1`.

    editor = new AchievementRule(multiplicity:1, transient:false)

Once again, a single key value suffices:

    editor.key = "Editor"

But this time our `predicate` function is a little trickier.  Within our domain model we are not explictly tracking the number of times a post is edited or the number of times a user edits a post.  But there is an event triggered each time a post is edited, and hence we can look to the user's event history to determine whether or not she has edited a post:

    editor.predicate = (key,engine,player,callback)->
      engine.get_player_history player, (err,history)->
        if err?
          callback(err)
        else
          for event in history
            if event.type is "Post Edited"
              callback(null,true)
              return
          callback(null,false)

#### The *Supporter* Badge

Recall that the "Supporter" badge is awarded to a user the first time she upvotes a question.

This achivement is permanent, and can only be awarded once. Hence we'll start with a non-transient AchievementRule with a `multiplicity` of `1`.

    supporter = new AchievementRule(multiplicity:1, transient:false)

Once again, a single key value suffices:

    supporter.key = "Supporter"

As with the `editor` achievement, our domain model doesn't directly store the information we're looking for in our `predicate` function.  We could enumerate every post and check to see if the given user is listed in the `post.up_voters` array, but that may not scale well if there are a very large number of posts (relative to the number of actions performed by each user).  Hence once again will look to the user's event history:

    supporter.predicate = (key,engine,player,callback)->
      engine.get_player_history player, (err,history)->
        if err?
          callback(err)
        else
          for event in history
            if event.type is "Post Upvoted"
              callback(null,true)
              return
          callback(null,false)


#### The *Sufferage* Badge

Recall that the "Sufferage" badge is awarded to a user that has voted 30 times in one day.

This achievement is permanent, so we'll start with  a non-transient AchievementRule.

This achievement can be awarded once per day, so once again we'll use a `multiplicity` of `1` and a distinct key for each time the achievement could be awarded:

    sufferage = new AchievementRule(multiplicity:1, transient:false)

The *Sufferage* badge is a little tricky to squeeze in to the current `key` logic.  We need to enumerate one key value for every time the achievement could be awarded, but creating one key for every single day the user has existed seems a little crazy.  Since the `key` function is passed the GameEngine and player instance, we can scale that back quite a bit by only looking at the days on which the user has voted at least once.

First, let's create a simple utility function that yields a formatted date from a JavaScript `Date.now()` timestamp:

    to_date_str = (ts)->
      d = new Date(ts)
      return "#{d.getFullYear()}/#{d.getMonth()+1}/#{d.getDate()}"

And then use that to generate our key values:

    sufferage.key = (engine,player,callback)->
      engine.get_player_history player, (err,history)->
        if err?
          callback(err)
        else
          keys = []
          for event in history
            if event.type in [ "Post Upvoted", "Post Downvoted" ]
              dstr = "Sufferage (#{to_date_str(event.timestamp)})"
              keys.push dstr unless(dstr in keys)
          callback(null,keys)

Our `predicate` function must reverse that process slightly.  First we parse the date in question from the generated key string, and then we review the user's event history to determine how many votes were cast on that day:

    sufferage.predicate = (key,engine,player,callback)->
      # parse the date from the key string
      dt = key.substring( "Sufferage (".length, key.length-1 )

      engine.get_player_history player, (err,history)->
        if err?
          callback(err)
        else
          vote_count = 0
          for event in history
            if event.type in [ "Post Upvoted", "Post Downvoted" ]
              if to_date_str(event.timestamp) is dt
                vote_count++
                if vote_count >= 7
                  callback(null,true)
                  return
          callback(null,false)

### Testing the Badges

Ok. Now lets try those out.

    console.log "\nTesting the Badge Implementations..."

First we'll need to register our achievement rules with the GameEngine:

    engine.add_achievement_rule favorite_question
    engine.add_achievement_rule good_question
    engine.add_achievement_rule commentor
    engine.add_achievement_rule editor
    engine.add_achievement_rule supporter
    engine.add_achievement_rule sufferage

Next, let's generate some users and posts that we can work with:

    users = []
    [1..40].forEach (i)->users.push model.create_user("User #{i}")

    posts = []
    [1..10].forEach (i)->posts.push model.create_post(users[i*2].id,"Post ${i}","Lorem ipsum...")

Finally, let's create a couple of specific users to be interested in:

    jane = model.create_user("Jane")
    john = model.create_user("John")


#### Initially, no badges at all

    console.log "  Initially, no badges..."

Initially, neither Jane nor John should have any badges yet:

    assert_achivement_count = (player,count, callback)->
      engine.get_player_achievements player, (err,achievements)->
        assert( err is null )
        assert( achievements.length is count )
        callback?()

    assert_achivement_count jane, 0, ()->
      assert_achivement_count john, 0, ()->
        console.log "  ...both Jane and John have no achievements."

#### The *Favorite Question* Badge

    console.log "  The Favorite Question Badge..."

Let's have Jane post a new question:

    janes_first_post = model.create_post(jane.id,"First Post","Lorem Ipsum")

and have a bunch of the other users favorite it:

    for user in users
      model.favorite_post(user.id,janes_first_post.id)

Now we should expect that Jane has earned the "Favorite Question" badge:

    assert_achievement = (player, badge, callback)->
      engine.get_player_achievements player, (err,achievements)->
        assert( err is null )
        assert( badge in achievements )
        callback?()

    assert_achievement jane, "Favorite Question (#{janes_first_post.id})", ()->
      console.log "  ...Jane has earned the Favorite Question badge."

Let's have Jane post a second question:

    janes_second_post = model.create_post(jane.id,"Second Post","Lorem Ipsum")

and again have a bunch of the other users favorite it:

    for user in users
      model.favorite_post(user.id,janes_second_post.id)

Now we should expect that Jane has earned two "Favorite Question" badges:

    assert_achievement jane, "Favorite Question (#{janes_first_post.id})", ()->
      assert_achievement jane, "Favorite Question (#{janes_second_post.id})", ()->
        console.log "  ...Jane has earned two of the Favorite Question badges."

But John still hasn't earned any badges:

    assert_achivement_count john, 0, ()->
      console.log "  ...but John still has no achievements."

#### The *Good Question* Badge

    console.log "  The Good Question Badge..."

Let's have John post a new question:

    johns_first_post = model.create_post(john.id,"John's First Post","Lorem Ipsum")

and have a bunch of the other users upvote it:

    for user in users
      model.upvote_post(user.id,johns_first_post.id)

Now we should expect that John has earned the "Good Question" badge:

    assert_achievement john, "Good Question (#{johns_first_post.id})", ()->
      console.log "  ...John has earned the Good Question badge."

But if some of the users were to change their votes from upvotes to downvotes:

    for user in users.slice(0,10)
      model.downvote_post(user.id,johns_first_post.id)

We expect John to un-earn that achievement:

    assert_achivement_count john, 0, ()->
      console.log "  ...John has now un-earned the Good Question badge."

#### The *Commentor* Badge

    console.log "  The Commentor Badge..."

Let's have John post comments on some of the other posts:

    for post in posts
      model.create_comment john.id, post.id, "A comment from John on post #{post.id}"

Now we should expect that John has earned the "Commentor" badge:

    assert_achievement john, "Commentor", ()->
      console.log "  ...John has earned the Commentor badge."

#### The *Editor* Badge

    console.log "  The Editor Badge..."

Next let's have Jane edit one of her posts:

    model.edit_post jane.id, janes_first_post.id, "Edited by Jane"

Now Jane should have earned the "Editor" badge:

    assert_achievement jane, "Editor", ()->
      console.log "  ...Jane has earned the Editor badge."

#### The *Supporter* Badge

    console.log "  The Supporter Badge..."

Jane hasn't upvoted a post yet, so she does not have the Supporter badge:

    assert_no_achievement = (player, badge, callback)->
      engine.get_player_achievements player, (err,achievements)->
        assert( err is null )
        assert( not ( badge in achievements) )
        callback?()

    assert_no_achievement jane, "Supporter", ()->
      console.log "  ...Jane doesn't have the Supporter badge yet."

But if she upvotes John's post:

    model.upvote_post jane.id, johns_first_post.id

Now Jane *should* have the "Supporter" badge:

    assert_achievement jane, "Supporter", ()->
      console.log "  ...now Jane has the Supporter badge."

#### The *Sufferage* Badge

    console.log "  The Sufferage Badge..."

John hasn't yet upvoted 30 posts today, so he does not have the Sufferage badge:

    assert_no_achievement john, "Sufferage (#{to_date_str(Date.now())})", ()->
      console.log "  ...John doesn't have the Sufferage badge yet."

But if he upvotes a bunch of posts

    for post in posts
      model.upvote_post john.id, post.id

Now he *should* have the "Sufferage" badge:

    assert_achievement john, "Sufferage (#{to_date_str(Date.now())})", ()->
      console.log "  ...now John has the Sufferage badge."

#### End of the Achievement Rule Tests

And with that, we've tested all of our achievements

    console.log "...Success! Done validating the achievement rules.\n"
