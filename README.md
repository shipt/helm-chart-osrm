# helm-chart-osrm

[Helm](https://helm.sh/) chart for [OSRM](https://github.com/Project-OSRM/osrm-backend).

Notable features:

- 🗺 Out-of-the-box map management, allowing to download and persist a map by the URI. Currently supports HTTP(S) and Google Cloud Storage,
others (AWS S3, etc) incoming.
- 🖴 Runs as a StatefulSet so each instance keeps its own maps in PersistentVolume.

By default, this chart deploys [osrm-routed](http://project-osrm.org/docs/v5.22.0/api/) server, but you can replace
it with your own implementation (e.g. based on `libosrm`) if you want. 

## Install

```bash
helm repo add hypnoglow https://hypnoglow.github.io/helm-charts

# For Helm v2
helm install hypnoglow/osrm --name osrm

# For Helm v3
helm install osrm hypnoglow/osrm
```

## Configuration

### Map Management and Source Providers (modes)

By default chart has map management enabled, with `http` as a source provider. This allows you to simply specify
publicly-accessible url to the map you want to download:

```yaml
map:
  http:
    uri: https://download.openstreetmap.fr/extracts/europe/monaco.osm.pbf
```

There are few so-called "source providers" you can use to download maps from:

- `http` - for HTTP endpoints 
- `gcs` - for Google Cloud Storage

#### Google Cloud Storage

To enable gcs as a source provider, use `--set map.source=gcs`.

By default the chart is configured to download maps from private buckets. If your bucket is public, you can disable
credentials requirement: `--set map.gcs.googleApplicationCredentials.enabled=false`.

To access maps in private bucket you need credentials. The chart is already configured to use secret named `osrm-google-application-credentials`
and key `credentials.json`. This secret is not managed by the chart. You can create secret from credentials file as follows:

```bash
kubectl create secret generic osrm-google-application-credentialss \
    --from-file=credentials.json=/path/to/credentials.json \
    --dry-run -o yaml | kubectl apply -f -
```

Example `values.yaml` customization for gcs provider:

```yaml
map:
  source: gcs
  gcs:
    version: "20200226-1"
    uri: "gs://my-osrm-maps/20200226-1/map.tar.gz"
```

### Alerting via Datadog

The chart can optionally render [`DatadogMonitor`](https://docs.datadoghq.com/monitors/manage/monitors_as_code/) resources for you, gated behind `datadogMonitors.enabled` (`false` by default). See `values.yaml` for the full list of default monitors and how to add your own.

**Prerequisites** — these are cluster-level and are not managed by this chart:

- The [Datadog Operator](https://github.com/DataDog/datadog-operator) must be installed in the cluster (this registers the `DatadogMonitor` CRD and reconciles it against the Datadog API), configured with a Datadog API key and application key.
- The default monitors rely on data already being collected by the Datadog Agent:
  - Kubernetes State Metrics (`kubernetes_state.*`) for the replicas-down, image-pull-failure, and crash-loop monitors.
  - Kubelet volume stats for the map PVC near-full monitor.
  - The [Datadog Envoy integration](https://docs.datadoghq.com/integrations/envoy/) scraping Contour's Envoy for the upstream 503s monitor.

Without these, `DatadogMonitor` objects will still be created, but the monitors will show "no data".

Enable it with:

```bash
helm upgrade osrm ./osrm \
  --set datadogMonitors.enabled=true \
  --set datadogMonitors.notify="@slack-osrm-alerts @pagerduty-osrm"
```

Verify with:

```bash
kubectl get datadogmonitors -n osrm
kubectl describe datadogmonitor osrm-osrm-upstream-503 -n osrm
```

