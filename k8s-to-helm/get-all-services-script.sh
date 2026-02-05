#!/bin/bash

OUTPUT_FILE="services_labels.yaml"

echo "---" > "$OUTPUT_FILE"

for svc in $(oc get svc -o jsonpath='{.items[*].metadata.name}'); do

    labels_yaml=$(oc get svc "$svc" -o json | yq -P '.metadata.labels')
    
    ports_yaml=$(oc get svc "$svc" -o json | yq -P '.spec.ports')

    selector_yaml=$(oc get svc "$svc" -o json | yq -P '.spec.selector')
    

    echo "$svc:" >> "$OUTPUT_FILE"
    
    echo "labels:" | sed 's/^/ /'>> "$OUTPUT_FILE" 
    echo "$labels_yaml" | sed 's/^/  /' >> "$OUTPUT_FILE"
    
    echo "ports:" | sed 's/^/ /' >> "$OUTPUT_FILE"
    echo "$ports_yaml" | sed 's/^/  /'>> "$OUTPUT_FILE"
    
    echo "selector:" | sed 's/^/ /'>> "$OUTPUT_FILE" 
    echo "$selector_yaml" | sed 's/^/  /' >> "$OUTPUT_FILE"

    cat <<EOF >> "$OUTPUT_FILE"
 ipFamilies:
    - IPv4
 ipFamilyPolicy: SingleStack
EOF
done

echo "All service labels exported to $OUTPUT_FILE"
