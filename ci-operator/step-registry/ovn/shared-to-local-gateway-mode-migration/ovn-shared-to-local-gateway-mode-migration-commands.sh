#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -x

echo "Changing to local gateway mode"
echo "-------------------"
oc patch Network.operator.openshift.io cluster --type='merge' --patch "{\"spec\":{\"defaultNetwork\":{\"ovnKubernetesConfig\":{\"gatewayConfig\":{\"routingViaHost\":true}}}}}"

oc wait co network --for='condition=PROGRESSING=True' --timeout=60s
# Wait until the ovn-kubernetes pods are restarted
timeout 300s oc rollout status ds/ovnkube-node -n openshift-ovn-kubernetes
timeout 300s oc rollout status ds/ovnkube-master -n openshift-ovn-kubernetes

# ensure the gateway mode change was successful, if not no use proceeding with the test
mode=$(oc get Network.operator.openshift.io cluster -o template --template '{{.spec.defaultNetwork.ovnKubernetesConfig.gatewayConfig.routingViaHost}}')
echo "Routing via host is set to ${mode}"
if [[ "${mode}" = true ]]; then
  echo "Overriding to OVN local gateway mode was a success"
else
  echo "Overriding to OVN local gateway mode was a faiure"
  exit 1
fi
