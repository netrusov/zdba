FROM docker.io/jruby:10.0.4.0-jdk AS build

WORKDIR /app

COPY Gemfile Gemfile.lock zdba.gemspec ./
COPY lib/zdba/version.rb ./lib/zdba/version.rb

RUN bundle config set without development
RUN bundle install

COPY . ./

RUN bundle exec warble jar

FROM gcr.io/distroless/java25-debian13

WORKDIR /work

COPY --from=build /app/zdba.jar /app/zdba.jar

ENTRYPOINT ["java", "--enable-native-access=ALL-UNNAMED", "--sun-misc-unsafe-memory-access=allow", "-jar", "/app/zdba.jar"]
