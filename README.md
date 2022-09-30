# Python (Flask) sample app hosted in multiple ways on AWS

A collection of Terraform modules and GitHub Actions pipelines (WIP) to deploy and manage a sample Flask app.

## Notes for building the pipelines

### App Runner

`-var="ecr_repo_arn=219353227387.dkr.ecr.ap-northeast-1.amazonaws.com/sample-python-flask-app:latest"`

`baba=$(tf output -raw app_runner_service_url)`

### EB Python

`-var="eb_app_version=21-08-2022-1" -var="eb_env_name=sample-python-flask-app-python"`

`aws elasticbeanstalk update-environment --environment-name sample-python-flask-app-python --version-label sample-python-flask-app-python-21-08-2022-1`

<https://awscli.amazonaws.com/v2/documentation/api/latest/reference/elasticbeanstalk/wait/environment-updated.html>

### EB Docker EC2

``` bash
ecr_repo_arn=219353227387.dkr.ecr.ap-southeast-2.amazonaws.com/sample-python-flask-app
tmp=$(mktemp)
jq --arg repo $ecr_repo_arn '.Image.Name = $repo' Dockerrun.aws.json > $tmp && mv $tmp Dockerrun.aws.json
```

`-var="eb_app_version=21-08-2022-1" -var="eb_env_name=sample-python-flask-app-docker-ec2"`

`aws elasticbeanstalk update-environment --environment-name sample-python-flask-app-docker-ec2 --version-label sample-python-flask-app-docker-ec2-21-08-2022-1`

<https://awscli.amazonaws.com/v2/documentation/api/latest/reference/elasticbeanstalk/wait/environment-updated.html>

### EB Docker ECS

``` bash
ecr_repo_arn=219353227387.dkr.ecr.ap-southeast-2.amazonaws.com/sample-python-flask-app
tmp=$(mktemp)
jq --arg repo $ecr_repo_arn '.containerDefinitions[0].image = $repo' Dockerrun.aws.json > $tmp && mv $tmp Dockerrun.aws.json
```

`-var="eb_app_version=21-08-2022-1" -var="eb_env_name=sample-python-flask-app-docker-ecs"`

`aws elasticbeanstalk update-environment --environment-name sample-python-flask-app-docker-ecs --version-label sample-python-flask-app-docker-ecs-21-08-2022-1`

<https://awscli.amazonaws.com/v2/documentation/api/latest/reference/elasticbeanstalk/wait/environment-updated.html>

### Lambda Python

``` bash
s3_bucket=zappa-w0nbx3pn6
tmp=$(mktemp)
jq --arg bucket $s3_bucket '."python-platform".s3_bucket = $bucket' zappa_settings.json > $tmp && mv $tmp zappa_settings.json

#trick due to Zappa bug https://github.com/zappa/Zappa/issues/361
for i in 1 2; do zappa deploy && break || sleep 15; done
zappa deploy python-platform

zappa status -j python-platform | jq -r '."API Gateway URL"'
```

### Lambda Docker

``` bash
s3_bucket=zappa-w0nbx3pn6
tmp=$(mktemp)
jq --arg bucket $s3_bucket '."docker-platform".s3_bucket = $bucket' zappa_settings.json > $tmp && mv $tmp zappa_settings.json

docker build -f Dockerfile.lambda -t sample-lambda-flask-app .

zappa save-python-settings-file docker-platform
for i in 1 2; do zappa deploy docker-platform -d 219353227387.dkr.ecr.ap-southeast-2.amazonaws.com/sample-lambda-flask-app:latest && break || sleep 15; done

zappa status -j docker-platform | jq -r '."API Gateway URL"'
```

### ECS

``` bash
ecr_image=219353227387.dkr.ecr.ap-southeast-2.amazonaws.com/sample-python-flask-app:latest
tmp=$(mktemp)
jq --arg image $ecr_image '.[0].image = $image' task_definition.json > $tmp && mv $tmp task_definition.json

task_arn=$(aws ecs list-tasks --cluster sample-python-flask-app-ecs-cluster --service-name sample-python-flask-app-ecs-service | jq -r '.taskArns[0]')
eni=$(aws ecs describe-tasks --cluster sample-python-flask-app-ecs-cluster --tasks $task_arn | jq -r '.tasks[0].attachments[0].details[] | select(.name=="networkInterfaceId").value')
dns_name=$(aws ec2 describe-network-interfaces --network-interface-ids $eni | jq -r '.NetworkInterfaces[0].Association.PublicDnsName')
url="$dns_name:5000"
```

### Copilot CLI

1. `copilot init` from the app/ folder
1. name the app sample-python-flask-app
1. select "Load Balanced Web Service"
1. name the service sample-python-flask-app-service
1. choose "y" to deploy to a test environment
