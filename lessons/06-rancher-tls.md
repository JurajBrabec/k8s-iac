# Lesson 6 — Rancher Manager (Custom TLS)

**Time:** 3 hours. **Level:** intermediate to advanced. **Prerequisite:** working ingress, instructor-approved Rancher/RKE2 versions, and a lab TLS certificate signed by a CA trusted on the workstation.

## Objectives and concepts

Install and use Rancher Manager to inspect the local RKE2 cluster. Compare management-cluster and downstream-cluster roles, projects, namespaces and RBAC. This all-in-one single-replica installation is for training, not a production reference architecture.

## Exercise

1. Confirm the Rancher FQDN resolves to the ingress endpoint. The instructor prepares the certificate files under `$HOME/certs/` outside the repository and installs the CA certificate on the workstation. Confirm the certificate SAN matches the hostname, then set the hostname and approved chart version:
   ```bash
   export RANCHER_FQDN='rancher.lab.example'
   export RANCHER_CHART_VERSION='<approved-rancher-chart-version>'
   ```
2. Create the namespace and TLS secret. The certificate must include the required chain. For the private-CA certificate used in this exercise, also create Rancher's CA bundle:
   ```bash
   kubectl create namespace cattle-system
   kubectl -n cattle-system create secret tls tls-rancher-ingress \
     --cert="$HOME/certs/tls.crt" --key="$HOME/certs/tls.key"
   kubectl -n cattle-system create secret generic tls-ca \
     --from-file=cacerts.pem="$HOME/certs/ca.crt"
   helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
   helm repo update
   helm install rancher rancher-stable/rancher -n cattle-system \
     --version "$RANCHER_CHART_VERSION" \
     --set hostname="$RANCHER_FQDN" --set replicas=1 \
     --set ingress.tls.source=secret --set privateCA=true \
     --wait --timeout 15m
   kubectl -n cattle-system rollout status deploy/rancher --timeout=15m
   ```
   With a publicly trusted certificate, omit the `tls-ca` secret command and `--set privateCA=true`; keep the TLS secret and `ingress.tls.source=secret`. This custom-secret path does not install cert-manager. Validate the chart's TLS requirements against its chosen version.
3. Open `https://<RANCHER_FQDN>`. Retrieve the generated bootstrap password on a private terminal, then set a strong administrator password and retain it securely. Do not copy the password into course evidence:
   ```bash
   kubectl -n cattle-system get secret bootstrap-secret -o go-template='{{ .data.bootstrapPassword | base64decode }}{{ "\n" }}'
   ```
4. In Rancher inspect the local cluster, all configured nodes, `lab` namespace and workload. Create a project and a separate namespace for the permissions exercise. Create a local restricted user, grant only the needed project membership, log in in a separate browser session and verify an allowed read and a denied administrative action. Restore the administrator session.
5. Explain how a separate HA Rancher management cluster, downstream clusters, real identity provider, backup and trusted TLS would improve on the lab topology.

## Acceptance

- Rancher is reachable at its HTTPS hostname with the browser trusting the certificate, and displays the expected cluster and nodes.
- The participant records one allowed and one denied action for the restricted user.
- The participant can distinguish RKE2 from Rancher Manager and state the single-cluster failure limitation.

**Hints:** Use `kubectl -n cattle-system get pods,ingress`, `kubectl -n cattle-system logs deploy/rancher`, certificate SAN inspection and the ingress controller logs. Never publish or commit TLS keys or bootstrap credentials.
