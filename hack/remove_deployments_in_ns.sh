#!/bin/bash 
# Scales to zero and deletes deployments
# Specify:
#   -n|--namespace  - the namespace
#   -r|--rebuild    - turn on flux rebuilds
#   -d|--delete     - perform deployment deletes
#   deployment1 deployment2
print_help()
{
	printf '%s\n' "Help"
	printf 'Usage: %s -n|--namespace <arg> -k|--kustomization <arg> [--r, --rebuild] [-d, --delete] [-h|--help] <deployments>\n' "$0"
	printf '\t%s\n' "<deployment>: one or more deployments, if none all is selected"
	printf '\t%s\n' "-r, --resume: optional flag to resume flux operations after script is done"
    printf '\t%s\n' "-d, --delete: optional flag to delete each deployment"
    printf '\t%s\n' "-n, --namespace: required name of the namespace the deployments are located in"
    printf '\t%s\n' "-k, --kustomization: required name of the kustomization to suspend/resume"
	printf '\t%s\n' "-h, --help: Prints help"
    printf '\t%s\n' "Example:"
    printf '\t%s\n' "$0 -n media -r --kustomization apps bazarr sonarr"
}

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -r|--resume)
      RESUME_FLAG=1
      shift
      ;;
    -d|--delete)
      DELETE_FLAG=1
      shift
      ;;
    -n|--namespace)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        NAMESPACE=$2
        shift 2
      else
        echo "✗ Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -k|--kustomization)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        KUSTOMIZATION=$2
        shift 2
      else
        echo "✗ Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -h|--help)
        print_help
        exit 0
        ;;
    -h*)
        print_help
        exit 0
        ;;
    -*|--*=) # unsupported flags
      echo "✗ Error: Unsupported flag $1" >&2
      print_help
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

# Setup environment
cd ~/cluster
export KUBECONFIG="/home/dfroberg/cluster/kubeconfig"

# Script takes argument schipt.sh 'bazarr|test|sonarr' or blank for all deployments.
if [[ -z $NAMESPACE ]] 
then
    echo "✗ No namespace specified, i.e. --namespace=media !"
    exit 2
else
    echo "Namespace: $NAMESPACE"
fi
if [[ -z $KUSTOMIZATION ]] 
then
    echo "✗ No kustomization specified, i.e. --kustomization=apps !"
    exit 2
else
    echo "Kustomization: $KUSTOMIZATION"
fi
if [[ -z $1 ]] 
then
    echo "► Deployments: all"
    deploymentselector=""
else
    deparg=$@
    echo "► Deployments: $deparg"
    deploymentselector=${deparg// /|}
    
fi
DEPLOYMENTS=$(kubectl get deploy -n $NAMESPACE -owide 2> /dev/null | grep -E "$deploymentselector" | awk '{print $1}' | grep -v "NAME" )
if [[ -z $DEPLOYMENTS ]] 
then
    echo "✗ No matching deployments found!"
    if [[ $REBUILD_FLAG == 0 ]] 
    then
        exit 2
    fi
    
fi

# Turn off automatic rebuilds
echo "► Suspending deployments:"
for deployment in $DEPLOYMENTS
do
    flux suspend helmrelease $deployment -n $NAMESPACE
done
# This one needs to be global
flux suspend kustomization $KUSTOMIZATION
echo "✔ Suspended helmreleases and kustomization rebuild of apps"

# Scale deployments to 0
echo "► Scaling deployments to zero:"
for deployment in $DEPLOYMENTS
do
    echo "◎ Scaling $deployment"
    kubectl scale -n $NAMESPACE deploy/$deployment --replicas 0 
done
echo "✔ Scaled all deployments to zero."
echo "► Waiting for pods to terminate"

while true; do
  check=$(kubectl get pods -n $NAMESPACE 2> /dev/null | grep -E "$deployment" | awk '{print $1}' | grep -v "NAME"  )
  [[ -z $check ]] && break
  echo -n "."
  sleep 3
done
echo "!"
echo "✔ All pods in namespace $NAMESPACE has terminated."

if [[ $DELETE_FLAG == 1 ]]
then
    # Remove deployments
    echo "► Deleting deployments:"
    for deployment in $DEPLOYMENTS
    do
            echo "◎ Deleting deployment $deployment"
            kubectl delete deployment $deployment -n $NAMESPACE --wait 
    done
    echo "✔ Done deleting!"
else
    echo "► Skipped deployment deletions "
fi
# TBD: Make SURE everything is deleted


if [[ $REBUILD_FLAG == 1 ]]
then 
    echo "► Resuming kustomizations:"
    flux resume kustomization $KUSTOMIZATION
    echo "► Resuming helmreleases:"
    flux resume helmrelease --all -n $NAMESPACE
    echo "✔ Resumed cluster rebuild of apps"
else
    echo "► Skipped resuming kustomizations and helmreleases:"
fi

