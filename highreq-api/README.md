# highreq-api

Spring Boot (Java) REST API shaped for **10,000 concurrent users / ~5,000 requests per second**,
built with **Gradle**. The built fat JAR contains every dependency, so the project
runs fully offline — the target machine only needs a JDK (17, 21 or 25).

## Project layout

```
highreq-api/
├── dist/highreq-api-1.0.0.jar   ← self-contained runnable JAR (all libs inside)
├── run.bat / run.sh             ← offline runners (java -jar dist/...)
├── build.gradle / settings.gradle
├── gradlew / gradlew.bat        ← Gradle wrapper (rebuilds the project)
├── gradle/wrapper/
├── src/main/java/com/highreq/   ← Application, User API, cache config
├── src/main/resources/application.yml
└── loadtest/
    ├── k6.js                    ← professional load test (k6)
    └── loadtest.py              ← zero-install load test (Python)
```

## Run (offline machine, JDK only — no internet needed)

Windows:

```bat
run.bat
```

Linux/macOS:

```sh
chmod +x run.sh && ./run.sh
```

Or directly:

```sh
java -jar dist/highreq-api-1.0.0.jar
```

The app starts on `http://localhost:8080`.

## Rebuild from source

### Offline machine (no internet at all)

The folder `gradle-offline-home/` contains everything Gradle needs: the Gradle
8.10.2 distribution plus all dependency JARs (~250 MB). It travels with the project.

```bat
build-offline.bat            :: Windows
```
```sh
chmod +x build-offline.sh && ./build-offline.sh   # Linux/macOS
```

This runs `gradlew --offline bootJar` against the vendored home and refreshes
`dist/highreq-api-1.0.0.jar`. Verified: builds with zero network access,
using only a JDK (17/21/25).

### Online machine (normal rebuild)

```sh
gradlew.bat bootJar          # Windows
./gradlew bootJar            # Linux/macOS
```

This recompiles and refreshes `build/libs/highreq-api-1.0.0.jar`
(copy it into `dist/` to update the offline copy).

## API endpoints

| Method | Path                     | Description                              |
|--------|--------------------------|------------------------------------------|
| GET    | /api/v1/users/health     | Health check                             |
| POST   | /api/v1/users            | Create user `{ "name": "...", "email": "..." }` |
| GET    | /api/v1/users/{id}       | Get user (cached read — hot path)        |
| GET    | /actuator/health         | Liveness/readiness probes                |
| GET    | /actuator/metrics        | Prometheus-style metrics                 |
| GET    | /actuator/caches         | Cache statistics                         |

## Test it

Smoke test (any machine with curl):

```sh
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"alice@example.com"}'
curl http://localhost:8080/api/v1/users/1
```

Load test — option A, **k6** (recommended, install from grafana.com/k6):

```sh
k6 run loadtest/k6.js                  # ramps to 10k VUs / 5k RPS with thresholds
k6 run -e RPS=5000 -e VUS=10000 loadtest/k6.js
```

Load test — option B, Python (no install beyond `requests`):

```sh
python loadtest/loadtest.py --connections 300 --duration 60
```

Watch the server side while testing: `http://localhost:8080/actuator/metrics/http.server.requests`

## How this design reaches 10k users / 5k RPS

This instance alone handles a large slice of the load; production reaches the
full target by **scaling out** (N stateless instances behind a load balancer):

1. **Stateless** — no in-memory sessions; any instance can serve any request.
2. **Cache hot reads** — Caffeine in-process (swap to Redis when multi-instance).
3. **Sized connection pools** — HikariCP capped at 20 (see `application.yml`);
   the DB is never the bottleneck for cached reads.
4. **Sized Tomcat** — `threads.max: 400`, `max-connections: 10000`.
5. **Async-ready stack** — Spring MVC + virtual threads friendly (JDK 21+).
6. **Observability** — Actuator metrics to watch latency/error rates during tests.

### Production checklist beyond this project

- 2+ app instances behind nginx/ALB/HAProxy; H2 → PostgreSQL/MySQL
- Redis for shared cache; externalized sessions if needed
- JVM flags: `-Xms/-Xmx` sized, G1 (or ZGC on JDK 21+)
- Confirm with k6: p95 < 200 ms and error rate < 1 % at 5k RPS
