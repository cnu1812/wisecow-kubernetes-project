# Cow wisdom web server

## Prerequisites

```
sudo apt install fortune-mod cowsay -y
```

## How to use?

1. Run `./wisecow.sh`
2. Point the browser to server port (default 4499)

## What to expect?
![wisecow](https://github.com/nyrahul/wisecow/assets/9133227/8d6bfde3-4a5a-480e-8d55-3fef60300d98)


#### 🚀 Features Implemented
- **Dockerization**  
  - Built a production-ready `Dockerfile` based on `debian:12-slim`  
  - Installed `fortune`, `cowsay`, and `netcat`  
  - Bundled custom fortune database and non-root runtime user  

- **Kubernetes Deployment**
  - Deployment, Service, and Ingress manifests under `/k8s`
  - Deployed on a local **Kind** cluster
  - Service exposed internally via ClusterIP
  - Ingress managed by **NGINX Ingress Controller**

- **TLS & Cert-Manager**
  - Configured `ClusterIssuer` (self-signed)  
  - Automatic TLS certificate provisioning (`wisecow-tls` Secret)  
  - HTTPS enabled via Ingress with redirect from HTTP → HTTPS  

- **Continuous Integration (CI)**
  - GitHub Actions workflow (`.github/workflows/ci.yml`)  
  - Automatically builds and pushes the image to **GHCR**  
  - Image published at:  
    ```
    ghcr.io/cnu1812/wisecow:latest
    ```

#### 🧪 Local Testing
```bash
# Start cluster
kind create cluster --name wisecow

# Apply manifests
kubectl apply -f k8s/

# Forward ingress for local testing
kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 18080:80 18443:443 &

# Access the app
curl -k -H "Host: wisecow.local" https://127.0.0.1:18443/
```

#### 📦 Repository Structure
```
.
├── wisecow.sh                # Application source
├── Dockerfile                # Container definition
├── k8s/                      # Kubernetes manifests
├── .github/workflows/ci.yml  # GitHub Actions CI pipeline
└── fortunes/                 # Custom fortune entries
```


 

