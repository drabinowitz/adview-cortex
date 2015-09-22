inject = require 'honk-di'

Cortex           = window.Cortex
{Ajax}           = require 'ajax'
{XMLHttpAjax}    = require 'ajax'
{AdView, config} = require 'vistar-ad-view-cortex'


init = ->
  # bindings required for AdView and Html5Player
  class Binder extends inject.Binder
    configure: ->
      @bind(Ajax).to(XMLHttpAjax)
      @bindConstant('config').to(config.config)
      @bindConstant('cortex').to(Cortex)
      @bindConstant('navigator').to(window.navigator)

  injector = new inject.Injector(new Binder)

  adView = injector.getInstance AdView
  Cortex.view.setDefaultView adView.constructor.name
  adView.run()

  window.__cortex_scheduler = Cortex.view
  container = document.getElementById('adview-app-container')
  Cortex.view.start(container)


module.exports = init()
