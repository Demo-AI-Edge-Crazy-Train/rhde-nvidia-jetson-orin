# Build the ISO image for unattended installation

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

$ sudo dnf insall -y lorax
```

## Build process

```sh
git clone https://github.com/Demo-AI-Edge-Crazy-Train/rhde-nvidia-jetson-orin.git
cd rhde-nvidia-jetson-orin/iso
cp jetson.ks.template jetson.ks
vi jetson.ks # Edit the kickstart file and fill in the redacted fields
sudo ./generate-iso.sh
```
