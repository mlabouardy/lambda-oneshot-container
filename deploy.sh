#!/bin/bash

## Override
JENKINS_HOST=""
JENKINS_USERNAME=""
JENKINS_PASSWORD=""
JENKINS_JOB=""
CRON_EXPRESSION="cron(0 8 * * ? *)"
## Global variables
AWS_REGION="us-east-1"
FUNCTION_NAME="RestartJob"

echo "Building binary"
GOOS=linux go build -o main main.go

echo "Generating deployment package"
zip deployment.zip main

echo "Creating IAM Role"
POLICY_ARN=$(aws iam create-policy --policy-name $FUNCTION_NAME --policy-document file://policy.json | jq -r '.Policy.Arn')
ROLE_ARN=$(aws iam create-role --role-name $FUNCTION_NAME --assume-role-policy-document file://role.json | jq -r '.Role.Arn')
aws iam attach-role-policy --role-name $FUNCTION_NAME --policy-arn $POLICY_ARN

echo "Creating Lambda function"
FUNCTION_ARN=$(aws lambda create-function --function-name $FUNCTION_NAME --runtime go1.x \
    --handler main --role $ROLE_ARN \
    --zip-file fileb://./deployment.zip \
    --environment Variables="{JENKINS_HOST=$JENKINS_HOST,JENKINS_USERNAME=$JENKINS_USERNAME,JENKINS_PASSWORD=$JENKINS_PASSWORD,JENKINS_JOB=$JENKINS_JOB}" \
    --region $AWS_REGION | jq -r '.FunctionArn')

echo "Creating CloudWatch Event rule"
RULE_ARN=$(aws events put-rule --name launch-container-daily --schedule-expression ''"$CRON_EXPRESSION"'' | jq -r '.RuleArn')
aws lambda add-permission --function-name $FUNCTION_NAME \
    --statement-id 1 \
    --action 'lambda:InvokeFunction' \
    --principal events.amazonaws.com \
    --source-arn $RULE_ARN
sed -i '.bak' 's/FUNCTION_ARN/'"$FUNCTION_ARN"'/g' targets.json
aws events put-targets --rule launch-container-daily --targets file://targets.json


echo "Cleaning up"
rm main deployment.zip *.bak