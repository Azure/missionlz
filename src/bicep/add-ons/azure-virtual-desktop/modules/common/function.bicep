param files object
param functionAppName string
param functionName string
param schedule string

resource functionApp 'Microsoft.Web/sites@2020-12-01' existing = {
  name: functionAppName
}

resource function 'Microsoft.Web/sites/functions@2020-12-01' = {
  parent: functionApp
  name: functionName
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'Timer'
          type: 'timerTrigger'
          direction: 'in'
          schedule: schedule
        }
      ]
    }
    files: files
  }
}
