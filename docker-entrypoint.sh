#!/bin/sh
# Railway asigna el puerto en la variable de entorno $PORT.
# Tomcat trae 8080 por defecto en server.xml, así que lo ajustamos al vuelo.
set -e

PORT="${PORT:-8080}"
sed -i "s/port=\"8080\"/port=\"${PORT}\"/" /usr/local/tomcat/conf/server.xml

exec catalina.sh run
