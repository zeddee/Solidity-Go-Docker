# Build
FROM golang:1.11 as builder

ENV gethsrc=/go/src/github.com/ethereum/go-ethereum
ENV solsrc=/root/solidity

WORKDIR /root

RUN apt-get update && apt-get install -y \
    sudo tree

RUN git clone https://github.com/ethereum/solidity ${solsrc} && \
    cd ${solsrc} && git checkout v0.5.2 && \
    cd ${solsrc}/scripts && \
    ./install_deps.sh

RUN cd ${solsrc} && mkdir build && \
    cd build && \
    cmake .. && make

RUN go get github.com/ethereum/go-ethereum && \
    cd $GOPATH/src/github.com/ethereum/go-ethereum/ && \
    git checkout v1.8.20 && \
    make all

# Pull all binaries into a second stage deploy alpine container
FROM debian:stretch

ENV gethsrc=/go/src/github.com/ethereum/go-ethereum
ENV solsrc=/root/solidity

RUN apt-get update && apt-get install -y libz3-4
COPY --from=builder ${gethsrc}/build/bin/* /usr/local/bin/
COPY --from=builder ${solsrc}/build/solc/solc /usr/local/bin
COPY --from=builder ${solsrc}/build/test/soltest /usr/local/bin
