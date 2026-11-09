# Styri VDA 5050 bench: vda5050-testkit at a pinned commit, with a plain pass/fail report.
# The testkit's source, with three 2.0.0 schema corrections: see build/patch_schemas.py.
FROM python:3.12-slim AS source
ARG TESTKIT=49b1f1e2cf11ef9bfaac8b1bdb5602546773c355
ADD https://github.com/ksshen0000/vda5050-testkit/archive/${TESTKIT}.tar.gz /tmp/testkit.tar.gz
COPY build/patch_schemas.py /tmp/
WORKDIR /src
RUN tar xzf /tmp/testkit.tar.gz --strip-components=1 && python3 -I /tmp/patch_schemas.py /src

FROM eclipse-temurin:21-jdk AS build
COPY --from=source /src /src
WORKDIR /src
RUN ./mvnw -B -ntp -q package -DskipTests

FROM eclipse-temurin:21-jre
RUN useradd --system --uid 10001 bench
COPY --from=build /src/vda5050-testkit-cli/target/vda5050-testkit.jar /opt/bench/vda5050-testkit.jar
COPY --from=build /src/LICENSE /opt/bench/testkit-LICENSE
COPY --from=build /src/NOTICE /opt/bench/testkit-NOTICE
COPY bench.sh NOTICE LICENSE /opt/bench/
USER bench
WORKDIR /tmp
ENTRYPOINT ["/opt/bench/bench.sh"]
