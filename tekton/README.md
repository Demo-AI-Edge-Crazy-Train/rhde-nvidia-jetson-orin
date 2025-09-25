# Multi-architecture Tekton Pipeline

## Share RHEL SCA entitlement with Tekton Pipelines

```sh
oc create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: etc-pki-entitlement
type: Opaque
data:
  aarch64.pem: $(base64 -w0 /etc/pki/entitlement/XXX.pem)
  aarch64-key.pem: $(base64 -w0 /etc/pki/entitlement/XXX-key.pem)
EOF
```

## Flightctl CLI container image

```sh
cd flightctl-image
./build.sh
```

## Tekton configuration

```sh
oc patch tektonconfig/config -n openshift-pipelines --type=merge -p '{"spec":{"pipeline":{"coschedule":"disabled","disable-affinity-assistant":true}}}'
```

## Pipeline manifests

```sh
oc apply -k common/
oc apply -f pipeline.yaml
```

## Authentication to the registries

```sh
export REGISTRY_AUTH_FILE="$PWD/auth.json"
podman login quay.io
podman login registry.redhat.io
oc apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  annotations:
    tekton.dev/docker-0: https://quay.io
    tekton.dev/docker-1: https://registry.redhat.io
  name: quay-authentication
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: $(base64 -w0 "$PWD/auth.json")
EOF
```

## Authentication to GitHub

```sh
cat > gitconfig <<EOF
[credential]
  helper=store
EOF
oc create secret generic github-authentication --from-literal=.git-credentials=https://user:password@github.com --from-file=.gitconfig=gitconfig
```

## Authentication to Flightctl

```sh
oc create secret generic flightctl-config --from-file=client.yaml=$HOME/.config/flightctl/client.yaml
```

## Build the jetson image

```sh
oc create -f pipelinerun.yaml
```
