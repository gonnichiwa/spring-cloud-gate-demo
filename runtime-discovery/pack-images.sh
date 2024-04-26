#!/bin/bash

echo "Performing a clean Maven build"
./mvnw clean package -DskipTests=true

echo "Setting the default builder for pack"
pack set-default-builder cloudfoundry/cnb:bionic

echo "Packing the Service"
cd service
mvn compile com.google.cloud.tools:jib-maven-plugin:1.3.0:dockerBuild -Dimage=scg-demo-service:latest
cd ..

echo "Packing the Eureka Discovery Server"
cd registry
mvn compile com.google.cloud.tools:jib-maven-plugin:1.3.0:dockerBuild -Dimage=scg-demo-registry:latest
cd ..

echo "Packing the Spring Cloud Gateway"
cd gateway
mvn compile com.google.cloud.tools:jib-maven-plugin:1.3.0:dockerBuild -Dimage=scg-demo-gateway:latest
cd ..
