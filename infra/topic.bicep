param region string
param prefix string

var topicName = '${prefix}-topic' 
var topicUamiName = '${topicName}-uami'

resource topicUami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: topicUamiName
  location: region
}

resource topic 'Microsoft.EventGrid/topics@2023-06-01-preview' = {
  name: topicName
  location: region
  sku: {
    name: 'Basic'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${topicUami.id}': {}
    }
  }
  properties: {
    inputSchema: 'CloudEventSchemaV1_0'
    publicNetworkAccess: 'Enabled'
  }
}


output topicName string = topic.name
output uamiName string = topicUami.name
