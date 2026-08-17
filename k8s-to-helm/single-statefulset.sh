read -p "Make sure you're logged into the Openshift API before proceeding. Proceed (y) or Exit (n) (y/n): " confirm && [[ $confirm == [yY] ]] || exit 1
read -p "Enter target Licenase Plate (ex// d7abee, d106d6): " license_plate
read -p "Enter the environment (ex// dev, test, prod): " environment

oc project $license_plate-$environment

echo "Below is the list of available stateful sets in $license_plate-$environment"
echo "---------------------------------------------------------------------------"
oc get statefulset --no-headers | awk '{print $1}'
echo "---------------------------------------------------------------------------"
read -p "Enter the name of the target statefulset: " statefulset

mkdir -p "$(date +%Y-%m-%d)" && cd "$_"

OUTPUT_FILE="$statefulset-$environment-statefulset.yaml"

echo "---" > "$OUTPUT_FILE"
oc get statefulset "$statefulset" -o json | yq -P '
  {
        .metadata.name: {
            "labels": .metadata.labels,
            "serviceName": .spec.serviceName,
            "replicas": .spec.replicas,
            "podManagementPolicy": .spec.podManagementPolicy,
            "revisionHistoryLimit": .spec.revisionHistoryLimit,
            "selector": {
                "matchLabels": {
                    "app": .spec.selector.matchLabels.app,
                    "role": .spec.selector.matchLabels.role
                }
            },
            "updateStrategy": {
                "type": .spec.updateStrategy.type,
                "rollingUpdate": .spec.updateStrategy.rollingUpdate
            },
            "template": {
                "metadata": {
                    "annotations": .spec.template.metadata.annotations
                },
                "labels": {
                    "labels": .spec.template.metadata.labels
                },
                "spec": {
                    "affinity": .spec.template.spec.affinity,
                    "securityContext": .spec.template.spec.securityContext,
                    "containers": .spec.template.spec.containers,
                    "ports": .spec.template.spec.ports,
                    "volumeMounts": .spec.template.spec.volumeMounts
                }
            },
            "volumeClaimTemplates": .spec.volumeClaimTemplates
        }
  }
' >> "$OUTPUT_FILE"
