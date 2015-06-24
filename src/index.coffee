inject = require 'honk-di'

CortexView       = window.Cortex?.view
setAsPlayed      = require('vistar-html5player').Player.setAsPlayed
{PassThrough}    = require 'stream'
{ProofOfPlay}    = require 'vistar-html5player'
{VariedAdStream} = require 'vistar-html5player'

config           = require './config'


class Playlist extends PassThrough
  constructor: ->
    super(objectMode: true, highWaterMark: 1)


class AdView
  ads:          inject VariedAdStream
  proofOfPlay:  inject ProofOfPlay
  playlist:     inject Playlist

  constructor: ->
    @ads.pipe(@playlist)
    @currentAd = null

  run: =>
    @currentAd = @playlist.read(1)
    if not @currentAd
      return setTimeout @run, 2000

    callbacks =
      error:  @_error
      end:    @_end

    if @currentAd.mime_type.match(/^image/)
      html = @render()
      # the 1st argument given to submitView/Video is expected to be the
      # constructor.name which is 'AdView' here.  if that ever changes, change
      # these as 1st arguments well.
      CortexView.submitView 'AdView',
        html,
        @currentAd.length_in_milliseconds,
        callbacks
    if @currentAd.mime_type.match(/^video/)
      CortexView.submitVideo 'AdView',
      @currentAd.asset_url,
        callbacks

  _end: =>
    if @currentAd
      console.log 'end w/current ad'
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

  render: =>
    """
    <div class="image-ad"
      style="background: url(#{@currentAd.asset_url}) no-repeat center center fixed;">
    </div>
    """


module.exports = {
  AdView
  config
}
