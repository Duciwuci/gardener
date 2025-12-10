FROM alpine:latest AS builder

ARG KUBECTL_VERSION="v1.30.0"
ARG HELM_VERSION="v4.0.0"
ARG YQ_VERSION="4.44.1" 

RUN apk update && \
    apk add --no-cache curl tar gzip bash

RUN curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

RUN curl -LO "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" && \
    tar -zxvf "helm-${HELM_VERSION}-linux-amd64.tar.gz" && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf linux-amd64 "helm-${HELM_VERSION}-linux-amd64.tar.gz"

RUN curl -LO "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" && \
    mv yq_linux_amd64 /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

FROM alpine:latest

RUN apk update && apk add --no-cache bash

COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/helm /usr/local/bin/helm
COPY --from=builder /usr/local/bin/yq /usr/local/bin/yq

USER root
WORKDIR /

ENTRYPOINT ["/bin/bash"]