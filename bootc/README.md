# Build the bootc image

## Prerequisites

```
$ arch
aarch64

$ grep -E '^(NAME|VERSION)=' /etc/os-release 
NAME="Red Hat Enterprise Linux"
VERSION="9.6 (Plow)"

$ sudo subscription-manager status
+-------------------------------------------+
   System Status Details
+-------------------------------------------+
Overall Status: Disabled
Content Access Mode is set to Simple Content Access. This host has access to content, regardless of subscription status.

System Purpose Status: Disabled
```

## Build process

```sh
git clone https://github.com/Demo-AI-Edge-Crazy-Train/rhde-nvidia-jetson-orin.git
cd rhde-nvidia-jetson-orin/bootc
sudo podman login quay.io
sudo podman build -t quay.io/demo-ai-edge-crazy-train/train-jetson-orin:latest .
sudo podman push quay.io/demo-ai-edge-crazy-train/train-jetson-orin:latest
```
