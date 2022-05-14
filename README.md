# compliance

**Git**
```
echo "# compliance" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/alpha-wolf-jin/compliance.git
git config --global credential.helper 'cache --timeout 7200'
git push -u origin main


git add . ; git commit -a -m "update README" ; git push -u origin main
```

**oc logn**
```
# oc login https://api.vuyee8aj.eastus.aroapp.io:6443/
You must obtain an API token by visiting https://oauth-openshift.apps.vuyee8aj.eastus.aroapp.io/oauth/token/request

oc login --token=sha256~ylgJMYfU --server=https://api.vuyee8aj.eastus.aroapp.io:6443
```
## Compliance Operator Deployment


The Compliance Operator lets OpenShift Container Platform administrators describe the required compliance state of a cluster and provides them with an overview of gaps and ways to remediate them.


**Installing Compliance Operator**

- 1. In the OpenShift Container Platform web console, navigate to Operators → OperatorHub.
- 2. Search for the Compliance Operator, then click Install.
- 3. Keep the default selection of Installation mode and namespace to ensure that the Operator will be installed to the openshift-compliance namespace.
- 4. Click Install.

**Verification**

- 1. Navigate to the Operators → Installed Operators page.
- 2. Check that the Compliance Operator is installed in the openshift-compliance namespace and its status is Succeeded.

## Compliance Operator Scan

```
# oc project openshift-compliance
```

**ScanSetting**
```
# cat scansetting.yaml
apiVersion: compliance.openshift.io/v1alpha1
kind: ScanSetting
metadata:
  name: rs-on-workers
  namespace: openshift-compliance
rawResultStorage:
  nodeSelector:
    node-role.kubernetes.io/worker: ""
  pvaccessModes:
  - ReadWriteOnce
  storageClassName: managed-premium
  rotation: 10
  size: 10Gi
roles:
- worker
- master
scanTolerations:
  - operator: Exists
schedule: '0 1 * * *'

# oc apply -f scansetting.yaml


```

>Change the the role and toleration accordingly

https://gitlab.consulting.redhat.com/customer-success/consulting-engagement-reports/client-cers/asean/sg/mha/mha-prod-ocp4.7-3789831#user-content-configuring-openshift-compliance

```
# vi mha-scansetting.yaml
apiVersion: compliance.openshift.io/v1alpha1
kind: ScanSetting
metadata:
  name: mha-scansetting
  namespace: openshift-compliance
rawResultStorage:
  pvAccessModes:
  - ReadWriteOnce
  rotation: 3
  size: 1Gi
roles:
- worker
- master
- ingress
- monitoring
- log
scanTolerations:
- effect: NoSchedule
  key: node-role.kubernetes.io/master
  operator: Exists
- effect: NoSchedule
  key: ingress
  value: reserved
  operator: Equals
- effect: NoSchedule
  key: monitoring
  value: reserved
  operator: Equals
- effect: NoSchedule
  key: log
  value: reserved
  operator: Equals
schedule: 0 1 * * *

# oc get ScanSetting
NAME                 AGE
default              14m
default-auto-apply   14m
rs-on-workers        13m

```
## ScanSettingBinding

```
# cat scansettingbinding.yaml
apiVersion: compliance.openshift.io/v1alpha1
kind: ScanSettingBinding
metadata:
  name: cis-compliance-01
profiles:
  - name: ocp4-cis
    kind: Profile
    apiGroup: compliance.openshift.io/v1alpha1
  - name: ocp4-cis-node
    kind: Profile
    apiGroup: compliance.openshift.io/v1alpha1
settingsRef:
  name: rs-on-workers
  kind: ScanSetting
  apiGroup: compliance.openshift.io/v1alpha1

# oc apply -f scansettingbinding.yaml

# oc get ScanSettingBinding
NAME                AGE
cis-compliance-01   8m35s

```

## CIS Master PV

```
# vim ocp4-cis-master-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ocp4-cis-master-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-premium

# oc apply -f ocp4-cis-master-pv.yaml

```

## CIS Worker PV

```
# vim ocp4-cis-worker-pv
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ocp4-cis-worker-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-premium

# oc apply -f ocp4-cis-worker-pv.yaml

```

## CIS PV

```
# vim ocp4-cis-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ocp4-cis-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: managed-premium

# oc apply -f ocp4-cis-pv.yaml

```

## CIS PV - Pod to Extract Results

