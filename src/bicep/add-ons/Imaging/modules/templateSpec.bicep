param imageDefinitionName string
param location string
param tags object

resource templateSpec 'Microsoft.Resources/templateSpecs@2022-02-01' = {
  name: 'ts-${imageDefinitionName}'
  location: location
  tags: contains(tags, 'Microsoft.Resources/templateSpecs') ? tags['Microsoft.Resources/templateSpecs'] : {}
  properties: {
    description: 'An automation runbook deploys a new image version for the "${imageDefinitionName}" image definition from this template spec.'
    displayName: 'Zero Trust Image Build Automation: ${imageDefinitionName}'
  }
}

resource version 'Microsoft.Resources/templateSpecs/versions@2022-02-01' = {
  parent: templateSpec
  name: '1.0'
  location: location
  tags: contains(tags, 'Microsoft.Resources/templateSpecs') ? tags['Microsoft.Resources/templateSpecs'] : {}
  properties: {
    mainTemplate: loadJsonContent('imageBuild.json')
  }
}

output resourceId string = version.id
