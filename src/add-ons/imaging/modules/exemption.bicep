/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param policyAssignmentId string

resource exemption 'Microsoft.Authorization/policyExemptions@2022-07-01-preview' = {
  name: 'exempt-imaging-resource-group'
  properties: {
    assignmentScopeValidation: 'Default'
    description: 'Exempts the imaging resource group to prevent issues with building images.'
    displayName: 'Imaging resource group'
    exemptionCategory: 'Mitigated'
    expiresOn: null
    metadata: null
    policyAssignmentId: policyAssignmentId
    policyDefinitionReferenceIds: []
    resourceSelectors: []
  }
}
