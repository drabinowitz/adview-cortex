require './test_case'
{Ajax}   = require 'ajax'
{expect} = require 'chai'
sinon    = require 'sinon'

{AdView}                       = require '../src/index'
{ConsecutiveOnlyAfterFallback} = require '../src/playlist'
{Playlist}                     = require '../src/playlist'


describe 'AdView', ->

  beforeEach ->
    @config = @injector.getInstance 'config'
    @view = @injector.getInstance AdView
    @ajax = @injector.getInstance Ajax

  it 'should use the default Playlist', ->
    expect(@view.playlist).to.be.an.instanceOf Playlist

  it 'should use given config.playlist_implementation', ->
    @config.uniqueAdSeconds = undefined
    @sandbox.stub @config,
      'playlistImplementation',
      'ConsecutiveOnlyAfterFallback'
    view = @injector.getInstance AdView
    expect(view.playlist).to.be.an.instanceOf ConsecutiveOnlyAfterFallback

  context 'ads pipe is broken', ->
    it 'should set the broken pipe flag', ->
      expect(@view._pipeIsBroken).to.be.false
      @view.playlist.emit 'error', new Error()
      expect(@view._pipeIsBroken).to.be.true

  describe '#isReady', ->

    it 'should be false if currentAd is null', ->
      expect(@view.isReady()).to.be.false

    it 'should be true if currentAd is not null', ->
      @view.currentAd = {}
      expect(@view.isReady()).to.be.true

  describe '#render', ->

    it 'should return null if no current ad', ->
      expect(@view.render()).to.be.null

    it 'should return asset url if video', ->
      @view.currentAd = {
        asset_url: 'http://example.com/'
        mime_type: 'video/webm'
      }
      expect(@view.render()).to.equal 'http://example.com/'

    it 'should return html if image', ->
      @view.currentAd = {
        asset_url: 'http://example.com/p.jpb'
        mime_type: 'image.jpg'
      }
      expect(@view.render()).to.have.string 'class="image-ad"'

  describe '#run', ->

    beforeEach ->
      now = 1438196488117
      @sandbox.useFakeTimers(now)
      @url = 'http://dev.api.vistarmedia.com/api/v1/get_ad/json'

    it 'should call `run` again in two seconds if no ad to show'

    it 'should call submitView with html if ad is image', ->
      cortex = @injector.getInstance 'cortex'
      view =
        submitView: @sandbox.spy()
      cortex.view = view

      @ajax.match url: @url, type: 'POST', (req, def) ->
        def.resolve
          advertisement: [
            creative_id: 'foxes'
            asset_url: 'http://example.com/foxes.jpg'
            length_in_milliseconds: 5000
            mime_type: 'image/png'
          ]
      view = @injector.getInstance AdView
      view.run()
      expect(cortex.view.submitView).to.have.been.called.once
      [cortexId, html, length, callbacks] = cortex.view.submitView.lastCall.args
      expect(cortexId).to.equal 'AdView'
      expect(html).to.contain.string 'image-ad'
      expect(html).to.contain.string 'http://example.com/foxes.jpg'
      expect(length).to.equal 5000
      expect(callbacks.end).to.equal view._end
      expect(callbacks.error).to.equal view._error


    it 'should call submitVideo with url if ad is video', ->
      cortex = @injector.getInstance 'cortex'
      view =
        submitVideo: @sandbox.spy()
      cortex.view = view

      @ajax.match url: @url, type: 'POST', (req, def) ->
        def.resolve
          advertisement: [
            creative_id: 'foxes'
            asset_url: 'http://example.com/foxes.webm'
            length_in_milliseconds: 5000
            mime_type: 'video/webm'
          ]
      view = @injector.getInstance AdView
      view.run()
      expect(cortex.view.submitVideo).to.have.been.called.once
      [cortexId, url, callbacks] = cortex.view.submitVideo.lastCall.args
      expect(cortexId).to.equal 'AdView'
      expect(url).to.equal 'http://example.com/foxes.webm'
      expect(callbacks.end).to.equal view._end
      expect(callbacks.error).to.equal view._error

    it 'should set running flag', ->
      expect(@view._isRunning).to.be.false
      @view.run()
      expect(@view._isRunning).to.be.true

    it 'should set last run time', ->
      expect(@view._lastRunTime).to.equal 0
      @view.run()
      expect(@view._lastRunTime).to.be.above 0

    context 'callbacks given to Cortex API', ->

      context 'on end', ->

        it 'should set add as played and write to proof of play', ->
          @sandbox.stub @view, 'currentAd',
            creative_id: 'house'
          @sandbox.spy @view.proofOfPlay, 'write'

          @view._end()
          expect(@view.proofOfPlay.write).to.have.been.called
          [ad] = @view.proofOfPlay.write.lastCall.args
          expect(ad).to.exist
          expect(ad.creative_id).to.equal 'house'
          expect(ad.html5player.was_played).to.be.true

        it 'should update the last render time', ->
          @sandbox.stub @view, 'currentAd',
            creative_id: 'house'
          @sandbox.spy @view.proofOfPlay, 'write'

          lrt = @view._lastAdRenderTime
          @view._end()
          expect(@view._lastAdRenderTime).to.be.above lrt

        it 'should set currentAd to null', ->
          @sandbox.stub @view, 'currentAd',
            creative_id: 'house'
          @sandbox.stub @view.proofOfPlay, 'write'

          @view._end()
          expect(@view.currentAd).to.be.null

        it 'should call `run` again immediately', ->
          @sandbox.spy @view, 'run'
          @view._end()

          expect(@view.run).to.have.been.called.once

      context 'on error', ->

        it 'should set as as not played and write to proof of play', ->
          @sandbox.stub @view, 'currentAd',
            creative_id: 'house'
          @sandbox.spy @view.proofOfPlay, 'write'

          @view._error()
          expect(@view.proofOfPlay.write).to.have.been.called.once
          [ad] = @view.proofOfPlay.write.lastCall.args
          expect(ad).to.exist
          expect(ad.creative_id).to.equal 'house'
          expect(ad.html5player.was_played).to.be.false

        it 'should set @currentAd to null', ->
          @sandbox.stub @view, 'currentAd',
            creative_id: 'house'
          @sandbox.stub @view.proofOfPlay, 'write'

          @view._error()
          expect(@view.currentAd).to.be.null

        it 'should call `run` again in 1 second', ->
          @sandbox.spy @view, 'run'
          @view._error()

          expect(@view.run).not.to.have.been.called
          @sandbox.clock.tick(1000)
          expect(@view.run).to.have.been.called.once

  describe '#onHealthCheck', ->
    beforeEach ->
      @clock = sinon.useFakeTimers()

    afterEach ->
      @clock.restore()

    it 'should fail when pipe is broken', (done) ->
      cortex = @injector.getInstance 'cortex'
      cortex.net =
        isConnected: (cb) -> cb true
      @view._pipeIsBroken = true
      @view.onHealthCheck (res) ->
        expect(res.status).to.be.false
        expect(res.reason).to.match /Ad view cannot process ads/
        done()

    it 'should pass when network is not connected', (done) ->
      cortex = @injector.getInstance 'cortex'
      cortex.net =
        isConnected: (cb) -> cb false
      @view._isRunning = true
      @view.onHealthCheck (res) ->
        expect(res.status).to.be.true
        done()

    it 'should pass when adview is not running', (done) ->
      cortex = @injector.getInstance 'cortex'
      cortex.net =
        isConnected: (cb) -> cb true
      @view.onHealthCheck (res) ->
        expect(res.status).to.be.true
        done()

    it 'should fail when ad view stopped running', (done) ->
      cortex = @injector.getInstance 'cortex'
      cortex.net =
        isConnected: (cb) -> cb true
      @view._lastRunTime = 1000
      @view._isRunning = true
      @view.onHealthCheck (res) =>
        expect(res.status).to.be.true
        @clock.tick (@config.healthCheck.lastAdViewRunTimeThreshold + 2000)
        @view.onHealthCheck (res) =>
          expect(res.status).to.be.false
          expect(res.reason).to.match /Ad view has stopped working/
          done()

    it 'should fail when last ad request time exceeds the threshold', (done) ->
      cortex = @injector.getInstance 'cortex'
      cortex.net =
        isConnected: (cb) -> cb true
      @view.ads.lastRequestTime = 1000
      @view._isRunning = true
      @view.onHealthCheck (res) =>
        expect(res.status).to.be.true
        @clock.tick (@config.healthCheck.lastAdRequestTimeThreshold + 2000)
        @view._lastRunTime = new Date().getTime()
        @view.onHealthCheck (res) =>
          expect(res.status).to.be.false
          expect(res.reason).to.match /Ad requests has stopped/
          done()

    it 'should fail when last successful ad request time exceeds the threshold', (done) ->
      cortex = @injector.getInstance 'cortex'
      cortex.net =
        isConnected: (cb) -> cb true
      @view.ads.lastSuccessfulRequestTime = 1000
      @view._isRunning = true
      @view.onHealthCheck (res) =>
        expect(res.status).to.be.true
        @clock.tick (@config.healthCheck.lastSuccessfulAdRequestTimeThreshold + 2000)
        @view._lastRunTime = new Date().getTime()
        @view.ads.lastRequestTime = new Date().getTime()
        @view.onHealthCheck (res) =>
          expect(res.status).to.be.false
          expect(res.reason).to.match /Ad requests are failing/
          done()

    it 'should fail when last PoP request time exceeds the threshold', (done) ->
      cortex = @injector.getInstance 'cortex'
      cortex.net =
        isConnected: (cb) -> cb true
      @view.proofOfPlay.lastRequestTime = 1000
      @view._isRunning = true
      @view._lastAdRenderTime = 1000
      @view.onHealthCheck (res) =>
        expect(res.status).to.be.true
        @clock.tick (@config.healthCheck.lastPopRequestTimeThreshold + 2000)
        @view._lastRunTime = new Date().getTime()
        @view._lastAdRenderTime = new Date().getTime()
        @view.ads.lastRequestTime = new Date().getTime()
        @view.onHealthCheck (res) =>
          expect(res.status).to.be.false
          expect(res.reason).to.match /PoP requests has stopped/
          done()

    it 'should fail when last successful PoP request time exceeds the threshold', (done) ->
      cortex = @injector.getInstance 'cortex'
      cortex.net =
        isConnected: (cb) -> cb true
      @view._isRunning = true
      @view._lastAdRenderTime = 1000
      @view.proofOfPlay.lastSuccessfulRequestTime = 1000
      @view.onHealthCheck (res) =>
        expect(res.status).to.be.true
        @clock.tick (@config.healthCheck.lastSuccessfulPopRequestTimeThreshold + 2000)
        @view._lastRunTime = new Date().getTime()
        @view._lastAdRenderTime = new Date().getTime()
        @view.ads.lastRequestTime = new Date().getTime()
        @view.ads.lastSuccessfulRequestTime = new Date().getTime()
        @view.proofOfPlay.lastRequestTime = new Date().getTime()
        @view.onHealthCheck (res) =>
          expect(res.status).to.be.false
          expect(res.reason).to.match /PoP requests are failing/
          done()

    it 'should pass when everything is alright', (done) ->
      cortex = @injector.getInstance 'cortex'
      cortex.net =
        isConnected: (cb) -> cb true
      @view._isRunning = true
      @view.onHealthCheck (res) =>
        expect(res.status).to.be.true
        @clock.tick (@config.healthCheck.lastSuccessfulPopRequestTimeThreshold + 2000)
        @view._lastRunTime = new Date().getTime()
        @view.ads.lastRequestTime = new Date().getTime()
        @view.ads.lastSuccessfulRequestTime = new Date().getTime()
        @view.proofOfPlay.lastRequestTime = new Date().getTime()
        @view.proofOfPlay.lastSuccessfulRequestTime = new Date().getTime()
        @view.onHealthCheck (res) =>
          expect(res.status).to.be.true
          done()
