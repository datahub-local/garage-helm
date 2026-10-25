# chart-config

## ADDED Requirements

### Requirement: Public S3 endpoint configuration

The chart SHALL render `public_endpoint` into the `[s3_api]` section of `garage.toml`
when `garage.s3.api.publicEndpoint` is non-empty, and SHALL omit the key when it is
empty.

#### Scenario: Public endpoint set

- **WHEN** `garage.s3.api.publicEndpoint` is `https://s3.example.com`
- **THEN** `garage.toml` contains `public_endpoint = "https://s3.example.com"`

#### Scenario: Public endpoint unset

- **WHEN** `garage.s3.api.publicEndpoint` is empty
- **THEN** `garage.toml` contains no `public_endpoint` key

### Requirement: Public S3 endpoint path style

The chart SHALL render `public_endpoint_path_style` as a TOML boolean when
`garage.s3.api.publicEndpointPathStyle` is set, including when it is explicitly
`false`, and SHALL omit the key when unset.

#### Scenario: Path style disabled

- **WHEN** `garage.s3.api.publicEndpointPathStyle` is `false`
- **THEN** `garage.toml` contains `public_endpoint_path_style = false`

### Requirement: JSON log format

The chart SHALL set the `GARAGE_LOG_FORMAT` environment variable on the Garage
container when `garage.logFormat` is non-empty, and SHALL not set it otherwise.

#### Scenario: JSON logs enabled

- **WHEN** `garage.logFormat` is `json`
- **THEN** the Garage container has `GARAGE_LOG_FORMAT=json`
