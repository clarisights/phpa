## poor man's Horizontal Pod Autoscaler


See [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) to know more about HPA

This tool takes metrics from our inflxudb and scales a deployment based on those metrics

## Deployment
- See help `deploy.rb --help`
- We create a deployment for each cluster. see `deploy/`.
- All configs for a cluster are in `deploy/config/<cluster-name>`