param prefix string
param region string
param deploymentUserId string
// az ad signed-in-user show --query id --output tsv 
param clientList array

module topic 'topic.bicep' = {
  name: 'topic'
  params: {
    region: region
    prefix: prefix
  }
}

module mqtt 'mqtt.bicep' = {
  name: 'mqtt'
  params: {
    region: region
    prefix: prefix
    routingTopicName: topic.outputs.topicName
    deploymentUserId: deploymentUserId
    clientList: clientList
  }
}

module eventhub 'subsc-evthub.bicep' = {
  name: 'eventhubSubscriber'
  params: {
    region: region
    prefix: prefix
    sourceTopicName: topic.outputs.topicName
    sourceTopicUamiName: topic.outputs.uamiName
  }
}

module queue 'subsc-storage.bicep' = {
  name: 'queueSubscriber'
  params: {
    region: region
    prefix: prefix
    sourceTopicName: topic.outputs.topicName
    sourceTopicUamiName: topic.outputs.uamiName

  }
}


