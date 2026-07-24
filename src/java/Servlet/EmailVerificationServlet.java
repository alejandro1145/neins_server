package Servlet;

import java.io.IOException;
import java.security.SecureRandom;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet(name = "EmailVerificationServlet", urlPatterns = {"/EmailVerificationServlet"})
public class EmailVerificationServlet extends HttpServlet {
    private static final SecureRandom RANDOM = new SecureRandom();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");

        String correo = request.getParameter("correo");
        if (correo == null || !correo.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) {
            response.getWriter().write("{\"ok\":false,\"message\":\"Escribe un correo valido.\"}");
            return;
        }

        String codigo = String.format("%06d", RANDOM.nextInt(1000000));
        HttpSession session = request.getSession();
        session.setAttribute("registroCorreo", correo.trim().toLowerCase());
        session.setAttribute("registroCodigo", codigo);
        session.setAttribute("registroCodigoExpira", System.currentTimeMillis() + (10 * 60 * 1000));

        /*
         * Sin librerias SMTP en el proyecto, se deja modo desarrollo para no bloquear
         * el registro. Si luego agregas Jakarta Mail, este servlet es el punto unico
         * para enviar el mensaje real.
         */
        response.getWriter().write("{\"ok\":true,\"message\":\"Codigo generado. Revisa el aviso en pantalla.\",\"devCode\":\"" + codigo + "\"}");
    }
}
