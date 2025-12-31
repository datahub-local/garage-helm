# garage-helm

Another Helm chart for Garage

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
