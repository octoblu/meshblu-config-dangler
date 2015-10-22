_             = require 'lodash'
Meshblu       = require 'meshblu'
debug         = require('debug')('meshblu-config-dangler:config-dangler')
MeshbluConfig = require 'meshblu-config'
UUID          = require 'node-uuid'

class ConfigDangler
  constructor: ->
    @keys = {}
    @deleteKeys = []
    @totalCount = 0
    @processedCount = 0
    @pendingCount = 0
    meshbluConfig = new MeshbluConfig
    @meshbluJSON = meshbluConfig.toJSON()

  run: =>

    @connect =>
      _.delay @printResult, 1000 * 10
      @conn.on 'config', @onConfig
      @updateInterval = setInterval @updateDevice, 100

  checkInterval: =>
    debug 'checking keys', _.size @keys
    _.each _.keys(@keys), (key) =>
      time = @keys[key]
      return unless time.getTime() < (Date.now() - 1000)
      @pendingCount++
      console.log 'pending config', key, time.toString()

  updateDevice: =>
    key = UUID.v1()
    @keys[key] = new Date()
    updateProperties =
      uuid: @meshbluJSON.uuid
      token: @meshbluJSON.token
    updateProperties[key] = true
    @totalCount++
    @conn.update updateProperties, (error) =>
      console.error error if erorr?
      debug 'updated'

  connect: (callback=->) =>
    @conn = Meshblu.createConnection @meshbluJSON
    @conn.on 'ready', =>
      callback()

  onConfig: (device) =>
    _.each _.keys(@keys), (key) =>
      return unless device[key]?
      debug 'found the key, great scott!'
      @processedCount++
      delete @keys[key]

  printResult: =>
    @checkInterval()
    console.log '================='
    console.log 'Total Count ', @totalCount
    console.log 'Total Processed', @processedCount
    console.log 'Total Pending', @pendingCount
    console.log 'Percent', Math.round @pendingCount / @totalCount
    console.log '================='
    process.exit 0

module.exports = ConfigDangler
