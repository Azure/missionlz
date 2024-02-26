param enableTileCacheDataStore bool = false
param enableSpatiotemporalBigDataStore bool  = false

var singleTierDataStoreTypes = [
  'Relational'
  enableTileCacheDataStore ? 'TileCache' : null
  enableSpatiotemporalBigDataStore ? 'SpatioTemporal' : null
]

var dataStoreTypesForBaseDeploymentServers = [for value in singleTierDataStoreTypes: value == 'Relational' || value == 'TileCache' || value == 'SpatioTemporal' ? value : 'Relational']

output test array = union(dataStoreTypesForBaseDeploymentServers, singleTierDataStoreTypes)
