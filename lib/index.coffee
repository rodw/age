path                    = require('path')
fs                      = require('fs')
HOMEDIR                 = path.join(__dirname,'..')
IS_INSTRUMENTED         = fs.existsSync(path.join(HOMEDIR,'lib-cov'))
LIB_DIR                 = if IS_INSTRUMENTED then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
exports                 = exports ? this
exports.DataStore       = require(path.join(LIB_DIR,'data-store')).DataStore
exports.MemoryDataStore = require(path.join(LIB_DIR,'memory-data-store')).MemoryDataStore
exports.GameEngine      = require(path.join(LIB_DIR,'game-engine')).GameEngine
exports.AchievementRule = require(path.join(LIB_DIR,'achievement-rule')).AchievementRule
