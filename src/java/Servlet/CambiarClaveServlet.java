package Servlet;

import Controlador.Conexion;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet(name = "CambiarClaveServlet", urlPatterns = {"/CambiarClaveServlet"})
public class CambiarClaveServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession(false);
        Integer idUsuario = session != null ? (Integer) session.getAttribute("clave_vencida_id_usuario") : null;
        String clave = request.getParameter("clave");
        String confirmar = request.getParameter("confirmar");

        if (idUsuario == null) {
            response.sendRedirect(request.getContextPath() + "/index.html");
            return;
        }
        if (clave == null || clave.length() < 6 || !clave.equals(confirmar)) {
            response.sendRedirect(request.getContextPath() + "/Vista/CambiarClave.jsp?error=1");
            return;
        }

        try (Connection con = new Conexion().getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "UPDATE Usuarios SET clave=SHA2(?, 256), clave_expira=DATE_ADD(CURDATE(), INTERVAL 30 DAY) WHERE id_usuarios=?")) {
            ps.setString(1, clave);
            ps.setInt(2, idUsuario);
            ps.executeUpdate();
            session.removeAttribute("clave_vencida_id_usuario");
            session.removeAttribute("clave_vencida_correo");
            response.sendRedirect(request.getContextPath() + "/index.html?clave=actualizada");
        } catch (Exception e) {
            System.out.println("Error cambiar clave: " + e);
            response.sendRedirect(request.getContextPath() + "/Vista/CambiarClave.jsp?error=db");
        }
    }
}
