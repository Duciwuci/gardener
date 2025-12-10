# Setup Helper Cluster

## Create Kubeconfig for `hollow`

### Prepare the Cluster Admin `ServiceAccount`

`kubectl create serviceaccount cluster-admin-sa -n kube-system`

Use the existing `ClusterRole` to create the binding:

```bash
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:cluster-admin-sa
```

### Install all CRDs

Install the CRDs in the `gardener/gardener/charts/gardener/gardenlet/templates` to this cluster. This is important to make the gardenlet's runnable in this hollow Shoot.

### Build the Kubeconfig

Create the Secret:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: cluster-admin-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: cluster-admin-sa
type: kubernetes.io/service-account-token
EOF
```

Extract the Information:

```bash
# 1. Get the Secret name
TOKEN_NAME=$(kubectl get secret -n kube-system cluster-admin-token -o jsonpath='{.metadata.name}')

# 2. Get the token (Base64 decoded)
SA_TOKEN=$(kubectl get secret -n kube-system $TOKEN_NAME -o jsonpath='{.data.token}' | base64 --decode)

# 3. Get the Cluster CA Certificate
CA_CRT=$(kubectl get secret -n kube-system $TOKEN_NAME -o jsonpath='{.data.ca\.crt}')
```

Extract the Cluster Details:

```bash
# Get the API Server URL
K8S_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# Get the Current Context Name
CONTEXT_NAME=$(kubectl config current-context)
```

**PUT IT ALL TOGETHER**:

```bash
cat <<EOF > hollow-kubeconfig.yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $CA_CRT
    server: $K8S_SERVER
  name: $CONTEXT_NAME
contexts:
- context:
    cluster: $CONTEXT_NAME
    user: cluster-admin-sa
    namespace: default
  name: cluster-admin-context
current-context: cluster-admin-context
kind: Config
preferences: {}
users:
- name: cluster-admin-sa
  user:
    token: $SA_TOKEN
EOF
```

## Prepare `helper`

**Create Kubeconfig for Garden Cluster** 

This Kubeconfig is important to access the Garden-Cluster to create Shoots.

`kubectl create secret generic garden-kubeconfig --from-file=kubeconfig=./garden-kubeconfig.yaml`

**Create Kubeconfig for Hollow Cluster** 

This Kubeconfig is important to access the Hollow-Cluster to Create Seeds.

`kubectl create secret generic hollow-kubeconfig --from-file=kubeconfig=./hollow-kubeconfig.yaml`

**Create ConfigMap for Script Creating Shoots** 

`kubectl create configmap shoot-script --from-file=shoot-script.sh=./shoot-script.sh`

**Create ConfigMap for Script Creating Seeds** 

`kubectl create configmap seed-script --from-file=seed-script.sh=./seed-script.sh`

### Prepare local files

To not push any secret data, you need to push your modified files to the cluster:

```bash
gardener_path=<your-path-to-gardener>
kubectl create configmap example-config \
  --from-file=$gardener_path/example/provider-local/shoot.yaml \
  --from-file=$gardener_path/example/gardener-local/hollow-gardenlet/values.yaml \
  --from-file=$gardener_path/example/gardener-local/hollow-gardenlet/secret-bootstrap-token.yaml
```

```bash
gardener_path=<your-path-to-gardener>
kubectl create configmap dev-setup-config \
  --from-file=$gardener_path/dev-setup/gardenconfig/components/credentials/secret-project-garden/secretbinding.yaml
```

```bash
gardener_path=<your-path-to-gardener>
kubectl create configmap charts-config \
  --from-file=$gardener_path/charts/gardener/gardenlet/values.yaml \
  --from-file=$gardener_path/charts/gardener/gardenlet/Chart.yaml
```

```bash
gardener_path=<your-path-to-gardener>
kubectl create configmap templates-config --from-file=$gardener_path/charts/gardener/gardenlet/templates
```
```bash
kubectl create configmap dev-config --from-file=./dev/shoot.yaml
```

### CronJobs

Apply it easily, whenever you are ready:

`kubectl apply -f seed-job.yaml -f shoot-job.yaml`
