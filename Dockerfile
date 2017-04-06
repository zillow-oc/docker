FROM docker:1.13-git

ENV BUILD_DEPS="del py-pip"
ENV RUN_DEPS="groff less python bash"
RUN \
  mkdir -p /aws && \
  apk -Uuv --no-cache add $RUN_DEPS $BUILD_DEPS && \
  pip install awscli && \
  apk --purge -v del $BUILD_DEPS && \
  rm /var/cache/apk/*
