#!/usr/bin/env sh
# Builds the project fully OFFLINE using the vendored Gradle home.
# Requirement: only a JDK (17/21/25). No internet, no Maven, no system Gradle.
cd "$(dirname "$0")" || exit 1
export GRADLE_USER_HOME="$(pwd)/gradle-offline-home"

if [ -z "$JAVA_HOME" ] && ! command -v java >/dev/null 2>&1; then
    echo "[ERROR] Java not found. Install JDK 17+ or set JAVA_HOME." >&2
    exit 1
fi

./gradlew --offline --no-daemon bootJar || exit 1
cp -f build/libs/highreq-api-1.0.0.jar dist/
echo
echo "[OK] Built offline: dist/highreq-api-1.0.0.jar"
