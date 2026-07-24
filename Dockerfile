# ============================================================
#  Dockerfile - NEINS
#  Compila los .java del proyecto (Servlets/JSP, sin EJB ni
#  Java EE completo) y los despliega en Tomcat 10 (Jakarta EE 10,
#  compatible con el web.xml de este proyecto).
# ============================================================

# ---------- Etapa 1: compilar ----------
FROM tomcat:10.1-jdk21-temurin AS build

WORKDIR /app

# Copiamos el código fuente y los recursos web
COPY src/java ./src/java
COPY web ./web
COPY build/web/WEB-INF/lib/mysql-connector-j-9.7.0.jar ./mysql-connector.jar

# Compilamos usando las librerías jakarta.servlet que ya trae Tomcat
RUN mkdir -p /app/classes && \
    find src/java -name "*.java" > /app/sources.txt && \
    javac -encoding UTF-8 \
        -cp "/usr/local/tomcat/lib/*:./mysql-connector.jar" \
        -d /app/classes \
        @/app/sources.txt

# Armamos el WAR (se despliega como ROOT para servir en la raíz "/")
RUN mkdir -p /app/warfiles/WEB-INF/classes /app/warfiles/WEB-INF/lib && \
    cp -r web/* /app/warfiles/ && \
    cp -r /app/classes/* /app/warfiles/WEB-INF/classes/ && \
    cp /app/mysql-connector.jar /app/warfiles/WEB-INF/lib/ && \
    cd /app/warfiles && jar -cf /app/ROOT.war .

# ---------- Etapa 2: runtime ----------
FROM tomcat:10.1-jdk21-temurin

RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /app/ROOT.war /usr/local/tomcat/webapps/ROOT.war
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
