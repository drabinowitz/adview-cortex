cortex        = Cortex?.getConfig() or {}
defaultConfig = {}

defaultConfig['vistar.api_key']           = '58b68728-11d4-41ed-964a-95dca7b59abd'
defaultConfig['vistar.network_id']        = 'Ex-f6cCtRcydns8mcQqFWQ'
defaultConfig['vistar.device_id']         = 'test-device-id'
defaultConfig['vistar.debug']             = false
defaultConfig['vistar.cache_assets']      = true
defaultConfig['vistar.allow_audio']       = false
defaultConfig['vistar.direct_connection'] = false
defaultConfig['vistar.cpm_floor_cents']   = 0
defaultConfig['vistar.ad_buffer_length']  = 8
defaultConfig['vistar.ads.playlist_impl'] = 'Playlist' # or 'ConsecutiveOnlyAfterFallback'
defaultConfig['vistar.mime_types']        = [
  'image/gif'
  'image/jpg'
  'image/jpeg'
  'image/png'
  'video/webm'
]

defaultConfig['vistar.health_check.last_ad_view_run_time_threshold']            = 3 * 60 * 1000
defaultConfig['vistar.health_check.last_ad_request_time_threshold']             = 3 * 60 * 1000
defaultConfig['vistar.health_check.last_successful_ad_request_time_threshold']  = 15 * 60 * 1000
defaultConfig['vistar.health_check.last_pop_request_time_threshold']            = 3 * 60 * 1000
defaultConfig['vistar.health_check.last_successful_pop_request_time_threshold'] = 15 * 60 * 1000

defaultConfig['vistar.url'] =
  'http://dev.api.vistarmedia.com/api/v1/get_ad/json'


try
  latitude  = Number(cortex['vistar.lat'])
  longitude = Number(cortex['vistar.lng'])
catch err
  console
    .error "Invalid lat/lng: #{latitude}, #{longitude}. err=#{err?.message}"
  latitude  = NaN
  longitude = NaN

if not isNaN(latitude) and not isNaN(longitude)
  cortex['vistar.latitude']  = latitude
  cortex['vistar.longitude'] = longitude

width  = Number(cortex['vistar.width'])
height = Number(cortex['vistar.height'])
if width and height
  cortex['vistar.width']  = width
  cortex['vistar.height'] = height
else
  throw new Error(
    "Invalid width/height: #{cortex['vistar.width']}/#{cortex['vistar.height']}"
  )

cortex['vistar.mime_types'] = Cortex?.player.getMimeTypes()


get = (key) ->
  if key of cortex
    cortex[key]
  else
    defaultConfig[key]


config =
  url:                     get 'vistar.url'
  apiKey:                  get 'vistar.api_key'
  networkId:               get 'vistar.network_id'
  width:                   get 'vistar.width'
  height:                  get 'vistar.height'
  debug:                   get 'vistar.debug'
  cacheAssets:             get 'vistar.cache_assets'
  allow_audio:             eval(get 'vistar.allow_audio')
  directConnection:        get 'vistar.direct_connection'
  deviceId:                get 'vistar.device_id'
  venueId:                 get 'vistar.venue_id'
  queueSize:               Number(get 'vistar.ad_buffer_length')
  playlistImplementation:  get 'vistar.ads.playlist_impl'
  mimeTypes:               get 'vistar.mime_types'
  latitude:                get 'vistar.latitude'
  longitude:               get 'vistar.longitude'
  cpmFloorCents:           get 'vistar.cpm_floor_cents'
  minDuration:             get 'vistar.min_duration'
  maxDuration:             get 'vistar.max_duration'
  displayArea: [
    {
      id:               'display-0'
      width:            get 'vistar.width'
      height:           get 'vistar.height'
      allow_audio:      eval(get 'vistar.allow_audio')
    }
  ]
  healthCheck:
    lastAdViewRunTimeThreshold:             Number(get 'vistar.health_check.last_ad_view_run_time_threshold')
    lastAdRequestTimeThreshold:             Number(get 'vistar.health_check.last_ad_request_time_threshold')
    lastSuccessfulAdRequestTimeThreshold:   Number(get 'vistar.health_check.last_successful_ad_request_time_threshold')
    lastPopRequestTimeThreshold:            Number(get 'vistar.health_check.last_pop_request_time_threshold')
    lastSuccessfulPopRequestTimeThreshold:  Number(get 'vistar.health_check.last_successful_pop_request_time_threshold')


module.exports = {
  get
  config
}
