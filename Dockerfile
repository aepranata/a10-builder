# Environment build Android 10 (Q) - Ubuntu 18.04 (base resmi yang direkomendasikan AOSP untuk Q)
FROM ubuntu:18.04

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USERNAME=builder

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Jakarta \
    USE_CCACHE=1 \
    CCACHE_EXEC=/usr/bin/ccache \
    CCACHE_DIR=/ccache

RUN apt-get update && apt-get install -y --no-install-recommends \
        locales tzdata ca-certificates \
        git git-core gnupg curl wget \
        flex bison build-essential gperf zip unzip zlib1g-dev \
        gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev lib32z1-dev \
        libncurses5 libncurses5-dev libx11-dev x11proto-core-dev libgl1-mesa-dev \
        libxml2-utils xsltproc fontconfig \
        libssl-dev libelf-dev bc rsync lzop schedtool squashfs-tools \
        imagemagick pngcrush liblz4-tool lz4 xz-utils zstd \
        python python3 python-pip python3-pip python-mako \
        openjdk-8-jdk-headless \
        ccache sudo vim nano less file procps openssh-client \
    && locale-gen en_US.UTF-8 \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

# Tool repo (jaga-jaga kalau perlu sync ulang)
RUN curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo \
    && chmod +x /usr/local/bin/repo

# User non-root dengan UID/GID sama seperti host supaya permission file aman
RUN groupadd -g ${GROUP_ID} ${USERNAME} \
    && useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && mkdir -p /src /ccache && chown ${USERNAME}:${USERNAME} /src /ccache

USER ${USERNAME}
WORKDIR /src

RUN git config --global user.name "builder" \
    && git config --global user.email "builder@localhost" \
    && git config --global color.ui false \
    && ccache -M 50G

CMD ["/bin/bash"]
