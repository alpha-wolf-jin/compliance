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

