FROM docker:1.13-git

RUN \
  mkdir -p /aws && \
  apk -Uuv add groff less python py-pip bash && \
  pip install awscli && \
  apk --purge -v del py-pip && \
  rm /var/cache/apk/*
