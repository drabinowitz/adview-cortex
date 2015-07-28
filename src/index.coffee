inject = require 'honk-di'

setAsPlayed      = require('vistar-html5player').Player.setAsPlayed
{ProofOfPlay}    = require 'vistar-html5player'
{VariedAdStream} = require 'vistar-html5player'

config = require './config'

{
  Playlist
  TimedUniquePlaylist
} = require './playlist'

getPlaylistImpl = (config) ->
  if config.uniqueAdSeconds
    TimedUniquePlaylist
  else
    Playlist


class AdView
  ads:          inject VariedAdStream
  proofOfPlay:  inject ProofOfPlay
  config:       inject 'config'
  _cortex:      inject 'cortex'

  constructor: ->
    @playlist = new (getPlaylistImpl(@config))(@proofOfPlay, @config)
    @ads.pipe(@playlist)
    @currentAd = null

  run: =>
    @currentAd = @playlist.read(1)
    if not @isReady()
      return setTimeout @run, 2000

    callbacks =
      error:  @_error
      end:    @_end

    if @isImage()
      @_cortex.view.submitView @constructor.name,
        @render()
        @currentAd.length_in_milliseconds,
        callbacks
    if @isVideo()
      @_cortex.view.submitVideo @constructor.name,
        @render()
        callbacks

  _end: =>
    if @currentAd
      ad = setAsPlayed @currentAd, true
      @proofOfPlay.write ad
      @currentAd = null
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
      return """
      <div class="image-ad"
        style="background: url(#{@currentAd.asset_url}) no-repeat fixed;">
      </div>
      """
    if @isVideo()
      return @currentAd.asset_url
    null


module.exports = {
  AdView
  config
}
