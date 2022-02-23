/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param name string

param addressPrefix string

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  name: name

  properties: {
    addressPrefix: addressPrefix
  }
}

output id string = subnet.id
