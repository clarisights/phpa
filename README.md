## PHPA: poor man's Horizontal Pod Autoscaler


See [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) to know more about HPA

This tool takes metrics from our inflxudb and scales a deployment based on those metrics

# Deployment
## service account (only once)
- setup phpa-service-account using `setup-access.yaml`
- check for service account `kubectl get serviceaccount phpa-service-account`

## deploy
At Clarisights we run phpa as k8s deployment in same cluster as the deployment
phpa is targeting.

1. build and push docker image
2. create config map from file with your phpa config files
3. mount config map in your phpa cronjob/deployment
4. deploy

look in examples folder for some example configs and deployment