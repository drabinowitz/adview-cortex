inject        = require 'honk-di'
{PassThrough} = require 'stream'
{Transform}   = require 'stream'

setAsPlayed      = require('vistar-html5player').Player.setAsPlayed
{ProofOfPlay}    = require 'vistar-html5player'


now = -> (new Date).getTime()


class Playlist extends PassThrough
  constructor: ->
    super(objectMode: true, highWaterMark: 1)


class TimedUniquePlaylist extends Transform
  # only allow the same ad every n seconds
  # if we get an ad we saw within the past n seconds, expire it

  constructor: (@proofOfPlay, config) ->
    @_wait   = Number(config?.uniqueAdSeconds or 15) * 1000
    @_lastAd = null
    super(objectMode: true, highWaterMark: 1)

  _setAd: (ad) ->
    @_lastAd = ad
    @_at = now()

  _shouldNotPlayAd: (ad) ->
    if not ad.creative_id
      # without creative_id we have nothing.  help a homie out if that happens
      throw new Error('creative_id required')
    isSame = ad.creative_id is @_lastAd?.creative_id
    isSame and (now() - @_at) <= @_wait

  _transform: (ad, encoding, done) ->
    if @_shouldNotPlayAd(ad)
      @proofOfPlay.write setAsPlayed(ad, false)
    else
      @_setAd(ad)
      @push(ad)
    done()


module.exports = {
  Playlist
  TimedUniquePlaylist
}
