# vistar-ad-view-cortex

a standalone Cortex lib for displaying Vistar Media ads.


coffeescript
```
adConfig            = require('vistar-ad-view-cortex').config
inject              = require 'honk-di'
{AdView}            = require('vistar-ad-view-cortex')
{Ajax, XMLHttpAjax} = require 'ajax'

class Binder extends inject.Binder
  configure: ->
    @bind(Ajax).to(XMLHttpAjax)
    @bindConstant('download-cache').to {}

    @bindConstant('config').to adConfig.config

injector = new inject.Injector(new Binder)
adView   = injector.getInstance AdView

Cortex?.view.register adView.constructor.name
Cortex?.view.setDefaultView adView.constructor.name

adView.run()
Cortex?.view.start()

```

the "config" object from the vistar-ad-view-cortex library will contain any
parameters set in the Cortex dashboard.

