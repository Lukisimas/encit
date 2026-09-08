FROM docker:29-cli AS dockercli
FROM jenkins/jenkins:2.568.2-jdk21
USER root
COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker
RUN apt-get update && apt-get install -y --no-install-recommends \
    git openssh-client curl jq ca-certificates && \
    rm -rf /var/lib/apt/lists/*
USER jenkins
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
