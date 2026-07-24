package Servlet;

import Controlador.Conexion;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Date;
import java.time.LocalDate;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet(name = "LoginServlet", urlPatterns = {"/LoginServlet"})
public class LoginServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String correo = request.getParameter("txtCorreo");
        String clave  = request.getParameter("txtClave");

        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            Conexion conexionClase = new Conexion();
            con = conexionClase.getConnection();

            // Verificar que la base de datos tiene las tablas necesarias
            PreparedStatement checkPS = con.prepareStatement(
                "SELECT COUNT(*) FROM information_schema.tables " +
                "WHERE table_schema = 'Neins' AND table_name = 'Usuarios'"
            );
            ResultSet checkRS = checkPS.executeQuery();
            checkRS.next();
            int tableCount = checkRS.getInt(1);
            checkRS.close();
            checkPS.close();

            if (tableCount == 0) {
                System.err.println("[NEINS] ERROR: La tabla 'Usuarios' no existe en la BD 'Neins'. Importa el archivo SQL primero.");
                response.sendRedirect("index.html?error=notables");
                return;
            }

            String sql = "SELECT u.*, r.descripcion_roles, c.id_cliente "
                    + "FROM Usuarios u "
                    + "JOIN roles r ON r.id_roles = u.id_roles "
                    + "LEFT JOIN clientes c ON c.id_usuario = u.id_usuarios "
                    + "WHERE u.correo = ? AND u.clave = SHA2(?, 256)";
            ps = con.prepareStatement(sql);
            ps.setString(1, correo);
            ps.setString(2, clave);

            rs = ps.executeQuery();

            if (rs.next()) {
                Date claveExpira = rs.getDate("clave_expira");
                if (claveExpira != null && claveExpira.toLocalDate().isBefore(LocalDate.now())) {
                    HttpSession session = request.getSession();
                    session.setAttribute("clave_vencida_id_usuario", rs.getInt("id_usuarios"));
                    session.setAttribute("clave_vencida_correo", rs.getString("correo"));
                    response.sendRedirect("Vista/CambiarClave.jsp");
                    return;
                }

                HttpSession session = request.getSession();

                String nombreCompleto = (rs.getString("nombre") + " " + rs.getString("apellidos")).trim();
                String rolUsuario = rs.getString("descripcion_roles");

                session.setAttribute("usuario", nombreCompleto);
                session.setAttribute("nombre", nombreCompleto);
                session.setAttribute("primer_nombre", rs.getString("nombre"));
                session.setAttribute("id_usuario", rs.getInt("id_usuarios"));
                session.setAttribute("id_cliente", rs.getObject("id_cliente")); // Object para soportar NULL
                session.setAttribute("rol", rolUsuario);
                session.setAttribute("correo", rs.getString("correo"));

                if ("administrador".equalsIgnoreCase(rolUsuario)) {
                    response.sendRedirect("Vista/MenuAdmin.jsp");
                } else {
                    response.sendRedirect("Vista/MenuCliente.jsp");
                }

            } else {
                response.sendRedirect("index.html?error=1");
            }

        } catch (SQLException e) {
            System.err.println("[NEINS] Error SQL en Login: " + e.getMessage());
            System.err.println("[NEINS] SQLState: " + e.getSQLState() + " | ErrorCode: " + e.getErrorCode());
            e.printStackTrace();
            response.sendRedirect("index.html?error=db");
        } catch (RuntimeException e) {
            System.err.println("[NEINS] Error de conexion en Login: " + e.getMessage());
            e.printStackTrace();
            response.sendRedirect("index.html?error=db");
        } finally {
            try { if (rs  != null) rs.close();  } catch (SQLException e) {}
            try { if (ps  != null) ps.close();  } catch (SQLException e) {}
            try { if (con != null) con.close();  } catch (SQLException e) {}
        }
    }
}
