#!/bin/bash
#TO DO :: remove the key value that are not needed or is default.

read -p "Enter target Namespace: " namespace
oc project "$namespace"

OUTPUT_FILE="routes.yaml"
echo "" > "$OUTPUT_FILE"

for route in $(oc get route -o jsonpath='{.items[*].metadata.name}'); do
  # Fetch values
  labels=$(oc get route "$route" -o json | yq -P '.metadata.labels // {}')
  annotations=$(oc get route "$route" -o json | yq -P '.metadata.annotations // {}')
  host=$(oc get route "$route" -o jsonpath='{.spec.host}')
  path=$(oc get route "$route" -o jsonpath='{.spec.path}')
  targetPort=$(oc get route "$route" -o jsonpath='{.spec.port.targetPort}')
  insecureEdgeTerminationPolicy=$(oc get route "$route" -o jsonpath='{.spec.tls.insecureEdgeTerminationPolicy}')
  serviceName=$(oc get route "$route" -o jsonpath='{.spec.to.name}')
  secretName=$(oc get route "$route" -o jsonpath='{.spec.tls.terminationSecretName}')

  # TLS certificate and key if secret exists
  if [ -n "$secretName" ] && [ "$secretName" != "<no value>" ]; then
    certificate=$(oc get secret "$secretName" -n "$namespace" -o jsonpath='{.data.tls\.crt}' | base64 --decode)
    key=$(oc get secret "$secretName" -n "$namespace" -o jsonpath='{.data.tls\.key}' | base64 --decode)
  else
    certificate=""
    key=""
  fi

  echo "$route:" >> "$OUTPUT_FILE"

  if [ "$(echo "$labels" | wc -c)" -gt 2 ]; then
    echo "  labels:" >> "$OUTPUT_FILE"
    echo "$labels" | sed 's/^/    /' >> "$OUTPUT_FILE"
  fi

  if [ "$(echo "$annotations" | wc -c)" -gt 2 ]; then
    echo "  annotations:" >> "$OUTPUT_FILE"
    echo "$annotations" | sed 's/^/    /' >> "$OUTPUT_FILE"
  fi

  [ -n "$host" ] && echo "  host: $host" >> "$OUTPUT_FILE"
  [ -n "$path" ] && echo "  path: $path" >> "$OUTPUT_FILE"
  [ -n "$targetPort" ] && echo "  targetPort: $targetPort" >> "$OUTPUT_FILE"

  if [ -n "$certificate" ] || [ -n "$key" ] || [ -n "$insecureEdgeTerminationPolicy" ]; then
    echo "  tls:" >> "$OUTPUT_FILE"
    [ -n "$insecureEdgeTerminationPolicy" ] && echo "    insecureEdgeTerminationPolicy: \"$insecureEdgeTerminationPolicy\"" >> "$OUTPUT_FILE"
    echo "    termination: edge" >> "$OUTPUT_FILE"
    [ -n "$certificate" ] && echo "    certificate: \"$certificate\"" >> "$OUTPUT_FILE"
    [ -n "$key" ] && echo "    key: \"$key\"" >> "$OUTPUT_FILE"
  fi


  echo "  serviceName: $serviceName" >> "$OUTPUT_FILE"
done

echo "All routes exported to $OUTPUT_FILE"