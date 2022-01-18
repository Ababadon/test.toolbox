# syntax=docker/dockerfile:experimental

#----- Build image -----#
FROM wurstmeister/kafka
WORKDIR /app

RUN apt update -y && \
    apt install -y software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt install -y ca-certificates wget curl openssl jq xxd unzip xml-twig-tools libnss3 libx11-6 locales && \
    apt install -y postgresql-client-common postgresql-client && \
    update-ca-certificates

RUN locale-gen en_US.UTF-8

# get venom v0.28.0
RUN wget -O /tmp/venom "https://github.com/ovh/venom/releases/download/v0.28.0/venom.linux-amd64" --no-check-certificate && \
    chmod +x /tmp/venom && \
    mv /tmp/venom /usr/local/bin/venom

# get Google Chrome
RUN curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list && \
    apt-get -y update && \
    apt-get -y install google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# get Chrome WebDriver
RUN CHROMEDRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` && \
    mkdir -p /opt/chromedriver-$CHROMEDRIVER_VERSION && \
    curl -sS -o /tmp/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip && \
    unzip -qq /tmp/chromedriver_linux64.zip -d /opt/chromedriver-$CHROMEDRIVER_VERSION && \
    rm /tmp/chromedriver_linux64.zip && \
    chmod +x /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver && \
    ln -fs /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver /usr/local/bin/chromedriver

RUN mkdir /app/test-results

COPY ./entrypoint.sh /app/entrypoint.sh
COPY test-suites/ /app/test-suites/
COPY data/ /app/data/
RUN chmod -R +x data/bin/

EXPOSE 8080

# For Chrome WebDriver
ENV DISPLAY :20.0
ENV SCREEN_GEOMETRY "1920x1080x24"
ENV CHROMEDRIVER_PORT 4444
ENV CHROMEDRIVER_WHITELISTED_IPS "127.0.0.1"
ENV CHROMEDRIVER_URL_BASE ''
ENV CHROMEDRIVER_EXTRA_ARGS ''

RUN ["chmod", "+x", "./entrypoint.sh"]
ENTRYPOINT ["./entrypoint.sh"]