FROM ruby:3.3.6

RUN mkdir /phpa
WORKDIR /phpa

# COPY code, config and install dependencies
COPY . .
RUN bundle install --quiet -j 16

# Install kubectl
RUN curl --silent -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

ENTRYPOINT ["bundle", "exec", "./phpa-cli"]
