# ============================================================
#  Dockerfile - NEINS (despliegue directo del WAR ya compilado)
#  Toma dist/Neins.war (ya armado con NetBeans/Ant) y lo despliega
#  en Tomcat 10 (Jakarta EE 10) como ROOT, para servir en "/".
# ============================================================
FROM tomcat:10.1-jdk21-temurin

RUN rm -rf /usr/local/tomcat/webapps/*
COPY dist/Neins.war /usr/local/tomcat/webapps/ROOT.war
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
