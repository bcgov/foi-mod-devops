#!/bin/bash

read -p "Make sure you're logged into the Openshift API before proceeding. Proceed (y) or Exit (n): " confirm && [[ $confirm == [yY] ]] || exit 1
read -p "Enter target database you're recovering (ex// foidb or foi-docreviewer): " database
read -p "What environment are you targetting? (ex// dev, test or prod): " environment
echo "This is the start of a disaster recovery exercise for $database"
read -p "To continue scaling all pods down in d7abee and d106d6 that consume $database, proceed (y) or exit (n): " confirm && [[ $confirm == [yY] ]] || exit 1

scale_environment(){
    echo "turnning off all consumer of the $1 in d7abee-$2."

    oc project d7abee-$2

    local deployments_d7abee=$(oc get deployment -n d7abee-$2 -l foidb-disaster-recovery=true -o jsonpath='{.items[*].metadata.name}')

    echo "Found deployments. Starting to scale all deployments with label foidb-disaster-recovery=true to zero."

        for deployment in ${deployments_d7abee}; do
        echo "Scaling '${deployment}' down to 0...."
        oc scale deployment/"${deployment}" -n d7abee-$2 --replicas=0
    done

    echo "All deployments with label foidb-disaster-recovery=true have been scaled to zero."

    echo "Turning off all consumers of the $1 in the d106d6-$2."

    oc project d106d6-$2

    local deployments_d106d6=$(oc get deployment -n d106d6-$2 -l foidb-disaster-recovery=true -o jsonpath='{.items[*].metadata.name}')

    echo "Found deployments. Starting to scall all deployments with label foidb-disaster-recovery=true to zero."

    for deployment in $deployments_d106d6; do
        echo "Scaling $deployment down to 0..."
        oc scale deployment/$deployment -n d106d6-$2 --replicas=0
    done

    echo "All deployments with label foidb-disaster-recovery=true have been scaled to zero."
}

if [[ "$database" == "foidb" ]]; then

    scale_environment "$database" "$environment"

elif [[ "$database" == "foi-docreviewer" ]]; then

    scale_environment "$database" "$environment"

fi