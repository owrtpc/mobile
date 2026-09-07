# syntax=docker/dockerfile:1
FROM eclipse-temurin:21.0.12_8-jdk-jammy@sha256:ce5767b7222312d42395f5bab033cd91f09e44032a2f21bdfd7b5b912dbe1e77 AS java
FROM owrtpc-mobile-flutter:3.47.2

COPY --from=java /opt/java/openjdk /opt/java/openjdk
ENV JAVA_HOME=/opt/java/openjdk \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH="/opt/java/openjdk/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:${PATH}"

# Official command-line archive and SHA-256 from developer.android.com/studio.
ARG ANDROID_TOOLS_BUILD=15859902
ARG ANDROID_TOOLS_SHA256=4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583
RUN curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_TOOLS_BUILD}_latest.zip" -o /tmp/android-tools.zip \
    && echo "${ANDROID_TOOLS_SHA256}  /tmp/android-tools.zip" | sha256sum -c - \
    && mkdir -p /opt/android-sdk/cmdline-tools \
    && unzip -q /tmp/android-tools.zip -d /opt/android-sdk/cmdline-tools \
    && mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest \
    && rm /tmp/android-tools.zip

# Building this development image accepts the standard Android SDK licences.
# Keep these package versions aligned with android/app/build.gradle.kts.
RUN yes | sdkmanager --licenses > /dev/null
RUN sdkmanager 'platforms;android-36' 'build-tools;36.0.0' 'ndk;28.2.13676358' 'platform-tools' \
    && flutter config --android-sdk /opt/android-sdk --jdk-dir /opt/java/openjdk \
    && flutter precache --android \
    && java -version \
    && sdkmanager --list_installed > /opt/android-sdk/installed-packages.txt

# Native plugins use SDK 35 and 37.0. The app targets SDK 36.
RUN sdkmanager 'platforms;android-35' 'platforms;android-37.0' \
    && sdkmanager --list_installed > /opt/android-sdk/installed-packages.txt

RUN sdkmanager 'cmake;3.22.1' \
    && sdkmanager --list_installed > /opt/android-sdk/installed-packages.txt

RUN apt-get update && apt-get install -y --no-install-recommends rsync util-linux \
    && rm -rf /var/lib/apt/lists/*
