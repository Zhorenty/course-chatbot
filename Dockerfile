FROM dart:stable AS build

WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline && dart compile exe bin/course_bot.dart -o course_bot.run

FROM ubuntu:noble AS runtime

WORKDIR /app

COPY --from=build /app/course_bot.run /app/

RUN apt-get update -y \
 && apt-get install -y --no-install-recommends ca-certificates libsqlite3-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/data

CMD ["/app/course_bot.run"]
