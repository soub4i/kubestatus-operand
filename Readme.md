


# KubeStatus Operand

KubeStatus Operand is a Kubernetes controller that works in conjunction with [KubeStatus Operator](https://github.com/soub4i/kubestatus-operator) to monitor Kubernetes service availability and expose their status via metrics.

## Overview

The operand component watches for services annotated with `kubestatus/watch='true'` and tracks their availability status. It exports these metrics for monitoring and alerting purposes.

## Prerequisites

- Kubernetes cluster 1.16+
- KubeStatus Operator installed
- Metrics server enabled

## Installation

1. Install KubeStatus Operator first:
```sh
kubectl apply -f https://raw.githubusercontent.com/soub4i/kubestatus-operator/main/config/deploy/operator.yaml
```

2. Deploy the operand:
```sh
kubectl apply -f https://raw.githubusercontent.com/soub4i/kubestatus-operand/main/config/deploy/operand.yaml
```

## Usage

1. Annotate services you want to monitor:
```sh
kubectl annotate svc <service-name> kubestatus/watch='true'
```

2. The operand will automatically start monitoring annotated services

3. Access metrics at:
```sh
kubectl port-forward svc/kubestatus-metrics 8080:8080
curl localhost:8080/metrics
```

## Metrics

The following metrics are exposed:

- `service_availability_status`: Current availability status (1 = available, 0 = unavailable)
- `service_total_requests`: Total number of availability checks
- `service_failed_requests`: Number of failed availability checks



## License

This project is licensed under the [Apache License 2.0](LICENSE).