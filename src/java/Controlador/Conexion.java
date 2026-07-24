package Controlador;

import java.net.URI;
import java.sql.Connection;
import java.sql.DriverManager;

/**
 * Maneja la conexión JDBC a MySQL.
 *
 * En Railway, el servicio de MySQL inyecta automáticamente variables de
 * entorno (MYSQLHOST, MYSQLPORT, MYSQLDATABASE, MYSQLUSER, MYSQLPASSWORD,
 * y también MYSQL_URL con el formato mysql://usuario:clave@host:puerto/bd).
 *
 * Si ninguna de esas variables está presente (por ejemplo, cuando se corre
 * el proyecto en local desde NetBeans), se usa la configuración local por
 * defecto (localhost:3307) para no romper el flujo de desarrollo.
 */
public class Conexion {

    Connection con;

    public Connection getConnection() {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            String url;
            String usuario;
            String clave;

            String mysqlUrl = System.getenv("MYSQL_URL");
            String host = System.getenv("MYSQLHOST");

            if (mysqlUrl != null && !mysqlUrl.isBlank()) {
                // Formato Railway: mysql://usuario:clave@host:puerto/basedatos
                URI uri = new URI(mysqlUrl);
                String userInfo = uri.getUserInfo(); // usuario:clave
                String[] partes = userInfo.split(":", 2);
                usuario = partes[0];
                clave = partes.length > 1 ? partes[1] : "";
                String bd = uri.getPath().replaceFirst("^/", "");
                url = "jdbc:mysql://" + uri.getHost() + ":" + uri.getPort() + "/" + bd
                        + "?useSSL=false&serverTimezone=America/Bogota&allowPublicKeyRetrieval=true";
            } else if (host != null && !host.isBlank()) {
                // Variables individuales de Railway
                String port = System.getenv().getOrDefault("MYSQLPORT", "3306");
                String bd = System.getenv().getOrDefault("MYSQLDATABASE", "railway");
                usuario = System.getenv().getOrDefault("MYSQLUSER", "root");
                clave = System.getenv().getOrDefault("MYSQLPASSWORD", "");
                url = "jdbc:mysql://" + host + ":" + port + "/" + bd
                        + "?useSSL=false&serverTimezone=America/Bogota&allowPublicKeyRetrieval=true";
            } else {
                // Fallback: desarrollo local (NetBeans + MySQL local en el puerto 3307)
                url = "jdbc:mysql://localhost:3307/Neins?useSSL=false&serverTimezone=America/Bogota&allowPublicKeyRetrieval=true";
                usuario = "root";
                clave = "";
            }

            con = DriverManager.getConnection(url, usuario, clave);
        } catch (Exception e) {
            System.err.println("[NEINS] Error de conexión a MySQL: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("No se pudo conectar a la base de datos: " + e.getMessage(), e);
        }
        return con;
    }
}
