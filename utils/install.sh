#!/bin/bash


charts=(
    pvc
    storage-tool-job
    amqp-integration-adapter
    batch-adapter
    db-integration-adapter
    file-integration-adapter
    plugin-integration-adapter
    push-notifications-adapter
    scheduler-adapter
    smev-http-adapter
    statistics-adapter
    ws-integration-adapter
    ui-adapter
    inner-integration-adapter
    smev-front
)

# helm install pvc charts/pvc/ -f $(ENV).yml -f pvc/values.yaml -n $(NAMESPACE)

env=prod
ns=default

for c in "${charts[@]}"; do
    echo "helm install ${c} charts/${c}/ -f ${env}.yml -f ${env}/${c}.yml -n ${ns}"
done