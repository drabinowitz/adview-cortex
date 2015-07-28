{sandbox, stub} = require 'sinon'
chai            = require 'chai'
{Ajax}          = require 'ajax'
TestAjax        = require 'ajax/test'
inject          = require 'honk-di'

# this global.window = {} is necessary because we're checking for
# window.Cortex?.net down in vistar-html5player.  probably inject Cortex down
# there instead
global.window = {}

chai.use(require('sinon-chai'))


class Binder extends inject.Binder
  {config} = require '../src/config'
  config.cacheAssets = false
  config.queueSize   = 2

  configure: ->
    @bind(Ajax).to(TestAjax)
    @bindConstant('cortex').to(stub())
    @bindConstant('config').to(config)
    @bindConstant('navigator').to
      mimeTypes: [
        type: 'x-test-mimetype-from-the-browser'
      ]


beforeEach ->
  binder    = new Binder
  @injector = new inject.Injector(binder)
  @sandbox  = sandbox.create()
  @fail = (why) ->
    throw new Error(why)


afterEach ->
  @sandbox.restore()