```
# vim ocp4-cis-pv-extract.yaml
apiVersion: "v1"
kind: Pod
metadata:
  name: ocp4-cis-pv-extract
spec:
  containers:
    - name: ocp4-cis-pv-extract-pod
      image: registry.access.redhat.com/ubi8/ubi
      command: ["sleep", "3000"]
      volumeMounts:
      - mountPath: "/ocp4-cis--scan-results"
        name: ocp4-cis-worker-pv
  volumes:
    - name: ocp4-cis-worker-pv
      persistentVolumeClaim:
        claimName: ocp4-cis

# oc apply -f ocp4-cis-pv-extract.yaml

# oc get pod ocp4-cis-pv-extract
NAME                  READY   STATUS    RESTARTS   AGE
ocp4-cis-pv-extract   1/1     Running   0          75s

```

# How to use the Compliance Operator in Red Hat OpenShift

https://access.redhat.com/solutions/5712421

## The Compliance Operator ships several compliance profiles out of the box
```
# oc get -n openshift-compliance profile.compliance
NAME                 AGE
ocp4-cis             43m
ocp4-cis-node        43m
ocp4-e8              43m
ocp4-moderate        43m
ocp4-moderate-node   43m
ocp4-nerc-cip        43m
ocp4-nerc-cip-node   43m
ocp4-pci-dss         43m
ocp4-pci-dss-node    43m
rhcos4-e8            43m
rhcos4-moderate      43m
rhcos4-nerc-cip      43m

```

**description should contain hints about the profile**
```
[root@localhost compliance]# oc get -n openshift-compliance profile.compliance ocp4-cis-node -o yaml | head
apiVersion: compliance.openshift.io/v1alpha1
description: This profile defines a baseline that aligns to the Center for Internet
  Security® Red Hat OpenShift Container Platform 4 Benchmark™, V1.1. This profile
  includes Center for Internet Security® Red Hat OpenShift Container Platform 4 CIS
  Benchmarks™ content. Note that this part of the profile is meant to run on the Operating
  System that Red Hat OpenShift Container Platform 4 runs on top of. This profile
  is applicable to OpenShift versions 4.6 and greater.
id: xccdf_org.ssgproject.content_profile_cis-node
kind: Profile

```

## Verification of compliance test execution

**The ScanSettingBinding will create a ComplianceSuite**
```
[root@localhost compliance]# oc get compliancesuites
NAME                PHASE   RESULT
cis-compliance-01   DONE    NON-COMPLIANT


```

**ComplianceSuite creates ComplianceScans**

```
# oc get compliancescans 
NAME                   PHASE   RESULT
ocp4-cis               DONE    NON-COMPLIANT
ocp4-cis-node-master   DONE    NON-COMPLIANT
ocp4-cis-node-worker   DONE    NON-COMPLIANT

```

```
[root@localhost compliance]# oc get pods -o wide
NAME                                                        READY   STATUS      RESTARTS      AGE   IP            NODE                                           NOMINATED NODE   READINESS GATES
aggregator-pod-ocp4-cis                                     0/1     Completed   0             42m   10.130.0.54   aro-cluster-zzzmc-k2ssj-master-1               <none>           <none>
aggregator-pod-ocp4-cis-node-master                         0/1     Completed   0             42m   10.128.0.63   aro-cluster-zzzmc-k2ssj-master-0               <none>           <none>
aggregator-pod-ocp4-cis-node-worker                         0/1     Completed   0             42m   10.128.0.62   aro-cluster-zzzmc-k2ssj-master-0               <none>           <none>
compliance-operator-84d85bc88f-h6ks9                        1/1     Running     1 (50m ago)   51m   10.128.0.58   aro-cluster-zzzmc-k2ssj-master-0               <none>           <none>
ocp4-cis-api-checks-pod                                     0/2     Completed   0             43m   10.128.0.60   aro-cluster-zzzmc-k2ssj-master-0               <none>           <none>
ocp4-cis-node-master-aro-cluster-zzzmc-k2ssj-master-0-pod   0/2     Completed   0             43m   10.128.0.61   aro-cluster-zzzmc-k2ssj-master-0               <none>           <none>
ocp4-cis-node-master-aro-cluster-zzzmc-k2ssj-master-1-pod   0/2     Completed   0             43m   10.130.0.53   aro-cluster-zzzmc-k2ssj-master-1               <none>           <none>
ocp4-cis-node-master-aro-cluster-zzzmc-k2ssj-master-2-pod   0/2     Completed   0             43m   10.129.0.76   aro-cluster-zzzmc-k2ssj-master-2               <none>           <none>
ocp4-cis-pv-extract                                         1/1     Running     0             20m   10.128.2.52   aro-cluster-zzzmc-k2ssj-worker-eastus3-j76jg   <none>           <none>
ocp4-openshift-compliance-pp-77849b4ff4-c2gld               1/1     Running     0             50m   10.130.0.52   aro-cluster-zzzmc-k2ssj-master-1               <none>           <none>
openscap-pod-7eae438a8db5097be20881bc53a2d26b593da270       0/2     Completed   0             43m   10.131.0.17   aro-cluster-zzzmc-k2ssj-worker-eastus2-7dgmg   <none>           <none>
openscap-pod-8885e18ac4bfc20261916fbf7f67f9430fb8aed9       0/2     Completed   0             43m   10.128.2.36   aro-cluster-zzzmc-k2ssj-worker-eastus3-j76jg   <none>           <none>
openscap-pod-f2b59d848a1e279ce70a7b1cdf224688d1137361       0/2     Completed   0             43m   10.129.2.20   aro-cluster-zzzmc-k2ssj-worker-eastus1-jvmn4   <none>           <none>
rhcos4-openshift-compliance-pp-77c6d7f7fd-fh89l             1/1     Running     0             50m   10.128.0.59   aro-cluster-zzzmc-k2ssj-master-0               <none>           <none>

```

