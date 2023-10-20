param region string
param prefix string
param sourceTopicName string
param sourceTopicUamiName string

var eventhubNsName = '${prefix}-ehns'
var eventhubName = '${prefix}-subsc'


resource sender 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: sourceTopicUamiName
}

resource sourceTopic 'Microsoft.EventGrid/topics@2020-10-15-preview' existing = {
  name: sourceTopicName
}

resource evthubNs 'Microsoft.EventHub/namespaces@2023-01-01-preview' = {
  location: region
  name: eventhubNsName
  sku: {
    name: 'Standard'
    capacity: 1
  }
 
  resource eventHubs 'eventHubs' = {
    name: eventhubName
    properties: {
      messageRetentionInDays: 1
      partitionCount: 1
      status: 'Active'
    }
  }
}

resource evthubDataSender 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: '2b629674-e913-4c01-ae53-ef4638d8f975'
}

resource assignSenderAsEventhubDataSender 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, sender.id, evthubNs.id, evthubDataSender.id)
  scope: evthubNs
  properties: {
    principalId: sender.properties.principalId
    roleDefinitionId: evthubDataSender.id
    principalType: 'ServicePrincipal'
  }
}

resource topicSubscription 'Microsoft.EventGrid/topics/eventSubscriptions@2023-06-01-preview' = {
  parent: sourceTopic
  name: '${sourceTopic.name}-${eventhubName}-subscription'

  properties: {
    eventDeliverySchema: 'CloudEventSchemaV1_0'
    filter: {
      enableAdvancedFilteringOnArrays: true
      subjectBeginsWith: ''
      subjectEndsWith: ''
    }
    deliveryWithResourceIdentity: {
      destination: {
        endpointType: 'EventHub'
        properties: {
          resourceId: evthubNs::eventHubs[eventhubName].id
        }
      }
      identity: {
        type: 'UserAssigned'
        userAssignedIdentity: sender.id
      }
    }
  }
}

output eventHubName string = eventhubName
output eventHubNamespaceName string = eventhubNsName
