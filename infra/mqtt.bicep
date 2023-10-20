param region string
param prefix string
param routingTopicName string
param deploymentUserId string
param clientList array

var egnsName = '${prefix}-egns'
var egnsUamiName = '${egnsName}-uami'


resource egnsUami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: egnsUamiName
  location: region
}

resource routingTopic 'Microsoft.EventGrid/topics@2023-06-01-preview' existing = {
  name: routingTopicName
}

resource eventGridPublisher 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: 'd5a91429-5739-47e2-a06b-3470a27159e7'
}

resource assingEgPublisher 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: routingTopic
  name: guid(subscription().id, resourceGroup().id, deploymentUserId, routingTopic.id, eventGridPublisher.id)
  // name: guid(subscription().id, resourceGroup().id, egnsUami.id, routingTopic.id, eventGridPublisher.id)
  properties: {
    roleDefinitionId: eventGridPublisher.id
    principalType: 'User'
    principalId: deploymentUserId
    // principalType: 'ServicePrincipal'
    // principalId: egnsUami.properties.principalId
  }
}


resource egns 'Microsoft.EventGrid/namespaces@2023-06-01-preview' = {
  name: egnsName
  location: region
  dependsOn: [ assingEgPublisher ]
  sku: {
    name: 'Standard'
    capacity: 1
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${egnsUami.id}': {}
    }
  }
  properties: {
    isZoneRedundant: true
    publicNetworkAccess: 'Enabled'
    topicSpacesConfiguration: {
      state: 'Enabled'
      maximumClientSessionsPerAuthenticationName: 1
      maximumSessionExpiryInHours: 1
      routeTopicResourceId: routingTopic.id
      routingIdentityInfo: null
      // routingIdentityInfo: {
      //   type: 'UserAssigned'
      //   userAssignedIdentity: egnsUami.id
      // }
    }
  }
}

resource clientGroup 'Microsoft.EventGrid/namespaces/clientGroups@2023-06-01-preview' = {
  parent: egns
  name: 'defaultClients'
  properties: {
    query: 'true'
  }
}

resource topicSpace 'Microsoft.EventGrid/namespaces/topicSpaces@2023-06-01-preview' = {
  parent: egns
  name: 'defaultTopicSpace'
  properties: {
    topicTemplates: [
      'mytopics/#'
    ]
  }
}

resource clientAsTopicSpacePublisher 'Microsoft.EventGrid/namespaces/permissionBindings@2023-06-01-preview' = {
  parent: egns
  name: 'defaultClients-as-publisher'
  properties: {
    clientGroupName: clientGroup.name
    topicSpaceName: topicSpace.name
    permission: 'Publisher'
  } 
}

resource clientAsTopicSpaceSubscriber 'Microsoft.EventGrid/namespaces/permissionBindings@2023-06-01-preview' = {
  parent: egns
  name: 'defaultClients-as-subscriber'
  properties: {
    clientGroupName: clientGroup.name
    topicSpaceName: topicSpace.name
    permission: 'Subscriber'
  } 
}

resource clients 'Microsoft.EventGrid/namespaces/clients@2023-06-01-preview' = [for client in clientList: {
  parent: egns
  name: client.name
  properties: {
    authenticationName: client.authName
    clientCertificateAuthentication: {
      validationScheme: 'ThumbprintMatch'
      allowedThumbprints: [
        client.thumb
      ]
    }
    state: 'Enabled'
  }
}]
