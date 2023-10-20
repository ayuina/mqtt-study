param region string
param prefix string
param sourceTopicName string
param sourceTopicUamiName string

var storageName = '${prefix}${uniqueString(subscription().id, resourceGroup().id)}'


resource sender 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: sourceTopicUamiName
}

resource sourceTopic 'Microsoft.EventGrid/topics@2020-10-15-preview' existing = {
  name: sourceTopicName
}

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  location: region
  name: storageName
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }

  resource queueSvc 'queueServices' existing = {
    name: 'default'

    resource queue 'queues' = {
      name: 'egtopic-subscription'
    }
  }
}

resource storageQueueSender 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: 'c6a89b2d-59bc-44d0-9896-0f6e12d7b80a'
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, sender.id, storage.id, storageQueueSender.id)
  scope: storage
  properties: {
    principalId: sender.properties.principalId
    roleDefinitionId: storageQueueSender.id
    principalType: 'ServicePrincipal'
  }
}

resource topicSubscription 'Microsoft.EventGrid/topics/eventSubscriptions@2023-06-01-preview' = {
  parent: sourceTopic
  name: '${storage::queueSvc::queue.name}-subscription'
  dependsOn: [assignment]
  properties: {
    eventDeliverySchema: 'CloudEventSchemaV1_0'
    filter: {
      enableAdvancedFilteringOnArrays: true
      subjectBeginsWith: ''
      subjectEndsWith: ''
    }
    deliveryWithResourceIdentity: {
      destination: {
        endpointType: 'StorageQueue'
        properties: {
          queueMessageTimeToLiveInSeconds: -1
          queueName: storage::queueSvc::queue.name
          resourceId: storage.id
        }
      }
      identity: {
        type: 'UserAssigned'
        userAssignedIdentity: sender.id
      }
    }
  }
}
