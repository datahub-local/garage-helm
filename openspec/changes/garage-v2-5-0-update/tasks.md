# Tasks

## 1. Chart metadata

- [x] 1.1 Bump `garage/Chart.yaml` to `version: 0.10.0`, `appVersion: v2.5.0`

## 2. New configuration

- [x] 2.1 Add `garage.s3.api.publicEndpoint` and `garage.s3.api.publicEndpointPathStyle` values
- [x] 2.2 Render both into `[s3_api]` in `garage/templates/_helpers.tpl` when set
- [x] 2.3 Add `garage.logFormat` value and `GARAGE_LOG_FORMAT` env var in `garage/templates/workload.yaml`

## 3. Monitoring

- [x] 3.1 Add "Block write buffer free" and "Deleted blocks" panels to `garage/files/grafana-dashboard.json`

## 4. Tests and docs

- [x] 4.1 Extend `garage/tests/configmap_test.yaml` for the two S3 API parameters
- [x] 4.2 Extend `garage/tests/workload_test.yaml` for the log format env var
- [x] 4.3 Regenerate `garage/README.md` values table
- [x] 4.4 Run `helm unittest garage` and `helm lint garage`

## 5. Upgrade documentation and release packaging

- [x] 5.1 Add `garage/README.md.gotmpl` with the top disclaimer and migration notes
- [x] 5.2 Point the root README at `garage/README.md#migration-notes`
- [x] 5.3 Exclude `README.md.gotmpl` from the packaged chart
- [x] 5.4 Attach the chart README to each release and append migration notes to its body
- [x] 5.5 Sync `README.md` and `garage/README.md` onto `gh-pages` so the Pages landing page is current
