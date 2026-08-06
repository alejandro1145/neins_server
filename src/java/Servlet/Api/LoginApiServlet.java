package Servlet.Api;

import Controlador.UsuariosDAO;
import Controlador.JsonUtil;
import Modelo.Usuarios;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.security.MessageDigest;

@WebServlet(name = "LoginApiServlet", urlPatterns = {"/api/login"})
public class LoginApiServlet extends HttpServlet {

    private UsuariosDAO dao = new UsuariosDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json; charset=UTF-8");

        String correo = req.getParameter("correo");
        String clave  = req.getParameter("clave");

        Usuarios u = dao.buscarPorCorreo(correo);

        if (u != null && u.getClave().equals(sha256(clave))) {
            String json = "{\"ok\":true,"
                    + "\"id_usuarios\":" + u.getId_usuarios() + ","
                    + "\"nombre\":\"" + JsonUtil.esc(u.getNombre()) + "\","
                    + "\"rol\":\"" + JsonUtil.esc(u.getRol()) + "\"}";
            resp.getWriter().write(json);
        } else {
            resp.getWriter().write("{\"ok\":false,\"mensaje\":\"Correo o clave incorrectos\"}");
        }
    }

    private String sha256(String texto) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(texto.getBytes("UTF-8"));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) {
            return "";
        }
    }
}
