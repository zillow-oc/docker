FROM docker:1.13-git

# BUILD_DEPS are used only to build the Docker image
# RUN_DEPS are installed and persist in the final built image
ENV BUILD_DEPS="py-pip" \
    RUN_DEPS="groff less python bash"

RUN \
  mkdir -p /aws && \
  apk -Uuv --no-cache add $RUN_DEPS $BUILD_DEPS && \
  pip install awscli && \
  apk --purge -v del $BUILD_DEPS && \
  rm /var/cache/apk/*
