FROM eclipse-temurin:17 as app-build

ENV RELEASE=17

WORKDIR /opt/build

COPY ./target/spring-boot-*.jar ./application.jar

RUN java -Djarmode=layertools -jar application.jar extract
RUN $JAVA_HOME/bin/jlink \
         --add-modules `jdeps --ignore-missing-deps -q -recursive --multi-release ${RELEASE} --print-module-deps -cp 'dependencies/BOOT-INF/lib/*' 'snapshot-dependencies/BOOT-INF/lib/' application.jar` \
         --strip-debug \
         --no-man-pages \
         --no-header-files \
         --compress=2 \
         --output ./custom-jdk

FROM alpine:latest

ARG BUILD_PATH=/opt/build
ENV JAVA_HOME=/opt/jdk
ENV PATH "${JAVA_HOME}/bin:${PATH}"

WORKDIR application

COPY --from=app-build $BUILD_PATH/custom-jdk $JAVA_HOME
COPY --from=app-build $BUILD_PATH/spring-boot-loader/ ./
COPY --from=app-build $BUILD_PATH/dependencies/ ./
COPY --from=app-build $BUILD_PATH/snapshot-dependencies/ ./
COPY --from=app-build $BUILD_PATH/application/ ./

ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]