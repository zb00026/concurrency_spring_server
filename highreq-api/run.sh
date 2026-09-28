#!/usr/bin/env sh
# Offline runner: needs only a JDK (17/21/25) on the machine. No internet required.
JAR="$(cd "$(dirname "$0")" && pwd)/dist/highreq-api-1.0.0.jar"

if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    exec "$JAVA_HOME/bin/java" -jar "$JAR"
elif command -v java >/dev/null 2>&1; then
    exec java -jar "$JAR"
else
    echo "[ERROR] Java not found. Install JDK 17 or newer, or set JAVA_HOME." >&2
    exit 1
fi
