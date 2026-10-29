# Lesson 8 — Prometheus and Grafana

**Time:** 3 hours. **Level:** advanced. **Prerequisite:** Lesson 7; healthy app and working Argo reconciliation.

## Objectives and concepts

Prometheus collects time-series metrics; Grafana queries and visualizes them; Alertmanager routes alerts. Logs provide individual events and traces describe distributed request paths: neither is replaced by metrics. Counters reset when pods restart, so use `rate` rather than raw values for traffic.

## Exercise

1. Choose an instructor-approved compatible kube-prometheus-stack chart version. The version must be explicit, not `latest`:
   ```bash
   export MONITORING_CHART_VERSION='<approved-chart-version>'
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update
   helm upgrade --install monitor prometheus-community/kube-prometheus-stack \
     -n monitoring --create-namespace --version "$MONITORING_CHART_VERSION" \
     -f monitoring/values.yaml --wait --timeout 15m
   kubectl -n monitoring get pods
   kubectl apply -f manifests/monitoring.yaml
   ```
   The provided values select ServiceMonitors and rules without the release-only selector. This is permissive for a dedicated lab; scope selectors in production. Prometheus and Grafana storage is ephemeral by default and alert notifications have no external receiver.
2. Start a Prometheus port forward on the workstation in another terminal:
   ```bash
   kubectl -n monitoring port-forward svc/monitor-kube-prometheus-prometheus 9090:9090
   ```
   Open `http://localhost:9090/targets`. Find `lab/lab-app` targets, allow time for scraping and verify they are `UP`. If service names differ with the chosen chart version, find the actual name using `kubectl -n monitoring get svc`.
3. Generate traffic including deliberate errors:
   ```bash
   for i in $(seq 1 50); do curl -sS -o /dev/null http://<APP_FQDN>/; done
   for i in $(seq 1 10); do curl -sS -o /dev/null http://<APP_FQDN>/fail; done
   ```
   In Prometheus evaluate `sum(rate(lab_http_requests_total[5m]))` and `sum(rate(lab_http_requests_total{status="500"}[5m]))`. Rate needs at least two scrape samples; generate more requests if necessary.
4. Port-forward Grafana in a separate terminal with `kubectl -n monitoring port-forward svc/monitor-grafana 3000:80`. In another private terminal retrieve the generated password, log in as `admin` at `http://localhost:3000` and change the password. Do not put credentials in the dashboard or evidence.
   ```bash
   kubectl -n monitoring get secret monitor-grafana -o jsonpath='{.data.admin-password}' | base64 --decode; echo
   ```
   Create a dashboard with request rate and 500 rate panels using the two queries above; generate more traffic and verify changes.
5. Trigger the supplied alert **through Git**: change `replicaCount` to 1 in `charts/lab-app/values.yaml`, commit and push. Wait for Argo to sync, then inspect the `LabDeploymentUnderReplicated` alert in Prometheus. After it has fired for at least one minute, change the value back to 2, commit and push; wait for alert clearance and two ready pods. Alerts can take additional scrape/evaluation intervals.

## Acceptance

- Application scrape targets are `UP`; both PromQL queries show meaningful samples and a Grafana dashboard has two panels.
- The named alert transitions to firing after the Git change and clears after restoration.
- Explain why this rule checks desired replicas rather than endpoint availability, and why there is no external notification.

**Hints:** Check `kubectl -n lab get servicemonitor,prometheusrule`, the `release: monitor` labels and Prometheus selectors. `kubectl -n monitoring get prometheus -o yaml` shows effective selectors. Grafana dashboards and monitoring history may be lost when pods/storage are removed.
