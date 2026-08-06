package Controlador;

import java.sql.Connection;
import java.sql.DriverManager;

public class Conexion {

    Connection con;

    public Connection getConnection() {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection(
                    "jdbc:mysql://localhost:3307/Neins?useSSL=false&serverTimezone=America/Bogota&allowPublicKeyRetrieval=true",
                    "root",
                    ""   // <-- Si tu root tiene contraseña, ponla aquí entre las comillas
            );
        } catch (Exception e) {
            System.err.println("[NEINS] Error de conexión a MySQL: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("No se pudo conectar a la base de datos: " + e.getMessage(), e);
        }
        return con;
    }
}
