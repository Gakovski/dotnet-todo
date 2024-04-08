# dotnet-todo

## Test the GET endpoints

Test the app by calling the endpoints from a browser or Postman. The following steps are for Postman.

  Create a new HTTP request.
  Set the HTTP method to GET.
  Set the request URI to https://localhost:<port>/todoitems. For example, https://localhost:5001/todoitems.
  Select Send.

The call to GET /todoitems produces a response similar to the following:

```json
[
  {
    "id": 1,
    "name": "walk dog",
    "isComplete": false
  }
]
```

  Set the request URI to https://localhost:<port>/todoitems/1. For example, https://localhost:5001/todoitems/1.

  Select Send.

  The response is similar to the following:

```json
  {
    "id": 1,
    "name": "walk dog",
    "isComplete": false
  }
```

This app uses an in-memory database. If the app is restarted, the GET request doesn't return any data. If no data is returned, POST data to the app and try the GET request again.

## Build and Run the Docker Image
### Prerequisites
- Docker installed on your machine.

### Building Docker Image
```
docker build -t dotnet-todo .
```

### Running Docker Container
```
docker run --rm -it -p 5000:8080 dotnet-todo
```
This command will run the container and map port 5000 of your host machine to port 8080 of the container.

You can now access your application using a web browser by navigating to:

```
http://localhost:5000/todoitems
```
## Commit Message Header

```
<type>(<scope>): <short summary>
  │       │             │
  │       │             └─⫸ Summary in present tense. Not capitalized. No period at the end.
  │       │
  │       └─⫸ Commit Scope: animations|bazel|benchpress|common|compiler|compiler-cli|core|
  │                          elements|forms|http|language-service|localize|platform-browser|
  │                          platform-browser-dynamic|platform-server|router|service-worker|
  │                          upgrade|zone.js|packaging|changelog|docs-infra|migrations|
  │                          devtools
  │
  └─⫸ Commit Type: build|ci|docs|feat|fix|perf|refactor|test
```

E.g. fix(animations): fixed the broken loading clock animation

## Deploy Helm Chart
Before we start we have to start a minikube cluster.
```
minikube start
```

- To install a cluster for the intg environment use the following helm command
```
helm install todoapi-intg .\mychart\ --values .\mychart\values.yaml
```
- To upgrade the cluster after editing the templates use the following helm command
```
helm upgrade todoapi-intg .\mychart\ --values .\mychart\values.yaml
```

- To access the cluster locally use minikube tunneling
```
minikube tunnel
```
Go to http://localhost:8080/todoapi

### Create TRAIN/PRODUCTION Clusters
```
kubectl create namespace train
kubectl create namespace prod
helm install todoapi-train .\mychart\ --values .\mychart\values.yaml -f .\mychart\values-train.yaml -n train
helm install todoapi-prod .\mychart\ --values .\mychart\values.yaml -f .\mychart\values-prod.yaml -n prod
```
Because all of the 3 clusters are exposed on port 8080, we have to use the following kubectl command to port-forward the traffic to another port, so we can access all three clusters.
The command can be found after executing the helm install commands, at the end of the output in the section NOTES.
We can close the minikube tunnel now, because we will access all three clusters via port-forwarding.

```
kubectl --namespace default port-forward service/todoapi-intg 8887:8080
kubectl --namespace train port-forward service/todoapi-train 8888:8080
kubectl --namespace prod port-forward service/todoapi-prod 8889:8080
```