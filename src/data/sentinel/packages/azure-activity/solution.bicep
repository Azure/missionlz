param location string
param logAnalyticsWorkspaceResourceId string
param workbook1Name string = 'Azure Activity'
param workbook2Name string = 'Azure Service Health Workbook'

var email = 'support@microsoft.com'
var _email = email
var _solutionName = 'Azure Activity'
var _solutionVersion = '3.0.3'
var solutionId = 'azuresentinel.azure-sentinel-solution-azureactivity'
var _solutionId = solutionId
var uiConfigId1 = 'AzureActivity'
var _uiConfigId1 = uiConfigId1
var dataConnectorContentId1 = 'AzureActivity'
var _dataConnectorContentId1 = dataConnectorContentId1
var dataConnectorId1 = extensionResourceId(
  resourceId('Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspaceName),
  'Microsoft.SecurityInsights/dataConnectors',
  _dataConnectorContentId1
)
var _dataConnectorId1 = dataConnectorId1
var dataConnectorVersion1 = '2.0.0'
var _dataConnectorcontentProductId1 = '${take(_solutionId,50)}-dc-${uniqueString('${_solutionId}-DataConnector-${_dataConnectorContentId1}-${dataConnectorVersion1}')}'
var huntingQueryObject1 = {
  huntingQueryVersion1: '2.0.2'
  _huntingQuerycontentId1: 'ef7ef44e-6129-4d8e-94fe-b5530415d8e5'
  huntingQueryTemplateSpecName1: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-hq-${uniqueString('ef7ef44e-6129-4d8e-94fe-b5530415d8e5')}'
}
var huntingQueryObject2 = {
  huntingQueryVersion2: '2.0.0'
  _huntingQuerycontentId2: '43cb0347-bdcc-4e83-af5a-cebbd03971d8'
  huntingQueryTemplateSpecName2: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-hq-${uniqueString('43cb0347-bdcc-4e83-af5a-cebbd03971d8')}'
}
var huntingQueryObject3 = {
  huntingQueryVersion3: '2.0.1'
  _huntingQuerycontentId3: '5d2399f9-ea5c-4e67-9435-1fba745f3a39'
  huntingQueryTemplateSpecName3: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-hq-${uniqueString('5d2399f9-ea5c-4e67-9435-1fba745f3a39')}'
}
var huntingQueryObject4 = {
  huntingQueryVersion4: '2.0.1'
  _huntingQuerycontentId4: '1b8779c9-abf2-444f-a21f-437b8f90ac4a'
  huntingQueryTemplateSpecName4: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-hq-${uniqueString('1b8779c9-abf2-444f-a21f-437b8f90ac4a')}'
}
var huntingQueryObject5 = {
  huntingQueryVersion5: '2.0.1'
  _huntingQuerycontentId5: 'e94d6756-981c-4f02-9a81-d006d80c8b41'
  huntingQueryTemplateSpecName5: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-hq-${uniqueString('e94d6756-981c-4f02-9a81-d006d80c8b41')}'
}
var huntingQueryObject6 = {
  huntingQueryVersion6: '2.1.1'
  _huntingQuerycontentId6: 'efe843ca-3ce7-4896-9f8b-f2c374ae6527'
  huntingQueryTemplateSpecName6: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-hq-${uniqueString('efe843ca-3ce7-4896-9f8b-f2c374ae6527')}'
}
var huntingQueryObject7 = {
  huntingQueryVersion7: '2.0.1'
  _huntingQuerycontentId7: '17201aa8-0916-4078-a020-7ea3a9262889'
  huntingQueryTemplateSpecName7: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-hq-${uniqueString('17201aa8-0916-4078-a020-7ea3a9262889')}'
}
var huntingQueryObject8 = {
  huntingQueryVersion8: '2.0.1'
  _huntingQuerycontentId8: '5a1f9655-c893-4091-8dc0-7f11d7676506'
  huntingQueryTemplateSpecName8: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-hq-${uniqueString('5a1f9655-c893-4091-8dc0-7f11d7676506')}'
}
var huntingQueryObject9 = {
  huntingQueryVersion9: '2.0.1'
  _huntingQuerycontentId9: '57784ba5-7791-422e-916f-65ef94fe1dbb'
  huntingQueryTemplateSpecName9: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-hq-${uniqueString('57784ba5-7791-422e-916f-65ef94fe1dbb')}'
}
var huntingQueryObject10 = {
  huntingQueryVersion10: '2.0.1'
  _huntingQuerycontentId10: '0278e3b8-9899-45c5-8928-700cd80d2d80'
  huntingQueryTemplateSpecName10: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-hq-${uniqueString('0278e3b8-9899-45c5-8928-700cd80d2d80')}'
}
var huntingQueryObject11 = {
  huntingQueryVersion11: '2.0.1'
  _huntingQuerycontentId11: 'a09e6368-065b-4f1e-a4ce-b1b3a64b493b'
  huntingQueryTemplateSpecName11: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-hq-${uniqueString('a09e6368-065b-4f1e-a4ce-b1b3a64b493b')}'
}
var huntingQueryObject12 = {
  huntingQueryVersion12: '2.0.1'
  _huntingQuerycontentId12: '860cda84-765b-4273-af44-958b7cca85f7'
  huntingQueryTemplateSpecName12: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-hq-${uniqueString('860cda84-765b-4273-af44-958b7cca85f7')}'
}
var huntingQueryObject13 = {
  huntingQueryVersion13: '2.0.1'
  _huntingQuerycontentId13: '9e146876-e303-49af-b847-b029d1a66852'
  huntingQueryTemplateSpecName13: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-hq-${uniqueString('9e146876-e303-49af-b847-b029d1a66852')}'
}
var huntingQueryObject14 = {
  huntingQueryVersion14: '2.0.1'
  _huntingQuerycontentId14: '81fd68a2-9ad6-4a1c-7bd7-18efe5c99081'
  huntingQueryTemplateSpecName14: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-hq-${uniqueString('81fd68a2-9ad6-4a1c-7bd7-18efe5c99081')}'
}
var huntingQueryObject15 = {
  huntingQueryVersion15: '1'
  _huntingQuerycontentId15: '26d116bd-324b-4bb8-b102-d4a282607ad7'
  huntingQueryTemplateSpecName15: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-hq-${uniqueString('26d116bd-324b-4bb8-b102-d4a282607ad7')}'
}
var analyticRuleObject1 = {
  analyticRuleVersion1: '2.0.3'
  _analyticRulecontentId1: '88f453ff-7b9e-45bb-8c12-4058ca5e44ee'
  analyticRuleId1: resourceId('Microsoft.SecurityInsights/AlertRuleTemplates', '88f453ff-7b9e-45bb-8c12-4058ca5e44ee')
  analyticRuleTemplateSpecName1: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-ar-${uniqueString('88f453ff-7b9e-45bb-8c12-4058ca5e44ee')}'
  _analyticRulecontentProductId1: '${take(_solutionId,50)}-ar-${uniqueString('${_solutionId}-AnalyticsRule-88f453ff-7b9e-45bb-8c12-4058ca5e44ee-2.0.3')}'
}
var analyticRuleObject2 = {
  analyticRuleVersion2: '2.0.3'
  _analyticRulecontentId2: '86a036b2-3686-42eb-b417-909fc0867771'
  analyticRuleId2: resourceId('Microsoft.SecurityInsights/AlertRuleTemplates', '86a036b2-3686-42eb-b417-909fc0867771')
  analyticRuleTemplateSpecName2: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-ar-${uniqueString('86a036b2-3686-42eb-b417-909fc0867771')}'
  _analyticRulecontentProductId2: '${take(_solutionId,50)}-ar-${uniqueString('${_solutionId}-AnalyticsRule-86a036b2-3686-42eb-b417-909fc0867771-2.0.3')}'
}
var analyticRuleObject3 = {
  analyticRuleVersion3: '2.0.3'
  _analyticRulecontentId3: 'd9938c3b-16f9-444d-bc22-ea9a9110e0fd'
  analyticRuleId3: resourceId('Microsoft.SecurityInsights/AlertRuleTemplates', 'd9938c3b-16f9-444d-bc22-ea9a9110e0fd')
  analyticRuleTemplateSpecName3: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-ar-${uniqueString('d9938c3b-16f9-444d-bc22-ea9a9110e0fd')}'
  _analyticRulecontentProductId3: '${take(_solutionId,50)}-ar-${uniqueString('${_solutionId}-AnalyticsRule-d9938c3b-16f9-444d-bc22-ea9a9110e0fd-2.0.3')}'
}
var analyticRuleObject4 = {
  analyticRuleVersion4: '2.0.4'
  _analyticRulecontentId4: '361dd1e3-1c11-491e-82a3-bb2e44ac36ba'
  analyticRuleId4: resourceId('Microsoft.SecurityInsights/AlertRuleTemplates', '361dd1e3-1c11-491e-82a3-bb2e44ac36ba')
  analyticRuleTemplateSpecName4: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-ar-${uniqueString('361dd1e3-1c11-491e-82a3-bb2e44ac36ba')}'
  _analyticRulecontentProductId4: '${take(_solutionId,50)}-ar-${uniqueString('${_solutionId}-AnalyticsRule-361dd1e3-1c11-491e-82a3-bb2e44ac36ba-2.0.4')}'
}
var analyticRuleObject5 = {
  analyticRuleVersion5: '2.0.3'
  _analyticRulecontentId5: '9736e5f1-7b6e-4bfb-a708-e53ff1d182c3'
  analyticRuleId5: resourceId('Microsoft.SecurityInsights/AlertRuleTemplates', '9736e5f1-7b6e-4bfb-a708-e53ff1d182c3')
  analyticRuleTemplateSpecName5: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-ar-${uniqueString('9736e5f1-7b6e-4bfb-a708-e53ff1d182c3')}'
  _analyticRulecontentProductId5: '${take(_solutionId,50)}-ar-${uniqueString('${_solutionId}-AnalyticsRule-9736e5f1-7b6e-4bfb-a708-e53ff1d182c3-2.0.3')}'
}
var analyticRuleObject6 = {
  analyticRuleVersion6: '2.0.2'
  _analyticRulecontentId6: 'b2c15736-b9eb-4dae-8b02-3016b6a45a32'
  analyticRuleId6: resourceId('Microsoft.SecurityInsights/AlertRuleTemplates', 'b2c15736-b9eb-4dae-8b02-3016b6a45a32')
  analyticRuleTemplateSpecName6: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-ar-${uniqueString('b2c15736-b9eb-4dae-8b02-3016b6a45a32')}'
  _analyticRulecontentProductId6: '${take(_solutionId,50)}-ar-${uniqueString('${_solutionId}-AnalyticsRule-b2c15736-b9eb-4dae-8b02-3016b6a45a32-2.0.2')}'
}
var analyticRuleObject7 = {
  analyticRuleVersion7: '2.0.3'
  _analyticRulecontentId7: 'ec491363-5fe7-4eff-b68e-f42dcb76fcf6'
  analyticRuleId7: resourceId('Microsoft.SecurityInsights/AlertRuleTemplates', 'ec491363-5fe7-4eff-b68e-f42dcb76fcf6')
  analyticRuleTemplateSpecName7: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-ar-${uniqueString('ec491363-5fe7-4eff-b68e-f42dcb76fcf6')}'
  _analyticRulecontentProductId7: '${take(_solutionId,50)}-ar-${uniqueString('${_solutionId}-AnalyticsRule-ec491363-5fe7-4eff-b68e-f42dcb76fcf6-2.0.3')}'
}
var analyticRuleObject8 = {
  analyticRuleVersion8: '2.0.3'
  _analyticRulecontentId8: '56fe0db0-6779-46fa-b3c5-006082a53064'
  analyticRuleId8: resourceId('Microsoft.SecurityInsights/AlertRuleTemplates', '56fe0db0-6779-46fa-b3c5-006082a53064')
  analyticRuleTemplateSpecName8: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-ar-${uniqueString('56fe0db0-6779-46fa-b3c5-006082a53064')}'
  _analyticRulecontentProductId8: '${take(_solutionId,50)}-ar-${uniqueString('${_solutionId}-AnalyticsRule-56fe0db0-6779-46fa-b3c5-006082a53064-2.0.3')}'
}
var analyticRuleObject9 = {
  analyticRuleVersion9: '2.0.3'
  _analyticRulecontentId9: '6d7214d9-4a28-44df-aafb-0910b9e6ae3e'
  analyticRuleId9: resourceId('Microsoft.SecurityInsights/AlertRuleTemplates', '6d7214d9-4a28-44df-aafb-0910b9e6ae3e')
  analyticRuleTemplateSpecName9: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-ar-${uniqueString('6d7214d9-4a28-44df-aafb-0910b9e6ae3e')}'
  _analyticRulecontentProductId9: '${take(_solutionId,50)}-ar-${uniqueString('${_solutionId}-AnalyticsRule-6d7214d9-4a28-44df-aafb-0910b9e6ae3e-2.0.3')}'
}
var analyticRuleObject10 = {
  analyticRuleVersion10: '2.0.4'
  _analyticRulecontentId10: '9fb57e58-3ed8-4b89-afcf-c8e786508b1c'
  analyticRuleId10: resourceId('Microsoft.SecurityInsights/AlertRuleTemplates', '9fb57e58-3ed8-4b89-afcf-c8e786508b1c')
  analyticRuleTemplateSpecName10: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-ar-${uniqueString('9fb57e58-3ed8-4b89-afcf-c8e786508b1c')}'
  _analyticRulecontentProductId10: '${take(_solutionId,50)}-ar-${uniqueString('${_solutionId}-AnalyticsRule-9fb57e58-3ed8-4b89-afcf-c8e786508b1c-2.0.4')}'
}
var analyticRuleObject11 = {
  analyticRuleVersion11: '2.0.3'
  _analyticRulecontentId11: '23de46ea-c425-4a77-b456-511ae4855d69'
  analyticRuleId11: resourceId('Microsoft.SecurityInsights/AlertRuleTemplates', '23de46ea-c425-4a77-b456-511ae4855d69')
  analyticRuleTemplateSpecName11: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-ar-${uniqueString('23de46ea-c425-4a77-b456-511ae4855d69')}'
  _analyticRulecontentProductId11: '${take(_solutionId,50)}-ar-${uniqueString('${_solutionId}-AnalyticsRule-23de46ea-c425-4a77-b456-511ae4855d69-2.0.3')}'
}
var analyticRuleObject12 = {
  analyticRuleVersion12: '2.0.4'
  _analyticRulecontentId12: 'ed43bdb7-eaab-4ea4-be52-6951fcfa7e3b'
  analyticRuleId12: resourceId('Microsoft.SecurityInsights/AlertRuleTemplates', 'ed43bdb7-eaab-4ea4-be52-6951fcfa7e3b')
  analyticRuleTemplateSpecName12: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-ar-${uniqueString('ed43bdb7-eaab-4ea4-be52-6951fcfa7e3b')}'
  _analyticRulecontentProductId12: '${take(_solutionId,50)}-ar-${uniqueString('${_solutionId}-AnalyticsRule-ed43bdb7-eaab-4ea4-be52-6951fcfa7e3b-2.0.4')}'
}
var analyticRuleObject13 = {
  analyticRuleVersion13: '1.0.1'
  _analyticRulecontentId13: '48c026d8-7f36-4a95-9568-6f1420d66e37'
  analyticRuleId13: resourceId('Microsoft.SecurityInsights/AlertRuleTemplates', '48c026d8-7f36-4a95-9568-6f1420d66e37')
  analyticRuleTemplateSpecName13: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-ar-${uniqueString('48c026d8-7f36-4a95-9568-6f1420d66e37')}'
  _analyticRulecontentProductId13: '${take(_solutionId,50)}-ar-${uniqueString('${_solutionId}-AnalyticsRule-48c026d8-7f36-4a95-9568-6f1420d66e37-1.0.1')}'
}
var analyticRuleObject14 = {
  analyticRuleVersion14: '1.0.0'
  _analyticRulecontentId14: '68c89998-8052-4c80-a1f6-9d81060b6d57'
  analyticRuleId14: resourceId('Microsoft.SecurityInsights/AlertRuleTemplates', '68c89998-8052-4c80-a1f6-9d81060b6d57')
  analyticRuleTemplateSpecName14: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-ar-${uniqueString('68c89998-8052-4c80-a1f6-9d81060b6d57')}'
  _analyticRulecontentProductId14: '${take(_solutionId,50)}-ar-${uniqueString('${_solutionId}-AnalyticsRule-68c89998-8052-4c80-a1f6-9d81060b6d57-1.0.0')}'
}
var logAnalyticsWorkspaceName = split(logAnalyticsWorkspaceResourceId, '/')[8]
var workbookVersion1 = '2.0.0'
var workbookContentId1 = 'AzureActivityWorkbook'
var workbookId1 = resourceId('Microsoft.Insights/workbooks', workbookContentId1)
var workbookTemplateSpecName1 = '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-wb-${uniqueString(_workbookContentId1)}'
var _workbookContentId1 = workbookContentId1
var _workbookcontentProductId1 = '${take(_solutionId,50)}-wb-${uniqueString('${_solutionId}-Workbook-${_workbookContentId1}-${workbookVersion1}')}'
var workbookVersion2 = '1.0.0'
var workbookContentId2 = 'AzureServiceHealthWorkbook'
var workbookId2 = resourceId('Microsoft.Insights/workbooks', workbookContentId2)
var workbookTemplateSpecName2 = '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${logAnalyticsWorkspaceName}-wb-${uniqueString(_workbookContentId2)}'
var _workbookContentId2 = workbookContentId2
var _workbookcontentProductId2 = '${take(_solutionId,50)}-wb-${uniqueString('${_solutionId}-Workbook-${_workbookContentId2}-${workbookVersion2}')}'
var _solutioncontentProductId = '${take(_solutionId,50)}-sl-${uniqueString('${_solutionId}-Solution-${_solutionId}-${_solutionVersion}')}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource contentPackage 'Microsoft.SecurityInsights/contentPackages@2025-09-01' = {
  scope: logAnalyticsWorkspace
  name: _solutionId
  properties: {
    version: '3.0.3'
    contentSchemaVersion: '3.0.0'
    displayName: 'Azure Activity'
    publisherDisplayName: 'Microsoft Sentinel, Microsoft Corporation'
    contentKind: 'Solution'
    contentProductId: _solutioncontentProductId
    icon: '<img src="https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Workbooks/Images/Logos/azureactivity_logo.svg" width="75px" height="75px">'
    contentId: _solutionId
    source: {
      kind: 'Solution'
      name: 'Azure Activity'
      sourceId: _solutionId
    }
    author: {
      name: 'Microsoft'
      email: _email
    }
    support: {
      name: 'Microsoft Corporation'
      email: 'support@microsoft.com'
      tier: 'Microsoft'
      link: 'https://support.microsoft.com/'
    }
    dependencies: {
      operator: 'AND'
      criteria: [
        {
          kind: 'DataConnector'
          contentId: _dataConnectorContentId1
          version: dataConnectorVersion1
        }
        {
          kind: 'HuntingQuery'
          contentId: huntingQueryObject1._huntingQuerycontentId1
          version: huntingQueryObject1.huntingQueryVersion1
        }
        {
          kind: 'HuntingQuery'
          contentId: huntingQueryObject2._huntingQuerycontentId2
          version: huntingQueryObject2.huntingQueryVersion2
        }
        {
          kind: 'HuntingQuery'
          contentId: huntingQueryObject3._huntingQuerycontentId3
          version: huntingQueryObject3.huntingQueryVersion3
        }
        {
          kind: 'HuntingQuery'
          contentId: huntingQueryObject4._huntingQuerycontentId4
          version: huntingQueryObject4.huntingQueryVersion4
        }
        {
          kind: 'HuntingQuery'
          contentId: huntingQueryObject5._huntingQuerycontentId5
          version: huntingQueryObject5.huntingQueryVersion5
        }
        {
          kind: 'HuntingQuery'
          contentId: huntingQueryObject6._huntingQuerycontentId6
          version: huntingQueryObject6.huntingQueryVersion6
        }
        {
          kind: 'HuntingQuery'
          contentId: huntingQueryObject7._huntingQuerycontentId7
          version: huntingQueryObject7.huntingQueryVersion7
        }
        {
          kind: 'HuntingQuery'
          contentId: huntingQueryObject8._huntingQuerycontentId8
          version: huntingQueryObject8.huntingQueryVersion8
        }
        {
          kind: 'HuntingQuery'
          contentId: huntingQueryObject9._huntingQuerycontentId9
          version: huntingQueryObject9.huntingQueryVersion9
        }
        {
          kind: 'HuntingQuery'
          contentId: huntingQueryObject10._huntingQuerycontentId10
          version: huntingQueryObject10.huntingQueryVersion10
        }
        {
          kind: 'HuntingQuery'
          contentId: huntingQueryObject11._huntingQuerycontentId11
          version: huntingQueryObject11.huntingQueryVersion11
        }
        {
          kind: 'HuntingQuery'
          contentId: huntingQueryObject12._huntingQuerycontentId12
          version: huntingQueryObject12.huntingQueryVersion12
        }
        {
          kind: 'HuntingQuery'
          contentId: huntingQueryObject13._huntingQuerycontentId13
          version: huntingQueryObject13.huntingQueryVersion13
        }
        {
          kind: 'HuntingQuery'
          contentId: huntingQueryObject14._huntingQuerycontentId14
          version: huntingQueryObject14.huntingQueryVersion14
        }
        {
          kind: 'HuntingQuery'
          contentId: huntingQueryObject15._huntingQuerycontentId15
          version: huntingQueryObject15.huntingQueryVersion15
        }
        {
          kind: 'AnalyticsRule'
          contentId: analyticRuleObject1._analyticRulecontentId1
          version: analyticRuleObject1.analyticRuleVersion1
        }
        {
          kind: 'AnalyticsRule'
          contentId: analyticRuleObject2._analyticRulecontentId2
          version: analyticRuleObject2.analyticRuleVersion2
        }
        {
          kind: 'AnalyticsRule'
          contentId: analyticRuleObject3._analyticRulecontentId3
          version: analyticRuleObject3.analyticRuleVersion3
        }
        {
          kind: 'AnalyticsRule'
          contentId: analyticRuleObject4._analyticRulecontentId4
          version: analyticRuleObject4.analyticRuleVersion4
        }
        {
          kind: 'AnalyticsRule'
          contentId: analyticRuleObject5._analyticRulecontentId5
          version: analyticRuleObject5.analyticRuleVersion5
        }
        {
          kind: 'AnalyticsRule'
          contentId: analyticRuleObject6._analyticRulecontentId6
          version: analyticRuleObject6.analyticRuleVersion6
        }
        {
          kind: 'AnalyticsRule'
          contentId: analyticRuleObject7._analyticRulecontentId7
          version: analyticRuleObject7.analyticRuleVersion7
        }
        {
          kind: 'AnalyticsRule'
          contentId: analyticRuleObject8._analyticRulecontentId8
          version: analyticRuleObject8.analyticRuleVersion8
        }
        {
          kind: 'AnalyticsRule'
          contentId: analyticRuleObject9._analyticRulecontentId9
          version: analyticRuleObject9.analyticRuleVersion9
        }
        {
          kind: 'AnalyticsRule'
          contentId: analyticRuleObject10._analyticRulecontentId10
          version: analyticRuleObject10.analyticRuleVersion10
        }
        {
          kind: 'AnalyticsRule'
          contentId: analyticRuleObject11._analyticRulecontentId11
          version: analyticRuleObject11.analyticRuleVersion11
        }
        {
          kind: 'AnalyticsRule'
          contentId: analyticRuleObject12._analyticRulecontentId12
          version: analyticRuleObject12.analyticRuleVersion12
        }
        {
          kind: 'AnalyticsRule'
          contentId: analyticRuleObject13._analyticRulecontentId13
          version: analyticRuleObject13.analyticRuleVersion13
        }
        {
          kind: 'AnalyticsRule'
          contentId: analyticRuleObject14._analyticRulecontentId14
          version: analyticRuleObject14.analyticRuleVersion14
        }
        {
          kind: 'Workbook'
          contentId: _workbookContentId1
          version: workbookVersion1
        }
        {
          kind: 'Workbook'
          contentId: _workbookContentId2
          version: workbookVersion2
        }
      ]
    }
    firstPublishDate: '2022-04-18'
    providers: [
      'Microsoft'
    ]
    categories: {
      domains: [
        'IT Operations'
      ]
    }
  }
}

