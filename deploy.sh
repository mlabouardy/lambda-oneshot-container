#!/bin/bash

AWS_REGION="us-east-1"
JENKINS_HOST=""
JENKINS_USERNAME=""
JENKINS_PASSWORD=""
JENKINS_JOB=""

echo "Building binary"
GOOS=linux go build -o main main.go

echo "Generating deployment package"
zip deployment.zip main


echo "Creating IAM Role"
ARN=$(aws iam create-policy --policy-name RestartJobRole --policy-document file://policy.json | jq -r '.Policy.Arn')
result=$(aws iam create-role --role-name RestartJobRole --assume-role-policy-document file://role.json | jq -r '.Role.Arn')
aws iam attach-role-policy --role-name RestartJobRole --policy-arn $ARN

echo "Creating Lambda function"
aws lambda create-function --function-name RestartJob --runtime go1.x \
    --handler main --role $ARN\
    --zip-file fileb://./deployment.zip \
    --environment Variables="{JENKINS_HOST=$JENKINS_HOST, JENKINS_USERNAME=$JENKINS_USERNAME, \
                              JENKINS_PASSWORD=$JENKINS_PASSWORD, JENKINS_JOB=$JENKINS_JOB}" \
    --region $AWS_REGION

echo "Creating CloudWatch Event rule"

# invoke it with cli to test
#show jenkins  