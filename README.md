**AGE** implements an abstract gamification engine.

Clients define ***achievement rules*** which define conditions that ***players*** must meet in order to earn the corresponding **achievement** and publish **events** that represent actions or events that add to a player's ***event history***.

AGE is implemented in [CoffeeScript](http://coffeescript.org/) but compiled to JavaScript prior to publishing.  It should work in any [Node.js](http://nodejs.org) environment.

(It may also work, or could be made to work, within a browser, but we haven't had the need for that nor the time to test it.  If you are interested in this feature, please [let us know](https://github.com/rodw/age/issues).

## Examples

For a detailed example of how to use the AGE framework, visit [docs/stack-exchange-example.litcoffee](docs/stack-exchange-example.litcoffee).

## Installing

AGE is published an an [npm](http://npmjs.org/) module under the name [age](https://npmjs.org/package/age).

To install it you can run:

    npm install -g age

(Omit the `-g` to install the package to the `node_modules` subdirectory of the current working directory rather than to the "global" npm package repository.)

Currently AGE has no external (runtime) dependencies.
