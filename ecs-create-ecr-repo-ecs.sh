### CREATE ECR repo

aws ecr create-repository --repository-name web2048

aws ecr describe-repositories --query 'repositories[].[repositoryName, repositoryUri]' --output table
export REPOSITORY_URI=$(aws ecr describe-repositories --query 'repositories[].[repositoryUri]' --output text)
echo ${REPOSITORY_URI}

### LOGIN to ECR

export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

### PUSH to ECR

docker tag web2048:latest ${REPOSITORY_URI}:latest
docker push ${REPOSITORY_URI}:latest

aws ecr describe-images --repository-name web2048

### CREATE ECS cluster

aws ecs create-cluster --cluster-name web2048
aws ecs register-task-definition --cli-input-json file://web2048_task_definition.json
aws ecs create-service --cli-input-json file://web2048_service.json

aws ecs describe-clusters --cluster web2048