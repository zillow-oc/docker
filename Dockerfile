FROM docker:17.06-git

# BUILD_DEPS are used only to build the Docker image
# RUN_DEPS are installed and persist in the final built image
ENV	\
		BUILD_DEPS="py-pip alpine-sdk go curl nodejs-npm" \
		RUN_DEPS="groff less python bash socat nodejs" \
		GOPATH=/ \
		NOMAD_URL="https://releases.hashicorp.com/nomad/0.6.2/nomad_0.6.2_linux_amd64.zip" \
		CONSUL_URL="https://releases.hashicorp.com/consul/0.9.0/consul_0.9.0_linux_amd64.zip" \
		CONSUL_TEMPLATE_URL="https://releases.hashicorp.com/consul-template/0.19.0/consul-template_0.19.0_linux_amd64.zip"

WORKDIR /

RUN \

	# Install packages without storing package manager cache
	mkdir -p /aws && \
	apk -Uuv --no-cache add $RUN_DEPS $BUILD_DEPS && \
	npm install -g kongfig && npm cache clean && \
	pip --no-cache-dir install awscli && \
	
	# Install Nomad
	curl $NOMAD_URL > /tmp/nomad.zip && \
	unzip -o /tmp/nomad.zip -d /usr/bin && \
	chmod +x /usr/bin/nomad && \
	# Work-around for alpine incompatibility
	mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
	rm -f /tmp/nomad.zip && \
	
	# Install Consul
	curl $CONSUL_URL > /tmp/consul.zip && \
	unzip -o /tmp/consul.zip -d /usr/bin && \
	chmod +x /usr/bin/consul && \
	rm -f /tmp/consul.zip && \
	
	# Install Consul Template
	curl $CONSUL_TEMPLATE_URL > /tmp/consul-template.zip && \
	unzip -o /tmp/consul-template.zip -d /usr/bin && \
	chmod +x /usr/bin/consul-template && \
	rm -f /tmp/consul-template.zip && \

	# Install https://github.com/awslabs/amazon-ecr-credential-helper
	# Uses IAM roles to login to AWS ECR without a separate docker login
	#   Disable by removing the "~/.docker/config.json"
	git clone https://github.com/awslabs/amazon-ecr-credential-helper.git src/github.com/awslabs/amazon-ecr-credential-helper && \
	cd src/github.com/awslabs/amazon-ecr-credential-helper && \
	make && \
	mv bin/local/docker-credential-ecr-login /bin/ && \
	cd / && \
	rm -rf src/github.com/awslabs/amazon-ecr-credential-helper && \
	mkdir -p ~/.docker && \
	echo -e '{ "credsStore": "ecr-login" }' > ~/.docker/config.json && \

	# Cleanup
	apk --purge -v del $BUILD_DEPS && \
	rm /var/cache/apk/*
