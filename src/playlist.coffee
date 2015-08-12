{PassThrough} = require 'stream'
{Transform}   = require 'stream'


class Playlist extends PassThrough
  constructor: (@_cortex) ->
    super(objectMode: true, highWaterMark: 1)


class ConsecutiveOnlyAfterFallback extends Transform
  # only pass ads thru this stream consecutively after we've submitted a no-op
  # view to Cortex, which will flip flop back and forth between the AdView and
  # the registered fallback view if it exists

  constructor: (@_cortex) ->
    @_setAd(null)
    super(objectMode: true, highWaterMark: 1)

  _setAd: (ad) ->
    @_lastAd = ad

  _shouldNotPlayAd: (ad) ->
    if not ad.creative_id
      # without creative_id we have nothing.  help a homie out if that happens
      throw new Error('creative_id required')
    ad.creative_id is @_lastAd?.creative_id

  _transform: (ad, encoding, done) ->
    if @_shouldNotPlayAd(ad)
      callbacks =
        end:    @_noOpEnd(done)
        error:  (e) -> console.error(e)
      @_cortex.view.submitNoop('AdView', callbacks)
    else
      @_setAd(ad)
      @push(ad)
      done()

  _noOpEnd: (done) ->
    =>
      @_setAd(null)
      done()


module.exports = {
  ConsecutiveOnlyAfterFallback
  Playlist
}
