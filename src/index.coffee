inject = require 'honk-di'

setAsPlayed      = require('vistar-html5player').Player.setAsPlayed
{ProofOfPlay}    = require 'vistar-html5player'
{VariedAdStream} = require 'vistar-html5player'

config = require './config'

{
  Playlist
  ConsecutiveOnlyAfterFallback
} = require './playlist'


getPlaylistImpl = (config) ->
  if config.playlistImplementation is 'ConsecutiveOnlyAfterFallback'
    ConsecutiveOnlyAfterFallback
  else
    Playlist


class AdView
  ads:          inject VariedAdStream
  proofOfPlay:  inject ProofOfPlay
  config:       inject 'config'
  _cortex:      inject 'cortex'

  constructor: ->
    @playlist = new (getPlaylistImpl(@config))(@_cortex)
    @_pipeIsBroken = false
    @ads.pipe(@playlist).on 'error', (e) =>
      @_pipeIsBroken = true
    @currentAd = null
    @_lastRunTime = 0
    @_lastAdRenderTime = 0
    @_isRunning = false

  run: =>
    @_isRunning = true
    @_lastRunTime = new Date().getTime()
    @currentAd = @playlist.read(1)
    if not @isReady()
      return setTimeout @run, 2000

    callbacks =
      error:  @_error
      end:    @_end

    opts =
      view:
        label: @currentAd.original_asset_url

    if @isImage()
      @_cortex.view.submitView @constructor.name,
        @render(),
        @currentAd.length_in_milliseconds,
        callbacks,
        opts
    if @isVideo()
      @_cortex.view.submitVideo @constructor.name,
        @render(),
        callbacks,
        opts

  _end: =>
    if @currentAd
      ad = setAsPlayed @currentAd, true
      @proofOfPlay.write ad
      @currentAd = null
      @_lastAdRenderTime = new Date().getTime()
    @run()

  _error: (err) =>
    console.error err
    if @currentAd
      ad = setAsPlayed @currentAd, false
      @proofOfPlay.write ad
      @currentAd = null
    setTimeout @run, 1000

  isImage: ->
    @currentAd and @currentAd.mime_type.match(/^image/)

  isVideo: ->
    @currentAd and @currentAd.mime_type.match(/^video/)

  isReady: ->
    @currentAd isnt null

  render: =>
    # return something to give to Cortex's submitView/Video function
    if @isImage()
      url = @currentAd.asset_url
      return """
      <div class="image-ad"
        style="background: url(#{url}) no-repeat center center local;">
      </div>
      """
    if @isVideo()
      return @currentAd.asset_url
    null

  onHealthCheck: (report) ->
    @_cortex.net.isConnected (connected) =>
      if @_pipeIsBroken
        # AdView is useless, we need to restart the app.
        report status: false, reason: 'Ad view cannot process ads'
        return

      if not connected or not @_isRunning
        # When there's no internet connection or the application hasn't started
        # this view we shouldn't do health checks.
        report status: true
        return

      # AdView is okay, we need to check the html5 player
      now = new Date().getTime()
      if @_lastRunTime + @config.healthCheck.lastAdViewRunTimeThreshold < now
        report status: false, reason: 'Ad view has stopped working'
      else if @ads.lastRequestTime + @config.healthCheck.lastAdRequestTimeThreshold < now
        report status: false, reason: 'Ad requests has stopped'
      else if @ads.lastSuccessfulRequestTime +
              @config.healthCheck.lastSuccessfulAdRequestTimeThreshold < now
        report status: false, reason: 'Ad requests are failing'
      else if @proofOfPlay.lastRequestTime +
              @config.healthCheck.lastPopRequestTimeThreshold < @_lastAdRenderTime
        report status: false, reason: 'PoP requests has stopped'
      else if @proofOfPlay.lastSuccessfulRequestTime +
              @config.healthCheck.lastSuccessfulPopRequestTimeThreshold < @_lastAdRenderTime
        report status: false, reason: 'PoP requests are failing'
      else
        report status: true

module.exports = {
  AdView
  config
}
