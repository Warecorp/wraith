FROM ruby:2.4-alpine
LABEL maintainer="Boris Efron <borisdr@gmail.com>"
ARG DEPLOY_USER_ID=1000
ARG DEPLOY_GROUP_ID=1000
ENV DOCKERIZE_VERSION v0.6.1
ENV APP_ROOT="/var/www/html"
ENV PHANTOMJS_VERSION 2.1.1
RUN set -xe; \
    mkdir -p /var/www/html
ADD . /var/www/html/
WORKDIR ${APP_ROOT}
RUN set -xe; \
    \
    # Delete existing user/group if uid/gid occupied.
    existing_group=$(getent group "${DEPLOY_GROUP_ID}" | cut -d: -f1); \
    if [[ -n "${existing_group}" ]]; then delgroup "${existing_group}"; fi; \
    existing_user=$(getent passwd "${DEPLOY_USER_ID}" | cut -d: -f1); \
    if [[ -n "${existing_user}" ]]; then deluser "${existing_user}"; fi; \
    \
  addgroup -g "${DEPLOY_GROUP_ID}" -S deploy; \
  adduser -u "${DEPLOY_USER_ID}" -D -S -s /bin/bash -G deploy deploy; \
  adduser deploy deploy; \
  sed -i '/^deploy/s/!/*/' /etc/shadow; \
    { \
        echo 'export PS1="\u@${APP_NAME:-wraith}.${RAILS_ENV:-container}:\w $ "'; \
        # Make sure PA TH is the same for ssh sessions.
        echo "export PATH=${PATH}"; \
    } | tee /home/deploy/.shrc; \
    \
    cp /home/deploy/.shrc /home/deploy/.bashrc; \
    cp /home/deploy/.shrc /home/deploy/.bash_profile; \
\
    gotpl_url="https://github.com/wodby/gotpl/releases/download/0.1.5/gotpl-alpine-linux-amd64-0.1.5.tar.gz"; \
    wget -qO- "${gotpl_url}" | tar xz -C /usr/local/bin; \
    dockerize_url="https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz"; \
    wget -qO- "${dockerize_url}" | tar xz -C /usr/local/bin; \
    apk --no-cache add --virtual .run-deps \
    bash \
    git \
    curl \
    imagemagick6 \
    libxslt \
    libxml2 \
    nodejs \
    npm \
    tzdata; \
    apk --no-cache add --virtual .build-deps \
    build-base \
    ruby-dev \
    imagemagick6-dev \
    libxml2-dev \
    libxslt-dev \
    su-exec;\
    # curl -Ls "https://github.com/dustinblackman/phantomized/releases/download/${PHANTOMJS_VERSION}/dockerized-phantomjs.tar.gz" | tar xz -C / ;\
    curl -k -Ls https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-${PHANTOMJS_VERSION}-linux-x86_64.tar.bz2  | tar -jxvf - -C / ;\
    cp /phantomjs-${PHANTOMJS_VERSION}-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs ;\
    rm -fR /phantomjs-${PHANTOMJS_VERSION}-linux-x86_64 ;\
    echo 'gem: --no-document' > /etc/gemrc; \
    gem update --system; \
    bundle config build.nokogiri --use-system-libraries; \
    bundle install ; \
    gem install wraith ;\
    rm -rf /root/.gem/cache ; \
    apk --purge del .build-deps; \
    # rm -rf /usr/local/bundle/cache; \
    rm -rf /root/.bundle/cache; \
    ln -sf /usr/bin/convert-6 /usr/bin/convert; \
    chown -R deploy:deploy /var/www/html
USER deploy
# ENTRYPOINT ["wraith"]
