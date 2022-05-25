# Build Stage
FROM --platform=linux/amd64 ubuntu:20.04 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y git clang cmake make libsdl2-dev

## Add source code to the build stage.
WORKDIR /
RUN git clone https://github.com/capuanob/SDL_sound.git
WORKDIR SDL_sound
RUN git checkout mayhem

## Build
RUN mkdir build
WORKDIR build
RUN CC=clang cmake .. -DSDLSOUND_INSTRUMENT=1 -DSDLSOUND_BUILD_SHARED=0
RUN make -j$(nproc)

## Package Stage
FROM --platform=linux/amd64 ubuntu:20.04
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y libsdl2-dev
COPY --from=builder /SDL_sound/build/fuzz/SDL_sound-fuzzer /SDL_sound-fuzzer
COPY --from=builder /SDL_sound/fuzz/corpus /corpus

## Set up fuzzing!
ENTRYPOINT []
CMD /SDL_sound-fuzzer /corpus -close_fd_mask=2
