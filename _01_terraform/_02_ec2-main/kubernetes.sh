#!/usr/bin/env bash
# EC2/Jenkins (Linux) uzerinde calistirin: ssh ec2-user@<EIP> sonra bash kubernetes.sh
# Yerel Mac/Windows'tan: ssh ile EC2'ye baglanip bu scripti orada calistirin.

#-------------------ArgoCD----------------
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


#----------------Helm-------------------
# Install Helm (if not installed)
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm version

#----------------Prometheus-------------------
helm repo add stable https://charts.helm.sh/stable
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
kubectl create namespace Prometheus
helm install stable prometheus-community/kube-prometheus-stack -n prometheus


#----------------EBS CSI Driver for Kubernetes volumes 
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update


#install aws ebs driver to Kubernetes 
helm upgrade --install aws-ebs-csi-driver --namespace kube-system aws-ebs-csi-driver/aws-ebs-csi-driver
