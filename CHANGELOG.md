# cortex-adview

### 2.3.2

* remove `vistar.width` and `vistar.height` from default config. Throw an error
  if they are not provided/are invalid.

### 2.3.0

* remove `vistar.ads.unique_within_seconds` in favor of specifying a playlist
  implementation.  make use of Cortex `submitNoop` in the
  `ConsecutiveOnlyAfterFallback` implementation to only play the same ad
  consecutively by rendering the fallback registered with the Adview

### 2.1.0

* add health checks
* use ad_original_asset_url as view label
