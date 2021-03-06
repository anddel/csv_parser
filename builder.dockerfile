FROM rust:latest as builder

# based on https://github.com/bitrise-io/android-ndk/blob/master/Dockerfile
# ------------------------------------------------------
# --- Android NDK

ENV ANDROID_NDK_HOME /opt/android-ndk
ENV ANDROID_NDK_VERSION r21d
ENV GCE_METADATA_ROOT 127.0.0.1

# download
RUN mkdir /opt/android-ndk-tmp && \
    cd /opt/android-ndk-tmp && \
    wget -q https://dl.google.com/android/repository/android-ndk-${ANDROID_NDK_VERSION}-linux-x86_64.zip && \
# uncompress
    unzip -q android-ndk-${ANDROID_NDK_VERSION}-linux-x86_64.zip && \
# move to its final location
    mv ./android-ndk-${ANDROID_NDK_VERSION} ${ANDROID_NDK_HOME} && \
# remove temp dir
    cd ${ANDROID_NDK_HOME} && \
    rm -rf /opt/android-ndk-tmp

# add to PATH
ENV PATH ${PATH}:${ANDROID_NDK_HOME}
# ------------------------------------------------------

WORKDIR /csv_parser
ADD . .

RUN apt-get update && apt-get install -y gcc-mingw-w64 && \
    make init && make all && make extract_artifacts

FROM scratch
COPY --from=builder /csv_parser/assets/binary /binary-build

CMD echo done