#!/bin/bash

nl(){ echo -e "\n"; }
pm() { echo $1; }

clusterrole(){

	pm "OUTPUT: Cluster Role Bindings with service accounts having $1 access"

	for clusterrole in $(for scc in $(oc get scc -o custom-columns=NAME:.metadata.name,Priv:.$1 | grep true | awk '{print $1}'); do oc get clusterrole -A -o custom-columns=NAME:.metadata.name,Resource:.rules[*].resourceNames | grep "\[$scc\]" | awk '{print $1}'; done) ; do oc get clusterrolebindings $clusterrole -oyaml -o custom-columns=NAME:.metadata.name,Account:.subjects[*].name 2>/dev/null; done |column -t; nl

}

localrole(){

	pm "OUTPUT: Local Role Bindings with service accounts having $1 access"

        for role in $(for scc in $(oc get scc -o custom-columns=NAME:.metadata.name,Priv:.$1 | grep true | awk '{print $1}'); do oc get role -A -o custom-columns=NAME:.metadata.name,Resource:.rules[*].resourceNames | grep "\[$scc\]" | awk '{print $1}'; done) ; do oc get rolebindings $role -oyaml -o custom-columns=NAME:.metadata.name,Account:.subjects[*].name 2>/dev/null; done |column -t; nl

}

ocp4-cis-scc-limit-root-containers(){

	clusterrole allowPrivilegedContainer
	localrole allowPrivilegedContainer

}

ocp4-cis-scc-limit-process-id-namespace(){

        clusterrole allowHostPID
        localrole allowHostPID

}

ocp4-cis-scc-limit-privileged-containers(){

        clusterrole allowPrivilegedContainer
        localrole allowPrivilegedContainer

}

ocp4-cis-scc-limit-privilege-escalation(){

        clusterrole allowPrivilegeEscalation
        localrole allowPrivilegeEscalation

}

ocp4-cis-scc-limit-network-namespace(){

        clusterrole allowHostNetwork
        localrole allowHostNetwork

}

ocp4-cis-scc-limit-ipc-namespace(){

        clusterrole allowHostIPC
        localrole allowHostIPC

}

ocp4-cis-scc-limit-ipc-namespace(){

        clusterrole allowHostIPC
        localrole allowHostIPC

}

ocp4-cis-accounts-restrict-service-account-tokens(){

	pm "OUTPUT: Pods that have automount service account token set to false"
	oc get pods -A  -oyaml -o custom-columns=NAME:.metadata.name,Project:.metadata.namespace,SAToken:.spec.automountServiceAccountToken | grep false; nl

}

ocp4-cis-accounts-unique-service-account(){

	pm "OUTPUT: Cluster Role Bindings with default service accounts"
	for clusterrolebinding in $(oc get clusterrolebindings --no-headers | awk '{print $1}'); do oc get clusterrolebindings $clusterrolebinding -oyaml -o custom-columns=Name:.metadata.name,Account:.subjects[*].name; done |grep default |column -t; nl

	pm "OUTPUT: Local Role Bindings with default service accounts"
        for rolebinding in $(oc get rolebindings --no-headers | awk '{print $1}'); do oc get rolebindings $rolebinding -oyaml -o custom-columns=Name:.metadata.name,Account:.subjects[*].name; done |grep default |column -t; nl

}

ocp4-cis-api-server-oauth-https-serving-cert(){

	pm "OUTPUT: Type and cert data in current oauth api serving cert secret"
	oc describe secrets serving-cert -n openshift-oauth-apiserver | grep -A3 -E "Type|Data" | column -t; nl

}

ocp4-cis-api-server-openshift-https-serving-cert(){

	pm "OUTPUT: Type and cert data in current api serving cert secret"
        oc describe secrets serving-cert -n openshift-apiserver | grep -A3 -E "Type|Data" | column -t; nl

}

ocp4-cis-file-groupowner-proxy-kubeconfig(){

	pm "OUTPUT: File and Group ownership of /config/kube-proxy-config.yaml file"
	for i in $(oc get pods -n openshift-sdn -l app=sdn -oname);do echo $i $(oc exec -n openshift-sdn $i -c sdn -- stat -Lc %U:%G /config/kube-proxy-config.yaml); done; nl

}

ocp4-cis-file-owner-proxy-kubeconfig(){

	pm "OUTPUT: File and Group ownership of /config/kube-proxy-config.yaml file"
        for i in $(oc get pods -n openshift-sdn -l app=sdn -oname);do echo $i $(oc exec -n openshift-sdn $i -c sdn -- stat -Lc %U:%G /config/kube-proxy-config.yaml); done; nl 

}

