read -p "Make sure you're logged into the Openshift API before proceeding. Proceed (y) or Exit (n) (y/n): " confirm && [[ $confirm == [yY] ]] || exit 1
read -p "Enter target Licenase Plate (ex// d7abee, d106d6): " LICENSE_PLATE
read -p "Enter the environment (ex// dev, test, prod): " ENVIRONMENT

oc project $LICENSE_PLATE-$ENVIRONMENT

echo "Below is the list of available cronjobs in $LICENSE_PLATE-$ENVIRONMENT"
echo "---------------------------------------------------------------------------"
oc get cronjobs --no-headers | awk '{print $1}'
echo "---------------------------------------------------------------------------"
read -p "Enter the name of the target cronjob: " CRONJOB

mkdir -p "$(date +%Y-%m-%d)" && cd "$_"

OUTPUT_FILE="$CRONJOB-$ENVIRONMENT-cronjob.yaml"
IMAGE=$(oc get cronjob "$CRONJOB" -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].image}')
REPOSITORY="${IMAGE%:*}"
TAG="${IMAGE##*:}"

echo "---" > "$OUTPUT_FILE"
oc get cronjobs "$CRONJOB" -o json | REPOSITORY="$REPOSITORY" TAG="$TAG" yq -P '
    {
        .metadata.name: {
            "schedule": .spec.schedule,
            "timeZone": .spec.timeZone,
            "successfulJobsHistoryLimit": .spec.successfulJobsHistoryLimit,
            "failedJobsHistoryLimit": .spec.failedJobsHistoryLimit,
            "concurrencyPolicy": .spec.concurrencyPolicy,
            "suspend": .spec.suspend,
            "env": .spec.jobTemplate.spec.template.spec.containers[].env,
            "imagePullPolicy": .spec.jobTemplate.spec.template.spec.containers[].imagePullPolicy,
            "volumeMounts": .spec.jobTemplate.spec.template.spec.containers[].volumeMounts,
            "restartPolicy": .spec.jobTemplate.spec.template.spec.restartPolicy,
            "image": {
                "repository": env(REPOSITORY),
                "tag": env(TAG)
            }
        }
    }
' >> "$OUTPUT_FILE"
