#!/bin/bash

read -p "Enter target Namespace: " namespace
echo "This will convert all the deployments from $namespace to IMB DevOps Helm chart pattern"

oc project $namespace


OUTPUT_FILE="deployment.yaml"

echo "---" > "$OUTPUT_FILE"

for deployment in $(oc get deployment -o jsonpath='{.items[*].metadata.name}'); do

   labels=$(oc get deployment "$deployment" -o json | yq -P '.metadata.labels')
   
   echo "$deployment:" >> "$OUTPUT_FILE"

   echo "labels:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$labels" | sed 's/^/  /' >> "$OUTPUT_FILE"

   checkForVault=$(oc get deployment "$deployment" -o json | yq '.spec.template.metadata.annotations."vault.hashicorp.com/agent-inject"')

   if [ -n "$checkForVault" ] && [ "$checkForVault" != "null" ]; then

   podAnnotations=$(oc get deployment "$deployment" -o json | jq -r '
  .spec.template.metadata.annotations 
  | del(."kubectl.kubernetes.io/restartedAt", ."openshift.openshift.io/restartedAt")
' | yq -P '.. style="literal"' )

   
   echo "podAnnotations:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$podAnnotations" | sed 's/^/  /' >> "$OUTPUT_FILE"

   fi

   
   replicaCount=$(oc get deployment "$deployment" -o jsonpath='{.spec.replicas}')
   
   echo "replicaCount:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$replicaCount" | sed 's/^/  /' >> "$OUTPUT_FILE"

   selector=$(oc get deployment "$deployment" -o json | yq -P '.spec.selector')

   echo "selector:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$selector" | sed 's/^/  /' >> "$OUTPUT_FILE"
   
   podLables=$(oc get deployment "$deployment" -o json | yq -P '.spec.template.metadata.labels')

   echo "podLables:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$podLables" | sed 's/^/  /' >> "$OUTPUT_FILE"
   

   echo "initContainersEnabled: false" | sed 's/^/ /' >> "$OUTPUT_FILE"
   
   image=$(oc get deployment "$deployment" -o jsonpath='{.spec.template.spec.containers[0].image}')


   repository="${image%:*}"
   tag="${image##*:}"


   IMAGE_BLOCK=$(cat <<EOF
repository: $repository
tag: $tag
imagePullPolicy: Always
EOF
)

   echo "image:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$IMAGE_BLOCK" | sed 's/^/  /' >> "$OUTPUT_FILE"
    

   command=$(oc get deployment "$deployment" -o json | yq  -P '.spec.template.spec.containers[0].command')

   if [ -n "$command" ] && [ "$command" != "null" ]; then
   echo "command:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$command" | sed 's/^/  /' >> "$OUTPUT_FILE"
   fi

   args=$(oc get deployment "$deployment" -o json | yq  -P '.spec.template.spec.containers[0].args')

   if [ -n "$args" ] && [ "$args" != "null" ]; then
   echo "args:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$args" | sed 's/^/  /' >> "$OUTPUT_FILE"
   fi

   ports=$(oc get deployment "$deployment" -o json | yq  -P '.spec.template.spec.containers[0].ports')

   if [ -n "$ports" ] && [ "$ports" != "null" ]; then
   echo "ports:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$ports" | sed 's/^/  /' >> "$OUTPUT_FILE"
   fi

   livenessProbe=$(oc get deployment "$deployment" -o json | yq  -P '.spec.template.spec.containers[0].livenessProbe')

   if [ -n "$livenessProbe" ] && [ "$livenessProbe" != "null" ]; then
   echo "livenessProbe:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$livenessProbe" | sed 's/^/  /' >> "$OUTPUT_FILE"
   fi

   readinessProbe=$(oc get deployment "$deployment" -o json | yq  -P '.spec.template.spec.containers[0].readinessProbe')

   if [ -n "$readinessProbe" ] && [ "$readinessProbe" != "null" ]; then
   echo "readinessProbe:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$readinessProbe" | sed 's/^/  /' >> "$OUTPUT_FILE"
   fi

   volumeMounts=$(oc get deployment "$deployment" -o json | yq  -P '.spec.template.spec.containers[0].volumeMounts')

   if [ -n "$volumeMounts" ] && [ "$volumeMounts" != "null" ]; then
   echo "volumeMounts:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$volumeMounts" | sed 's/^/  /' >> "$OUTPUT_FILE"
   fi

   env=$(oc get deployment "$deployment" -o json | yq  -P '.spec.template.spec.containers[0].env')

   if [ -n "$env" ] && [ "$env" != "null" ]; then
   echo "env:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$env" | sed 's/^/  /' >> "$OUTPUT_FILE"
   fi

   envFrom=$(oc get deployment "$deployment" -o json | yq  -P '.spec.template.spec.containers[0].envFrom')

   if [ -n "$envFrom" ] && [ "$envFrom" != "null" ]; then
   echo "envFrom:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$envFrom" | sed 's/^/  /' >> "$OUTPUT_FILE"
   fi

   resources=$(oc get deployment "$deployment" -o json | yq  -P '.spec.template.spec.containers[0].resources')

   if [ -n "$resources" ] && [ "$resources" != "null" ]; then
   echo "resources:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$resources" | sed 's/^/  /' >> "$OUTPUT_FILE"
   fi

   volumes=$(oc get deployment "$deployment" -o json | yq  -P '.spec.template.spec.volumes')

   if [ -n "$volumes" ] && [ "$volumes" != "null" ]; then
   echo "volumes:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$volumes" | sed 's/^/  /' >> "$OUTPUT_FILE"
   fi

   serviceAccountName=$(oc get deployment "$deployment" -o json | yq  -P '.spec.template.spec.serviceAccountName')

   if [ -n "$serviceAccountName" ] && [ "$serviceAccountName" != "null" ]; then
   echo "serviceAccountName:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$serviceAccountName" | sed 's/^/  /' >> "$OUTPUT_FILE"
   fi
    
   imagePullSecrets=$(oc get deployment "$deployment" -o json | yq  -P '.spec.template.spec.imagePullSecrets')

   if [ -n "$imagePullSecrets" ] && [ "$imagePullSecrets" != "null" ]; then
   echo "imagePullSecrets:" | sed 's/^/ /' >> "$OUTPUT_FILE"
   echo "$imagePullSecrets" | sed 's/^/  /' >> "$OUTPUT_FILE"
   fi
   echo "" >> "$OUTPUT_FILE" 
done

echo "All deployment exported to $OUTPUT_FILE"
