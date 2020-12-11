FROM debian:bullseye as debianbase
ENV DEBIAN_FRONTEND=noninteractive

FROM debianbase as deps
RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc golang-go make \
        libglvnd-dev libsecret-1-dev git ca-certificates qt5-qmake g++

FROM deps as build
WORKDIR /tmp/build
COPY . .

ENV GOPATH="/root/go"
ENV PATH="${PATH}:${GOPATH}/bin"

RUN make build

FROM debianbase as test
WORKDIR /tmp/docker

RUN apt-get update \
    && apt-get install -y --no-install-recommends pass gnupg rng-tools \
        libqt5designer5 libqt5multimediawidgets5 libqt5quickwidgets5 \
        libpulse-mainloop-glib0 libsecret-1-0 fonts-dejavu tar \
        ca-certificates

COPY --from=build /tmp/build/bridge_linux_*.tgz .

RUN rngd -r /dev/urandom \
    && gpg --batch --yes --passphrase '' \
        --quick-generate-key 'tester@example.com' \
    && pass init `gpg --list-keys | grep "^   " | tail -1 \
        | tr -d '[:space:]'` \
    && tar zxvf /tmp/docker/bridge_linux_*.tgz
