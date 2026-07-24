<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="java.sql.*,Controlador.Conexion"%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Diagnóstico NEINS</title>
<style>
  body { font-family: monospace; background: #111; color: #eee; padding: 30px; }
  .ok  { color: #5f5; } .err { color: #f55; } .warn { color: #fa0; }
  pre  { background: #222; padding: 12px; border-radius: 6px; }
  h2   { color: #d4af37; }
</style>
</head>
<body>
<h2>🔧 Diagnóstico NEINS</h2>
<%
String url  = "jdbc:mysql://localhost:3307/Neins?useSSL=false&serverTimezone=America/Bogota&allowPublicKeyRetrieval=true";
String user = "root";
String pass = "";

// Test 1: Driver
out.println("<h3>1. Driver MySQL</h3>");
try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    out.println("<p class='ok'>✅ Driver encontrado: com.mysql.cj.jdbc.Driver</p>");
} catch (Exception e) {
    out.println("<p class='err'>❌ Driver NO encontrado: " + e.getMessage() + "</p>");
    out.println("<p class='warn'>→ Copia mysql-connector-j-9.7.0.jar a web/WEB-INF/lib/</p>");
}

// Test 2: Conexión
Connection con = null;
out.println("<h3>2. Conexión a MySQL:3307</h3>");
try {
    con = DriverManager.getConnection(url, user, pass);
    out.println("<p class='ok'>✅ Conexión exitosa al puerto 3307</p>");
} catch (Exception e) {
    out.println("<p class='err'>❌ No se pudo conectar: " + e.getMessage() + "</p>");
    if (e.getMessage().contains("Access denied")) {
        out.println("<p class='warn'>→ Contraseña incorrecta para root. Edita Conexion.java</p>");
    } else if (e.getMessage().contains("refused") || e.getMessage().contains("3307")) {
        out.println("<p class='warn'>→ MySQL no está corriendo en puerto 3307</p>");
    }
    out.println("<pre>" + e.toString() + "</pre>");
}

// Test 3: Base de datos
if (con != null) {
    out.println("<h3>3. Base de datos 'Neins'</h3>");
    try {
        ResultSet rs = con.createStatement().executeQuery(
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='Neins'");
        rs.next();
        int n = rs.getInt(1);
        if (n == 0) {
            out.println("<p class='err'>❌ La BD 'Neins' existe pero NO tiene tablas</p>");
            out.println("<p class='warn'>→ Importa el archivo Neins_BASE_COMPLETA_con_cambios_SIN_BOM.sql</p>");
        } else {
            out.println("<p class='ok'>✅ BD 'Neins' tiene " + n + " tablas</p>");
        }

        // Test 4: Usuario admin
        out.println("<h3>4. Usuario admin</h3>");
        ResultSet rs2 = con.createStatement().executeQuery(
            "SELECT COUNT(*) FROM Neins.Usuarios WHERE correo='admin@neins.com'");
        rs2.next();
        int admins = rs2.getInt(1);
        if (admins == 0) {
            out.println("<p class='err'>❌ No existe el usuario admin@neins.com</p>");
            out.println("<p class='warn'>→ Reimporta el SQL — incluye el INSERT del admin</p>");
        } else {
            out.println("<p class='ok'>✅ Usuario admin@neins.com encontrado</p>");
            out.println("<p class='ok'>   Credenciales: admin@neins.com / admin123</p>");
        }
    } catch (Exception e) {
        out.println("<p class='err'>❌ Error consultando BD: " + e.getMessage() + "</p>");
        if (e.getMessage().contains("doesn't exist") || e.getMessage().contains("Unknown database")) {
            out.println("<p class='warn'>→ La BD 'Neins' no existe. Importa el SQL en MySQL:3307</p>");
        }
        out.println("<pre>" + e.toString() + "</pre>");
    } finally {
        try { con.close(); } catch (Exception e) {}
    }
}
%>
<h3>5. Info del servidor</h3>
<p>GlassFish contexto: <%= request.getContextPath() %></p>
<p>Java: <%= System.getProperty("java.version") %></p>
<hr>
<p><a href="index.html" style="color:#d4af37">← Volver al login</a></p>
</body>
</html>
