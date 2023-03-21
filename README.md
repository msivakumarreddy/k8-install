### EKS Install

*NOTE:* This is for the lab purpose, not for PROD purpose.

### How to provision EKS Cluster?

Below software are mandatory to provision EKS Cluster.

* Eksctl
* AWS CLI V2
* Kubectl

We can create one EC2 Server and use it as work station to create EKS cluster
                                            or
We can use our laptop as workstation to create EKS Cluster

![alt text](ec2-eks.png)


eksctl is the popular tool to provision EKS cluster. We make use of spot instances to save the cost.

```
# spot-cluster.yaml

apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: spot-cluster
  region: ap-south-1

managedNodeGroups:

# `instanceTypes` defaults to [`m5.large`]
- name: spot-1
  spot: true

```

### Pre-requisites