resource contentTemplate1 'Microsoft.SecurityInsights/contentTemplates@2025-09-01' = {
  scope: logAnalyticsWorkspace
  name: '${logAnalyticsWorkspaceName}-dc-${uniqueString(_dataConnectorContentId1)}'
  properties: {
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: dataConnectorVersion1
      parameters: {}
      variables: {}
      resources: [
        {
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/${_dataConnectorContentId1}'
          apiVersion: '2021-03-01-preview'
          type: 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors'
          location: location
          kind: 'StaticUI'
          properties: {
            connectorUiConfig: {
              id: _uiConfigId1
              title: 'Azure Activity'
              publisher: 'Microsoft'
              descriptionMarkdown: 'Azure Activity Log is a subscription log that provides insight into subscription-level events that occur in Azure, including events from Azure Resource Manager operational data, service health events, write operations taken on the resources in your subscription, and the status of activities performed in Azure. For more information, see the [Microsoft Sentinel documentation ](https://go.microsoft.com/fwlink/p/?linkid=2219695&wt.mc_id=sentinel_dataconnectordocs_content_cnl_csasci).'
              graphQueries: [
                {
                  metricName: 'Total data received'
                  legend: 'AzureActivity'
                  baseQuery: 'AzureActivity'
                }
              ]
              connectivityCriterias: [
                {
                  type: 'IsConnectedQuery'
                  value: [
                    'AzureActivity\n          | summarize LastLogReceived = max(TimeGenerated)\n            | project IsConnected = LastLogReceived > ago(7d)'
                  ]
                }
              ]
              dataTypes: [
                {
                  name: 'AzureActivity'
                  lastDataReceivedQuery: 'AzureActivity\n            | summarize Time = max(TimeGenerated)\n            | where isnotempty(Time)'
                }
              ]
            }
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2023-04-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/DataConnector-${last(split(_dataConnectorId1,'/'))}'
          properties: {
            parentId: extensionResourceId(
              resourceId('Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspaceName),
              'Microsoft.SecurityInsights/dataConnectors',
              _dataConnectorContentId1
            )
            contentId: _dataConnectorContentId1
            kind: 'DataConnector'
            version: dataConnectorVersion1
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: _dataConnectorContentId1
    contentKind: 'DataConnector'
    displayName: 'Azure Activity'
    contentProductId: _dataConnectorcontentProductId1
    version: dataConnectorVersion1
  }
  dependsOn: [
    contentPackage
  ]
}

resource metadata 'Microsoft.SecurityInsights/metadata@2025-09-01' = {
  scope: logAnalyticsWorkspace
  name: 'DataConnector-${last(split(_dataConnectorId1,'/'))}'
  properties: {
    parentId: extensionResourceId(
      resourceId('Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspaceName),
      'Microsoft.SecurityInsights/dataConnectors',
      _dataConnectorContentId1
    )
    contentId: _dataConnectorContentId1
    kind: 'DataConnector'
    version: dataConnectorVersion1
    source: {
      kind: 'Solution'
      name: 'Azure Activity'
      sourceId: _solutionId
    }
    author: {
      name: 'Microsoft'
      email: _email
    }
    support: {
      tier: 'Microsoft'
      name: 'Microsoft Corporation'
      email: 'support@microsoft.com'
      link: 'https://support.microsoft.com/'
    }
  }
}

resource dataConnector1 'Microsoft.SecurityInsights/dataConnectors@2025-09-01' = {
  scope: logAnalyticsWorkspace
  name: _dataConnectorContentId1
  location: location
  kind: 'StaticUI'
  properties: {
    connectorUiConfig: {
      title: 'Azure Activity'
      publisher: 'Microsoft'
      descriptionMarkdown: 'Azure Activity Log is a subscription log that provides insight into subscription-level events that occur in Azure, including events from Azure Resource Manager operational data, service health events, write operations taken on the resources in your subscription, and the status of activities performed in Azure. For more information, see the [Microsoft Sentinel documentation ](https://go.microsoft.com/fwlink/p/?linkid=2219695&wt.mc_id=sentinel_dataconnectordocs_content_cnl_csasci).'
      graphQueries: [
        {
          metricName: 'Total data received'
          legend: 'AzureActivity'
          baseQuery: 'AzureActivity'
        }
      ]
      dataTypes: [
        {
          name: 'AzureActivity'
          lastDataReceivedQuery: 'AzureActivity\n            | summarize Time = max(TimeGenerated)\n            | where isnotempty(Time)'
        }
      ]
      connectivityCriterias: [
        {
          type: 'IsConnectedQuery'
          value: [
            'AzureActivity\n            | summarize LastLogReceived = max(TimeGenerated)\n            | project IsConnected = LastLogReceived > ago(7d)'
          ]
        }
      ]
      id: _uiConfigId1
    }
  }
}

resource huntingQueryObject1_huntingQueryTemplateSpec1 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: huntingQueryObject1.huntingQueryTemplateSpecName1
  location: location
  properties: {
    description: 'AnalyticsRulesAdministrativeOperations_HuntingQueries Hunting Query with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: huntingQueryObject1.huntingQueryVersion1
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.OperationalInsights/savedSearches'
          apiVersion: '2022-10-01'
          name: 'Azure_Activity_Hunting_Query_1'
          location: location
          properties: {
            eTag: '*'
            displayName: 'Microsoft Sentinel Analytics Rules Administrative Operations'
            category: 'Hunting Queries'
            query: 'let opValues = dynamic(["Microsoft.SecurityInsights/alertRules/write", "Microsoft.SecurityInsights/alertRules/delete"]);\n// Microsoft Sentinel Analytics - Rule Create / Update / Delete\nAzureActivity\n| where CategoryValue =~ "Administrative"\n| where OperationNameValue in~ (opValues)\n| where ActivitySubstatusValue in~ ("Created", "OK")\n| sort by TimeGenerated desc\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| extend Account_0_Name = Name\n| extend Account_0_UPNSuffix = UPNSuffix\n| extend IP_0_Address = CallerIpAddress\n'
            version: 2
            tags: [
              {
                name: 'description'
                value: 'Identifies Microsoft Sentinel Analytics Rules administrative operations'
              }
              {
                name: 'tactics'
                value: 'Impact'
              }
              {
                name: 'techniques'
                value: 'T1496'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/HuntingQuery-${last(split(resourceId('Microsoft.OperationalInsights/savedSearches',huntingQueryObject1._huntingQuerycontentId1),'/'))}'
          properties: {
            description: 'Azure Activity Hunting Query 1'
            parentId: resourceId(
              'Microsoft.OperationalInsights/savedSearches',
              huntingQueryObject1._huntingQuerycontentId1
            )
            contentId: huntingQueryObject1._huntingQuerycontentId1
            kind: 'HuntingQuery'
            version: huntingQueryObject1.huntingQueryVersion1
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: huntingQueryObject1._huntingQuerycontentId1
    contentKind: 'HuntingQuery'
    displayName: 'Microsoft Sentinel Analytics Rules Administrative Operations'
    contentProductId: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject1._huntingQuerycontentId1}-2.0.2')}'
    id: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject1._huntingQuerycontentId1}-2.0.2')}'
    version: '2.0.2'
  }
  dependsOn: [

  ]
}

resource huntingQueryObject2_huntingQueryTemplateSpec2 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: huntingQueryObject2.huntingQueryTemplateSpecName2
  location: location
  properties: {
    description: 'AnomalousAzureOperationModel_HuntingQueries Hunting Query with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: huntingQueryObject2.huntingQueryVersion2
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.OperationalInsights/savedSearches'
          apiVersion: '2022-10-01'
          name: 'Azure_Activity_Hunting_Query_2'
          location: location
          properties: {
            eTag: '*'
            displayName: 'Anomalous Azure Operation Hunting Model'
            category: 'Hunting Queries'
            query: '// When the detection window will end (3 days prior to now)\nlet startDetectDate = 3d;\n// When the detection window will start (now)\nlet endDetectDate = 0d;\n// When to start collecting data for detection\nlet startDate = startDetectDate + 30d;\n// Operation to monitor, in this case Run Command\nlet monitoredOps = dynamic([\'microsoft.compute/virtualmachines/runcommand/action\']);\n// The resource type to monitor, in this case virtual machines\nlet monitoredResource = pack_array(\'microsoft.compute/virtualmachines\');\nlet pair_probabilities_fl = (tbl:(*), A_col:string, B_col:string, scope_col:string)\n{\nlet T = (tbl | extend _A = column_ifexists(A_col, \'\'), _B = column_ifexists(B_col, \'\'), _scope = column_ifexists(scope_col, \'\'));\nlet countOnScope = T | summarize countAllOnScope = count() by _scope;\nlet probAB = T | summarize countAB = count() by _A, _B, _scope | join kind = leftouter (countOnScope) on _scope | extend P_AB = todouble(countAB)/countAllOnScope;\nlet probA  = probAB | summarize countA = sum(countAB), countAllOnScope = max(countAllOnScope) by _A, _scope | extend P_A = todouble(countA)/countAllOnScope;\nlet probB  = probAB | summarize countB = sum(countAB), countAllOnScope = max(countAllOnScope) by _B, _scope | extend P_B = todouble(countB)/countAllOnScope;\n    probAB\n    | join kind = leftouter (probA) on _A, _scope\n    | join kind = leftouter (probB) on _B, _scope\n    | extend P_AUB = P_A + P_B - P_AB\n           , P_AIB = P_AB/P_B\n           , P_BIA = P_AB/P_A\n    | extend Lift_AB = P_AB/(P_A * P_B)\n           , Jaccard_AB = P_AB/P_AUB\n    | project _A, _B, _scope, floor(P_A, 0.00001), floor(P_B, 0.00001), floor(P_AB, 0.00001), floor(P_AUB, 0.00001), floor(P_AIB, 0.00001)\n    , floor(P_BIA, 0.00001), floor(Lift_AB, 0.00001), floor(Jaccard_AB, 0.00001)\n    | sort by _scope, _A, _B\n};\nlet eventsTable = materialize (\nAzureActivity\n| where TimeGenerated between (ago(startDate) .. ago(endDetectDate))\n| where isnotempty(CallerIpAddress)\n| where ActivityStatusValue has_any (\'Success\', \'Succeeded\')\n| extend ResourceId = iff(isempty(_ResourceId), ResourceId, _ResourceId)\n| extend splitOp = split(OperationNameValue, \'/\')\n| extend splitRes = split(ResourceId, \'/\')\n| project TimeGenerated , subscriptionId=SubscriptionId\n            , ResourceProvider\n            , ResourceName = tolower(tostring(splitRes[-1]))\n            , OperationNameValue = tolower(OperationNameValue)\n            , timeSlice = floor(TimeGenerated, 1d)\n            , clientIp = tostring(CallerIpAddress)\n            , Caller\n            , isMonitoredOp = iff(OperationNameValue has_any (monitoredOps), 1, 0)\n            , isMonitoredResource = iff(OperationNameValue has_any (monitoredResource), 1, 0)\n            , CorrelationId\n| extend clientIpMask = format_ipv4_mask(clientIp, 16)\n);\nlet modelData =  (\neventsTable\n| where TimeGenerated < ago(startDetectDate) and isnotempty(Caller) and isnotempty(subscriptionId)\n| summarize countEvents = count(), countMonRes = countif(isMonitoredResource == 1), counMonOp = countif(isMonitoredOp == 1)\n    , firstSeen = min(timeSlice), firstSeenOnMonRes = minif(timeSlice, isMonitoredResource == 1), firstSeenOnMonOp = minif(timeSlice, isMonitoredOp == 1)\n    by subscriptionId, Caller, clientIpMask\n);\nlet monOpProbs = materialize (\neventsTable\n| where TimeGenerated < ago(startDetectDate) and isnotempty(Caller) and isnotempty(subscriptionId)\n| invoke pair_probabilities_fl(\'Caller\', \'isMonitoredResource\',\'subscriptionId\')\n| where _B == 1\n| sort by P_AIB desc\n| extend rankOnMonRes = row_rank(P_AIB), sumBiggerCondProbs = row_cumsum(P_AIB) - P_AIB\n| extend avgBiggerCondProbs = floor(iff(rankOnMonRes > 1, sumBiggerCondProbs/(rankOnMonRes-1), max_of(0.0, prev(sumBiggerCondProbs))), 0.00001)\n| project-away sumBiggerCondProbs\n);\neventsTable\n| where TimeGenerated between (ago(startDetectDate) .. ago(endDetectDate))\n| join kind = leftouter (modelData | summarize countEventsPrincOnSub = sum(countEvents), countEventsMonResPrincOnSub = sum(countMonRes),  countEventsMonOpPrincOnSub = sum(counMonOp)\n    , firstSeenPrincOnSubs = min(firstSeen), firstSeenMonResPrincOnSubs = min(firstSeenOnMonRes), firstSeenMonOpPrincOnSubs = min(firstSeenOnMonOp) by subscriptionId, Caller) \n        on subscriptionId, Caller\n| join kind = leftouter (modelData | summarize countEventsIpMaskOnSub = sum(countEvents), countEventsMonResIpMaskOnSub = sum(countMonRes),  countEventsMonOpIpMaskOnSub = sum(counMonOp)\n    , firstSeenIpMaskOnSubs = min(firstSeen), firstSeenMonResIpMaskOnSubs = min(firstSeenOnMonRes), firstSeenMonOpIpMaskOnSubs = min(firstSeenOnMonOp) by subscriptionId, clientIpMask) \n        on subscriptionId, clientIpMask\n| join kind = leftouter (modelData | summarize countEventsOnSub = sum(countEvents), countEventsMonResOnSub = sum(countMonRes),  countEventsMonOpOnSub = sum(counMonOp)\n    , firstSeenOnSubs = min(firstSeen), firstSeenMonResOnSubs = min(firstSeenOnMonRes), firstSeenMonOpOnSubs = min(firstSeenOnMonOp)\n    , countCallersOnSubs = dcount(Caller), countIpMasksOnSubs = dcount(clientIpMask) by subscriptionId)\n        on subscriptionId        \n| project-away subscriptionId1, Caller1, subscriptionId2\n| extend daysOnSubs = datetime_diff(\'day\', timeSlice, firstSeenOnSubs)\n| extend avgMonOpOnSubs = floor(1.0*countEventsMonOpOnSub/daysOnSubs, 0.01), avgMonResOnSubs = floor(1.0*countEventsMonResOnSub/daysOnSubs, 0.01)\n| join kind = leftouter(monOpProbs) on $left.subscriptionId == $right._scope, $left.Caller == $right._A\n| project-away _A, _B, _scope\n| sort by subscriptionId asc, TimeGenerated asc\n| extend rnOnSubs = row_number(1, subscriptionId != prev(subscriptionId))\n| sort by subscriptionId asc, Caller asc, TimeGenerated asc\n| extend rnOnCallerSubs = row_number(1, (subscriptionId != prev(subscriptionId) and (Caller != prev(Caller))))\n| extend newCaller = iff(isempty(firstSeenPrincOnSubs), 1, 0)\n    , newCallerOnMonRes = iff(isempty(firstSeenMonResPrincOnSubs), 1, 0)\n    , newIpMask = iff(isempty(firstSeenIpMaskOnSubs), 1, 0)\n    , newIpMaskOnMonRes = iff(isempty(firstSeenMonResIpMaskOnSubs), 1, 0)\n    , newMonOpOnSubs = iff(isempty(firstSeenMonResOnSubs), 1, 0)\n    , anomCallerMonRes = iff(((Jaccard_AB <= 0.1) or (P_AIB <= 0.1)), 1, 0)\n| project TimeGenerated, subscriptionId,  ResourceProvider, ResourceName, OperationNameValue, Caller, CorrelationId, ClientIP=clientIp, ActiveDaysOnSub=daysOnSubs, avgMonOpOnSubs, newCaller, newCallerOnMonRes, newIpMask, newIpMaskOnMonRes, newMonOpOnSubs, anomCallerMonRes, isMonitoredOp, isMonitoredResource\n| order by TimeGenerated\n| where isMonitoredOp == 1\n// Optional - focus only on monitored operations or monitored resource in detection window\n| where isMonitoredOp == 1\n//| where isMonitoredResource == 1\n'
            version: 2
            tags: [
              {
                name: 'description'
                value: 'This query identifies Azure Operation anomalies during threat hunts. It detects new callers, IPs, IP ranges, and anomalous operations. Initially set for Run Command operations, it can be configured for other operations and resource types.'
              }
              {
                name: 'tactics'
                value: 'LateralMovement,CredentialAccess'
              }
              {
                name: 'techniques'
                value: 'T1570,T1078.004'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/HuntingQuery-${last(split(resourceId('Microsoft.OperationalInsights/savedSearches',huntingQueryObject2._huntingQuerycontentId2),'/'))}'
          properties: {
            description: 'Azure Activity Hunting Query 2'
            parentId: resourceId(
              'Microsoft.OperationalInsights/savedSearches',
              huntingQueryObject2._huntingQuerycontentId2
            )
            contentId: huntingQueryObject2._huntingQuerycontentId2
            kind: 'HuntingQuery'
            version: huntingQueryObject2.huntingQueryVersion2
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: huntingQueryObject2._huntingQuerycontentId2
    contentKind: 'HuntingQuery'
    displayName: 'Anomalous Azure Operation Hunting Model'
    contentProductId: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject2._huntingQuerycontentId2}-2.0.0')}'
    id: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject2._huntingQuerycontentId2}-2.0.0')}'
    version: '2.0.0'
  }
  dependsOn: [
contentPackage
  ]
}

resource huntingQueryObject3_huntingQueryTemplateSpec3 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: huntingQueryObject3.huntingQueryTemplateSpecName3
  location: location
  properties: {
    description: 'Anomalous_Listing_Of_Storage_Keys_HuntingQueries Hunting Query with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: huntingQueryObject3.huntingQueryVersion3
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.OperationalInsights/savedSearches'
          apiVersion: '2022-10-01'
          name: 'Azure_Activity_Hunting_Query_3'
          location: location
          properties: {
            eTag: '*'
            displayName: 'Azure storage key enumeration'
            category: 'Hunting Queries'
            query: 'AzureActivity\n| where OperationNameValue =~ "microsoft.storage/storageaccounts/listkeys/action"\n| where ActivityStatusValue =~ "Succeeded" \n| join kind= inner (\n    AzureActivity\n    | where OperationNameValue =~ "microsoft.storage/storageaccounts/listkeys/action"\n    | where ActivityStatusValue =~ "Succeeded" \n    | project ExpectedIpAddress=CallerIpAddress, Caller \n    | evaluate autocluster()\n) on Caller\n| where CallerIpAddress != ExpectedIpAddress\n| summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated), ResourceIds = make_set(ResourceId,100), ResourceIdCount = dcount(ResourceId) by OperationNameValue, Caller, CallerIpAddress\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| extend Account_0_Name = Name\n| extend Account_0_UPNSuffix = UPNSuffix\n| extend IP_0_Address = CallerIpAddress\n'
            version: 2
            tags: [
              {
                name: 'description'
                value: 'Azure\'s storage key listing can expose secrets, PII, and grant VM access. Monitoring for anomalous accounts or IPs is crucial. The query generates IP clusters, correlates activities, and flags unexpected ones. Single-operation users are excluded.'
              }
              {
                name: 'tactics'
                value: 'Discovery'
              }
              {
                name: 'techniques'
                value: 'T1087'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/HuntingQuery-${last(split(resourceId('Microsoft.OperationalInsights/savedSearches',huntingQueryObject3._huntingQuerycontentId3),'/'))}'
          properties: {
            description: 'Azure Activity Hunting Query 3'
            parentId: resourceId(
              'Microsoft.OperationalInsights/savedSearches',
              huntingQueryObject3._huntingQuerycontentId3
            )
            contentId: huntingQueryObject3._huntingQuerycontentId3
            kind: 'HuntingQuery'
            version: huntingQueryObject3.huntingQueryVersion3
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: huntingQueryObject3._huntingQuerycontentId3
    contentKind: 'HuntingQuery'
    displayName: 'Azure storage key enumeration'
    contentProductId: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject3._huntingQuerycontentId3}-2.0.1')}'
    id: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject3._huntingQuerycontentId3}-2.0.1')}'
    version: '2.0.1'
  }
  dependsOn: [
contentPackage
  ]
}

resource huntingQueryObject4_huntingQueryTemplateSpec4 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: huntingQueryObject4.huntingQueryTemplateSpecName4
  location: location
  properties: {
    description: 'AzureAdministrationFromVPS_HuntingQueries Hunting Query with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: huntingQueryObject4.huntingQueryVersion4
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.OperationalInsights/savedSearches'
          apiVersion: '2022-10-01'
          name: 'Azure_Activity_Hunting_Query_4'
          location: location
          properties: {
            eTag: '*'
            displayName: 'AzureActivity Administration From VPS Providers'
            category: 'Hunting Queries'
            query: 'let IP_Data = (externaldata(network:string)\n[@"https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Sample%20Data/Feeds/VPS_Networks.csv"] with (format="csv"));\nAzureActivity\n| where CategoryValue =~ "Administrative"\n| evaluate ipv4_lookup(IP_Data, CallerIpAddress, network, return_unmatched = false)\n| summarize Operations = make_set(OperationNameValue), StartTime = min(TimeGenerated), EndTime = max(TimeGenerated) by CallerIpAddress, Caller\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| extend Account_0_Name = Name\n| extend Account_0_UPNSuffix = UPNSuffix\n| extend IP_0_Address = CallerIpAddress\n'
            version: 2
            tags: [
              {
                name: 'description'
                value: 'Looks for administrative actions in AzureActivity from known VPS provider network ranges.\nThis is not an exhaustive list of VPS provider ranges but covers some of the most prevalent providers observed.'
              }
              {
                name: 'tactics'
                value: 'InitialAccess'
              }
              {
                name: 'techniques'
                value: 'T1078'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/HuntingQuery-${last(split(resourceId('Microsoft.OperationalInsights/savedSearches',huntingQueryObject4._huntingQuerycontentId4),'/'))}'
          properties: {
            description: 'Azure Activity Hunting Query 4'
            parentId: resourceId(
              'Microsoft.OperationalInsights/savedSearches',
              huntingQueryObject4._huntingQuerycontentId4
            )
            contentId: huntingQueryObject4._huntingQuerycontentId4
            kind: 'HuntingQuery'
            version: huntingQueryObject4.huntingQueryVersion4
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: huntingQueryObject4._huntingQuerycontentId4
    contentKind: 'HuntingQuery'
    displayName: 'AzureActivity Administration From VPS Providers'
    contentProductId: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject4._huntingQuerycontentId4}-2.0.1')}'
    id: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject4._huntingQuerycontentId4}-2.0.1')}'
    version: '2.0.1'
  }
  dependsOn: [
contentPackage
  ]
}

resource huntingQueryObject5_huntingQueryTemplateSpec5 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: huntingQueryObject5.huntingQueryTemplateSpecName5
  location: location
  properties: {
    description: 'AzureNSG_AdministrativeOperations_HuntingQueries Hunting Query with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: huntingQueryObject5.huntingQueryVersion5
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.OperationalInsights/savedSearches'
          apiVersion: '2022-10-01'
          name: 'Azure_Activity_Hunting_Query_5'
          location: location
          properties: {
            eTag: '*'
            displayName: 'Azure Network Security Group NSG Administrative Operations'
            category: 'Hunting Queries'
            query: 'let opValues = dynamic(["Microsoft.Network/networkSecurityGroups/write", "Microsoft.Network/networkSecurityGroups/delete"]);\n// Azure NSG Create / Update / Delete\nAzureActivity\n| where Category =~ "Administrative"\n| where OperationNameValue in~ (opValues)\n| where ActivitySubstatusValue in~ ("Created", "OK","Accepted")\n| sort by TimeGenerated desc\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| extend Account_0_Name = Name\n| extend Account_0_UPNSuffix = UPNSuffix\n| extend IP_0_Address = CallerIpAddress\n'
            version: 2
            tags: [
              {
                name: 'description'
                value: 'Identifies a set of Azure NSG administrative and operational detection queries for hunting activities.'
              }
              {
                name: 'tactics'
                value: 'Impact'
              }
              {
                name: 'techniques'
                value: 'T1496'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/HuntingQuery-${last(split(resourceId('Microsoft.OperationalInsights/savedSearches',huntingQueryObject5._huntingQuerycontentId5),'/'))}'
          properties: {
            description: 'Azure Activity Hunting Query 5'
            parentId: resourceId(
              'Microsoft.OperationalInsights/savedSearches',
              huntingQueryObject5._huntingQuerycontentId5
            )
            contentId: huntingQueryObject5._huntingQuerycontentId5
            kind: 'HuntingQuery'
            version: huntingQueryObject5.huntingQueryVersion5
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: huntingQueryObject5._huntingQuerycontentId5
    contentKind: 'HuntingQuery'
    displayName: 'Azure Network Security Group NSG Administrative Operations'
    contentProductId: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject5._huntingQuerycontentId5}-2.0.1')}'
    id: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject5._huntingQuerycontentId5}-2.0.1')}'
    version: '2.0.1'
  }
  dependsOn: [
contentPackage
  ]
}

resource huntingQueryObject6_huntingQueryTemplateSpec6 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: huntingQueryObject6.huntingQueryTemplateSpecName6
  location: location
  properties: {
    description: 'AzureRunCommandFromAzureIP_HuntingQueries Hunting Query with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: huntingQueryObject6.huntingQueryVersion6
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.OperationalInsights/savedSearches'
          apiVersion: '2022-10-01'
          name: 'Azure_Activity_Hunting_Query_6'
          location: location
          properties: {
            eTag: '*'
            displayName: 'Azure VM Run Command executed from Azure IP address'
            category: 'Hunting Queries'
            query: 'let azure_ranges = externaldata(changeNumber: string, cloud: string, values: dynamic)\n["https://raw.githubusercontent.com/microsoft/mstic/master/PublicFeeds/MSFTIPRanges/ServiceTags_Public.json"] with(format=\'multijson\')\n| mv-expand values\n| extend Name = values.name, AddressPrefixes = values.properties.addressPrefixes\n| where Name startswith "WindowsVirtualDesktop"\n| mv-expand AddressPrefixes\n| summarize by tostring(AddressPrefixes);\nAzureActivity\n| where TimeGenerated > ago(30d)\n// Isolate run command actions\n| where OperationNameValue == "Microsoft.Compute/virtualMachines/runCommand/action"\n// Confirm that the operation impacted a virtual machine\n| where Authorization has "virtualMachines"\n// Each runcommand operation consists of three events when successful, Started, Accepted (or Rejected), Successful (or Failed).\n| summarize StartTime=min(TimeGenerated), EndTime=max(TimeGenerated), max(CallerIpAddress), make_list(ActivityStatusValue) by CorrelationId, Authorization, Caller\n// Limit to Run Command executions that Succeeded\n| where list_ActivityStatusValue has "Succeeded"\n// Extract data from the Authorization field, allowing us to later extract the Caller (UPN) and CallerIpAddress\n| extend Authorization_d = parse_json(Authorization)\n| extend Scope = Authorization_d.scope\n| extend Scope_s = split(Scope, "/")\n| extend Subscription = tostring(Scope_s[2])\n| extend VirtualMachineName = tostring(Scope_s[-1])\n| project StartTime, EndTime, Subscription, VirtualMachineName, CorrelationId, Caller, CallerIpAddress=max_CallerIpAddress\n| evaluate ipv4_lookup(azure_ranges, CallerIpAddress, AddressPrefixes)\n| extend IP_0_Address = CallerIpAddress\n'
            version: 2
            tags: [
              {
                name: 'description'
                value: 'Identifies any Azure VM Run Command operation executed from an Azure IP address.\nRun Command allows an attacker or legitimate user to execute arbitrary PowerShell\non a target VM. This technique has been seen in use by NOBELIUM.'
              }
              {
                name: 'tactics'
                value: 'LateralMovement,CredentialAccess'
              }
              {
                name: 'techniques'
                value: 'T1570,T1078.004'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/HuntingQuery-${last(split(resourceId('Microsoft.OperationalInsights/savedSearches',huntingQueryObject6._huntingQuerycontentId6),'/'))}'
          properties: {
            description: 'Azure Activity Hunting Query 6'
            parentId: resourceId(
              'Microsoft.OperationalInsights/savedSearches',
              huntingQueryObject6._huntingQuerycontentId6
            )
            contentId: huntingQueryObject6._huntingQuerycontentId6
            kind: 'HuntingQuery'
            version: huntingQueryObject6.huntingQueryVersion6
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: huntingQueryObject6._huntingQuerycontentId6
    contentKind: 'HuntingQuery'
    displayName: 'Azure VM Run Command executed from Azure IP address'
    contentProductId: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject6._huntingQuerycontentId6}-2.1.1')}'
    id: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject6._huntingQuerycontentId6}-2.1.1')}'
    version: '2.1.1'
  }
  dependsOn: [
contentPackage
  ]
}

resource huntingQueryObject7_huntingQueryTemplateSpec7 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: huntingQueryObject7.huntingQueryTemplateSpecName7
  location: location
  properties: {
    description: 'AzureSentinelConnectors_AdministrativeOperations_HuntingQueries Hunting Query with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: huntingQueryObject7.huntingQueryVersion7
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.OperationalInsights/savedSearches'
          apiVersion: '2022-10-01'
          name: 'Azure_Activity_Hunting_Query_7'
          location: location
          properties: {
            eTag: '*'
            displayName: 'Microsoft Sentinel Connectors Administrative Operations'
            category: 'Hunting Queries'
            query: 'let opValues = dynamic(["Microsoft.SecurityInsights/dataConnectors/write", "Microsoft.SecurityInsights/dataConnectors/delete"]);\n// Microsoft Sentinel Data Connectors Update / Delete\nAzureActivity\n| where OperationNameValue in~ (opValues)\n| where ActivitySubstatusValue in~ ("Created", "OK")\n| sort by TimeGenerated desc\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| extend Account_0_Name = Name\n| extend Account_0_UPNSuffix = UPNSuffix\n| extend IP_0_Address = CallerIpAddress\n'
            version: 2
            tags: [
              {
                name: 'description'
                value: 'Identifies a set of Microsoft Sentinel Data Connectors for administrative and operational detection queries for hunting activities.'
              }
              {
                name: 'tactics'
                value: 'Impact'
              }
              {
                name: 'techniques'
                value: 'T1496'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/HuntingQuery-${last(split(resourceId('Microsoft.OperationalInsights/savedSearches',huntingQueryObject7._huntingQuerycontentId7),'/'))}'
          properties: {
            description: 'Azure Activity Hunting Query 7'
            parentId: resourceId(
              'Microsoft.OperationalInsights/savedSearches',
              huntingQueryObject7._huntingQuerycontentId7
            )
            contentId: huntingQueryObject7._huntingQuerycontentId7
            kind: 'HuntingQuery'
            version: huntingQueryObject7.huntingQueryVersion7
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: huntingQueryObject7._huntingQuerycontentId7
    contentKind: 'HuntingQuery'
    displayName: 'Microsoft Sentinel Connectors Administrative Operations'
    contentProductId: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject7._huntingQuerycontentId7}-2.0.1')}'
    id: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject7._huntingQuerycontentId7}-2.0.1')}'
    version: '2.0.1'
  }
  dependsOn: [
contentPackage
  ]
}

resource huntingQueryObject8_huntingQueryTemplateSpec8 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: huntingQueryObject8.huntingQueryTemplateSpecName8
  location: location
  properties: {
    description: 'AzureSentinelWorkbooks_AdministrativeOperation_HuntingQueries Hunting Query with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: huntingQueryObject8.huntingQueryVersion8
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.OperationalInsights/savedSearches'
          apiVersion: '2022-10-01'
          name: 'Azure_Activity_Hunting_Query_8'
          location: location
          properties: {
            eTag: '*'
            displayName: 'Microsoft Sentinel Workbooks Administrative Operations'
            category: 'Hunting Queries'
            query: 'let opValues = dynamic(["microsoft.insights/workbooks/write", "microsoft.insights/workbooks/delete"]);\n// Microsoft Sentinel Workbook Create / Update / Delete\nAzureActivity\n| where Category =~ "Administrative"\n| where OperationNameValue in~ (opValues)\n| where ActivitySubstatusValue in~ ("Created", "OK")\n| sort by TimeGenerated desc\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| extend Account_0_Name = Name\n| extend Account_0_UPNSuffix = UPNSuffix\n| extend IP_0_Address = CallerIpAddress\n'
            version: 2
            tags: [
              {
                name: 'description'
                value: 'Identifies set of Microsoft Sentinel Workbooks administrative operational detection queries for hunting activites'
              }
              {
                name: 'tactics'
                value: 'Impact'
              }
              {
                name: 'techniques'
                value: 'T1496'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/HuntingQuery-${last(split(resourceId('Microsoft.OperationalInsights/savedSearches',huntingQueryObject8._huntingQuerycontentId8),'/'))}'
          properties: {
            description: 'Azure Activity Hunting Query 8'
            parentId: resourceId(
              'Microsoft.OperationalInsights/savedSearches',
              huntingQueryObject8._huntingQuerycontentId8
            )
            contentId: huntingQueryObject8._huntingQuerycontentId8
            kind: 'HuntingQuery'
            version: huntingQueryObject8.huntingQueryVersion8
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: huntingQueryObject8._huntingQuerycontentId8
    contentKind: 'HuntingQuery'
    displayName: 'Microsoft Sentinel Workbooks Administrative Operations'
    contentProductId: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject8._huntingQuerycontentId8}-2.0.1')}'
    id: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject8._huntingQuerycontentId8}-2.0.1')}'
    version: '2.0.1'
  }
  dependsOn: [
contentPackage
  ]
}

resource huntingQueryObject9_huntingQueryTemplateSpec9 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: huntingQueryObject9.huntingQueryTemplateSpecName9
  location: location
  properties: {
    description: 'AzureVirtualNetworkSubnets_AdministrativeOperationset_HuntingQueries Hunting Query with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: huntingQueryObject9.huntingQueryVersion9
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.OperationalInsights/savedSearches'
          apiVersion: '2022-10-01'
          name: 'Azure_Activity_Hunting_Query_9'
          location: location
          properties: {
            eTag: '*'
            displayName: 'Azure Virtual Network Subnets Administrative Operations'
            category: 'Hunting Queries'
            query: 'let opValues = dynamic(["Microsoft.Network/virtualNetworks/subnets/write","Microsoft.Network/virtualNetworks/subnets/delete"]);\n// Creating, Updating or Deleting Virtual Network Subnets\nAzureActivity\n| where CategoryValue =~ "Administrative"\n| where OperationNameValue in~ (opValues)\n| where ActivitySubstatusValue in~ ("Created","Accepted")\n| sort by TimeGenerated desc\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| extend Account_0_Name = Name\n| extend Account_0_UPNSuffix = UPNSuffix\n| extend IP_0_Address = CallerIpAddress\n'
            version: 2
            tags: [
              {
                name: 'description'
                value: 'Identifies a set of Azure Virtual Network Subnets for administrative and operational detection queries for hunting activities.'
              }
              {
                name: 'tactics'
                value: 'Impact'
              }
              {
                name: 'techniques'
                value: 'T1496'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/HuntingQuery-${last(split(resourceId('Microsoft.OperationalInsights/savedSearches',huntingQueryObject9._huntingQuerycontentId9),'/'))}'
          properties: {
            description: 'Azure Activity Hunting Query 9'
            parentId: resourceId(
              'Microsoft.OperationalInsights/savedSearches',
              huntingQueryObject9._huntingQuerycontentId9
            )
            contentId: huntingQueryObject9._huntingQuerycontentId9
            kind: 'HuntingQuery'
            version: huntingQueryObject9.huntingQueryVersion9
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: huntingQueryObject9._huntingQuerycontentId9
    contentKind: 'HuntingQuery'
    displayName: 'Azure Virtual Network Subnets Administrative Operations'
    contentProductId: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject9._huntingQuerycontentId9}-2.0.1')}'
    id: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject9._huntingQuerycontentId9}-2.0.1')}'
    version: '2.0.1'
  }
  dependsOn: [
contentPackage
  ]
}

resource huntingQueryObject10_huntingQueryTemplateSpec10 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: huntingQueryObject10.huntingQueryTemplateSpecName10
  location: location
  properties: {
    description: 'Common_Deployed_Resources_HuntingQueries Hunting Query with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: huntingQueryObject10.huntingQueryVersion10
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.OperationalInsights/savedSearches'
          apiVersion: '2022-10-01'
          name: 'Azure_Activity_Hunting_Query_10'
          location: location
          properties: {
            eTag: '*'
            displayName: 'Common deployed resources'
            category: 'Hunting Queries'
            query: 'AzureActivity\n| where OperationNameValue has_any (@"deployments/write", @"virtualMachines/write")  \n| where ActivityStatusValue =~ "Succeeded"\n| summarize by bin(TimeGenerated,1d), Resource, ResourceGroup, ResourceId, OperationNameValue, Caller\n| evaluate basket()\n| where isnotempty(Caller) and isnotempty(Resource) and isnotempty(TimeGenerated)\n| order by Percent desc, TimeGenerated desc\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| extend Account_0_Name = Name\n| extend Account_0_UPNSuffix = UPNSuffix\n| extend AzureResource_0_ResourceId = ResourceId\n// remove comments below on filters if the goal is to see more common or more rare Resource, Resource Group and Caller combinations\n//| where Percent <= 40 // <-- more rare\n//| where Percent >= 60 // <-- more common\n'
            version: 2
            tags: [
              {
                name: 'description'
                value: 'This query identifies common deployed resources in Azure, like resource names and groups. It can be used with other suspicious deployment signals to evaluate if a resource is commonly deployed or unique.'
              }
              {
                name: 'tactics'
                value: 'Impact'
              }
              {
                name: 'techniques'
                value: 'T1496'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/HuntingQuery-${last(split(resourceId('Microsoft.OperationalInsights/savedSearches',huntingQueryObject10._huntingQuerycontentId10),'/'))}'
          properties: {
            description: 'Azure Activity Hunting Query 10'
            parentId: resourceId(
              'Microsoft.OperationalInsights/savedSearches',
              huntingQueryObject10._huntingQuerycontentId10
            )
            contentId: huntingQueryObject10._huntingQuerycontentId10
            kind: 'HuntingQuery'
            version: huntingQueryObject10.huntingQueryVersion10
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: huntingQueryObject10._huntingQuerycontentId10
    contentKind: 'HuntingQuery'
    displayName: 'Common deployed resources'
    contentProductId: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject10._huntingQuerycontentId10}-2.0.1')}'
    id: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject10._huntingQuerycontentId10}-2.0.1')}'
    version: '2.0.1'
  }
  dependsOn: [
contentPackage
  ]
}

resource huntingQueryObject11_huntingQueryTemplateSpec11 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: huntingQueryObject11.huntingQueryTemplateSpecName11
  location: location
  properties: {
    description: 'Creating_Anomalous_Number_Of_Resources_HuntingQueries Hunting Query with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: huntingQueryObject11.huntingQueryVersion11
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.OperationalInsights/savedSearches'
          apiVersion: '2022-10-01'
          name: 'Azure_Activity_Hunting_Query_11'
          location: location
          properties: {
            eTag: '*'
            displayName: 'Creation of an anomalous number of resources'
            category: 'Hunting Queries'
            query: 'AzureActivity\n| where OperationNameValue in~ ("microsoft.compute/virtualMachines/write", "microsoft.resources/deployments/write")\n| where ActivityStatusValue == "Succeeded" \n| make-series dcount(ResourceId)  default=0 on EventSubmissionTimestamp in range(ago(7d), now(), 1d) by Caller\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| extend Account_0_Name = Name\n| extend Account_0_UPNSuffix = UPNSuffix\n'
            version: 2
            tags: [
              {
                name: 'description'
                value: 'Looks for anomalous number of resources creation or deployment activities in azure activity log.\nIt is best to run this query on a look back period which is at least 7 days.'
              }
              {
                name: 'tactics'
                value: 'Impact'
              }
              {
                name: 'techniques'
                value: 'T1496'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/HuntingQuery-${last(split(resourceId('Microsoft.OperationalInsights/savedSearches',huntingQueryObject11._huntingQuerycontentId11),'/'))}'
          properties: {
            description: 'Azure Activity Hunting Query 11'
            parentId: resourceId(
              'Microsoft.OperationalInsights/savedSearches',
              huntingQueryObject11._huntingQuerycontentId11
            )
            contentId: huntingQueryObject11._huntingQuerycontentId11
            kind: 'HuntingQuery'
            version: huntingQueryObject11.huntingQueryVersion11
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: huntingQueryObject11._huntingQuerycontentId11
    contentKind: 'HuntingQuery'
    displayName: 'Creation of an anomalous number of resources'
    contentProductId: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject11._huntingQuerycontentId11}-2.0.1')}'
    id: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject11._huntingQuerycontentId11}-2.0.1')}'
    version: '2.0.1'
  }
  dependsOn: [
contentPackage
  ]
}

resource huntingQueryObject12_huntingQueryTemplateSpec12 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: huntingQueryObject12.huntingQueryTemplateSpecName12
  location: location
  properties: {
    description: 'Granting_Permissions_to_Account_HuntingQueries Hunting Query with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: huntingQueryObject12.huntingQueryVersion12
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.OperationalInsights/savedSearches'
          apiVersion: '2022-10-01'
          name: 'Azure_Activity_Hunting_Query_12'
          location: location
          properties: {
            eTag: '*'
            displayName: 'Granting permissions to account'
            category: 'Hunting Queries'
            query: 'AzureActivity\n| where OperationName =~ "Create role assignment"\n| where ActivityStatus =~ "Succeeded" \n| project Caller, CallerIpAddress\n| evaluate basket()\n// Returns all the records from the left side and only matching records from the right side.\n| join kind=leftouter (AzureActivity\n| where OperationName =~ "Create role assignment"\n| where ActivityStatus =~ "Succeeded"\n| summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated) by Caller, CallerIpAddress)\non Caller, CallerIpAddress\n| project-away Caller1, CallerIpAddress1\n| where isnotempty(StartTime)\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| extend Account_0_Name = Name\n| extend Account_0_UPNSuffix = UPNSuffix\n| extend IP_0_Address = CallerIpAddress\n'
            version: 2
            tags: [
              {
                name: 'description'
                value: 'Shows the most prevalent users who grant access to others on Azure resources. List the common source IP address for each of those accounts. If an operation is not from those IP addresses, it may be worthy of investigation.'
              }
              {
                name: 'tactics'
                value: 'Persistence,PrivilegeEscalation'
              }
              {
                name: 'techniques'
                value: 'T1098'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/HuntingQuery-${last(split(resourceId('Microsoft.OperationalInsights/savedSearches',huntingQueryObject12._huntingQuerycontentId12),'/'))}'
          properties: {
            description: 'Azure Activity Hunting Query 12'
            parentId: resourceId(
              'Microsoft.OperationalInsights/savedSearches',
              huntingQueryObject12._huntingQuerycontentId12
            )
            contentId: huntingQueryObject12._huntingQuerycontentId12
            kind: 'HuntingQuery'
            version: huntingQueryObject12.huntingQueryVersion12
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: huntingQueryObject12._huntingQuerycontentId12
    contentKind: 'HuntingQuery'
    displayName: 'Granting permissions to account'
    contentProductId: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject12._huntingQuerycontentId12}-2.0.1')}'
    id: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject12._huntingQuerycontentId12}-2.0.1')}'
    version: '2.0.1'
  }
  dependsOn: [
contentPackage
  ]
}

resource huntingQueryObject13_huntingQueryTemplateSpec13 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: huntingQueryObject13.huntingQueryTemplateSpecName13
  location: location
  properties: {
    description: 'PortOpenedForAzureResource_HuntingQueries Hunting Query with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: huntingQueryObject13.huntingQueryVersion13
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.OperationalInsights/savedSearches'
          apiVersion: '2022-10-01'
          name: 'Azure_Activity_Hunting_Query_13'
          location: location
          properties: {
            eTag: '*'
            displayName: 'Port opened for an Azure Resource'
            category: 'Hunting Queries'
            query: 'let lookback = 7d;\nAzureActivity\n| where TimeGenerated >= ago(lookback)\n| where OperationNameValue has_any ("ipfilterrules", "securityRules", "publicIPAddresses", "firewallrules") and OperationNameValue endswith "write"\n// Choosing Accepted here because it has the Rule Attributes included\n| where ActivityStatusValue == "Accepted" \n// If there is publicIP info, include it\n| extend parsed_properties = parse_json(tostring(parse_json(Properties).responseBody)).properties\n| extend publicIPAddressVersion = case(Properties has_cs \'publicIPAddressVersion\',tostring(parsed_properties.publicIPAddressVersion),"")\n| extend publicIPAllocationMethod = case(Properties has_cs \'publicIPAllocationMethod\',tostring(parsed_properties.publicIPAllocationMethod),"")\n// Include rule attributes for context\n| extend access = case(Properties has_cs \'access\',tostring(parsed_properties.access),"")\n| extend description = case(Properties has_cs \'description\',tostring(parsed_properties.description),"")\n| extend destinationPortRange = case(Properties has_cs \'destinationPortRange\',tostring(parsed_properties.destinationPortRange),"")\n| extend direction = case(Properties has_cs \'direction\',tostring(parsed_properties.direction),"")\n| extend protocol = case(Properties has_cs \'protocol\',tostring(parsed_properties.protocol),"")\n| extend sourcePortRange = case(Properties has_cs \'sourcePortRange\',tostring(parsed_properties.sourcePortRange),"")\n| summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated), ResourceIds = make_set(_ResourceId,100) by Caller, CallerIpAddress, Resource, ResourceGroup, \nActivityStatusValue, ActivitySubstatus, SubscriptionId, access, description, destinationPortRange, direction, protocol, sourcePortRange, publicIPAddressVersion, publicIPAllocationMethod\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| extend Account_0_Name = Name\n| extend Account_0_UPNSuffix = UPNSuffix\n| extend IP_0_Address = CallerIpAddress\n'
            version: 2
            tags: [
              {
                name: 'description'
                value: 'Identifies what ports may have been opened for a given Azure Resource over the last 7 days'
              }
              {
                name: 'tactics'
                value: 'CommandAndControl,Impact'
              }
              {
                name: 'techniques'
                value: 'T1071,T1571,T1496'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/HuntingQuery-${last(split(resourceId('Microsoft.OperationalInsights/savedSearches',huntingQueryObject13._huntingQuerycontentId13),'/'))}'
          properties: {
            description: 'Azure Activity Hunting Query 13'
            parentId: resourceId(
              'Microsoft.OperationalInsights/savedSearches',
              huntingQueryObject13._huntingQuerycontentId13
            )
            contentId: huntingQueryObject13._huntingQuerycontentId13
            kind: 'HuntingQuery'
            version: huntingQueryObject13.huntingQueryVersion13
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: huntingQueryObject13._huntingQuerycontentId13
    contentKind: 'HuntingQuery'
    displayName: 'Port opened for an Azure Resource'
    contentProductId: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject13._huntingQuerycontentId13}-2.0.1')}'
    id: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject13._huntingQuerycontentId13}-2.0.1')}'
    version: '2.0.1'
  }
  dependsOn: [
contentPackage
  ]
}

resource huntingQueryObject14_huntingQueryTemplateSpec14 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: huntingQueryObject14.huntingQueryTemplateSpecName14
  location: location
  properties: {
    description: 'Rare_Custom_Script_Extension_HuntingQueries Hunting Query with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: huntingQueryObject14.huntingQueryVersion14
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.OperationalInsights/savedSearches'
          apiVersion: '2022-10-01'
          name: 'Azure_Activity_Hunting_Query_14'
          location: location
          properties: {
            eTag: '*'
            displayName: 'Rare Custom Script Extension'
            category: 'Hunting Queries'
            query: 'let starttime = todatetime(\'{{StartTimeISO}}\');\nlet endtime = todatetime(\'{{EndTimeISO}}\');\nlet Lookback = starttime - 14d;\nlet CustomScriptExecution = AzureActivity\n| where TimeGenerated >= Lookback\n| where OperationName =~ "Create or Update Virtual Machine Extension"\n| extend parsed_properties = parse_json(Properties)\n| extend Settings = tostring((parse_json(tostring(parsed_properties.responseBody)).properties).settings)\n| parse Settings with * \'fileUris":[\' FileURI "]" *\n| parse Settings with * \'commandToExecute":\' commandToExecute \'}\' *\n| extend message_ = tostring((parse_json(tostring(parsed_properties.statusMessage)).error).message);\nlet LookbackCustomScriptExecution = CustomScriptExecution\n| where TimeGenerated >= Lookback and TimeGenerated < starttime\n| where isnotempty(FileURI) and isnotempty(commandToExecute)\n| summarize max(TimeGenerated), OperationCount = count() by Caller, Resource, CallerIpAddress, FileURI, commandToExecute;\nlet CurrentCustomScriptExecution = CustomScriptExecution\n| where TimeGenerated between (starttime..endtime)\n| where isnotempty(FileURI) and isnotempty(commandToExecute)\n| project TimeGenerated, ActivityStatus, OperationId, CorrelationId, ResourceId, CallerIpAddress, Caller, OperationName, Resource, ResourceGroup, FileURI, commandToExecute, FailureMessage = message_, HTTPRequest, Settings;\nlet RareCustomScriptExecution =  CurrentCustomScriptExecution\n| join kind= leftanti (LookbackCustomScriptExecution) on Caller, CallerIpAddress, FileURI, commandToExecute;\nlet IPCheck = RareCustomScriptExecution\n| summarize arg_max(TimeGenerated, OperationName), OperationIds = make_set(OperationId,100), CallerIpAddresses = make_set(CallerIpAddress,100) by ActivityStatus, CorrelationId, ResourceId, Caller, Resource, ResourceGroup, FileURI, commandToExecute, FailureMessage\n| extend IPArray = array_length(CallerIpAddresses);\n//Get IPs for later summarization so all associated CorrelationIds and Caller actions have an IP.  Success and Fails do not always have IP\nlet multiIP = IPCheck | where IPArray > 1\n| mv-expand CallerIpAddresses | extend CallerIpAddress = tostring(CallerIpAddresses)\n| where isnotempty(CallerIpAddresses);\nlet singleIP = IPCheck | where IPArray <= 1\n| mv-expand CallerIpAddresses | extend CallerIpAddress = tostring(CallerIpAddresses);\nlet FullDetails = singleIP | union multiIP;\n//Get IP address associated with successes and fails with no IP listed\nlet IPList = FullDetails | where isnotempty(CallerIpAddress) | summarize by CorrelationId, Caller, CallerIpAddress;\nlet EmptyIP = FullDetails | where isempty(CallerIpAddress) | project-away CallerIpAddress;\nlet IpJoin = EmptyIP | join kind= leftouter (IPList) on CorrelationId, Caller | project-away CorrelationId1, Caller1;\nlet nonEmptyIP = FullDetails | where isnotempty(CallerIpAddress);\nnonEmptyIP | union IpJoin\n// summarize all activities with a given CorrelationId and Caller together so we can provide a singular result\n| summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated), ActivityStatusSet = make_set(ActivityStatus,100), OperationIds = make_set(OperationIds,100), FailureMessages = make_set(FailureMessage,100) by CorrelationId, ResourceId, CallerIpAddress, Caller, Resource, ResourceGroup, FileURI, commandToExecute\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| extend Account_0_Name = Name\n| extend Account_0_UPNSuffix = UPNSuffix\n| extend IP_0_Address = CallerIpAddress\n'
            version: 2
            tags: [
              {
                name: 'description'
                value: 'The Custom Script Extension in Azure executes scripts on VMs, useful for post-deployment tasks. Scripts can be from various sources and could be used maliciously. The query identifies rare custom script extensions executed in your environment.'
              }
              {
                name: 'tactics'
                value: 'Execution'
              }
              {
                name: 'techniques'
                value: 'T1059'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/HuntingQuery-${last(split(resourceId('Microsoft.OperationalInsights/savedSearches',huntingQueryObject14._huntingQuerycontentId14),'/'))}'
          properties: {
            description: 'Azure Activity Hunting Query 14'
            parentId: resourceId(
              'Microsoft.OperationalInsights/savedSearches',
              huntingQueryObject14._huntingQuerycontentId14
            )
            contentId: huntingQueryObject14._huntingQuerycontentId14
            kind: 'HuntingQuery'
            version: huntingQueryObject14.huntingQueryVersion14
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: huntingQueryObject14._huntingQuerycontentId14
    contentKind: 'HuntingQuery'
    displayName: 'Rare Custom Script Extension'
    contentProductId: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject14._huntingQuerycontentId14}-2.0.1')}'
    id: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject14._huntingQuerycontentId14}-2.0.1')}'
    version: '2.0.1'
  }
  dependsOn: [
contentPackage
  ]
}

resource huntingQueryObject15_huntingQueryTemplateSpec15 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: huntingQueryObject15.huntingQueryTemplateSpecName15
  location: location
  properties: {
    description: 'Machine_Learning_Creation_HuntingQueries Hunting Query with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: huntingQueryObject15.huntingQueryVersion15
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.OperationalInsights/savedSearches'
          apiVersion: '2022-10-01'
          name: 'Azure_Activity_Hunting_Query_15'
          location: location
          properties: {
            eTag: '*'
            displayName: 'Azure Machine Learning Write Operations'
            category: 'Hunting Queries'
            query: 'AzureActivity\n| where ResourceProviderValue == "MICROSOFT.MACHINELEARNINGSERVICES"  // Filter activities related to Microsoft Machine Learning Services\n| extend SCOPE = tostring(parse_json(Authorization).scope)  // Parse Authorization scope as string\n| extend subname = split(Hierarchy, "/")  // Split Hierarchy to extract Subscription Name and ID\n| extend [\'Subscription Name\'] = subname[-2], [\'Subscription ID\'] = subname[-1]  // Extract Subscription Name and ID\n| extend Properties = parse_json(Properties)  // Parse Properties as JSON\n| extend Properties_entity = tostring(Properties.entity)  // Cast Properties.entity to string\n| where isnotempty(Properties_entity)  // Filter activities where Properties.entity is not empty\n// | where Properties_entity contains "deepseek"  // Filter activities where Properties.entity contains "deepseek"\n| where OperationNameValue contains "write"  // Filter activities where OperationNameValue contains "write"\n| where OperationNameValue !contains "MICROSOFT.AUTHORIZATION/ROLEASSIGNMENTS/WRITE"  // Exclude role assignments\n| extend LLM = tostring(split(Properties_entity, "/")[-1])  // Extract the last segment of Properties_entity and cast it to string\n| distinct TimeGenerated, tostring([\'Subscription Name\']), ResourceGroup, tostring([\'Subscription ID\']), Caller, CallerIpAddress, OperationNameValue, LLM, _ResourceId  // Select distinct relevant fields for output\n'
            version: 2
            tags: [
              {
                name: 'description'
                value: 'Shows the most prevalent users who perform write operations on Azure Machine Learning resources. List the common source IP address for each of those accounts. If an operation is not from those IP addresses, it may be worthy of investigation.'
              }
              {
                name: 'tactics'
                value: 'InitialAccess,Execution,Impact'
              }
              {
                name: 'techniques'
                value: 'T1078,T1059,T1496'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/HuntingQuery-${last(split(resourceId('Microsoft.OperationalInsights/savedSearches',huntingQueryObject15._huntingQuerycontentId15),'/'))}'
          properties: {
            description: 'Azure Activity Hunting Query 15'
            parentId: resourceId(
              'Microsoft.OperationalInsights/savedSearches',
              huntingQueryObject15._huntingQuerycontentId15
            )
            contentId: huntingQueryObject15._huntingQuerycontentId15
            kind: 'HuntingQuery'
            version: huntingQueryObject15.huntingQueryVersion15
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: huntingQueryObject15._huntingQuerycontentId15
    contentKind: 'HuntingQuery'
    displayName: 'Azure Machine Learning Write Operations'
    contentProductId: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject15._huntingQuerycontentId15}-1')}'
    id: '${take(_solutionId,50)}-hq-${uniqueString('${_solutionId}-HuntingQuery-${huntingQueryObject15._huntingQuerycontentId15}-1')}'
    version: '1'
  }
  dependsOn: [
contentPackage
  ]
}

resource analyticRuleObject1_analyticRuleTemplateSpec1 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: analyticRuleObject1.analyticRuleTemplateSpecName1
  location: location
  properties: {
    description: 'AADHybridHealthADFSNewServer_AnalyticalRules Analytics Rule with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: analyticRuleObject1.analyticRuleVersion1
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.SecurityInsights/AlertRuleTemplates'
          name: analyticRuleObject1._analyticRulecontentId1
          apiVersion: '2023-02-01-preview'
          kind: 'Scheduled'
          location: location
          properties: {
            description: 'This detection uses AzureActivity logs (Administrative category) to identify the creation or update of a server instance in an Microsoft Entra ID Hybrid Health AD FS service.\nA threat actor can create a new AD Health ADFS service and create a fake server instance to spoof AD FS signing logs. There is no need to compromise an on-premises AD FS server.\nThis can be done programmatically via HTTP requests to Azure. More information in this blog: https://o365blog.com/post/hybridhealthagent/'
            displayName: 'Microsoft Entra ID Hybrid Health AD FS New Server'
            enabled: false
            query: 'AzureActivity\n| where CategoryValue =~ \'Administrative\'\n| where ResourceProviderValue =~ \'Microsoft.ADHybridHealthService\'\n| where _ResourceId has \'AdFederationService\'\n| where OperationNameValue =~ \'Microsoft.ADHybridHealthService/services/servicemembers/action\'\n| extend claimsJson = parse_json(Claims)\n| extend AppId = tostring(claimsJson.appid), AccountName = tostring(claimsJson.name), Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| project-away claimsJson\n'
            queryFrequency: 'P1D'
            queryPeriod: 'P1D'
            severity: 'Medium'
            suppressionDuration: 'PT1H'
            suppressionEnabled: false
            triggerOperator: 'GreaterThan'
            triggerThreshold: 0
            status: 'Available'
            requiredDataConnectors: [
              {
                connectorId: 'AzureActivity'
                dataTypes: [
                  'AzureActivity'
                ]
              }
            ]
            tactics: [
              'DefenseEvasion'
            ]
            techniques: [
              'T1578'
            ]
            entityMappings: [
              {
                fieldMappings: [
                  {
                    columnName: 'Caller'
                    identifier: 'FullName'
                  }
                  {
                    columnName: 'Name'
                    identifier: 'Name'
                  }
                  {
                    columnName: 'UPNSuffix'
                    identifier: 'UPNSuffix'
                  }
                ]
                entityType: 'Account'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'CallerIpAddress'
                    identifier: 'Address'
                  }
                ]
                entityType: 'IP'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/AnalyticsRule-${last(split(analyticRuleObject1.analyticRuleId1,'/'))}'
          properties: {
            description: 'Azure Activity Analytics Rule 1'
            parentId: analyticRuleObject1.analyticRuleId1
            contentId: analyticRuleObject1._analyticRulecontentId1
            kind: 'AnalyticsRule'
            version: analyticRuleObject1.analyticRuleVersion1
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: analyticRuleObject1._analyticRulecontentId1
    contentKind: 'AnalyticsRule'
    displayName: 'Microsoft Entra ID Hybrid Health AD FS New Server'
    contentProductId: analyticRuleObject1._analyticRulecontentProductId1
    id: analyticRuleObject1._analyticRulecontentProductId1
    version: analyticRuleObject1.analyticRuleVersion1
  }
  dependsOn: [
contentPackage
  ]
}

resource analyticRuleObject2_analyticRuleTemplateSpec2 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: analyticRuleObject2.analyticRuleTemplateSpecName2
  location: location
  properties: {
    description: 'AADHybridHealthADFSServiceDelete_AnalyticalRules Analytics Rule with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: analyticRuleObject2.analyticRuleVersion2
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.SecurityInsights/AlertRuleTemplates'
          name: analyticRuleObject2._analyticRulecontentId2
          apiVersion: '2023-02-01-preview'
          kind: 'Scheduled'
          location: location
          properties: {
            description: 'This detection uses AzureActivity logs (Administrative category) to identify the deletion of an Microsoft Entra ID Hybrid Health AD FS service instance in a tenant.\nA threat actor can create a new AD Health ADFS service and create a fake server to spoof AD FS signing logs.\nThe health AD FS service can then be deleted after it is no longer needed via HTTP requests to Azure.\nMore information is available in this blog https://o365blog.com/post/hybridhealthagent/'
            displayName: 'Microsoft Entra ID Hybrid Health AD FS Service Delete'
            enabled: false
            query: 'AzureActivity\n| where CategoryValue =~ \'Administrative\'\n| where ResourceProviderValue =~ \'Microsoft.ADHybridHealthService\'\n| where _ResourceId has \'AdFederationService\'\n| where OperationNameValue =~ \'Microsoft.ADHybridHealthService/services/delete\'\n| extend claimsJson = parse_json(Claims)\n| extend AppId = tostring(claimsJson.appid), AccountName = tostring(claimsJson.name), Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| project-away claimsJson\n'
            queryFrequency: 'P1D'
            queryPeriod: 'P1D'
            severity: 'Medium'
            suppressionDuration: 'PT1H'
            suppressionEnabled: false
            triggerOperator: 'GreaterThan'
            triggerThreshold: 0
            status: 'Available'
            requiredDataConnectors: [
              {
                connectorId: 'AzureActivity'
                dataTypes: [
                  'AzureActivity'
                ]
              }
            ]
            tactics: [
              'DefenseEvasion'
            ]
            subTechniques: [
              'T1578.003'
            ]
            techniques: [
              'T1578'
            ]
            entityMappings: [
              {
                fieldMappings: [
                  {
                    columnName: 'Caller'
                    identifier: 'FullName'
                  }
                  {
                    columnName: 'Name'
                    identifier: 'Name'
                  }
                  {
                    columnName: 'UPNSuffix'
                    identifier: 'UPNSuffix'
                  }
                ]
                entityType: 'Account'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'CallerIpAddress'
                    identifier: 'Address'
                  }
                ]
                entityType: 'IP'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/AnalyticsRule-${last(split(analyticRuleObject2.analyticRuleId2,'/'))}'
          properties: {
            description: 'Azure Activity Analytics Rule 2'
            parentId: analyticRuleObject2.analyticRuleId2
            contentId: analyticRuleObject2._analyticRulecontentId2
            kind: 'AnalyticsRule'
            version: analyticRuleObject2.analyticRuleVersion2
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: analyticRuleObject2._analyticRulecontentId2
    contentKind: 'AnalyticsRule'
    displayName: 'Microsoft Entra ID Hybrid Health AD FS Service Delete'
    contentProductId: analyticRuleObject2._analyticRulecontentProductId2
    id: analyticRuleObject2._analyticRulecontentProductId2
    version: analyticRuleObject2.analyticRuleVersion2
  }
  dependsOn: [
contentPackage
  ]
}

resource analyticRuleObject3_analyticRuleTemplateSpec3 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: analyticRuleObject3.analyticRuleTemplateSpecName3
  location: location
  properties: {
    description: 'AADHybridHealthADFSSuspApp_AnalyticalRules Analytics Rule with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: analyticRuleObject3.analyticRuleVersion3
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.SecurityInsights/AlertRuleTemplates'
          name: analyticRuleObject3._analyticRulecontentId3
          apiVersion: '2023-02-01-preview'
          kind: 'Scheduled'
          location: location
          properties: {
            description: 'This detection uses AzureActivity logs (Administrative category) to identify a suspicious application adding a server instance to an Microsoft Entra ID Hybrid Health AD FS service or deleting the AD FS service instance.\nUsually the Microsoft Entra ID Connect Health Agent application with ID cf6d7e68-f018-4e0a-a7b3-126e053fb88d and ID cb1056e2-e479-49de-ae31-7812af012ed8 is used to perform those operations.'
            displayName: 'Microsoft Entra ID Hybrid Health AD FS Suspicious Application'
            enabled: false
            query: '// Microsoft Entra ID Connect Health Agent - cf6d7e68-f018-4e0a-a7b3-126e053fb88d\n// Microsoft Entra ID Connect - cb1056e2-e479-49de-ae31-7812af012ed8\nlet appList = dynamic([\'cf6d7e68-f018-4e0a-a7b3-126e053fb88d\',\'cb1056e2-e479-49de-ae31-7812af012ed8\']);\nlet operationNamesList = dynamic([\'Microsoft.ADHybridHealthService/services/servicemembers/action\',\'Microsoft.ADHybridHealthService/services/delete\']);\nAzureActivity\n| where CategoryValue =~ \'Administrative\'\n| where ResourceProviderValue =~ \'Microsoft.ADHybridHealthService\'\n| where _ResourceId has \'AdFederationService\'\n| where OperationNameValue in~ (operationNamesList)\n| extend claimsJson = parse_json(Claims)\n| extend AppId = tostring(claimsJson.appid), AccountName = tostring(claimsJson.name), Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| where AppId !in (appList)\n| project-away claimsJson\n'
            queryFrequency: 'P1D'
            queryPeriod: 'P1D'
            severity: 'Medium'
            suppressionDuration: 'PT1H'
            suppressionEnabled: false
            triggerOperator: 'GreaterThan'
            triggerThreshold: 0
            status: 'Available'
            requiredDataConnectors: [
              {
                connectorId: 'AzureActivity'
                dataTypes: [
                  'AzureActivity'
                ]
              }
            ]
            tactics: [
              'CredentialAccess'
              'DefenseEvasion'
            ]
            techniques: [
              'T1528'
              'T1550'
            ]
            entityMappings: [
              {
                fieldMappings: [
                  {
                    columnName: 'Caller'
                    identifier: 'FullName'
                  }
                  {
                    columnName: 'Name'
                    identifier: 'Name'
                  }
                  {
                    columnName: 'UPNSuffix'
                    identifier: 'UPNSuffix'
                  }
                ]
                entityType: 'Account'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'CallerIpAddress'
                    identifier: 'Address'
                  }
                ]
                entityType: 'IP'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/AnalyticsRule-${last(split(analyticRuleObject3.analyticRuleId3,'/'))}'
          properties: {
            description: 'Azure Activity Analytics Rule 3'
            parentId: analyticRuleObject3.analyticRuleId3
            contentId: analyticRuleObject3._analyticRulecontentId3
            kind: 'AnalyticsRule'
            version: analyticRuleObject3.analyticRuleVersion3
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: analyticRuleObject3._analyticRulecontentId3
    contentKind: 'AnalyticsRule'
    displayName: 'Microsoft Entra ID Hybrid Health AD FS Suspicious Application'
    contentProductId: analyticRuleObject3._analyticRulecontentProductId3
    id: analyticRuleObject3._analyticRulecontentProductId3
    version: analyticRuleObject3.analyticRuleVersion3
  }
  dependsOn: [
contentPackage
  ]
}

resource analyticRuleObject4_analyticRuleTemplateSpec4 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: analyticRuleObject4.analyticRuleTemplateSpecName4
  location: location
  properties: {
    description: 'Creating_Anomalous_Number_Of_Resources_detection_AnalyticalRules Analytics Rule with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: analyticRuleObject4.analyticRuleVersion4
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.SecurityInsights/AlertRuleTemplates'
          name: analyticRuleObject4._analyticRulecontentId4
          apiVersion: '2023-02-01-preview'
          kind: 'Scheduled'
          location: location
          properties: {
            description: 'Indicates when an anomalous number of VM creations or deployment activities occur in Azure via the AzureActivity log. This query generates the baseline pattern of cloud resource creation by an individual and generates an anomaly when any unusual spike is detected. These anomalies from unusual or privileged users could be an indication of a cloud infrastructure takedown by an adversary.'
            displayName: 'Suspicious number of resource creation or deployment activities'
            enabled: false
            query: 'let szOperationNames = dynamic(["microsoft.compute/virtualMachines/write", "microsoft.resources/deployments/write"]);\nlet starttime = 7d;\nlet endtime = 1d;\nlet timeframe = 1d;\nlet TimeSeriesData =\nAzureActivity\n| where TimeGenerated between (startofday(ago(starttime)) .. startofday(now()))\n| where OperationNameValue in~ (szOperationNames)\n| project TimeGenerated, Caller \n| make-series Total = count() on TimeGenerated from startofday(ago(starttime)) to startofday(now()) step timeframe by Caller; \nTimeSeriesData\n| extend (anomalies, score, baseline) = series_decompose_anomalies(Total, 3, -1, \'linefit\')\n| mv-expand Total to typeof(double), TimeGenerated to typeof(datetime), anomalies to typeof(double), score to typeof(double), baseline to typeof(long) \n| where TimeGenerated >= startofday(ago(endtime))\n| where anomalies > 0 and baseline > 0\n| project Caller, TimeGenerated, Total, baseline, anomalies, score\n| join (AzureActivity\n| where TimeGenerated > startofday(ago(endtime)) \n| where OperationNameValue in~ (szOperationNames)\n| summarize make_set(OperationNameValue,100), make_set(_ResourceId,100), make_set(CallerIpAddress,100) by bin(TimeGenerated, timeframe), Caller\n) on TimeGenerated, Caller\n| mv-expand CallerIpAddress=set_CallerIpAddress\n| project-away Caller1\n| extend Name = iif(Caller has \'@\',tostring(split(Caller,\'@\',0)[0]),"")\n| extend UPNSuffix = iif(Caller has \'@\',tostring(split(Caller,\'@\',1)[0]),"")\n| extend AadUserId = iif(Caller !has \'@\',Caller,"")\n'
            queryFrequency: 'P1D'
            queryPeriod: 'P7D'
            severity: 'Medium'
            suppressionDuration: 'PT1H'
            suppressionEnabled: false
            triggerOperator: 'GreaterThan'
            triggerThreshold: 0
            status: 'Available'
            requiredDataConnectors: [
              {
                connectorId: 'AzureActivity'
                dataTypes: [
                  'AzureActivity'
                ]
              }
            ]
            tactics: [
              'Impact'
            ]
            techniques: [
              'T1496'
            ]
            entityMappings: [
              {
                fieldMappings: [
                  {
                    columnName: 'Caller'
                    identifier: 'FullName'
                  }
                  {
                    columnName: 'Name'
                    identifier: 'Name'
                  }
                  {
                    columnName: 'UPNSuffix'
                    identifier: 'UPNSuffix'
                  }
                ]
                entityType: 'Account'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'AadUserId'
                    identifier: 'AadUserId'
                  }
                ]
                entityType: 'Account'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'CallerIpAddress'
                    identifier: 'Address'
                  }
                ]
                entityType: 'IP'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/AnalyticsRule-${last(split(analyticRuleObject4.analyticRuleId4,'/'))}'
          properties: {
            description: 'Azure Activity Analytics Rule 4'
            parentId: analyticRuleObject4.analyticRuleId4
            contentId: analyticRuleObject4._analyticRulecontentId4
            kind: 'AnalyticsRule'
            version: analyticRuleObject4.analyticRuleVersion4
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: analyticRuleObject4._analyticRulecontentId4
    contentKind: 'AnalyticsRule'
    displayName: 'Suspicious number of resource creation or deployment activities'
    contentProductId: analyticRuleObject4._analyticRulecontentProductId4
    id: analyticRuleObject4._analyticRulecontentProductId4
    version: analyticRuleObject4.analyticRuleVersion4
  }
  dependsOn: [
contentPackage
  ]
}

resource analyticRuleObject5_analyticRuleTemplateSpec5 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: analyticRuleObject5.analyticRuleTemplateSpecName5
  location: location
  properties: {
    description: 'Creation_of_Expensive_Computes_in_Azure_AnalyticalRules Analytics Rule with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: analyticRuleObject5.analyticRuleVersion5
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.SecurityInsights/AlertRuleTemplates'
          name: analyticRuleObject5._analyticRulecontentId5
          apiVersion: '2023-02-01-preview'
          kind: 'Scheduled'
          location: location
          properties: {
            description: 'Identifies the creation of large size or expensive VMs (with GPUs or with a large number of virtual CPUs) in Azure.\nAn adversary may create new or update existing virtual machines to evade defenses or use them for cryptomining purposes.\nFor Windows/Linux Vm Sizes, see https://docs.microsoft.com/azure/virtual-machines/windows/sizes \nAzure VM Naming Conventions, see https://docs.microsoft.com/azure/virtual-machines/vm-naming-conventions'
            displayName: 'Creation of expensive computes in Azure'
            enabled: false
            query: 'let tokens = dynamic(["416","208","192","128","120","96","80","72","64","48","44","40","nc12","nc24","nv24"]);\nlet operationList = dynamic(["microsoft.compute/virtualmachines/write", "microsoft.resources/deployments/write"]);\nAzureActivity\n| where OperationNameValue in~ (operationList)\n| where ActivityStatusValue startswith "Accept"\n| where Properties has \'vmSize\'\n| extend parsed_property= parse_json(tostring((parse_json(Properties).responseBody))).properties\n| extend vmSize = tostring((parsed_property.hardwareProfile).vmSize)\n| mv-apply token=tokens to typeof(string) on (where vmSize contains token)\n| extend ComputerName = tostring((parsed_property.osProfile).computerName)\n| project TimeGenerated, OperationNameValue, ActivityStatusValue, Caller, CallerIpAddress, ComputerName, vmSize\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n'
            queryFrequency: 'P1D'
            queryPeriod: 'P1D'
            severity: 'Low'
            suppressionDuration: 'PT1H'
            suppressionEnabled: false
            triggerOperator: 'GreaterThan'
            triggerThreshold: 1
            status: 'Available'
            requiredDataConnectors: [
              {
                connectorId: 'AzureActivity'
                dataTypes: [
                  'AzureActivity'
                ]
              }
            ]
            tactics: [
              'DefenseEvasion'
            ]
            techniques: [
              'T1578'
            ]
            entityMappings: [
              {
                fieldMappings: [
                  {
                    columnName: 'Caller'
                    identifier: 'FullName'
                  }
                  {
                    columnName: 'Name'
                    identifier: 'Name'
                  }
                  {
                    columnName: 'UPNSuffix'
                    identifier: 'UPNSuffix'
                  }
                ]
                entityType: 'Account'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'ComputerName'
                    identifier: 'HostName'
                  }
                ]
                entityType: 'Host'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'CallerIpAddress'
                    identifier: 'Address'
                  }
                ]
                entityType: 'IP'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/AnalyticsRule-${last(split(analyticRuleObject5.analyticRuleId5,'/'))}'
          properties: {
            description: 'Azure Activity Analytics Rule 5'
            parentId: analyticRuleObject5.analyticRuleId5
            contentId: analyticRuleObject5._analyticRulecontentId5
            kind: 'AnalyticsRule'
            version: analyticRuleObject5.analyticRuleVersion5
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: analyticRuleObject5._analyticRulecontentId5
    contentKind: 'AnalyticsRule'
    displayName: 'Creation of expensive computes in Azure'
    contentProductId: analyticRuleObject5._analyticRulecontentProductId5
    id: analyticRuleObject5._analyticRulecontentProductId5
    version: analyticRuleObject5.analyticRuleVersion5
  }
  dependsOn: [
contentPackage
  ]
}

resource analyticRuleObject6_analyticRuleTemplateSpec6 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: analyticRuleObject6.analyticRuleTemplateSpecName6
  location: location
  properties: {
    description: 'Granting_Permissions_To_Account_detection_AnalyticalRules Analytics Rule with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: analyticRuleObject6.analyticRuleVersion6
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.SecurityInsights/AlertRuleTemplates'
          name: analyticRuleObject6._analyticRulecontentId6
          apiVersion: '2023-02-01-preview'
          kind: 'Scheduled'
          location: location
          properties: {
            description: 'Identifies IPs from which users grant access to other users on Azure resources and alerts when a previously unseen source IP address is used.'
            displayName: 'Suspicious granting of permissions to an account'
            enabled: false
            query: 'let starttime = 14d;\nlet endtime = 1d;\n// The number of operations above which an IP address is considered an unusual source of role assignment operations\nlet alertOperationThreshold = 5;\nlet AzureBuiltInRole = externaldata(Role:string,RoleDescription:string,ID:string) [@"https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Sample%20Data/Feeds/AzureBuiltInRole.csv"] with (format="csv", ignoreFirstRecord=True);\nlet createRoleAssignmentActivity = AzureActivity\n| where OperationNameValue =~ "microsoft.authorization/roleassignments/write";\nlet RoleAssignedActivity = createRoleAssignmentActivity \n| where TimeGenerated between (ago(starttime) .. ago(endtime))\n| summarize count() by CallerIpAddress, Caller, bin(TimeGenerated, 1d)\n| where count_ >= alertOperationThreshold\n// Returns all the records from the right side that don\'t have matches from the left.\n| join kind = rightanti ( \ncreateRoleAssignmentActivity\n| where TimeGenerated > ago(endtime)\n| extend parsed_property = tostring(parse_json(Properties).requestbody)\n| extend PrincipalId = case(parsed_property has_cs \'PrincipalId\',parse_json(parsed_property).Properties.PrincipalId, parsed_property has_cs \'principalId\',parse_json(parsed_property).properties.principalId,"")\n| extend PrincipalType = case(parsed_property has_cs \'PrincipalType\',parse_json(parsed_property).Properties.PrincipalType, parsed_property has_cs \'principalType\',parse_json(parsed_property).properties.principalType, "")\n| extend Scope = case(parsed_property has_cs \'Scope\',parse_json(parsed_property).Properties.Scope, parsed_property has_cs \'scope\',parse_json(parsed_property).properties.scope,"")\n| extend RoleAddedDetails = case(parsed_property has_cs \'RoleDefinitionId\',parse_json(parsed_property).Properties.RoleDefinitionId,parsed_property has_cs \'roleDefinitionId\',parse_json(parsed_property).properties.roleDefinitionId,"")\n| summarize StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated), ActivityTimeStamp = make_set(TimeGenerated), ActivityStatusValue = make_set(ActivityStatusValue), CorrelationId = make_set(CorrelationId), ActivityCountByCallerIPAddress = count()  \nby ResourceId, CallerIpAddress, Caller, OperationNameValue, Resource, ResourceGroup, PrincipalId, PrincipalType, Scope, RoleAddedDetails\n) on CallerIpAddress, Caller\n| extend timestamp = StartTimeUtc, AccountCustomEntity = Caller, IPCustomEntity = CallerIpAddress;\nlet RoleAssignedActivitywithRoleDetails = RoleAssignedActivity\n| extend RoleAssignedID = tostring(split(RoleAddedDetails, "/")[-1])\n// Returns all matching records from left and right sides.\n| join kind = inner (AzureBuiltInRole \n) on $left.RoleAssignedID == $right.ID;\nlet CallerIPCountSummary = RoleAssignedActivitywithRoleDetails | summarize AssignmentCountbyCaller = count() by Caller, CallerIpAddress;\nlet RoleAssignedActivityWithCount = RoleAssignedActivitywithRoleDetails | join kind = inner (CallerIPCountSummary | project Caller, AssignmentCountbyCaller, CallerIpAddress) on Caller, CallerIpAddress;\nRoleAssignedActivityWithCount\n| summarize arg_max(StartTimeUtc, *) by PrincipalId, RoleAssignedID\n// \tReturns all the records from the left side and only matching records from the right side.\n| join kind = leftouter( IdentityInfo\n| summarize arg_max(TimeGenerated, *) by AccountObjectId\n) on $left.PrincipalId == $right.AccountObjectId\n// Check if assignment count is greater than the threshold.\n| where AssignmentCountbyCaller >= alertOperationThreshold\n| project ActivityTimeStamp, OperationNameValue, Caller, CallerIpAddress, PrincipalId, RoleAssignedID, RoleAddedDetails, Role, RoleDescription, AccountUPN, AccountCreationTime, GroupMembership, UserType, ActivityStatusValue, ResourceGroup, PrincipalType, Scope, CorrelationId, timestamp, AccountCustomEntity, IPCustomEntity, AssignmentCountbyCaller\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n'
            queryFrequency: 'P1D'
            queryPeriod: 'P14D'
            severity: 'Medium'
            suppressionDuration: 'PT1H'
            suppressionEnabled: false
            triggerOperator: 'GreaterThan'
            triggerThreshold: 0
            status: 'Available'
            requiredDataConnectors: [
              {
                connectorId: 'AzureActivity'
                dataTypes: [
                  'AzureActivity'
                ]
              }
              {
                connectorId: 'BehaviorAnalytics'
                dataTypes: [
                  'IdentityInfo'
                ]
              }
            ]
            tactics: [
              'Persistence'
              'PrivilegeEscalation'
            ]
            techniques: [
              'T1098'
              'T1548'
            ]
            entityMappings: [
              {
                fieldMappings: [
                  {
                    columnName: 'Caller'
                    identifier: 'FullName'
                  }
                  {
                    columnName: 'Name'
                    identifier: 'Name'
                  }
                  {
                    columnName: 'UPNSuffix'
                    identifier: 'UPNSuffix'
                  }
                ]
                entityType: 'Account'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'CallerIpAddress'
                    identifier: 'Address'
                  }
                ]
                entityType: 'IP'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/AnalyticsRule-${last(split(analyticRuleObject6.analyticRuleId6,'/'))}'
          properties: {
            description: 'Azure Activity Analytics Rule 6'
            parentId: analyticRuleObject6.analyticRuleId6
            contentId: analyticRuleObject6._analyticRulecontentId6
            kind: 'AnalyticsRule'
            version: analyticRuleObject6.analyticRuleVersion6
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: analyticRuleObject6._analyticRulecontentId6
    contentKind: 'AnalyticsRule'
    displayName: 'Suspicious granting of permissions to an account'
    contentProductId: analyticRuleObject6._analyticRulecontentProductId6
    id: analyticRuleObject6._analyticRulecontentProductId6
    version: analyticRuleObject6.analyticRuleVersion6
  }
  dependsOn: [
contentPackage
  ]
}

resource analyticRuleObject7_analyticRuleTemplateSpec7 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: analyticRuleObject7.analyticRuleTemplateSpecName7
  location: location
  properties: {
    description: 'NRT-AADHybridHealthADFSNewServer_AnalyticalRules Analytics Rule with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: analyticRuleObject7.analyticRuleVersion7
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.SecurityInsights/AlertRuleTemplates'
          name: analyticRuleObject7._analyticRulecontentId7
          apiVersion: '2023-02-01-preview'
          kind: 'NRT'
          location: location
          properties: {
            description: 'This detection uses AzureActivity logs (Administrative category) to identify the creation or update of a server instance in an Microsoft Entra ID Hybrid Health AD FS service.\nA threat actor can create a new AD Health ADFS service and create a fake server instance to spoof AD FS signing logs. There is no need to compromise an on-premises AD FS server.\nThis can be done programmatically via HTTP requests to Azure. More information in this blog: https://o365blog.com/post/hybridhealthagent/'
            displayName: 'NRT Microsoft Entra ID Hybrid Health AD FS New Server'
            enabled: false
            query: 'AzureActivity\n| where CategoryValue =~ \'Administrative\'\n| where ResourceProviderValue =~ \'Microsoft.ADHybridHealthService\'\n| where _ResourceId has \'AdFederationService\'\n| where OperationNameValue =~ \'Microsoft.ADHybridHealthService/services/servicemembers/action\'\n| extend claimsJson = parse_json(Claims)\n| extend AppId = tostring(claimsJson.appid), AccountName = tostring(claimsJson.name), Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n| project-away claimsJson\n'
            severity: 'Medium'
            suppressionDuration: 'PT1H'
            suppressionEnabled: false
            status: 'Available'
            requiredDataConnectors: [
              {
                connectorId: 'AzureActivity'
                dataTypes: [
                  'AzureActivity'
                ]
              }
            ]
            tactics: [
              'DefenseEvasion'
            ]
            techniques: [
              'T1578'
            ]
            entityMappings: [
              {
                fieldMappings: [
                  {
                    columnName: 'Caller'
                    identifier: 'FullName'
                  }
                  {
                    columnName: 'Name'
                    identifier: 'Name'
                  }
                  {
                    columnName: 'UPNSuffix'
                    identifier: 'UPNSuffix'
                  }
                ]
                entityType: 'Account'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'CallerIpAddress'
                    identifier: 'Address'
                  }
                ]
                entityType: 'IP'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/AnalyticsRule-${last(split(analyticRuleObject7.analyticRuleId7,'/'))}'
          properties: {
            description: 'Azure Activity Analytics Rule 7'
            parentId: analyticRuleObject7.analyticRuleId7
            contentId: analyticRuleObject7._analyticRulecontentId7
            kind: 'AnalyticsRule'
            version: analyticRuleObject7.analyticRuleVersion7
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: analyticRuleObject7._analyticRulecontentId7
    contentKind: 'AnalyticsRule'
    displayName: 'NRT Microsoft Entra ID Hybrid Health AD FS New Server'
    contentProductId: analyticRuleObject7._analyticRulecontentProductId7
    id: analyticRuleObject7._analyticRulecontentProductId7
    version: analyticRuleObject7.analyticRuleVersion7
  }
  dependsOn: [
contentPackage
  ]
}

resource analyticRuleObject8_analyticRuleTemplateSpec8 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: analyticRuleObject8.analyticRuleTemplateSpecName8
  location: location
  properties: {
    description: 'NRT_Creation_of_Expensive_Computes_in_Azure_AnalyticalRules Analytics Rule with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: analyticRuleObject8.analyticRuleVersion8
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.SecurityInsights/AlertRuleTemplates'
          name: analyticRuleObject8._analyticRulecontentId8
          apiVersion: '2023-02-01-preview'
          kind: 'NRT'
          location: location
          properties: {
            description: 'Identifies the creation of large size or expensive VMs (with GPUs or with a large number of virtual CPUs) in Azure.\nAn adversary may create new or update existing virtual machines to evade defenses or use them for cryptomining purposes.\nFor Windows/Linux Vm Sizes, see https://docs.microsoft.com/azure/virtual-machines/windows/sizes \nAzure VM Naming Conventions, see https://docs.microsoft.com/azure/virtual-machines/vm-naming-conventions'
            displayName: 'NRT Creation of expensive computes in Azure'
            enabled: false
            query: 'let tokens = dynamic(["416","208","192","128","120","96","80","72","64","48","44","40","nc12","nc24","nv24"]);\nlet operationList = dynamic(["microsoft.compute/virtualmachines/write", "microsoft.resources/deployments/write"]);\nAzureActivity\n| where OperationNameValue in~ (operationList)\n| where ActivityStatusValue startswith "Accept"\n| where Properties has \'vmSize\'\n| extend parsed_property= parse_json(tostring((parse_json(Properties).responseBody))).properties\n| extend vmSize = tostring((parsed_property.hardwareProfile).vmSize)\n| mv-apply token=tokens to typeof(string) on (where vmSize contains token)\n| extend ComputerName = tostring((parsed_property.osProfile).computerName)\n| project TimeGenerated, OperationNameValue, ActivityStatusValue, Caller, CallerIpAddress, ComputerName, vmSize\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n'
            severity: 'Medium'
            suppressionDuration: 'PT1H'
            suppressionEnabled: false
            status: 'Available'
            requiredDataConnectors: [
              {
                connectorId: 'AzureActivity'
                dataTypes: [
                  'AzureActivity'
                ]
              }
            ]
            tactics: [
              'DefenseEvasion'
            ]
            techniques: [
              'T1578'
            ]
            entityMappings: [
              {
                fieldMappings: [
                  {
                    columnName: 'Caller'
                    identifier: 'FullName'
                  }
                  {
                    columnName: 'Name'
                    identifier: 'Name'
                  }
                  {
                    columnName: 'UPNSuffix'
                    identifier: 'UPNSuffix'
                  }
                ]
                entityType: 'Account'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'ComputerName'
                    identifier: 'HostName'
                  }
                ]
                entityType: 'Host'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'CallerIpAddress'
                    identifier: 'Address'
                  }
                ]
                entityType: 'IP'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/AnalyticsRule-${last(split(analyticRuleObject8.analyticRuleId8,'/'))}'
          properties: {
            description: 'Azure Activity Analytics Rule 8'
            parentId: analyticRuleObject8.analyticRuleId8
            contentId: analyticRuleObject8._analyticRulecontentId8
            kind: 'AnalyticsRule'
            version: analyticRuleObject8.analyticRuleVersion8
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: analyticRuleObject8._analyticRulecontentId8
    contentKind: 'AnalyticsRule'
    displayName: 'NRT Creation of expensive computes in Azure'
    contentProductId: analyticRuleObject8._analyticRulecontentProductId8
    id: analyticRuleObject8._analyticRulecontentProductId8
    version: analyticRuleObject8.analyticRuleVersion8
  }
  dependsOn: [
contentPackage
  ]
}

resource analyticRuleObject9_analyticRuleTemplateSpec9 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: analyticRuleObject9.analyticRuleTemplateSpecName9
  location: location
  properties: {
    description: 'New-CloudShell-User_AnalyticalRules Analytics Rule with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: analyticRuleObject9.analyticRuleVersion9
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.SecurityInsights/AlertRuleTemplates'
          name: analyticRuleObject9._analyticRulecontentId9
          apiVersion: '2023-02-01-preview'
          kind: 'Scheduled'
          location: location
          properties: {
            description: 'Identifies when a user creates an Azure CloudShell for the first time.\nMonitor this activity to ensure only the expected users are using CloudShell.'
            displayName: 'New CloudShell User'
            enabled: false
            query: 'let match_window = 3m;\nAzureActivity\n| where ResourceGroup has "cloud-shell"\n| where (OperationNameValue =~ "Microsoft.Storage/storageAccounts/listKeys/action")\n| where ActivityStatusValue =~ "Success"\n| extend TimeKey = bin(TimeGenerated, match_window), AzureIP = CallerIpAddress\n| join kind = inner\n(AzureActivity\n| where ResourceGroup has "cloud-shell"\n| where (OperationNameValue =~ "Microsoft.Storage/storageAccounts/write")\n| extend TimeKey = bin(TimeGenerated, match_window), UserIP = CallerIpAddress\n) on Caller, TimeKey\n| summarize count() by TimeKey, Caller, ResourceGroup, SubscriptionId, TenantId, AzureIP, UserIP, HTTPRequest, Type, Properties, CategoryValue, OperationList = strcat(OperationNameValue, \' , \', OperationNameValue1)\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n'
            queryFrequency: 'P1D'
            queryPeriod: 'P1D'
            severity: 'Low'
            suppressionDuration: 'PT1H'
            suppressionEnabled: false
            triggerOperator: 'GreaterThan'
            triggerThreshold: 0
            status: 'Available'
            requiredDataConnectors: [
              {
                connectorId: 'AzureActivity'
                dataTypes: [
                  'AzureActivity'
                ]
              }
            ]
            tactics: [
              'Execution'
            ]
            techniques: [
              'T1059'
            ]
            entityMappings: [
              {
                fieldMappings: [
                  {
                    columnName: 'Caller'
                    identifier: 'FullName'
                  }
                  {
                    columnName: 'Name'
                    identifier: 'Name'
                  }
                  {
                    columnName: 'UPNSuffix'
                    identifier: 'UPNSuffix'
                  }
                ]
                entityType: 'Account'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'UserIP'
                    identifier: 'Address'
                  }
                ]
                entityType: 'IP'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/AnalyticsRule-${last(split(analyticRuleObject9.analyticRuleId9,'/'))}'
          properties: {
            description: 'Azure Activity Analytics Rule 9'
            parentId: analyticRuleObject9.analyticRuleId9
            contentId: analyticRuleObject9._analyticRulecontentId9
            kind: 'AnalyticsRule'
            version: analyticRuleObject9.analyticRuleVersion9
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: analyticRuleObject9._analyticRulecontentId9
    contentKind: 'AnalyticsRule'
    displayName: 'New CloudShell User'
    contentProductId: analyticRuleObject9._analyticRulecontentProductId9
    id: analyticRuleObject9._analyticRulecontentProductId9
    version: analyticRuleObject9.analyticRuleVersion9
  }
  dependsOn: [
contentPackage
  ]
}

resource analyticRuleObject10_analyticRuleTemplateSpec10 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: analyticRuleObject10.analyticRuleTemplateSpecName10
  location: location
  properties: {
    description: 'NewResourceGroupsDeployedTo_AnalyticalRules Analytics Rule with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: analyticRuleObject10.analyticRuleVersion10
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.SecurityInsights/AlertRuleTemplates'
          name: analyticRuleObject10._analyticRulecontentId10
          apiVersion: '2023-02-01-preview'
          kind: 'Scheduled'
          location: location
          properties: {
            description: 'Identifies when a rare Resource and ResourceGroup deployment occurs by a previously unseen caller.'
            displayName: 'Suspicious Resource deployment'
            enabled: false
            query: '// Add or remove operation names below as per your requirements. For operations lists, please refer to https://learn.microsoft.com/en-us/Azure/role-based-access-control/resource-provider-operations#all\nlet szOperationNames = dynamic(["Microsoft.Compute/virtualMachines/write", "Microsoft.Resources/deployments/write", "Microsoft.Resources/subscriptions/resourceGroups/write"]);\nlet starttime = 14d;\nlet endtime = 1d;\nlet RareCaller = AzureActivity\n| where TimeGenerated between (ago(starttime) .. ago(endtime))\n| where OperationNameValue in~ (szOperationNames)\n| summarize count() by CallerIpAddress, Caller, OperationNameValue, bin(TimeGenerated,1d)\n// Returns all the records from the right side that don\'t have matches from the left.\n| join kind=rightantisemi (\nAzureActivity\n| where TimeGenerated > ago(endtime)\n| where OperationNameValue in~ (szOperationNames)\n| summarize StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated), ActivityTimeStamp = make_set(TimeGenerated,100), ActivityStatusValue = make_set(ActivityStatusValue,100), CorrelationIds = make_set(CorrelationId,100), ResourceGroups = make_set(ResourceGroup,100), ResourceIds = make_set(_ResourceId,100), ActivityCountByCallerIPAddress = count()\nby CallerIpAddress, Caller, OperationNameValue) on CallerIpAddress, Caller, OperationNameValue;\nRareCaller\n| extend Name = iif(Caller has \'@\',tostring(split(Caller,\'@\',0)[0]),"")\n| extend UPNSuffix = iif(Caller has \'@\',tostring(split(Caller,\'@\',1)[0]),"")\n| extend AadUserId = iif(Caller !has \'@\',Caller,"")\n'
            queryFrequency: 'P1D'
            queryPeriod: 'P14D'
            severity: 'Low'
            suppressionDuration: 'PT1H'
            suppressionEnabled: false
            triggerOperator: 'GreaterThan'
            triggerThreshold: 0
            status: 'Available'
            requiredDataConnectors: [
              {
                connectorId: 'AzureActivity'
                dataTypes: [
                  'AzureActivity'
                ]
              }
            ]
            tactics: [
              'Impact'
            ]
            techniques: [
              'T1496'
            ]
            entityMappings: [
              {
                fieldMappings: [
                  {
                    columnName: 'Caller'
                    identifier: 'FullName'
                  }
                  {
                    columnName: 'Name'
                    identifier: 'Name'
                  }
                  {
                    columnName: 'UPNSuffix'
                    identifier: 'UPNSuffix'
                  }
                ]
                entityType: 'Account'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'AadUserId'
                    identifier: 'AadUserId'
                  }
                ]
                entityType: 'Account'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'CallerIpAddress'
                    identifier: 'Address'
                  }
                ]
                entityType: 'IP'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/AnalyticsRule-${last(split(analyticRuleObject10.analyticRuleId10,'/'))}'
          properties: {
            description: 'Azure Activity Analytics Rule 10'
            parentId: analyticRuleObject10.analyticRuleId10
            contentId: analyticRuleObject10._analyticRulecontentId10
            kind: 'AnalyticsRule'
            version: analyticRuleObject10.analyticRuleVersion10
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: analyticRuleObject10._analyticRulecontentId10
    contentKind: 'AnalyticsRule'
    displayName: 'Suspicious Resource deployment'
    contentProductId: analyticRuleObject10._analyticRulecontentProductId10
    id: analyticRuleObject10._analyticRulecontentProductId10
    version: analyticRuleObject10.analyticRuleVersion10
  }
  dependsOn: [
contentPackage
  ]
}

resource analyticRuleObject11_analyticRuleTemplateSpec11 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: analyticRuleObject11.analyticRuleTemplateSpecName11
  location: location
  properties: {
    description: 'RareOperations_AnalyticalRules Analytics Rule with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: analyticRuleObject11.analyticRuleVersion11
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.SecurityInsights/AlertRuleTemplates'
          name: analyticRuleObject11._analyticRulecontentId11
          apiVersion: '2023-02-01-preview'
          kind: 'Scheduled'
          location: location
          properties: {
            description: 'This query looks for a few sensitive subscription-level events based on Azure Activity Logs. For example, this monitors for the operation name \'Create or Update Snapshot\', which is used for creating backups but could be misused by attackers to dump hashes or extract sensitive information from the disk.'
            displayName: 'Rare subscription-level operations in Azure'
            enabled: false
            query: 'let starttime = 14d;\nlet endtime = 1d;\n// The number of operations above which an IP address is considered an unusual source of role assignment operations\nlet alertOperationThreshold = 5;\n// Add or remove operation names below as per your requirements. For operations lists, please refer to https://learn.microsoft.com/en-us/Azure/role-based-access-control/resource-provider-operations#all\nlet SensitiveOperationList =  dynamic(["microsoft.compute/snapshots/write", "microsoft.network/networksecuritygroups/write", "microsoft.storage/storageaccounts/listkeys/action"]);\nlet SensitiveActivity = AzureActivity\n| where OperationNameValue in~ (SensitiveOperationList) or OperationNameValue hassuffix "listkeys/action"\n| where ActivityStatusValue =~ "Success";\nSensitiveActivity\n| where TimeGenerated between (ago(starttime) .. ago(endtime))\n| summarize count() by CallerIpAddress, Caller, OperationNameValue, bin(TimeGenerated,1d)\n| where count_ >= alertOperationThreshold\n// Returns all the records from the right side that don\'t have matches from the left\n| join kind = rightanti (\nSensitiveActivity\n| where TimeGenerated >= ago(endtime)\n| summarize StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated), ActivityTimeStamp = make_list(TimeGenerated), ActivityStatusValue = make_list(ActivityStatusValue), CorrelationIds = make_list(CorrelationId), ResourceGroups = make_list(ResourceGroup), ResourceIds = make_list(_ResourceId), ActivityCountByCallerIPAddress = count()\nby CallerIpAddress, Caller, OperationNameValue\n| where ActivityCountByCallerIPAddress >= alertOperationThreshold\n) on CallerIpAddress, Caller, OperationNameValue\n| extend Name = tostring(split(Caller,\'@\',0)[0]), UPNSuffix = tostring(split(Caller,\'@\',1)[0])\n'
            queryFrequency: 'P1D'
            queryPeriod: 'P14D'
            severity: 'Low'
            suppressionDuration: 'PT1H'
            suppressionEnabled: false
            triggerOperator: 'GreaterThan'
            triggerThreshold: 0
            status: 'Available'
            requiredDataConnectors: [
              {
                connectorId: 'AzureActivity'
                dataTypes: [
                  'AzureActivity'
                ]
              }
            ]
            tactics: [
              'CredentialAccess'
              'Persistence'
            ]
            techniques: [
              'T1003'
              'T1098'
            ]
            entityMappings: [
              {
                fieldMappings: [
                  {
                    columnName: 'Caller'
                    identifier: 'FullName'
                  }
                  {
                    columnName: 'Name'
                    identifier: 'Name'
                  }
                  {
                    columnName: 'UPNSuffix'
                    identifier: 'UPNSuffix'
                  }
                ]
                entityType: 'Account'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'CallerIpAddress'
                    identifier: 'Address'
                  }
                ]
                entityType: 'IP'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/AnalyticsRule-${last(split(analyticRuleObject11.analyticRuleId11,'/'))}'
          properties: {
            description: 'Azure Activity Analytics Rule 11'
            parentId: analyticRuleObject11.analyticRuleId11
            contentId: analyticRuleObject11._analyticRulecontentId11
            kind: 'AnalyticsRule'
            version: analyticRuleObject11.analyticRuleVersion11
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: analyticRuleObject11._analyticRulecontentId11
    contentKind: 'AnalyticsRule'
    displayName: 'Rare subscription-level operations in Azure'
    contentProductId: analyticRuleObject11._analyticRulecontentProductId11
    id: analyticRuleObject11._analyticRulecontentProductId11
    version: analyticRuleObject11.analyticRuleVersion11
  }
  dependsOn: [
contentPackage
  ]
}

resource analyticRuleObject12_analyticRuleTemplateSpec12 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: analyticRuleObject12.analyticRuleTemplateSpecName12
  location: location
  properties: {
    description: 'TimeSeriesAnomaly_Mass_Cloud_Resource_Deletions_AnalyticalRules Analytics Rule with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: analyticRuleObject12.analyticRuleVersion12
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.SecurityInsights/AlertRuleTemplates'
          name: analyticRuleObject12._analyticRulecontentId12
          apiVersion: '2023-02-01-preview'
          kind: 'Scheduled'
          location: location
          properties: {
            description: 'This query generates the baseline pattern of cloud resource deletions by an individual and generates an anomaly when any unusual spike is detected. These anomalies from unusual or privileged users could be an indication of a cloud infrastructure takedown by an adversary.'
            displayName: 'Mass Cloud resource deletions Time Series Anomaly'
            enabled: false
            query: 'let starttime = 14d;\nlet endtime = 1d;\nlet timeframe = 1d;\nlet TotalEventsThreshold = 25;\nlet TimeSeriesData = AzureActivity \n| where TimeGenerated between (startofday(ago(starttime))..startofday(now())) \n| where OperationNameValue endswith "delete" \n| project TimeGenerated, Caller \n| make-series Total = count() on TimeGenerated from startofday(ago(starttime)) to startofday(now()) step timeframe by Caller;\nTimeSeriesData \n| extend (anomalies, score, baseline) = series_decompose_anomalies(Total, 3, -1, \'linefit\') \n| mv-expand Total to typeof(double), TimeGenerated to typeof(datetime), anomalies to typeof(double), score to typeof(double), baseline to typeof(long) \n| where TimeGenerated >= startofday(ago(endtime)) \n| where anomalies > 0 \n| project Caller, TimeGenerated, Total, baseline, anomalies, score \n| where Total > TotalEventsThreshold and baseline > 0 \n| join (AzureActivity \n| where TimeGenerated > startofday(ago(endtime)) \n| where OperationNameValue endswith "delete" \n| summarize count(), make_set(OperationNameValue,100), make_set(_ResourceId,100) by bin(TimeGenerated, timeframe), Caller ) on TimeGenerated, Caller \n| extend Name = iif(Caller has \'@\',tostring(split(Caller,\'@\',0)[0]),"")\n| extend UPNSuffix = iif(Caller has \'@\',tostring(split(Caller,\'@\',1)[0]),"")\n| extend AadUserId = iif(Caller !has \'@\',Caller,"")\n'
            queryFrequency: 'P1D'
            queryPeriod: 'P14D'
            severity: 'Medium'
            suppressionDuration: 'PT1H'
            suppressionEnabled: false
            triggerOperator: 'GreaterThan'
            triggerThreshold: 0
            status: 'Available'
            requiredDataConnectors: [
              {
                connectorId: 'AzureActivity'
                dataTypes: [
                  'AzureActivity'
                ]
              }
            ]
            tactics: [
              'Impact'
            ]
            techniques: [
              'T1485'
            ]
            entityMappings: [
              {
                fieldMappings: [
                  {
                    columnName: 'Caller'
                    identifier: 'FullName'
                  }
                  {
                    columnName: 'Name'
                    identifier: 'Name'
                  }
                  {
                    columnName: 'UPNSuffix'
                    identifier: 'UPNSuffix'
                  }
                ]
                entityType: 'Account'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'AadUserId'
                    identifier: 'AadUserId'
                  }
                ]
                entityType: 'Account'
              }
            ]
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/AnalyticsRule-${last(split(analyticRuleObject12.analyticRuleId12,'/'))}'
          properties: {
            description: 'Azure Activity Analytics Rule 12'
            parentId: analyticRuleObject12.analyticRuleId12
            contentId: analyticRuleObject12._analyticRulecontentId12
            kind: 'AnalyticsRule'
            version: analyticRuleObject12.analyticRuleVersion12
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: analyticRuleObject12._analyticRulecontentId12
    contentKind: 'AnalyticsRule'
    displayName: 'Mass Cloud resource deletions Time Series Anomaly'
    contentProductId: analyticRuleObject12._analyticRulecontentProductId12
    id: analyticRuleObject12._analyticRulecontentProductId12
    version: analyticRuleObject12.analyticRuleVersion12
  }
  dependsOn: [
contentPackage
  ]
}

resource analyticRuleObject13_analyticRuleTemplateSpec13 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: analyticRuleObject13.analyticRuleTemplateSpecName13
  location: location
  properties: {
    description: 'SubscriptionMigration_AnalyticalRules Analytics Rule with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: analyticRuleObject13.analyticRuleVersion13
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.SecurityInsights/AlertRuleTemplates'
          name: analyticRuleObject13._analyticRulecontentId13
          apiVersion: '2023-02-01-preview'
          kind: 'Scheduled'
          location: location
          properties: {
            description: 'This detection uses AzureActivity logs (Security category) to identify when a subscription is moved to another tenant.\nA threat actor may move a subscription into their own tenant to circumvent local resource deployment and logging policies.\nOnce moved, threat actors may deploy resources and perform malicious activities such as crypto mining.\nThis is a technique known as "subscription hijacking". More information can be found here: https://techcommunity.microsoft.com/t5/microsoft-365-defender-blog/hunt-for-compromised-azure-subscriptions-using-microsoft/ba-p/3607121'
            displayName: 'Subscription moved to another tenant'
            enabled: false
            query: 'let queryFrequency = 5m;\nlet eventCapture = "moved from tenant ([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}) to tenant ([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})";\nAzureActivity\n| where ingestion_time() > ago(queryFrequency)\n| where CategoryValue =~ "Security"\n| where OperationNameValue =~ "Microsoft.Subscription/updateTenant/action"\n| extend Properties_d = coalesce(parse_json(Properties), Properties_d)\n| where isnotempty(Properties_d)\n| extend Summary = tostring(Properties_d.message)\n| extend EventCapture = extract_all(eventCapture, Summary)\n| extend SourceTenantId = iff(isnotempty(EventCapture), EventCapture[0][0], "")\n| extend DestinationTenantId = iff(isnotempty(EventCapture), EventCapture[0][1], "")\n| extend \n    Name = split(Caller, "@", 0)[0],\n    UPNSuffix = split(Caller, "@", 1)[0]\n'
            queryFrequency: 'PT5M'
            queryPeriod: 'PT20M'
            severity: 'Low'
            suppressionDuration: 'PT1H'
            suppressionEnabled: false
            triggerOperator: 'GreaterThan'
            triggerThreshold: 0
            status: 'Available'
            requiredDataConnectors: [
              {
                connectorId: 'AzureActivity'
                dataTypes: [
                  'AzureActivity'
                ]
              }
            ]
            tactics: [
              'Impact'
            ]
            techniques: [
              'T1496'
            ]
            entityMappings: [
              {
                fieldMappings: [
                  {
                    columnName: '_ResourceId'
                    identifier: 'ResourceId'
                  }
                ]
                entityType: 'AzureResource'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'Caller'
                    identifier: 'FullName'
                  }
                  {
                    columnName: 'Name'
                    identifier: 'Name'
                  }
                  {
                    columnName: 'UPNSuffix'
                    identifier: 'UPNSuffix'
                  }
                ]
                entityType: 'Account'
              }
            ]
            eventGroupingSettings: {
              aggregationKind: 'SingleAlert'
            }
            customDetails: {
              DestinationTenantId: 'DestinationTenantId'
              SourceTenantId: 'SourceTenantId'
            }
            alertDetailsOverride: {
              alertDescriptionFormat: 'The user {{Caller}} moved a subscription:\n\n{{Summary}}\n\nIf this was not expected, it may indicate a subscription hijacking event.\n'
              alertDisplayNameFormat: 'Subscription {{SubscriptionId}} changed tenants\n'
            }
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/AnalyticsRule-${last(split(analyticRuleObject13.analyticRuleId13,'/'))}'
          properties: {
            description: 'Azure Activity Analytics Rule 13'
            parentId: analyticRuleObject13.analyticRuleId13
            contentId: analyticRuleObject13._analyticRulecontentId13
            kind: 'AnalyticsRule'
            version: analyticRuleObject13.analyticRuleVersion13
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: analyticRuleObject13._analyticRulecontentId13
    contentKind: 'AnalyticsRule'
    displayName: 'Subscription moved to another tenant'
    contentProductId: analyticRuleObject13._analyticRulecontentProductId13
    id: analyticRuleObject13._analyticRulecontentProductId13
    version: analyticRuleObject13.analyticRuleVersion13
  }
  dependsOn: [
contentPackage
  ]
}

resource analyticRuleObject14_analyticRuleTemplateSpec14 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: analyticRuleObject14.analyticRuleTemplateSpecName14
  location: location
  properties: {
    description: 'Machine_Learning_Creation_AnalyticalRules Analytics Rule with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: analyticRuleObject14.analyticRuleVersion14
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.SecurityInsights/AlertRuleTemplates'
          name: analyticRuleObject14._analyticRulecontentId14
          apiVersion: '2023-02-01-preview'
          kind: 'Scheduled'
          location: location
          properties: {
            description: 'Shows the most prevalent users who perform write operations on Azure Machine Learning resources. List the common source IP address for each of those accounts. If an operation is not from those IP addresses, it may be worthy of investigation.'
            displayName: 'Azure Machine Learning Write Operations'
            enabled: false
            query: 'AzureActivity\n| where ResourceProviderValue == "MICROSOFT.MACHINELEARNINGSERVICES"  // Filter activities related to Microsoft Machine Learning Services\n| extend SCOPE = tostring(parse_json(Authorization).scope)  // Parse Authorization scope as string\n| extend subname = split(Hierarchy, "/")  // Split Hierarchy to extract Subscription Name and ID\n| extend [\'Subscription Name\'] = subname[-2], [\'Subscription ID\'] = subname[-1]  // Extract Subscription Name and ID\n| extend Properties = parse_json(Properties)  // Parse Properties as JSON\n| extend Properties_entity = tostring(Properties.entity)  // Cast Properties.entity to string\n| where isnotempty(Properties_entity)  // Filter activities where Properties.entity is not empty\n// | where Properties_entity contains "deepseek"  // Filter activities where Properties.entity contains "deepseek"\n| where OperationNameValue contains "write"  // Filter activities where OperationNameValue contains "write"\n| where OperationNameValue !contains "MICROSOFT.AUTHORIZATION/ROLEASSIGNMENTS/WRITE"  // Exclude role assignments\n| extend LLM = tostring(split(Properties_entity, "/")[-1])  // Extract the last segment of Properties_entity and cast it to string\n| distinct TimeGenerated, tostring([\'Subscription Name\']), ResourceGroup, tostring([\'Subscription ID\']), Caller, CallerIpAddress, OperationNameValue, LLM, _ResourceId  // Select distinct relevant fields for output\n'
            queryFrequency: 'P1D'
            queryPeriod: 'P1D'
            severity: 'Low'
            suppressionDuration: 'PT1H'
            suppressionEnabled: false
            triggerOperator: 'GreaterThan'
            triggerThreshold: 0
            status: 'Available'
            requiredDataConnectors: [
              {
                connectorId: 'AzureActivity'
                dataTypes: [
                  'AzureActivity'
                ]
              }
            ]
            tactics: [
              'InitialAccess'
              'Execution'
              'Impact'
            ]
            techniques: [
              'T1078'
              'T1059'
              'T1496'
            ]
            entityMappings: [
              {
                fieldMappings: [
                  {
                    columnName: 'Caller'
                    identifier: 'Name'
                  }
                ]
                entityType: 'Account'
              }
              {
                fieldMappings: [
                  {
                    columnName: 'CallerIpAddress'
                    identifier: 'Address'
                  }
                ]
                entityType: 'IP'
              }
              {
                fieldMappings: [
                  {
                    columnName: '_ResourceId'
                    identifier: 'ResourceId'
                  }
                ]
                entityType: 'AzureResource'
              }
            ]
            eventGroupingSettings: {
              aggregationKind: 'SingleAlert'
            }
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/AnalyticsRule-${last(split(analyticRuleObject14.analyticRuleId14,'/'))}'
          properties: {
            description: 'Azure Activity Analytics Rule 14'
            parentId: analyticRuleObject14.analyticRuleId14
            contentId: analyticRuleObject14._analyticRulecontentId14
            kind: 'AnalyticsRule'
            version: analyticRuleObject14.analyticRuleVersion14
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: analyticRuleObject14._analyticRulecontentId14
    contentKind: 'AnalyticsRule'
    displayName: 'Azure Machine Learning Write Operations'
    contentProductId: analyticRuleObject14._analyticRulecontentProductId14
    id: analyticRuleObject14._analyticRulecontentProductId14
    version: analyticRuleObject14.analyticRuleVersion14
  }
  dependsOn: [
contentPackage
  ]
}

resource workbookTemplateSpec1 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: workbookTemplateSpecName1
  location: location
  properties: {
    description: 'AzureActivity Workbook with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: workbookVersion1
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.Insights/workbooks'
          name: workbookContentId1
          location: location
          kind: 'shared'
          apiVersion: '2021-08-01'
          metadata: {
            description: 'Gain extensive insight into your organization\'s Azure Activity by analyzing, and correlating all user operations and events.\nYou can learn about all user operations, trends, and anomalous changes over time.\nThis workbook gives you the ability to drill down into caller activities and summarize detected failure and warning events.'
          }
          properties: {
            displayName: workbook1Name
            serializedData: '{"version":"Notebook/1.0","items":[{"type":9,"content":{"version":"KqlParameterItem/1.0","query":"","parameters":[{"id":"52bfbd84-1639-480c-bda5-bfc87fd81832","version":"KqlParameterItem/1.0","name":"TimeRange","type":4,"isRequired":true,"value":{"durationMs":604800000},"typeSettings":{"selectableValues":[{"durationMs":300000},{"durationMs":900000},{"durationMs":1800000},{"durationMs":3600000},{"durationMs":14400000},{"durationMs":43200000},{"durationMs":86400000},{"durationMs":172800000},{"durationMs":259200000},{"durationMs":604800000},{"durationMs":1209600000},{"durationMs":2419200000},{"durationMs":2592000000},{"durationMs":5184000000},{"durationMs":7776000000}]}},{"id":"eeb5dcf9-e898-46af-9c12-d91d97e13cd3","version":"KqlParameterItem/1.0","name":"Caller","type":2,"isRequired":true,"multiSelect":true,"quote":"\'","delimiter":",","query":"AzureActivity\\r\\n| summarize by Caller","value":["value::all"],"typeSettings":{"additionalResourceOptions":["value::all"],"selectAllValue":"All"},"timeContext":{"durationMs":0},"timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces"},{"id":"46375a76-7ae1-4d7e-9082-4191531198a9","version":"KqlParameterItem/1.0","name":"ResourceGroup","type":2,"isRequired":true,"multiSelect":true,"quote":"\'","delimiter":",","query":"AzureActivity\\r\\n| summarize by ResourceGroup","value":["value::all"],"typeSettings":{"resourceTypeFilter":{"microsoft.resources/resourcegroups":true},"additionalResourceOptions":["value::all"],"selectAllValue":"All"},"timeContext":{"durationMs":0},"timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces"}],"style":"pills","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces"},"name":"parameters - 2"},{"type":3,"content":{"version":"KqlItem/1.0","query":"let data = AzureActivity\\r\\n| where \\"{Caller:lable}\\" == \\"All\\" or \\"{Caller:lable}\\" == \\"All\\" or Caller in ({Caller})\\r\\n| where \\"{ResourceGroup:lable}\\" == \\"All\\" or \\"{ResourceGroup:lable}\\" == \\"All\\" or ResourceGroup in ({ResourceGroup});\\r\\ndata\\r\\n| summarize Count = count() by ResourceGroup\\r\\n| join kind = fullouter (datatable(ResourceGroup:string)[\'Medium\', \'high\', \'low\']) on ResourceGroup\\r\\n| project ResourceGroup = iff(ResourceGroup == \'\', ResourceGroup1, ResourceGroup), Count = iff(ResourceGroup == \'\', 0, Count)\\r\\n| join kind = inner (data\\r\\n | make-series Trend = count() default = 0 on TimeGenerated from {TimeRange:start} to {TimeRange:end} step {TimeRange:grain} by ResourceGroup)\\r\\n on ResourceGroup\\r\\n| project-away ResourceGroup1, TimeGenerated\\r\\n| extend ResourceGroups = ResourceGroup\\r\\n| union (\\r\\n data \\r\\n | summarize Count = count() \\r\\n | extend jkey = 1\\r\\n | join kind=inner (data\\r\\n | make-series Trend = count() default = 0 on TimeGenerated from {TimeRange:start} to {TimeRange:end} step {TimeRange:grain}\\r\\n | extend jkey = 1) on jkey\\r\\n | extend ResourceGroup = \'All\', ResourceGroups = \'*\' \\r\\n)\\r\\n| order by Count desc\\r\\n| take 10","size":4,"exportToExcelOptions":"visible","title":"Top 10 active resource groups","timeContext":{"durationMs":0},"timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"tiles","tileSettings":{"titleContent":{"columnMatch":"ResourceGroup","formatter":1,"formatOptions":{"showIcon":true}},"leftContent":{"columnMatch":"Count","formatter":12,"formatOptions":{"palette":"auto","showIcon":true},"numberFormat":{"unit":17,"options":{"maximumSignificantDigits":3,"maximumFractionDigits":2}}},"secondaryContent":{"columnMatch":"Trend","formatter":9,"formatOptions":{"palette":"blueOrange","showIcon":true}},"showBorder":false}},"name":"query - 3"},{"type":3,"content":{"version":"KqlItem/1.0","query":"AzureActivity\\r\\n| where \\"{Caller:lable}\\" == \\"All\\" or Caller in ({Caller})\\r\\n| where \\"{ResourceGroup:lable}\\" == \\"All\\" or ResourceGroup in ({ResourceGroup})\\r\\n| summarize deletions = countif(OperationNameValue hassuffix \\"delete\\"), creations = countif(OperationNameValue hassuffix \\"write\\"), updates = countif(OperationNameValue hassuffix \\"write\\"), Activities = count(OperationNameValue) by bin_at(TimeGenerated, 1h, now())\\r\\n","size":0,"exportToExcelOptions":"visible","title":"Activities over time","color":"gray","timeContext":{"durationMs":0},"timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"linechart","graphSettings":{"type":0}},"name":"query - 1"},{"type":3,"content":{"version":"KqlItem/1.0","query":"AzureActivity\\r\\n| where \\"{Caller:lable}\\" == \\"All\\" or Caller in ({Caller})\\r\\n| where \\"{ResourceGroup:lable}\\" == \\"All\\" or ResourceGroup in ({ResourceGroup})\\r\\n| summarize deletions = countif(OperationNameValue hassuffix \\"Delete\\"), creations = countif(OperationNameValue hassuffix \\"write\\"), updates = countif(OperationNameValue hassuffix \\"write\\"), Activities = count() by Caller\\r\\n","size":1,"exportToExcelOptions":"visible","title":"Caller activities","timeContext":{"durationMs":0},"timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","gridSettings":{"formatters":[{"columnMatch":"Caller","formatter":0,"formatOptions":{"showIcon":true}},{"columnMatch":"deletions","formatter":4,"formatOptions":{"showIcon":true,"aggregation":"Count"}},{"columnMatch":"creations","formatter":4,"formatOptions":{"palette":"purple","showIcon":true,"aggregation":"Count"}},{"columnMatch":"updates","formatter":4,"formatOptions":{"palette":"gray","showIcon":true,"aggregation":"Count"}},{"columnMatch":"Activities","formatter":4,"formatOptions":{"palette":"greenDark","linkTarget":"GenericDetails","linkIsContextBlade":true,"showIcon":true,"aggregation":"Count","workbookContext":{"componentIdSource":"workbook","resourceIdsSource":"workbook","templateIdSource":"static","templateId":"https://go.microsoft.com/fwlink/?linkid=874159&resourceId=%2Fsubscriptions%2F44e4eff8-1fcb-4a22-a7d6-992ac7286382%2FresourceGroups%2FSOC&featureName=Workbooks&itemId=%2Fsubscriptions%2F44e4eff8-1fcb-4a22-a7d6-992ac7286382%2Fresourcegroups%2Fsoc%2Fproviders%2Fmicrosoft.insights%2Fworkbooks%2F4c195aec-747f-40bb-addb-934acb3ec646&name=CiscoASA&func=NavigateToPortalFeature&type=workbook","typeSource":"workbook","gallerySource":"workbook"}}}],"sortBy":[{"itemKey":"$gen_bar_updates_3","sortOrder":2}]}},"name":"query - 1"},{"type":3,"content":{"version":"KqlItem/1.0","query":"AzureActivity \\r\\n| where \\"{Caller:lable}\\" == \\"All\\" or Caller in ({Caller})\\r\\n| where \\"{ResourceGroup:lable}\\" == \\"All\\" or ResourceGroup in ({ResourceGroup})\\r\\n| summarize Informational = countif(Level == \\"Informational\\"), Warning = countif(Level == \\"Warning\\"), Error = countif(Level == \\"Error\\") by bin_at(TimeGenerated, 1h, now())\\r\\n","size":0,"exportToExcelOptions":"visible","title":"Activities by log level over time","color":"redBright","timeContext":{"durationMs":0},"timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"scatterchart","tileSettings":{"showBorder":false},"graphSettings":{"type":2,"topContent":{"columnMatch":"Error","formatter":12,"formatOptions":{"showIcon":true}},"hivesContent":{"columnMatch":"TimeGenerated","formatter":1,"formatOptions":{"showIcon":true}},"nodeIdField":"Error","sourceIdField":"Error","targetIdField":"Error","staticNodeSize":100,"groupByField":"TimeGenerated","hivesMargin":5}},"name":"query - 4"}],"fromTemplateId":"sentinel-AzureActivity","$schema":"https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"}\r\n'
            version: '1.0'
            sourceId: logAnalyticsWorkspaceResourceId
            category: 'sentinel'
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/Workbook-${last(split(workbookId1,'/'))}'
          properties: {
            description: '@{workbookKey=AzureActivityWorkbook; logoFileName=azureactivity_logo.svg; description=Gain extensive insight into your organization\'s Azure Activity by analyzing, and correlating all user operations and events.\nYou can learn about all user operations, trends, and anomalous changes over time.\nThis workbook gives you the ability to drill down into caller activities and summarize detected failure and warning events.; dataTypesDependencies=System.Object[]; dataConnectorsDependencies=System.Object[]; previewImagesFileNames=System.Object[]; version=2.0.0; title=Azure Activity; templateRelativePath=AzureActivity.json; subtitle=; provider=Microsoft}.description'
            parentId: workbookId1
            contentId: _workbookContentId1
            kind: 'Workbook'
            version: workbookVersion1
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
            dependencies: {
              operator: 'AND'
              criteria: [
                {
                  contentId: 'AzureActivity'
                  kind: 'DataType'
                }
                {
                  contentId: 'AzureActivity'
                  kind: 'DataConnector'
                }
              ]
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: _workbookContentId1
    contentKind: 'Workbook'
    displayName: workbook1Name
    contentProductId: _workbookcontentProductId1
    id: _workbookcontentProductId1
    version: workbookVersion1
  }
  dependsOn: [
contentPackage
  ]
}

resource workbookTemplateSpec2 'Microsoft.OperationalInsights/workspaces/providers/contentTemplates@2023-04-01-preview' = {
  name: workbookTemplateSpecName2
  location: location
  properties: {
    description: 'AzureServiceHealthWorkbook Workbook with template version 3.0.3'
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: workbookVersion2
      parameters: {}
      variables: {}
      resources: [
        {
          type: 'Microsoft.Insights/workbooks'
          name: workbookContentId2
          location: location
          kind: 'shared'
          apiVersion: '2021-08-01'
          metadata: {
            description: 'A collection of queries to provide visibility into Azure Service Health across the subscriptions.'
          }
          properties: {
            displayName: workbook2Name
            serializedData: '{"version":"Notebook/1.0","items":[{"type":1,"content":{"json":"## Azure Activity Logs for Azure Service Health Analysis Workbook"},"name":"text - 1"},{"type":9,"content":{"version":"KqlParameterItem/1.0","crossComponentResources":["{Subscription}"],"parameters":[{"id":"76e0f423-6828-47f3-aa86-522604bbbc6f","version":"KqlParameterItem/1.0","name":"Subscription","type":6,"description":"Azure Subscription where is the Log Analytics with Activity Logs informaiton","isRequired":true,"query":"summarize by subscriptionId\\r\\n| project value = strcat(\\"/subscriptions/\\",subscriptionId), label = subscriptionId\\r\\n| order by value ","crossComponentResources":["value::all"],"typeSettings":{"showDefault":false},"timeContext":{"durationMs":86400000},"queryType":1,"resourceType":"microsoft.resourcegraph/resources","value":"/subscriptions/fcb7d51b-418f-45a9-8418-5c0f17e343c8"},{"id":"ea100a5b-3c79-4761-8235-6a7989c83da5","version":"KqlParameterItem/1.0","name":"LAworkspace","label":"Log Analytics workspace","type":5,"description":"Log Analytics workspace where the Activity Logs information is sent","isRequired":true,"query":"where type == \'microsoft.operationalinsights/workspaces\'\\r\\n| project id\\r\\n| order by id asc","crossComponentResources":["{Subscription}"],"typeSettings":{"showDefault":false},"timeContext":{"durationMs":86400000},"queryType":1,"resourceType":"microsoft.resourcegraph/resources","value":""},{"id":"6b112ffe-a3a2-4b9e-a17a-c4ea5af739d7","version":"KqlParameterItem/1.0","name":"TimeRange","type":4,"typeSettings":{"selectableValues":[{"durationMs":3600000},{"durationMs":86400000},{"durationMs":259200000},{"durationMs":604800000},{"durationMs":1209600000},{"durationMs":2592000000}],"allowCustom":true},"timeContext":{"durationMs":86400000},"value":{"durationMs":2592000000}}],"style":"pills","queryType":1,"resourceType":"microsoft.resourcegraph/resources"},"name":"parameters - 0"},{"type":9,"content":{"version":"KqlParameterItem/1.0","crossComponentResources":["{LAworkspace}"],"parameters":[{"id":"2fb175cb-a2b6-4dd3-9473-886a8db4cd9c","version":"KqlParameterItem/1.0","name":"TrackingID_P","label":"Tracking ID","type":2,"isRequired":true,"multiSelect":true,"quote":"\'","delimiter":",","query":"AzureActivity\\r\\n| where CategoryValue == \\"ServiceHealth\\"\\r\\n| extend TrackingId = tostring(Properties_d.trackingId)\\r\\n| distinct TrackingId\\r\\n| order by TrackingId asc","crossComponentResources":["{LAworkspace}"],"typeSettings":{"additionalResourceOptions":["value::all"],"selectAllValue":"All","showDefault":false},"timeContext":{"durationMs":0},"timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","value":["value::all"]}],"style":"pills","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces"},"name":"parameters - 3"},{"type":12,"content":{"version":"NotebookGroup/1.0","groupType":"editable","items":[{"type":3,"content":{"version":"KqlItem/1.0","query":"AzureActivity\\r\\n| where CategoryValue == \\"ServiceHealth\\" \\r\\n| summarize TimeGenerated=arg_max(TimeGenerated,*) by SubscriptionId\\r\\n| extend SubscriptionId == strcat(\'/subscriptions/\', SubscriptionId)","size":1,"showAnalytics":true,"title":"Subscriptions Impacted","timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","crossComponentResources":["{LAworkspace}"],"visualization":"tiles","gridSettings":{"formatters":[{"columnMatch":"TimeGenerated","formatter":0,"formatOptions":{"customColumnWidthSetting":"22ch"}},{"columnMatch":"TrackingId","formatter":7,"formatOptions":{"linkTarget":"GenericDetails","linkIsContextBlade":true,"customColumnWidthSetting":"14ch"}},{"columnMatch":"Status","formatter":18,"formatOptions":{"thresholdsOptions":"icons","thresholdsGrid":[{"operator":"==","thresholdValue":"Active","representation":"2","text":"{0}{1}"},{"operator":"==","thresholdValue":"Resolved","representation":"Resolved","text":"{0}{1}"},{"operator":"Default","representation":"more","text":"{0}{1}"}],"customColumnWidthSetting":"12ch"}},{"columnMatch":"Impact Start Time","formatter":5},{"columnMatch":"Level","formatter":18,"formatOptions":{"thresholdsOptions":"icons","thresholdsGrid":[{"operator":"==","thresholdValue":"Information","representation":"info","text":"{0}{1}"},{"operator":"==","thresholdValue":"Warning","representation":"warning","text":"{0}{1}"},{"operator":"==","thresholdValue":"Error","representation":"error","text":"{0}{1}"},{"operator":"Default","representation":"Unknown","text":"{0}{1}"}]}},{"columnMatch":"IncidentType","formatter":18,"formatOptions":{"thresholdsOptions":"icons","thresholdsGrid":[{"operator":"==","thresholdValue":"Incident","representation":"error","text":"{0}{1}"},{"operator":"==","thresholdValue":"Maintenance","representation":"Tools","text":"{0}{1}"},{"operator":"==","thresholdValue":"ActionRequired","representation":"Clock","text":"{0}{1}"},{"operator":"==","thresholdValue":"Informational","representation":"1","text":"{0}{1}"},{"operator":"Default","representation":"more","text":"{0}{1}"}]}},{"columnMatch":"ImpactedSubscriptions","formatter":5},{"columnMatch":"# Subs.","formatter":8,"formatOptions":{"min":-1,"palette":"red"}},{"columnMatch":"ImpactedRegions","formatter":5},{"columnMatch":"# Regions","formatter":8,"formatOptions":{"min":-1,"palette":"magenta"}},{"columnMatch":"ImpactMitigationTime","formatter":5},{"columnMatch":"ResolutionTime (hours)","formatter":4,"formatOptions":{"min":-1,"palette":"orange","customColumnWidthSetting":"26ch"}}]},"tileSettings":{"titleContent":{"columnMatch":"SubscriptionId","formatter":13,"formatOptions":{"showIcon":true}},"showBorder":false}},"customWidth":"30","name":"query - 0 - Copy","styleSettings":{"showBorder":true}},{"type":3,"content":{"version":"KqlItem/1.0","query":"AzureActivity\\r\\n| where CategoryValue == \\"ServiceHealth\\"\\r\\n| extend TrackingId = tostring(Properties_d.trackingId)\\r\\n| summarize arg_max(TimeGenerated,*) by TrackingId\\r\\n| where TrackingId in ({TrackingID_P:value}) or \'{TrackingID_P:label}\'==\'All\'\\r\\n| extend ImpactedRegions = tostring(Properties_d.region)\\r\\n| summarize count() by ImpactedRegions","size":1,"title":"Impacted Regions","timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"tiles","tileSettings":{"titleContent":{"columnMatch":"ImpactedRegions","formatter":1},"leftContent":{"columnMatch":"count_","formatter":12,"formatOptions":{"palette":"auto"},"numberFormat":{"unit":17,"options":{"maximumSignificantDigits":3,"maximumFractionDigits":2}}},"showBorder":false}},"customWidth":"35","name":"query - 4","styleSettings":{"showBorder":true}},{"type":3,"content":{"version":"KqlItem/1.0","query":"AzureActivity\\r\\n| where CategoryValue == \\"ServiceHealth\\"\\r\\n| extend TrackingId = tostring(Properties_d.trackingId)\\r\\n| summarize arg_max(TimeGenerated,*) by TrackingId\\r\\n| where TrackingId in ({TrackingID_P:value}) or \'{TrackingID_P:label}\'==\'All\'\\r\\n| extend IncidentType= tostring(Properties_d.incidentType)\\r\\n| summarize count() by IncidentType","size":1,"title":"Type of Incidents","timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"piechart","tileSettings":{"titleContent":{"columnMatch":"IncidentType","formatter":1},"leftContent":{"columnMatch":"count_","formatter":12,"formatOptions":{"palette":"auto"},"numberFormat":{"unit":17,"options":{"maximumSignificantDigits":3,"maximumFractionDigits":2}}},"showBorder":false},"chartSettings":{"seriesLabelSettings":[{"seriesName":"Maintenance","color":"gray"},{"seriesName":"Incident","color":"yellowDark"},{"seriesName":"ActionRequired","color":"redBright"}]}},"customWidth":"35","name":"query - 4 - Copy","styleSettings":{"showBorder":true}},{"type":3,"content":{"version":"KqlItem/1.0","query":"AzureActivity\\r\\n| where CategoryValue == \\"ServiceHealth\\"\\r\\n| extend TrackingId = tostring(Properties_d.trackingId)\\r\\n| summarize arg_max(TimeGenerated,*) by TrackingId\\r\\n| where TrackingId in ({TrackingID_P:value}) or \'{TrackingID_P:label}\'==\'All\'\\r\\n| extend Status = tostring(Properties_d.activityStatusValue)\\r\\n| summarize count() by Status","size":0,"title":"Service Health on Status","timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"piechart","tileSettings":{"titleContent":{"columnMatch":"IncidentType","formatter":1},"leftContent":{"columnMatch":"count_","formatter":12,"formatOptions":{"palette":"auto"},"numberFormat":{"unit":17,"options":{"maximumSignificantDigits":3,"maximumFractionDigits":2}}},"showBorder":false},"chartSettings":{"seriesLabelSettings":[{"seriesName":"Active","color":"red"},{"seriesName":"Resolved","color":"green"}]}},"customWidth":"45","name":"query - 4 - Copy - Copy","styleSettings":{"showBorder":true}},{"type":3,"content":{"version":"KqlItem/1.0","query":"AzureActivity\\r\\n| where CategoryValue == \\"ServiceHealth\\"\\r\\n| extend TrackingId = tostring(Properties_d.trackingId)\\r\\n| summarize arg_max(TimeGenerated,*) by TrackingId\\r\\n| where TrackingId in ({TrackingID_P:value}) or \'{TrackingID_P:label}\'==\'All\'\\r\\n| extend Service = tostring(Properties_d.service)\\r\\n| summarize count() by Service","size":0,"title":"Service Health Across Services","timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"categoricalbar","tileSettings":{"titleContent":{"columnMatch":"IncidentType","formatter":1},"leftContent":{"columnMatch":"count_","formatter":12,"formatOptions":{"palette":"auto"},"numberFormat":{"unit":17,"options":{"maximumSignificantDigits":3,"maximumFractionDigits":2}}},"showBorder":false},"chartSettings":{"seriesLabelSettings":[{"seriesName":"Active","color":"red"},{"seriesName":"Resolved","color":"green"}]}},"customWidth":"55","name":"query - 4 - Copy - Copy - Copy","styleSettings":{"showBorder":true}},{"type":3,"content":{"version":"KqlItem/1.0","query":"AzureActivity\\r\\n| where CategoryValue == \\"ServiceHealth\\"\\r\\n| extend TrackingId = tostring(Properties_d.trackingId)\\r\\n| summarize arg_max(TimeGenerated,*) by TrackingId\\r\\n| where TrackingId in ({TrackingID_P:value}) or \'{TrackingID_P:label}\'==\'All\'\\r\\n| extend Service = tostring(Properties_d.service)\\r\\n| extend ImpactMitigationTime = tostring(Properties_d.impactMitigationTime)\\r\\n| extend ImpactStartTime = tostring(Properties_d.impactStartTime)\\r\\n| extend [\\"ResolutionTime\\"]=datetime_diff(\'hour\',todatetime(ImpactMitigationTime),todatetime(ImpactStartTime))\\r\\n| extend ImpactedRegions = todynamic(parse_json(tostring(parse_json(tostring(parse_json(Properties).impactedServices))[0].ImpactedRegions)))\\r\\n| mv-expand ImpactedRegions\\r\\n| project  Service,ImpactedRegions.RegionName, [\\"ResolutionTime\\"], _ResourceId","size":0,"title":"Resolution Time","timeContextFromParameter":"TimeRange","showExportToExcel":true,"queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"table","gridSettings":{"formatters":[{"columnMatch":"$gen_group","formatter":13,"formatOptions":{"showIcon":true}},{"columnMatch":"ResolutionTime","formatter":8,"formatOptions":{"palette":"redDark"},"numberFormat":{"unit":25,"options":{"style":"decimal","useGrouping":false}}},{"columnMatch":"_ResourceId","formatter":5}],"filter":true,"hierarchySettings":{"treeType":1,"groupBy":["_ResourceId"],"expandTopLevel":true}},"tileSettings":{"titleContent":{"columnMatch":"IncidentType","formatter":1},"leftContent":{"columnMatch":"count_","formatter":12,"formatOptions":{"palette":"auto"},"numberFormat":{"unit":17,"options":{"maximumSignificantDigits":3,"maximumFractionDigits":2}}},"showBorder":false},"chartSettings":{"seriesLabelSettings":[{"seriesName":"Active","color":"red"},{"seriesName":"Resolved","color":"green"}]}},"customWidth":"70","name":"query - 4 - Copy - Copy - Copy - Copy","styleSettings":{"showBorder":true}},{"type":3,"content":{"version":"KqlItem/1.0","query":"AzureActivity\\r\\n| where CategoryValue == \\"ServiceHealth\\"\\r\\n| extend TrackingId = tostring(Properties_d.trackingId)\\r\\n| summarize arg_max(TimeGenerated,*) by TrackingId\\r\\n| where TrackingId in ({TrackingID_P:value}) or \'{TrackingID_P:label}\'==\'All\'\\r\\n| extend Stage = tostring(parse_json(Properties).stage)\\r\\n| summarize count() by Stage","size":0,"title":"Current Stage","timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","visualization":"tiles","tileSettings":{"titleContent":{"columnMatch":"Stage","formatter":1},"leftContent":{"columnMatch":"count_","formatter":12,"formatOptions":{"palette":"auto"},"numberFormat":{"unit":17,"options":{"maximumSignificantDigits":3,"maximumFractionDigits":2}}},"showBorder":false},"chartSettings":{"seriesLabelSettings":[{"seriesName":"Active","color":"red"},{"seriesName":"Resolved","color":"green"}]}},"customWidth":"30","name":"query - 4 - Copy - Copy - Copy - Copy - Copy","styleSettings":{"showBorder":true}},{"type":3,"content":{"version":"KqlItem/1.0","query":"AzureActivity\\r\\n| where CategoryValue == \\"ServiceHealth\\"\\r\\n| extend TrackingId = tostring(Properties_d.trackingId)\\r\\n| summarize arg_max(TimeGenerated,) by TrackingId\\r\\n| where TrackingId in ({TrackingID_P:value}) or \'{TrackingID_P:label}\'==\'All\'\\r\\n//| where Level in (\'Warning\',\'Error\',\'Information\')\\r\\n| extend IncidentType= tostring(Properties_d.incidentType)\\r\\n//| where IncidentType in (\'Incident\',\'Maintenance\',\'ActionRequired\')\\r\\n| extend ImpactMitigationTime = tostring(Properties_d.impactMitigationTime)\\r\\n| extend ImpactStartTime = tostring(Properties_d.impactStartTime)\\r\\n| extend Status = tostring(Properties_d.activityStatusValue)\\r\\n| extend Service = tostring(Properties_d.service)\\r\\n| extend Title = tostring(Properties_d.defaultLanguageTitle)\\r\\n| extend ImpactedRegions = tostring(parse_json(tostring(parse_json(tostring(parse_json(Properties).impactedServices))[0].ImpactedRegions)))\\r\\n| summarize ImpactedSubscriptions=make_set(SubscriptionId), TimeGenerated=arg_max(TimeGenerated,) by Level, ImpactedRegions, Service, TrackingId, Status\\r\\n| project TimeGenerated\\r\\n        , TrackingId\\r\\n        , Title\\r\\n        , Status\\r\\n        , [\\"Impact Start Time\\"]=todatetime(ImpactStartTime)\\r\\n        , Level\\r\\n        , IncidentType\\r\\n        , ImpactedSubscriptions\\r\\n        , Service\\r\\n        , [\\"# Subs.\\"]=array_length(ImpactedSubscriptions)\\r\\n        , ImpactedRegions\\r\\n        , [\\"# Regions\\"]=array_length(parse_json(ImpactedRegions))\\r\\n        , todatetime(ImpactMitigationTime)\\r\\n        , [\\"ResolutionTime (hours)\\"]=datetime_diff(\'hour\',todatetime(ImpactMitigationTime),todatetime(ImpactStartTime))\\r\\n| order by TimeGenerated ","size":0,"showAnalytics":true,"title":"Analysis of incident","timeContextFromParameter":"TimeRange","showExportToExcel":true,"queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","crossComponentResources":["{LAworkspace}"],"gridSettings":{"formatters":[{"columnMatch":"TimeGenerated","formatter":0,"formatOptions":{"customColumnWidthSetting":"22ch"}},{"columnMatch":"TrackingId","formatter":7,"formatOptions":{"linkTarget":"GenericDetails","linkIsContextBlade":true,"customColumnWidthSetting":"14ch"}},{"columnMatch":"Status","formatter":18,"formatOptions":{"thresholdsOptions":"icons","thresholdsGrid":[{"operator":"==","thresholdValue":"Active","representation":"2","text":"{0}{1}"},{"operator":"==","thresholdValue":"Resolved","representation":"Resolved","text":"{0}{1}"},{"operator":"Default","representation":"more","text":"{0}{1}"}],"customColumnWidthSetting":"12ch"}},{"columnMatch":"Impact Start Time","formatter":5},{"columnMatch":"Level","formatter":18,"formatOptions":{"thresholdsOptions":"icons","thresholdsGrid":[{"operator":"==","thresholdValue":"Information","representation":"info","text":"{0}{1}"},{"operator":"==","thresholdValue":"Warning","representation":"warning","text":"{0}{1}"},{"operator":"==","thresholdValue":"Error","representation":"error","text":"{0}{1}"},{"operator":"Default","representation":"Unknown","text":"{0}{1}"}]}},{"columnMatch":"IncidentType","formatter":18,"formatOptions":{"thresholdsOptions":"icons","thresholdsGrid":[{"operator":"==","thresholdValue":"Incident","representation":"error","text":"{0}{1}"},{"operator":"==","thresholdValue":"Maintenance","representation":"Tools","text":"{0}{1}"},{"operator":"==","thresholdValue":"ActionRequired","representation":"Clock","text":"{0}{1}"},{"operator":"==","thresholdValue":"Informational","representation":"1","text":"{0}{1}"},{"operator":"Default","representation":"more","text":"{0}{1}"}]}},{"columnMatch":"ImpactedSubscriptions","formatter":5},{"columnMatch":"# Subs.","formatter":8,"formatOptions":{"min":-1,"palette":"red"}},{"columnMatch":"ImpactedRegions","formatter":5},{"columnMatch":"# Regions","formatter":8,"formatOptions":{"min":-1,"palette":"magenta"}},{"columnMatch":"ImpactMitigationTime","formatter":5},{"columnMatch":"ResolutionTime (hours)","formatter":4,"formatOptions":{"min":-1,"palette":"orange","customColumnWidthSetting":"26ch"}}],"filter":true,"sortBy":[{"itemKey":"$gen_link_TrackingId_1","sortOrder":1}]},"sortBy":[{"itemKey":"$gen_link_TrackingId_1","sortOrder":1}]},"name":"query - 0","styleSettings":{"showBorder":true}},{"type":3,"content":{"version":"KqlItem/1.0","query":"AzureActivity\\r\\n| where CategoryValue == \\"ServiceHealth\\"\\r\\n| extend TrackingId = tostring(Properties_d.trackingId)\\r\\n| where TrackingId in ({TrackingID_P:value}) or \'{TrackingID_P:label}\'==\'All\'\\r\\n| summarize ImpactedSubscriptions=make_set(SubscriptionId) by TrackingId\\r\\n| project ImpactedSubscriptions, TrackingId\\r\\n| mv-expand ImpactedSubscriptions\\r\\n| project Subscription=strcat(\'/subscriptions/\',ImpactedSubscriptions), TrackingId\\r\\n| extend Info=strcat(\'https://app.azure.com/h/\',TrackingId)\\r\\n| order by TrackingId asc","size":0,"showAnalytics":true,"title":"Affected subscriptions","timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","crossComponentResources":["{LAworkspace}"],"gridSettings":{"formatters":[{"columnMatch":"TrackingId","formatter":1,"formatOptions":{"linkColumn":"Info","linkTarget":"Url"}},{"columnMatch":"Info","formatter":5,"formatOptions":{"linkTarget":"Url","linkLabel":"Shareable link"}}],"filter":true}},"customWidth":"50","name":"query - 2","styleSettings":{"showBorder":true}},{"type":3,"content":{"version":"KqlItem/1.0","query":"AzureActivity\\r\\n| where CategoryValue == \\"ServiceHealth\\"\\r\\n| extend TrackingId = tostring(Properties_d.trackingId)\\r\\n| where TrackingId in ({TrackingID_P:value}) or \'{TrackingID_P:label}\'==\'All\'\\r\\n| extend ImpactedRegions = tostring(parse_json(tostring(parse_json(tostring(parse_json(Properties).impactedServices))[0].ImpactedRegions)))\\r\\n| project todynamic(ImpactedRegions), TrackingId\\r\\n| mv-expand ImpactedRegions\\r\\n| project Region=strcat(tostring(ImpactedRegions.RegionName),\' (\',tostring(ImpactedRegions.RegionId),\')\'),TrackingId\\r\\n| distinct Region, TrackingId\\r\\n| extend Info=strcat(\'https://app.azure.com/h/\', TrackingId)\\r\\n| order by TrackingId asc\\r\\n","size":0,"showAnalytics":true,"title":"Affected regions","timeContextFromParameter":"TimeRange","queryType":0,"resourceType":"microsoft.operationalinsights/workspaces","crossComponentResources":["{LAworkspace}"],"gridSettings":{"formatters":[{"columnMatch":"TrackingId","formatter":1,"formatOptions":{"linkColumn":"Info","linkTarget":"Url"}},{"columnMatch":"Info","formatter":5}],"filter":true}},"customWidth":"50","name":"query - 1","styleSettings":{"showBorder":true}}]},"name":"GroupActivityLogs01","styleSettings":{"showBorder":true}}],"fromTemplateId":"sentinel-AzureServiceHealthWorkbook","$schema":"https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"}\r\n'
            version: '1.0'
            sourceId: logAnalyticsWorkspaceResourceId
            category: 'sentinel'
          }
        }
        {
          type: 'Microsoft.OperationalInsights/workspaces/providers/metadata'
          apiVersion: '2022-01-01-preview'
          name: '${logAnalyticsWorkspaceName}/Microsoft.SecurityInsights/Workbook-${last(split(workbookId2,'/'))}'
          properties: {
            description: '@{workbookKey=AzureServiceHealthWorkbook; logoFileName=; description=A collection of queries to provide visibility into Azure Service Health across the subscriptions.; dataTypesDependencies=System.Object[]; dataConnectorsDependencies=System.Object[]; previewImagesFileNames=System.Object[]; version=1.0.0; title=Azure Service Health Workbook; templateRelativePath=AzureServiceHealthWorkbook.json; subtitle=; provider=Microsoft Sentinel Community}.description'
            parentId: workbookId2
            contentId: _workbookContentId2
            kind: 'Workbook'
            version: workbookVersion2
            source: {
              kind: 'Solution'
              name: 'Azure Activity'
              sourceId: _solutionId
            }
            author: {
              name: 'Microsoft'
              email: _email
            }
            support: {
              tier: 'Microsoft'
              name: 'Microsoft Corporation'
              email: 'support@microsoft.com'
              link: 'https://support.microsoft.com/'
            }
            dependencies: {
              operator: 'AND'
              criteria: [
                {
                  contentId: 'AzureActivity'
                  kind: 'DataType'
                }
                {
                  contentId: 'AzureActivity'
                  kind: 'DataConnector'
                }
              ]
            }
          }
        }
      ]
    }
    packageKind: 'Solution'
    packageVersion: _solutionVersion
    packageName: _solutionName
    packageId: _solutionId
    contentSchemaVersion: '3.0.0'
    contentId: _workbookContentId2
    contentKind: 'Workbook'
    displayName: workbook2Name
    contentProductId: _workbookcontentProductId2
    id: _workbookcontentProductId2
    version: workbookVersion2
  }
  dependsOn: [
    contentPackage
  ]
}


