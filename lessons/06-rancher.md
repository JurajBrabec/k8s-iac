# Lesson 6 — Rancher Manager

**Time:** 3 hours. **Level:** intermediate to advanced. **Prerequisite:** working ingress and instructor-approved, compatible Rancher, RKE2 and cert-manager versions.

## Objectives and concepts

Install and use Rancher Manager to inspect the local RKE2 cluster. Compare management-cluster and downstream-cluster roles, projects, namespaces and RBAC. This all-in-one single-replica installation is for training, not a production reference architecture.

## Exercise

1. Confirm the Rancher FQDN resolves to the ingress endpoint. Set the hostname and instructor-approved chart versions:
   ```bash
   export RANCHER_FQDN='rancher.lab.example'
   export RANCHER_CHART_VERSION='<approved-rancher-chart-version>'
   export CERT_MANAGER_VERSION='<approved-cert-manager-chart-version>'
   ```
2. Install cert-manager using the version tested with the selected Rancher release. Rancher uses it to issue and maintain its own CA and ingress certificate:
   ```bash
   helm repo add jetstack https://charts.jetstack.io
   helm repo update
   helm install cert-manager jetstack/cert-manager \
     --namespace cert-manager --create-namespace \
     --version "$CERT_MANAGER_VERSION" --set crds.enabled=true \
     --wait --timeout 5m
   kubectl create namespace cattle-system
   helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
   helm repo update
   helm install rancher rancher-stable/rancher -n cattle-system \
     --version "$RANCHER_CHART_VERSION" \
     --set hostname="$RANCHER_FQDN" --set replicas=1 \
     --set ingress.tls.source=rancher \
     --wait --timeout 15m
   kubectl -n cattle-system rollout status deploy/rancher --timeout=15m
   ```
   No `tls-rancher-ingress` or `tls-ca` secret is created manually for this certificate source. The generated certificate is self-signed, so a browser trust warning is expected unless the Rancher CA is explicitly trusted on the workstation. In this isolated lab, verify the hostname and certificate before proceeding; never disable certificate validation globally or do so for production systems.
3. Open `https://<RANCHER_FQDN>`. Retrieve the generated bootstrap password on a private terminal, then set a strong administrator password and retain it securely. Do not copy the password into course evidence:
   ```bash
   kubectl -n cattle-system get secret bootstrap-secret -o go-template='{{ .data.bootstrapPassword | base64decode }}{{ "\n" }}'
   ```
4. In Rancher inspect the local cluster, all configured nodes, `lab` namespace and workload. Create a project and a separate namespace for the permissions exercise. Create a local restricted user, grant only the needed project membership, log in in a separate browser session and verify an allowed read and a denied administrative action. Restore the administrator session.
5. Explain how a separate HA Rancher management cluster, downstream clusters, real identity provider, backup and trusted TLS would improve on the lab topology.

## Acceptance

- Rancher is reachable at its HTTPS hostname and displays the expected cluster and nodes. The participant explains that the lab certificate is self-signed and how to establish trust rather than bypassing certificate validation in production.
- The participant records one allowed and one denied action for the restricted user.
- The participant can distinguish RKE2 from Rancher Manager and state the single-cluster failure limitation.

**Hints:** Use `kubectl -n cattle-system get pods,ingress`, `kubectl -n cattle-system logs deploy/rancher`, `kubectl -n cert-manager get pods`, certificate inspection and the ingress controller logs. Never publish or commit TLS keys or bootstrap credentials.
