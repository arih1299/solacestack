# Last updated: July/5/2021 
# Author: Hayoung Yoon - hayoung.yoon@solace.com
# This is a Dockerfile to build minimal docker image to run 1) GCP Cluster creation and PubSubPlus HA deployment and 2) Solace Cloud Provisioning and Configuration using Ansible

# HOWTO TEST
# $ docker build --tag solaceansibletest:0.3 . 
# $ docker run -v <URI_GCP_SERVICE_ACCOUNT_CREDENTIAL>:/app-pb/res/my-project-serviceaccount.json -it solaceansibletest:0.3
#     EX: docker run -v ~/.google_gcp/serviceAccountCredential.json:/app-pb/res/my-project-serviceaccount.json -p 5000:5000 -it solaceansibletest:0.3
#
# 1. Run ansible-playbook - HA setup cluster creation and HA deployment
# -- test ansible-playbook - gcloud api auth
# $ ansible-playbook -vvv /app-pb/create.gcp.cluster.yml -e="gcp_cluster_name=overridedbyextra"
# -- test ansible-playbook - cluster creation and HA deployment 
# $ ansible-playbook -vvv /app-pb/create.gcp.cluster.yml -e="gcp_cluster_name=overridedbyextra"
# $ ansible-playbook -vvv /app-pb/deploy.solace.ha.yml -e="pubsub_name=pubsubtesthaover"
# -- test ansible-playbook - HA setup HA undeployment and cluster deletion
# $ ansible-playbook -vvv /app-pb/undeploy.solace.ha.yml -e="pubsub_name=pubsubtesthaover"
# $ ansible-playbook -vvv /app-pb/destroy.gcp.cluster.yml -e="gcp_cluster_name=overridedbyextra"
#
# 2. Run ansible-playbook - Solace Cloud 
# -- run another terminal to run bash
# $ export export SOLACE_CLOUD_API_TOKEN=<Your Solace Cloud API token>
# $ root@xxyyzzaa112233:~/ansible-solace/working-with-solace-cloud# ./run.create.sh
#
# More than a few min to complete the command. If successful, it will display the message like below at the end.
# PLAY RECAP ******************************************************************************************************************
# localhost                  : ok=8    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

FROM python:3.7

# We copy just the requirements.txt first to leverage Docker cache
COPY ./requirements.txt /app/requirements.txt

WORKDIR /app
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends docker sshpass vim tar \
    && pip install -r requirements.txt \
    && ansible-galaxy collection install solace.pubsub_plus google.cloud kubernetes.core \
    && git clone https://github.com/solace-iot-team/ansible-solace.git

RUN curl -sSL https://sdk.cloud.google.com > /tmp/gcl && bash /tmp/gcl --install-dir=/root/ --disable-prompts
ENV PATH="$PATH:/root/google-cloud-sdk/bin"
RUN export CLOUDSDK_CORE_DISABLE_PROMPTS=1
RUN gcloud components update kubectl

COPY ./solstack_web /app
COPY ./pb /app-pb
COPY ./linux-amd64/helm /usr/local/bin/helm

ENTRYPOINT [ "python" ]

CMD [ "app.py" ]
