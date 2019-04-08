FROM centos:latest

WORKDIR /embulk_digdag

# java
RUN yum update -y && yum install -y \
      java-1.8.9-openjdk \
      java-1.8.0-openjdk-devel \
      vim

ENV TD_API_KEY='td_api_key' \
    AWS_ACCESS_KEY_ID='aws_access_key' \
    AWS_SECRET_ACCESS_KEY='aws_secret_access_key'

# treasure data toolbelt
RUN curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent2.sh | sed -e "s/sudo//g" | /bin/bash && \
    td apikey:set $TD_API_KEY

# embulk
RUN curl --create-dirs -o ~/.embulk/bin/embulk -L "https://dl.embulk.org/embulk-latest.jar" &&\
    chmod +x ~/.embulk/bin/embulk && \
    echo 'export PATH="$HOME/.embulk/bin:$PATH"' >> ~/.bashrc && \
    source ~/.bashrc && \
    embulk gem install embulk-input-mysql embulk-output-td embulk-input-s3 embulk-filter-column embulk-filter-add_time

# digdag
RUN curl -o ~/bin/digdag --create-dirs -L "https://dl.digdag.io/digdag-latest" && \
    chmod +x ~/bin/digdag && \
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc && \
    source ~/.bashrc && \
    mkdir -p ~/.config/digdag; touch ~/.config/digdag/config && \
    echo "client.http.endpoint = https://digdag.サーバー名.com" >> ~/.config/digdag/config

# digdagのpath設定
ENV PATH /root/bin:${PATH}

# aws cli
RUN set -xv && \
    curl -s "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" && \
    python get-pip.py && \
    pip install awscli --ignore-installed six && \
    curl -s -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | sh && \
    source ~/.nvm/nvm.sh && \
    nvm install v6.10.3 && \
    npm install -g jsonlint && \
    npm install -g jq

RUN digdag secrets --local --set td.apikey=${TD_API_KEY} && \
    digdag secrets --local --set aws.access_key_id=${AWS_ACCESS_KEY_ID} && \
    digdag secrets --local --set aws.secret_access_key=${AWS_SECRET_ACCESS_KEY}
