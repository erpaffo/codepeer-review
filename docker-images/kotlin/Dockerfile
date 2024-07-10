FROM openjdk:11

WORKDIR /app

CMD ["sh", "-c", "kotlinc main.kt -include-runtime -d main.jar && java -jar main.jar"]
