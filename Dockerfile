FROM kubeaws/awsbeats:0.2.4-heartbeat-6.3.1

USER root

RUN yum install -y curl

RUN curl -o /usr/local/bin/jq -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && chmod +x /usr/local/bin/jq

RUN curl -L https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64 -o /usr/local/bin/dumb-init && \
    chmod +x /usr/local/bin/dumb-init

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

RUN mkdir -p /var/heartbeat-operator && \
    chown heartbeat:heartbeat /var/heartbeat-operator

RUN mkdir -p /usr/share/heartbeat/monitors && \
    chown heartbeat:heartbeat /usr/share/heartbeat/monitors

USER heartbeat

COPY rootfs /

ENV PATH=${PATH}:/opt/heartbeat-operator/bin

ENTRYPOINT ["dumb-init", "--", "heartbeat-operator", "--", "heartbeat"]

CMD ["heartbeat-operator"]