**Wait until all scans complete**
```
# oc get compliancescans -n openshift-compliance
NAME                   PHASE   RESULT
ocp4-cis               DONE    NON-COMPLIANT
ocp4-cis-node-master   DONE    NON-COMPLIANT
ocp4-cis-node-worker   DONE    NON-COMPLIANT

```

**check results **
```
# oc get ComplianceCheckResult
NAME                                                                           STATUS   SEVERITY
ocp4-cis-accounts-restrict-service-account-tokens                              MANUAL   medium
ocp4-cis-accounts-unique-service-account                                       MANUAL   medium
ocp4-cis-api-server-admission-control-plugin-alwaysadmit                       PASS     medium
ocp4-cis-api-server-admission-control-plugin-alwayspullimages                  PASS     high
ocp4-cis-api-server-admission-control-plugin-namespacelifecycle                PASS     medium
ocp4-cis-api-server-api-priority-gate-enabled                                  PASS     medium
ocp4-cis-api-server-audit-log-maxbackup                                        PASS     low
ocp4-cis-api-server-audit-log-maxsize                                          PASS     medium
ocp4-cis-api-server-audit-log-path                                             PASS     high
ocp4-cis-api-server-auth-mode-rbac                                             PASS     medium
ocp4-cis-api-server-basic-auth                                                 PASS     medium
ocp4-cis-api-server-bind-address                                               PASS     low
ocp4-cis-api-server-client-ca                                                  PASS     medium
ocp4-cis-api-server-encryption-provider-cipher                                 FAIL     medium
ocp4-cis-api-server-encryption-provider-config                                 FAIL     medium
ocp4-cis-api-server-etcd-ca                                                    PASS     medium
...

# oc get ComplianceCheckResult | grep FAIL
ocp4-cis-api-server-encryption-provider-cipher                                 FAIL     medium
ocp4-cis-api-server-encryption-provider-config                                 FAIL     medium
ocp4-cis-audit-log-forwarding-enabled                                          FAIL     medium
ocp4-cis-configure-network-policies-namespaces                                 FAIL     high
ocp4-cis-idp-is-configured                                                     FAIL     medium
ocp4-cis-kubeadmin-removed                                                     FAIL     medium
ocp4-cis-node-master-kubelet-configure-event-creation                          FAIL     medium
...


```

**remediations**
```
# oc get ComplianceRemediation
NAME                                                                             STATE
ocp4-cis-api-server-encryption-provider-cipher                                   NotApplied
ocp4-cis-api-server-encryption-provider-config                                   NotApplied
ocp4-cis-node-master-kubelet-configure-event-creation                            NotApplied
ocp4-cis-node-master-kubelet-configure-tls-cipher-suites                         NotApplied
...

```

**To apply a remediation, edit that object and set its Apply attribute to true**

oc patch -n openshift-compliance complianceremediation ocp4-cis-api-server-encryption-provider-config -p '{"spec":{"apply":true}}' --type='merge'
complianceremediation.compliance.openshift.io/ocp4-cis-api-server-encryption-provider-config patched

**Then, verify**

oc get -n openshift-compliance complianceremediation ocp4-cis-api-server-encryption-provider-config 


# Reverting to original configuration

