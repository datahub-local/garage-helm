# Garage v2.5.0 support

## Why

Garage v2.5.0 adds the recommended `public_endpoint` / `public_endpoint_path_style`
S3 API parameters and a `GARAGE_LOG_FORMAT=json` log mode. The chart still pins
`appVersion: v2.4.1` and its bundled Grafana dashboard predates the new block
metrics, so users cannot configure the new parameters through values and the
dashboard misses two panels.

## What Changes

- Bump chart `appVersion` to `v2.5.0` and chart version to `0.10.0`.
- Add `garage.s3.api.publicEndpoint` and `garage.s3.api.publicEndpointPathStyle`,
  rendered into the `[s3_api]` section of `garage.toml` when set.
- Add `garage.logFormat`, rendered as the `GARAGE_LOG_FORMAT` container env var.
- Add the "Deleted blocks" and "Block write buffer free" panels to the bundled
  Grafana dashboard.
- Move the upgrade disclaimer and migration notes into the chart README through a
  `README.md.gotmpl`, so helm-docs keeps them on regeneration; the root README
  links to that section instead of duplicating it.
- Publish the chart README as a release asset and append its migration notes to
  the GitHub release body.
- Cover the new rendering with helm-unittest assertions and refresh the generated
  values documentation.

Out of scope: `[k2v] public_endpoint` (this chart does not render a k2v section),
the upstream chart's optional admin service (this chart already publishes port
3903), and any change driven by the v2.5.0 S3 lifecycle permission tightening,
which is an API-level breaking change and needs no chart change.
