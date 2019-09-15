FROM	debian:buster-slim
SHELL   ["/bin/bash", "-xeo", "pipefail", "-c"]

ARG     PGAP_VERSION="2019-02-11.build3477"
ARG     UID=1000
ARG     GID=1000
ARG     NAME="pgap"

RUN     groupadd --gid ${GID} ${NAME}; \
        useradd --create-home --system --shell /sbin/nologin --gid "${GID}" --uid "${UID}" "${NAME}"; \
        export DEBIAN_FRONTEND=noninteractive; \
        apt-get update; \
        apt-get dist-upgrade -y; \
        apt-get install -y --no-install-recommends \
                build-essential ca-certificates curl git jq nodejs \
                python3-dev python3-pip python3-setuptools python3-wheel sudo; \
        echo "$NAME ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers; \
        pip3 install cwltool PyYAML cwlref-runner; \
         mkdir -vp /usr/src/pgap; \
        if [[ ! -z "${PGAP_VERSION}" ]]; then \
                curl -fsSLo- "https://api.github.com/repos/ncbi/pgap/tarball/${PGAP_VERSION}" | tar zxf - -C /usr/src/pgap --strip-components 1; \
        else \
                _jsondata="$(curl -fsSLo- https://api.github.com/repos/ncbi/pgap/releases/latest)"; \
                _tarball_url="$(echo -n ${_jsondata} | jq -r '.tarball_url')"; \
                export PGAP_VERSION="$(basename ${_tarball_url})"; \
                curl -fsSLo- "${_tarball_url}" | tar zxf - -C /usr/src/pgap --strip-components 1; \
        fi; \
        chown -R $UID:$GID /usr/src/pgap; \
        apt-get remove --purge --autoremove -y build-essential curl jq; \
        apt-get autoclean; \
        rm -rf /usr/src/pgap/.git /tmp/* /root/*tmp*

#RUN     curl -fSLo "/tmp/input-${PGAP_VERSION}.tgz" "https://s3.amazonaws.com/pgap-data/input-${PGAP_VERSION}.tgz"; \
#        tar zxvf "/tmp/input-${PGAP_VERSION}.tgz" -C /usr/src/pgap --strip-components 1
#RUN    cat /usr/src/pgap/input.yaml /usr/src/pgap/MG37/input.yaml > /usr/src/pgap/mg37_input.yaml

WORKDIR /usr/src/pgap
USER    "$NAME"
