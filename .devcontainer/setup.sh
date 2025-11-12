#!/usr/bin/env bash
set -e
apt-get update -y
apt-get install -y curl sudo ca-certificates apt-transport-https gnupg lsb-release jq
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
# kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
install -o root -g root -m 0755 kind /usr/local/bin/kind
rm kind
# helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

usermod -aG docker vscode || true
