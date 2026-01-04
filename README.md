# Another Helm chart for Garage

Why Garage?
- MinIO is no longer a real OSS project. Garage is open, simple, and actively maintained.
- Perfect for small/home clusters. No crazy resource requirements or complex setup.
- S3 API compatible, so your apps and tools just work.

What makes this Helm chart better than the official one?

1. Automated cluster configuration: No more manual CLI or YAML hacks. Just set your layout, buckets, and keys in values.yaml and it all gets set up for you.
2. Built-in WebUI: Deploy the Garage WebUI with a single flag for easy management.
3. Gateway API support: Native support for Kubernetes Gateway API (plus Ingress), so you’re ready for modern K8s networking.
4. Grafana dashboard & ServiceMonitor: Get instant metrics and dashboards out of the box.
5. Extra resources: Inject any custom K8s manifest (Secrets, ConfigMaps, etc.) directly via values.yaml.

## :test_tube: Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See [deployment](#deployment) for notes on how to deploy the project on a live system.

### Prerequisites

- Git
- Helm
- Kubernetes Cluster (for testing purposes)
- Python 3

### Installing

1. Clone the repository:

```shell
$ git clone https://github.com/datahub-local/garage-helm.git && cd garage
```
  
2. Prepare your [`values.yaml`](#values)
3. Try it in your cluster to check that everything is fine (replace the `garage/` with the chart folder if your workdir is different):

```shell
$ helm install garage-dev garage/ \
--namespace garage-dev \
--create-namespace \
--values values.yaml
```

## :rocket: Deployment

To deploy the Helm Chart:

1. Add the Helm repository:

```shell
$ helm repo add garage-helm https://datahub-local.github.io/garage-helm
```

2. Install the release:

```shell
$ helm install <release-name> garage-helm/garage \
--namespace garage \
--create-namespace \
--values values.yaml
```

> [!WARNING]
>
> A minimum set of values must include the various parameters with the anchor reference, otherwise the anchors won't work as intended and the deployment may fail. Please, read the [Helm Chart README.md](./garage/README.md) section to see a minimal `values.yaml` sample.

If you want to install a specific version, execute the previous command adding: `--version x.y.z`

### Values

Please read the [Helm Chart README.md](./garage/README.md) for details on how to configure the values needed for this chart.

### Examples

- `garage/examples/basic.yaml` – Persistent volumes plus the minimum cluster configuration job that seeds buckets and API keys.
- `garage/examples/recommended.yaml` – Builds on the basics with the Web UI and nginx Ingress entries for `garage.example.com` style domains.
- `garage/examples/advanced.yaml` – Shows a scaled layout with resource tuning, monitoring objects, and Gateway API routes for production domains.

## :memo: Contributing

Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## :busts_in_silhouette: Contributors

<a href="https://github.com/datahub-local/garage-helm/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=datahub-local/garage-helm" />
</a>

See the full list of [contributors](https://github.com/datahub-local/garage-helm/contributors) who participated in this project.

###### Remember that each dependency has its own author(s) and contributors. Please contact them via their repositories.

## :label: Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [releases on this repository](https://github.com/datahub-local/garage-helm/releases). 

## :scroll: License

This project is licensed under the GNU AGPL v3 License - see the [LICENSE](LICENSE) file for details.

<!--
## Acknowledgments

* Hat tip to anyone whose code was used
* Inspiration
* etc
-->
