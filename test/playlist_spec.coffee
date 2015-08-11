require './test_case'
through2      = require 'through2'
{expect}      = require 'chai'

{ConsecutiveOnlyAfterFallback} = require '../src/playlist'
{Playlist}               = require '../src/playlist'


describe 'Playlist implementation:  ', ->

  beforeEach ->
    @cortex = @sandbox.stub()

  describe 'ConsecutiveOnlyAfterFallback', ->

    it 'should set _lastAd to null', ->
      playlist = new ConsecutiveOnlyAfterFallback(@cortex)
      expect(playlist._lastAd).to.be.null

    it 'should set _cortex', ->
      playlist = new ConsecutiveOnlyAfterFallback(@cortex)
      expect(playlist._cortex).to.equal @cortex

    describe 'when given an ad with a matching creative_id', ->

      beforeEach ->
        @cortex.view =
          submitNoop: (registerId, callbacks) ->
            callbacks.end?()
        @ad =
          creative_id: 'dogbeef'

        @playlist = new ConsecutiveOnlyAfterFallback(@cortex)
        @playlist._lastAd = @ad

      it 'should not pass that ad down the stream', ->
        @playlist.pipe through2.obj =>
          @fail('should not pass ad down stream')

        @playlist.write(@ad)

      it 'should call Cortex submitNoop with "AdView", end and error cb', ->
        submitNoop = @sandbox.spy @cortex.view, 'submitNoop'
        @playlist.write(@ad)

        expect(submitNoop).to.have.been.called.once
        [registerName, callbacks] = @cortex.view.submitNoop.lastCall.args
        expect(registerName).to.equal 'AdView'
        expect(callbacks.error).to.be.an.instanceOf Function
        expect(callbacks.end).to.be.an.instanceOf Function

      it 'should call the end callback, which will set _lastAd to null', ->
        expect(@playlist._lastAd.creative_id).to.equal 'dogbeef'
        @playlist.write(@ad)

        expect(@playlist._lastAd).to.be.null

    describe 'when given an ad that does not match _lastAd.creative_id', ->

      beforeEach ->
        @ad =
          creative_id: 'dogbeef'

        @playlist = new ConsecutiveOnlyAfterFallback(@cortex)
        @playlist._lastAd =
          creative_id: 'catbeef'

      it 'should pass that ad on down the stream', (done) ->
        verify = (ad) ->
          expect(ad.creative_id).to.equal 'dogbeef'
          done()
        @playlist.pipe through2.obj verify

        @playlist.write @ad

      it 'should set _lastAd to that ad', ->
        @playlist.write @ad

        expect(@playlist._lastAd.creative_id).to.equal 'dogbeef'
