#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

mkdir -p eks-client-install
cd eks-client-install

LOG=eks-client-install.log
USER_ID=$(id -u)
if [ $USER_ID -ne 0 ]; then
	echo  -e "$R You are not the root user, you dont have permissions to run this $N"
	exit 1
fi

VALIDATE(){
	if [ $1 -ne 0 ]; then
		echo -e "$2 ... $R FAILED $N"
		exit 1
	else
		echo -e "$2 ... $G SUCCESS $N"
	fi

}

echo "Enter Your AWS Access key: "
read -s ACCESS_KEY

echo "Enter Your AWS Secret key: "
read -s SECRET_KEY

read -p "Enter Your AWS Region: " REGION
REGION=${REGION:-ap-south-1}

echo "Enter your key pair name: "
read KEY_PAIR

echo "Enter your cluster name: "
read CLUSTER_NAME


su -l ec2-user -c "aws configure set aws_access_key_id $ACCESS_KEY"
su -l ec2-user -c "aws configure set aws_secret_access_key $SECRET_KEY"
su -l ec2-user -c "aws configure set default.region $REGION"

curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &>> $LOG

VALIDATE $? "Downloaded AWS CLI V2"

if [ -d "aws" ]; then
    echo -e "AWS directory already exists...$Y SKIPPING Unzip $N"
else
    unzip awscliv2.zip &>> $LOG
    VALIDATE "unzip AWS CLI V2"
fi

./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update &>> $LOG

VALIDATE $? "Updated AWS CLI V2"

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp &>> $LOG
VALIDATE $? "Downloaded eksctl command"
chmod +x /tmp/eksctl &>> $LOG
VALIDATE $?  "Added execute permissions to eksctl"
mv /tmp/eksctl /usr/local/bin &>> $LOG
VALIDATE $? "moved eksctl to bin folder"

curl -s -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.10/2023-01-30/bin/linux/amd64/kubectl &>> $LOG
VALIDATE $? "Downloaded kubectl 1.24 version"
chmod +x kubectl &>> $LOG
VALIDATE $?  "Added execute permissions to kubectl"
mv kubectl /usr/local/bin/kubectl &>> $LOG
VALIDATE $?  "moved kubectl to bin folder"


yaml='---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: "$CLUSTER_NAME"
  region: "$REGION"

managedNodeGroups:

# `instanceTypes` defaults to [`m5.large`]
- name: spot-1
  spot: true
  ssh:
    publicKeyName: "${KEY_PAIR}"
'
cat $yaml > eksctl-config.yaml
eksctl create cluster --config-file=eksctl-config.yaml