#ocp4-cis-general-apply-scc(){}

ocp4-cis-general-configure-imagepolicywebhook(){

	oc get image.config.openshift.io/cluster -o yaml
	pm "OUTPUT: Check for allowed and blocked registry sources in the above output"
	pm "Reference: https://docs.openshift.com/container-platform/4.10/openshift_images/image-configuration.html"; nl

}


ocp4-cis-general-default-namespace-use(){

	pm "OUTPUT: Check that only openshift and default service is created in default ns"
	oc get all -n default; nl

}

ocp4-cis-general-default-seccomp-profile(){


	pm "OUTPUT: By default,seccomp profile is set to unconfined which means that no seccomp profiles are enabled."
	nl
	pm "To enable the default seccomp profile, use the reserved value /runtime/default that will make sure that the pod uses the default policy available on the host. If the default seccomp profile is too restrictive for you, you will need to create and manage your own seccomp profiles."

}



ocp4-cis-general-namespaces-in-use(){
	
	pm "OUTPUT: Check the namespaces created are the ones you need and are adequately administered"
	oc get ns | grep -v -E "openshift|kube|default"; nl

}

ocp4-cis-rbac-limit-cluster-admin(){

	pm "OUTPUT: Check the below users with cluster-admin role. Do not modify clusterrolebindings that include system: prefix"
	oc get clusterrolebindings -o=custom-columns=NAME:.metadata.name,ROLE:.roleRef.name,SUBJECT:.subjects[*].kind | grep -v system: | grep cluster-admin | column -t; nl

}

ocp4-cis-rbac-limit-secrets-access(){

	pm "OUTPUT: Cluster roles that have access to secrets"
	for clusterrole in $(oc get clusterrole --no-headers -o NAME | grep -v system:); do echo $clusterrole $(oc describe  $clusterrole | grep secrets | grep -v /secrets) | grep secrets ; done; nl

	pm "OUTPUT: Local roles that have access to secrets"
	for ns in $(oc get ns --no-headers -o NAME | awk -F/ '{print $2}'); do for role in $(oc get role -n $ns --no-headers -o NAME); do echo $ns $role $(oc describe  $role -n $ns | grep secrets | grep -v /secrets) | grep secrets; done;done; nl

}

ocp4-cis-rbac-pod-creation-access(){

	pm "OUTPUT: Cluster roles that have access to create pods"
	for clusterrole in $(oc get clusterrole --no-headers -o NAME | grep -v system:); do echo $clusterrole $(oc describe  $clusterrole | grep "pods " | grep create) | grep pods ; done; nl

	pm "OUTPUT: Local roles that have access to create pods"
	for ns in $(oc get ns --no-headers -o NAME | awk -F/ '{print $2}'); do for role in $(oc get role -n $ns --no-headers -o NAME); do echo $role $(oc describe  $role -n $ns | grep "pods " | grep create) | grep pods; done;done;nl 
	
}

#ocp4-cis-rbac-wildcard-use(){}

ocp4-cis-scc-drop-container-capabilities(){

	pm "OUTPUT: List of SCC's and their DROP Capabilities."
        for i in `oc get scc --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'`; do echo "$i" $(oc describe scc $i | grep "Required Drop Capabilities") ; done | column -t; nl

}

ocp4-cis-scc-limit-net-raw-capability(){

	pm "OUTPUT: List of SCC's and their DROP Capabilities."
	for i in `oc get scc --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'`; do echo "$i" $(oc describe scc $i | grep "Required Drop Capabilities") ; done | column -t; nl

}

ocp4-cis-secrets-consider-external-storage(){

	pm "OUTPUT: Check with customer if they use any third party systems to store secrets"

}

ocp4-cis-secrets-no-environment-variables(){

	pm "OUTPUT: Secrets mounted as environment variables. If the below output is blank there are no secrets that are mounted a env variables"
	oc get all -o jsonpath='{range .items[?(@..secretKeyRef)]} {.kind} {.metadata.namespace} {.metadata.name} {"\n"}{end}' -A |column -t; nl

}

for manual_check in $(oc -n openshift-compliance get compliancecheckresult | grep MANUAL | awk '{print $1}')

do
	pm "NAME:"
	oc -n openshift-compliance get compliancecheckresult $manual_check -o jsonpath='{.metadata.name}'

	nl
	pm "Description:"
	oc -n openshift-compliance get compliancecheckresult $manual_check -o jsonpath='{.description}' | xargs -d'\n'

	nl
	pm "Instructions:"
	oc -n openshift-compliance get compliancecheckresult $manual_check -o jsonpath='{.instructions}' | xargs -d'\n'

	nl
	$manual_check
done
