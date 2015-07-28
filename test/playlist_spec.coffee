require './test_case'
through2      = require 'through2'
{expect}      = require 'chai'
{ProofOfPlay} = require 'vistar-html5player'

{Playlist}            = require '../src/playlist'
{TimedUniquePlaylist} = require '../src/playlist'


describe 'TimedUniquePlaylist', ->

  beforeEach ->
    @proofOfPlay = @injector.getInstance ProofOfPlay

  it 'should get its _wait property from given config', ->
    playlist = new TimedUniquePlaylist(@proofOfPlay, uniqueAdSeconds: 5)
    expect(playlist._wait).to.equal 5000

  describe 'when given an ad with a matching creative_id', ->

    describe 'when that ad has played within the threshold', ->

      beforeEach ->
        @ad =
          creative_id: 'dogbeef'
        now = 1438196488117
        # threshold of 15 seconds
        threshold = 15 * 1000
        @sandbox.useFakeTimers(now)

        @playlist = new TimedUniquePlaylist(@proofOfPlay)
        @playlist._wait   = threshold
        # last saw this ad 7 seconds ago
        @playlist._at     = now - 7 * 1000
        @playlist._lastAd = @ad

      it 'should not pass that ad down the stream', ->
        @playlist.pipe through2.obj =>
          @fail('should not pass ad down stream')

        @playlist.write(@ad)

      it 'should write ad as "not played" to proofOfPlay', ->
        write = @sandbox.spy @playlist.proofOfPlay, 'write'

        @playlist.write(@ad)
        expect(write).to.have.been.calledOnce
        [ad] = write.lastCall.args
        expect(ad.creative_id).to.equal 'dogbeef'
        expect(ad.html5player?.was_played).to.be.false

    describe 'when that ad has played outside the threshold', ->

      beforeEach ->
        @ad =
          creative_id: 'dogbeef'
          lease_expiry: 143
        now = 1438196488117
        @sandbox.useFakeTimers(now)

        @playlist = new TimedUniquePlaylist(@proofOfPlay)
        # threshold of 15 seconds
        @playlist._wait   = 15 * 1000
        # last saw this ad 17 seconds ago
        @playlist._at     = now - 17 * 1000
        @playlist._lastAd = @ad

      it 'should write that ad as @_lastAd', ->
        # we're checking the "lease_expiry" we've set above to ensure we change
        expect(@playlist._lastAd.lease_expiry).to.equal 143
        @playlist.write
          creative_id: 'dogbeef'
          lease_expiry: 142
        expect(@playlist._lastAd.lease_expiry).to.equal 142

      it 'should pass that ad on down the stream', (done) ->
        verify = (ad) ->
          expect(ad.creative_id).to.equal 'dogbeef'
          done()
        @playlist.pipe through2.obj verify

        @playlist.write
          creative_id: 'dogbeef'
        # since we're using fake timers, we'll need something to cause mocha to
        # barf out if we never get something piped into verify.  I hate this.
        @sandbox.clock.tick 3000

    describe 'when getting an ad that does not match the previous one', ->

      beforeEach ->
        @ad =
          creative_id: 'line-one-holding'
        now = 1438196488117
        # threshold of 15 seconds
        threshold = 15 * 1000
        @sandbox.useFakeTimers(now)

        @playlist = new TimedUniquePlaylist(@proofOfPlay)
        @playlist._wait   = threshold
        # last saw this ad 7 seconds ago
        @playlist._at     = now - 7 * 1000
        @playlist._lastAd = @ad

      it 'should write that ad as @_lastAd', ->
        expect(@playlist._lastAd.creative_id).to.equal 'line-one-holding'
        @playlist.write
          creative_id: 'this-is-a-different-id'
        expect(@playlist._lastAd.creative_id).to.equal 'this-is-a-different-id'

      it 'should pass that ad on down the stream', (done) ->
        verify = (ad) ->
          expect(ad.creative_id).to.equal 'this-is-a-different-id'
          done()
        @playlist.pipe through2.obj verify

        @playlist.write
          creative_id: 'this-is-a-different-id'
        # since we're using fake timers, we'll need something to cause mocha to
        # barf out if we never get something piped into verify.  I hate this.
        @sandbox.clock.tick 3000
