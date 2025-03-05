FROM horologger/btcshell:v0.0.6 AS builder
LABEL maintainer="horologger <horologger@protonmail.com>"

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "Spaces Build Starting...$TARGETPLATFORM"
# RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM"

ARG PG_ENABLE

# docker buildx build --platform linux/arm64,linux/amd64 --tag horologger/spaces:v0.0.7 --output "type=registry" . --build-arg POSTGRESQL_ENABLE=true
RUN if [ "$PG_ENABLE" = "true" ] ; then \
    echo "PG ENABLED"; \
else \
    echo "PG DISABLED"; \
fi    


# Start9 Packaging
# Use this one in order got get the proper version of cargo
RUN apk update && apk upgrade && apk add --no-cache cargo --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main
RUN apk add --no-cache yq pkgconfig openssh openssl openssl-dev openssl-libs-static gcompat git; \
    rm -f /var/cache/apk/*

# Once the main version of cargo is at least 1.8
# RUN apk add --no-cache yq cargo pkgconfig openssh openssl openssl-dev openssl-libs-static gcompat git; \
#     rm -f /var/cache/apk/*

RUN if [ "$PG_ENABLE" = "true" ] ; then \
    apk add npm postgresql; rm -f /var/cache/apk/*;  \
fi    


# RUN git clone https://github.com/spacesprotocol/spaced && cd spaced ; \
# RUN git clone https://github.com/horologger/spaced && cd spaced ; \
#     # cargo build --release ; \
#     cargo install --path node --locked ; cd ..
# # echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc

# RUN git clone https://github.com/horologger/spaced && cd spaced ; \ 
# cargo install --path node --locked ; cd ..

RUN git clone https://github.com/horologger/spaced && cd spaced ; \ 
    cargo install --path client --locked ; cd ..
# echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc

# Get the Spaces Explorer code but don't do anthing yet.
# RUN git clone https://github.com/horologger/spaces-explorer

# Install Fabric
# RUN npm install -g @spacesprotocol/fabric

# libgc++ g++ clang make rustup 
# apk add clang make libgc++ g++
# https://www.rust-lang.org/tools/install
# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# cargo install cargo-risczero
# cargo risczero install
# RUN git clone https://github.com/andrewlunde/subspacer && cd subspacer ; \
#     cargo build --release ; \
#     cargo install --path node --locked

# Final stage
FROM horologger/btcshell:v0.0.6

# Required runtime dependencies based on docker_entrypoint.sh usage
RUN apk add --no-cache \
    yq \
    openssl \
    openssl-libs-static \
    gcompat \
    screen \
    htop \
    bash \
    miller \
    nodejs \
    npm \
    iperf \
    nano \
    && rm -f /var/cache/apk/*

# Copy built binaries from builder stage
# RUN mkdir -p /root/.cargo/bin
COPY --from=builder /root/.cargo/bin/spaced /root/.cargo/bin/spaced
COPY --from=builder /root/.cargo/bin/space-cli /root/.cargo/bin/space-cli

COPY --chmod=755 docker_entrypoint.sh /usr/local/bin/

EXPOSE 22253/udp
EXPOSE 22253/tcp
EXPOSE 5173
EXPOSE 3000

# Run docker_entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]