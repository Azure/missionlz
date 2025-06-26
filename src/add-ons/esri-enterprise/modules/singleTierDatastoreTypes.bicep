param enableTileCacheDataStore bool = true
param enableSpatiotemporalBigDataStore bool = false

var singleTierDataStoreTypes = [
  'Relational'
  enableTileCacheDataStore ? 'TileCache' : 'Relational'
  enableSpatiotemporalBigDataStore ? 'SpatioTemporal' : 'Relational'
]

var dataStoreTypesForSingleTier = [for value in singleTierDataStoreTypes: value == 'Relational' || value == 'TileCache' || value == 'SpatioTemporal' ? value : 'Relational']

var dataStoreTypesForBaseDeployment= union(singleTierDataStoreTypes, dataStoreTypesForSingleTier)

output dataStoreTypesForBaseDeploymentServers string = join(dataStoreTypesForBaseDeployment, ',')
