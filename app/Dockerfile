FROM openjdk:17-slim
WORKDIR /app
RUN apt-get update && apt-get install -y curl && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && curl -L -o hotrod.jar https://github.com/jaegertracing/example-hotrod/releases/latest/download/hotrod.jar
EXPOSE 8080
CMD ["java", "-jar", "hotrod.jar"]