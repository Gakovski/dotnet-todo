# dotnet-todo
![Main CI/CD](https://github.com/gakovski/dotnet-todo/actions/workflows/main.yaml/badge.svg)
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
Alternatively we can also access the clusters via the minikube's IP address along with the assigned port.
```
minikube service todoapi-train -n train --url
minikube service todoapi-prod -n prod --url
```
The output will display the IP address and port number. Open that url and add /todoitems

## Workflows

1. **build.yaml**: Responsible for building Docker images and pushing them to Docker Hub.
2. **deploy.yaml**: Deploys the Docker container to a Kubernetes cluster.
3. **release.yaml**: Creates release notes using semantic versioning.
4. **scan-code.yaml**: Analyzes the code using CodeQL.
5. **main.yaml**: Main CI/CD workflow that orchestrates the execution of other workflows based on specific conditions.
6. **lambda.yaml**: Builds and deploys a Docker container to AWS ECR, then deploys it as an AWS Lambda function.

## Workflow Details

### 1. build.yaml

This workflow builds Docker images and pushes them to Docker Hub.

- **Inputs**: 
  - `image_name`: Name of the Docker image.
  - `image_tag`: Tag of the Docker image.
- **Secrets**:
  - `dockerhub_username`: Docker Hub username.
  - `dockerhub_password`: Docker Hub access token.

### 2. deploy.yaml

Deploys the Docker container to a Kubernetes cluster.

- **Inputs**: 
  - `environment`: Specifies the deployment environment (e.g., 'prod' or 'train').

### 3. release.yaml

Creates release notes using semantic versioning.

- **Secrets**:
  - `token`: GitHub token with necessary permissions to create releases.

### 4. scan-code.yaml

Analyzes the code using CodeQL.

### 5. main.yaml

Main CI/CD workflow that orchestrates the execution of other workflows based on specific conditions.

- **Inputs**:
  - `deploy_prod`: Boolean variable indicating whether to deploy to the production environment.

### 6. lambda.yaml

Builds and deploys a Docker container to AWS ECR, then deploys it as an AWS Lambda function.

- **Inputs**:
  - `func_name`: Name of the AWS Lambda function.
- **Secrets**:
  - `aws_access_key`: AWS Access Key ID.
  - `aws_secret_key`: AWS Secret Access Key.
  - `aws_repository`: Name of the AWS ECR repository.

## Conditional Execution

The `main.yaml` workflow includes conditional execution logic to trigger different jobs based on specific conditions. For example, the deployment to the production environment (`deploy-cluster-prod`) is executed only when the `deploy_prod` input is set to `true`.

## Reusability

These workflows are designed to be reusable and modular. They can be easily integrated into other repositories by referencing the workflow files using their respective paths.

For more detailed information about each workflow and its usage, refer to the corresponding YAML files in the `.github/workflows` directory.

# Infrastructure as Code Solution
## Thought Process for Implementing Step 4

This document outlines the thought process and steps to create an Infrastructure as Code (IaaC) solution using Terraform for deploying a Dockerized application on AWS Lambda service running inside a Virtual Private Cloud (VPC) and exposing it to the internet.

Please note that this document serves as a guide and further implementation and testing are necessary for full functionality.

## Steps

### 1. Define Infrastructure Components

- **VPC**: Create a Virtual Private Cloud (VPC) to isolate the Lambda function and provide network-level security.
- **Subnets**: Define public and private subnets within the VPC.
- **Internet Gateway**: Attach an Internet Gateway to the VPC to enable internet access.
- **Security Groups**: Create security groups to control inbound and outbound traffic.
- **Lambda Function**: Define the Lambda function to host the application code.
- **IAM Roles and Policies**: Define IAM roles and policies for Lambda function execution.

### 2. Configure Lambda Function

- Specify runtime environment, memory allocation, and timeout settings.
- Package application code and dependencies into a deployment package.

### 3. Network Configuration

- Associate Lambda function with the private subnet.
- Configure route tables and route traffic between subnets and the internet gateway.

### 4. Security Configuration

- Apply security group rules to control traffic.
- Implement network access control lists (NACLs) if needed.

### 5. Exposing the Application

- Expose the Lambda function using the default domain provided by AWS API Gateway.
- Create API endpoints if necessary.

### 6. Testing and Validation

- Simulate traffic to Lambda function to ensure functionality.
- Verify accessibility from the internet.

## Local Testing and CI/CD Integration

This Infrastructure as Code (IaC) solution can be tested locally using Terraform CLI. Additionally, it can be integrated into GitHub Actions as a stage for further fully automated deployments.

## Conclusion

By following these steps and using Terraform for Infrastructure as Code (IaC), you can create a robust solution to deploy applications onto AWS Lambda in a VPC and expose them to the internet.