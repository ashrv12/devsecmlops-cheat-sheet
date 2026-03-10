# Adding one click reference functionality configuration

### Metric --> Trace (Exemplars)
In your Prometheus/Mimir data source:
 1. Enable Exemplars.
 2. Internal Link: Set the target to your Tempo data source.
 3. Label Name: trace_id.
 4. Result: Hovering over a latency spike shows a "diamond" icon; clicking it jumps directly to the trace.

```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://mimir:9009
    jsonData:
      exemplars:
        - internal: true
          # The name of your Tempo data source
          datasourceUid: 'tempo-uid' 
          # The label in your metrics that holds the trace ID
          labelname: 'trace_id'
```

### Log --> Trace (Derived Fields)
In your Loki data source:
 1. Add a Derived Field.
 2. Name: TraceID.
 3. Regex: (?:trace_id|traceID|tid)=(\w+) (or similar depending on your log format).
 4. Internal Link: Set to Tempo.

```yaml
apiVersion: 1
datasources:
  - name: Loki
    type: loki
    url: http://loki:3100
    jsonData:
      derivedFields:
        - datasourceUid: 'tempo-uid'
          matcherRegex: '(?:trace_id|tid)=(\w+)'
          name: TraceID
          # This creates the URL that points to the Tempo search/view
          url: '$${__value.raw}'
```

**Result: Every log line with a Trace ID becomes a clickable link to the full trace.**

### Trace --> Log (Trace to Logs)
In your Tempo data source:
 1. Configure Trace to logs.
 2. Data source: Select Loki.
 3. Tags: map service.name to your Loki label (e.g., job or app).
 4. Filter by Trace ID: Enabled.

```yaml
apiVersion: 1
datasources:
  - name: Tempo
    type: tempo
    url: http://tempo:3200
    jsonData:
      tracesToLogs:
        datasourceUid: 'loki-uid'
        # Map span attributes to Loki labels
        tags: ['job', 'instance', 'pod']
        filterByTraceId: true
        filterBySpanId: false
      tracesToMetrics:
        datasourceUid: 'prometheus-uid'
        tags: ['job', 'instance']
        queries:
          - name: 'Sample Query'
            query: 'sum(rate(container_cpu_usage_seconds_total{$$__tags}[5m]))'
```

**Result: When viewing a span, a "Logs for this span" button appears, which queries Loki for that exact trace_id.**
