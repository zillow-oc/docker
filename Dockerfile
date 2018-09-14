FROM docker:18.06-git

# BUILD_DEPS are used only to build the Docker image
# RUN_DEPS are installed and persist in the final built image
ENV \
	BUILD_DEPS="py-pip alpine-sdk go nodejs-npm" \
	RUN_DEPS="groff less python bash socat nodejs curl" \
	GOPATH=/ \
	NOMAD_URL="https://releases.hashicorp.com/nomad/0.8.4/nomad_0.8.4_linux_amd64.zip" \
	CONSUL_URL="https://releases.hashicorp.com/consul/1.2.1/consul_1.2.1_linux_amd64.zip" \
	CONSUL_TEMPLATE_URL="https://releases.hashicorp.com/consul-template/0.19.5/consul-template_0.19.5_linux_amd64.zip" \
	LEVANT_URL="https://github.com/jrasell/levant/releases/download/0.2.2/linux-amd64-levant" \
	TF_URL="https://releases.hashicorp.com/terraform/0.11.8/terraform_0.11.8_linux_amd64.zip" \
	TF_KONG_PLUGIN_URL="https://github.com/kevholditch/terraform-provider-kong/releases/download/v1.7.0/terraform-provider-kong_1.7.0_linux_amd64.zip"

WORKDIR /

RUN \

	# Install packages without storing package manager cache
	mkdir -p /aws && \
	apk -Uuv --no-cache add $RUN_DEPS $BUILD_DEPS && \
	npm install -g kongfig && npm cache clean --force && \
	pip --no-cache-dir install awscli && \

	# Install Nomad
	curl -L $NOMAD_URL > /tmp/nomad.zip && \
	unzip -o /tmp/nomad.zip -d /usr/bin && \
	chmod +x /usr/bin/nomad && \
	# Work-around for alpine incompatibility
	mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
	rm -f /tmp/nomad.zip && \

	# Install Consul
	curl -L $CONSUL_URL > /tmp/consul.zip && \
	unzip -o /tmp/consul.zip -d /usr/bin && \
	chmod +x /usr/bin/consul && \
	rm -f /tmp/consul.zip && \

	# Install Consul Template
	curl -L $CONSUL_TEMPLATE_URL > /tmp/consul-template.zip && \
	unzip -o /tmp/consul-template.zip -d /usr/bin && \
	chmod +x /usr/bin/consul-template && \
	rm -f /tmp/consul-template.zip && \

	# Install Levant - Nomad Deploy helper
	curl -L $LEVANT_URL -o /tmp/levant && \
	mv /tmp/levant /usr/bin/levant && \
	chmod +x /usr/bin/levant && \

	# Install Terraform - Infrastructure as Code
	curl -L $TF_URL > /tmp/tf.zip && \
	unzip -o /tmp/tf.zip -d /usr/bin && \
	chmod +x /usr/bin/terraform && \
	rm -f /tmp/tf.zip && \

	# Install Terraform Kong provider - github.com/kevholditch/terraform-provider-kong
	curl -L $TF_KONG_PLUGIN_URL > /tmp/tf-kong-provider.zip && \
	mkdir -p ~/.terraform.d/plugins && \
	unzip -o /tmp/tf-kong-provider.zip -d ~/.terraform.d/plugins && \
	rm -f /tmp/tf-kong-provider.zip && \

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
