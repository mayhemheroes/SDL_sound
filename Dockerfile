# Build Stage
FROM --platform=linux/amd64 ubuntu:20.04 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y clang cmake make libsdl2-dev

## Add source code to the build stage.
WORKDIR /
ADD . /SDL_sound
WORKDIR SDL_sound

## Build
RUN mkdir build
WORKDIR build
RUN mkdir /install
RUN CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/install .. -DSDLSOUND_INSTRUMENT=1 
RUN make -j$(nproc)
RUN make install

## Package Stage
FROM --platform=linux/amd64 ubuntu:20.04
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y libsdl2-dev
COPY --from=builder /SDL_sound/build/fuzz/SDL_sound-fuzzer /SDL_sound-fuzzer
COPY --from=builder /SDL_sound/fuzz/testsuite /testsuite
COPY --from=builder /install /install

ENV LD_LIBRARY_PATH=/install/lib

## Set up fuzzing!
ENTRYPOINT []
CMD /SDL_sound-fuzzer /testsuite
