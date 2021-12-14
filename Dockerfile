# -----------
# Build stage
# -----------

FROM debian:11-slim AS build
WORKDIR /build

# Set stk version that should be built
ENV VERSION=1.3

# Install build dependencies
RUN apt-get update && \
    apt-get install -y build-essential \
                       cmake \
                       git \
                       libcurl4-openssl-dev \
                       libenet-dev \
                       libssl-dev \
                       pkg-config \
                       subversion \
                       zlib1g-dev

# Get code and assets
RUN git clone --branch ${VERSION} --depth=1 https://github.com/supertuxkart/stk-code.git
RUN svn checkout https://svn.code.sf.net/p/supertuxkart/code/stk-assets stk-assets

# Build server
RUN mkdir stk-code/cmake_build && \
    cd stk-code/cmake_build && \
    cmake .. -DSERVER_ONLY=ON && \
    make -j$(nproc) && \
    make install

# -----------
# Final stage
# -----------

FROM debian:11-slim
WORKDIR /app

# Install libcurl dependency
RUN apt-get update && \
    apt-get install -y libcurl4-openssl-dev curl unzip && \
    rm -rf /var/lib/apt/lists/*

# Copy artifacts from build stage
COPY --from=build /usr/local/bin/supertuxkart /usr/local/bin
COPY --from=build /usr/local/share/supertuxkart /usr/local/share/supertuxkart
COPY ./entrypoint /app/entrypoint
COPY ./install-all-addons.sh /app/install-all-addons.sh

# Expose ports
EXPOSE 2757
EXPOSE 2759

ENTRYPOINT ["/app/entrypoint"]
