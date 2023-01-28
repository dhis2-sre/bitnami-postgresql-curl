ARG fromTag=latest
FROM bitnami/postgresql:$fromTag
USER root
RUN install_packages curl
USER 1001
