FROM dart:3.13.1 AS build

WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline && dart compile exe bin/course_bot.dart -o course_bot.run

FROM ubuntu:24.04 AS runtime

WORKDIR /app

COPY --from=build /app/course_bot.run /app/
COPY --from=build /app/assets /app/assets

RUN apt-get update -y \
 && apt-get install -y --no-install-recommends ca-certificates curl libsqlite3-0 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/data /app/data/backups

CMD ["/app/course_bot.run"]
