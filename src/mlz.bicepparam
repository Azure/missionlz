using './mlz.bicep'

param additionalFwPipCount = 3
param deployIdentity = true
param deployNetworkWatcherTrafficAnalytics = true
param deployWindowsVirtualMachine = true
param emailSecurityContact = 'brsteel@microsoft.com'
param enableProxy = true
param environmentAbbreviation = 'dev'
param hubSubscriptionId = 'afb59830-1fc9-44c9-bba3-04f657483578'
param identifier = 'new'
param identitySubscriptionId = 'd9cb6670-f9bf-416f-aa7b-2d6936edcaeb'
param location = 'usgovvirginia'
param operationsSubscriptionId = '6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24'
param sharedServicesSubscriptionId = '3a8f043c-c15c-4a67-9410-a585a85f2109'
