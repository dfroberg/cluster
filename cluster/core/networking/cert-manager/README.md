# Using External Vault with Helm Vault Injector
## Create Service
export EXTERNAL_VAULT_ADDR=192.168.3.94
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: external-vault
  namespace: default
spec:
  ports:
  - protocol: TCP
    port: 8200
---
apiVersion: v1
kind: Endpoints
metadata:
  name: external-vault
subsets:
  - addresses:
      - ip: $EXTERNAL_VAULT_ADDR
    ports:
      - port: 8200
EOF

# Using Vault as PKI
vault secrets enable pki
vault secrets tune -max-lease-ttl=8760h pki

# Example
vault write pki/root/generate/internal \
    common_name=example.com \
    ttl=8760h

# Policies
vault write pki/config/urls \
    issuing_certificates="https://vault.cs.aml.ink/v1/pki/ca" \
    crl_distribution_points="https://vault.cs.aml.ink/v1/pki/crl"


vault write pki/roles/example-dot-com \
    allowed_domains=example.com \
    allow_subdomains=true \
    max_ttl=72h

vault policy write pki - <<EOF
path "pki*"                        { capabilities = ["read", "list"] }
path "pki/sign/example-dot-com"    { capabilities = ["create", "update"] }
path "pki/issue/example-dot-com"   { capabilities = ["create"] }
EOF

# Enabling Kuberenetes Auth
vault auth enable kuberenetes

# Point to internal node or LB
<!-- 
    export KUBERNETES_PORT_6443_TCP_ADDR=192.168.30.60
    vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_6443_TCP_ADDR:6443" \
    token_reviewer_jwt="$(kubectl get secret $(kubectl get serviceaccount default -ojson | jq .secrets[].name -r) -ojson | jq .data.token -r | base64 --decode)" \
    kubernetes_ca_cert="$(kubectl get secret $(kubectl get serviceaccount default -ojson | jq .secrets[].name -r) -ojson | jq .data'."ca.crt"' -r | base64 --decode)" \
    issuer="https://kubernetes.default.svc.cluster.local" 
-->



vault write auth/kubernetes/role/issuer \
    bound_service_account_names=issuer \
    bound_service_account_namespaces=default \
    policies=pki \
    ttl=20m

kubectl create serviceaccount issuer
kubectl get secrets

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: issuer
EOF

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: issuer-secret
  annotations:
    kubernetes.io/service-account.name: issuer
type: kubernetes.io/service-account-token
EOF

kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: vault-issuer
  namespace: default
spec:
  vault:
    server: https://vault.cs.aml.ink
    path: pki/sign/example-dot-com
    auth:
      kubernetes:
        mountPath: /v1/auth/kubernetes
        role: issuer
        secretRef:
          name: issuer-secret
          key: token
EOF

kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com
  namespace: default
spec:
  secretName: example-com-tls
  issuerRef:
    name: vault-issuer
  commonName: www.example.com
  dnsNames:
  - www.example.com
EOF


kubectl describe certificate.cert-manager example-com

kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1alpha3
kind: ClusterIssuer
metadata:
  name: vault-issuer
spec:
  vault:
    path: pki/sign/cert-manager
    server: https://vault.${SECRET_NODE_DOMAIN}
    # caBundle: ${vault_ca}
    auth:
      kubernetes:
        role: cert-manager
        mountPath: /v1/auth/kubernetes-${cluster}
        secretRef:
          name: ${sa_secret_name}
          key: token
EOF

## Add Vault Secrets injector
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault hashicorp/vault \
    --set "injector.externalVaultAddr=http://external-vault.default.svc.cluster.local:8200"
vault auth enable kubernetes
VAULT_HELM_SECRET_NAME=$(kubectl get secrets --output=json | jq -r '.items[].metadata | select(.name|startswith("vault-token-")).name')
TOKEN_REVIEW_JWT=$(kubectl get secret $VAULT_HELM_SECRET_NAME --output='go-template={{ .data.token }}' | base64 --decode)
KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')
vault write auth/kubernetes/config \
        token_reviewer_jwt="$TOKEN_REVIEW_JWT" \
        kubernetes_host="$KUBE_HOST" \
        kubernetes_ca_cert="$KUBE_CA_CERT" \
        issuer="https://kubernetes.default.svc.cluster.local"