https://docs.openshift.com/container-platform/4.6/security/compliance_operator/compliance-operator-remediation.html#compliance-unapplying_compliance-remediation

## Applying manual compliance remediations

Failed checks without a complianceremediation object must be remediated manually. In that case, extract all ARF reports from the PhysicalVolumes as shown below and convert them to HTML files. The resulting HTML reports will explain the manual remediation steps that must be taken.


## Rerunning scans

oc annotate compliancescans/<scan_name> compliance.openshift.io/rescan=


# Retrieving scan reports

**The ARF results are stored on Physical Volumes**

```
# oc get pv -n openshift-compliance
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                       STORAGECLASS      REASON   AGE
pvc-027d1c96-4836-4fce-894b-f9cf1e64dc88   10Gi       RWO            Delete           Bound    openshift-compliance/ocp4-cis-node-worker   managed-premium            81m
pvc-2492fd8d-63ee-497d-ac58-7de275955b9d   10Gi       RWO            Delete           Bound    openshift-compliance/ocp4-cis               managed-premium            81m
pvc-6c8b2230-c1f2-4165-8e2d-3aba9077634e   10Gi       RWO            Delete           Bound    openshift-compliance/ocp4-cis-node-master   managed-premium            81m

# oc get pvc -n openshift-compliance
NAME                   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
ocp4-cis               Bound    pvc-2492fd8d-63ee-497d-ac58-7de275955b9d   10Gi       RWO            managed-premium   82m
ocp4-cis-node-master   Bound    pvc-6c8b2230-c1f2-4165-8e2d-3aba9077634e   10Gi       RWO            managed-premium   82m
ocp4-cis-node-worker   Bound    pvc-027d1c96-4836-4fce-894b-f9cf1e64dc88   10Gi       RWO            managed-premium   82m

```

**in order to extract results from the 3 tests above, spawn a pod that binds to the 3 PVs**

```
cat <<'EOF' | oc apply -n openshift-compliance -f -
apiVersion: "v1"
kind: Pod
metadata:
  name: pv-extract-ocp4-cis
spec:
  containers:
    - name: pv-extract-pod-ocp4-cis
      image: registry.access.redhat.com/ubi8/ubi
      command: ["sleep", "3000"]
      volumeMounts:
        - mountPath: "/ocp4-cis-vol"
          name: ocp4-cis-vol
  volumes:
    - name: ocp4-cis-vol
      persistentVolumeClaim:
        claimName: ocp4-cis
EOF

# oc get pod/pv-extract-ocp4-cis
NAME                  READY   STATUS    RESTARTS   AGE
pv-extract-ocp4-cis   1/1     Running   0          10s

# oc exec -n openshift-compliance pv-extract-ocp4-cis -- ls /ocp4-cis-vol/0/
ocp4-cis-api-checks-pod.xml.bzip2

# oc cp pv-extract-ocp4-cis:/ocp4-cis-vol/0 .

# ll ocp4-cis-api-checks-pod.xml.bzip2
-rw-r--r--. 1 root root 240026 May 14 20:59 ocp4-cis-api-checks-pod.xml.bzip2

# bunzip2 ocp4-cis-api-checks-pod.xml.bzip2
bunzip2: Can't guess original name for ocp4-cis-api-checks-pod.xml.bzip2 -- using ocp4-cis-api-checks-pod.xml.bzip2.out

# head ocp4-cis-api-checks-pod.xml.bzip2.out
<?xml version="1.0" encoding="UTF-8"?>
<arf:asset-report-collection xmlns:arf="http://scap.nist.gov/schema/asset-reporting-format/1.1" xmlns:core="http://scap.nist.gov/schema/reporting-core/1.1" xmlns:ai="http://scap.nist.gov/schema/asset-identification/1.1">
  <core:relationships xmlns:arfvocab="http://scap.nist.gov/specifications/arf/vocabulary/relationships/1.0#">
    <core:relationship type="arfvocab:createdFor" subject="xccdf1">
      <core:ref>collection1</core:ref>
    </core:relationship>
    <core:relationship type="arfvocab:isAbout" subject="xccdf1">
      <core:ref>asset0</core:ref>
    </core:relationship>
  </core:relationships>

# mv ocp4-cis-api-checks-pod.xml.bzip2.out ocp4-cis-api-checks-pod.xml

# yum install openscap-scanner -y

# oscap xccdf generate report  ocp4-cis-api-checks-pod.xml > report.html

```
![Create DNS ZONE](images/compliance-01.png)

