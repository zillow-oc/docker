FROM docker:17.06-git

# BUILD_DEPS are used only to build the Docker image
# RUN_DEPS are installed and persist in the final built image
ENV	\
		BUILD_DEPS="py-pip alpine-sdk go curl" \
		RUN_DEPS="groff less python bash socat" \
		GOPATH=/ \
		NOMAD_URL="https://releases.hashicorp.com/nomad/0.5.6/nomad_0.5.6_linux_amd64.zip" \
		NOMAD_ENDPOINT="http://nomad.service.consul:4646"

WORKDIR /

RUN \

	# Install packages without storing package manager cache
	mkdir -p /aws && \
	apk -Uuv --no-cache add $RUN_DEPS $BUILD_DEPS && \	
	pip --no-cache-dir install awscli && \
	
	curl $NOMAD_URL > /tmp/nomad.zip && \
	unzip -o /tmp/nomad.zip -d /usr/bin && \
	chmod +x /usr/bin/nomad && \
	rm -f /tmp/nomad.zip && \

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
