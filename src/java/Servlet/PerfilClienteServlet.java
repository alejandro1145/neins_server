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
import jakarta.servlet.http.Part;
import jakarta.servlet.annotation.MultipartConfig;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

@WebServlet(name = "PerfilClienteServlet", urlPatterns = {"/PerfilClienteServlet"})
@MultipartConfig(fileSizeThreshold = 1024 * 1024, maxFileSize = 2 * 1024 * 1024, maxRequestSize = 3 * 1024 * 1024)
public class PerfilClienteServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("id_usuario") == null) {
            response.sendRedirect(request.getContextPath() + "/Vista/Login.jsp");
            return;
        }

        String nombreCompleto = clean(request.getParameter("nombre"));
        String correo = clean(request.getParameter("correo"));
        String telefono = clean(request.getParameter("telefono"));

        if (nombreCompleto.isEmpty() || correo.isEmpty() || telefono.isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/Vista/MenuCliente.jsp?section=perfil&perfil=error");
            return;
        }

        String[] partes = nombreCompleto.trim().split("\\s+", 2);
        String nombre = partes[0];
        String apellidos = partes.length > 1 ? partes[1] : "";
        int idUsuario = (Integer) session.getAttribute("id_usuario");
        String fotoPerfil = guardarFoto(request, idUsuario);

        try (Connection con = new Conexion().getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "UPDATE Usuarios SET nombre=?, apellidos=?, correo=?, telefono=?, foto_perfil=COALESCE(?, foto_perfil) WHERE id_usuarios=?")) {
            ps.setString(1, nombre);
            ps.setString(2, apellidos);
            ps.setString(3, correo);
            ps.setString(4, telefono);
            ps.setString(5, fotoPerfil);
            ps.setInt(6, idUsuario);
            ps.executeUpdate();

            String finalName = (nombre + " " + apellidos).trim();
            session.setAttribute("usuario", finalName);
            session.setAttribute("nombre", finalName);
            session.setAttribute("primer_nombre", nombre);
            session.setAttribute("correo", correo);
            response.sendRedirect(request.getContextPath() + "/Vista/MenuCliente.jsp?section=perfil&perfil=ok");
        } catch (Exception e) {
            System.out.println("Error perfil cliente: " + e);
            response.sendRedirect(request.getContextPath() + "/Vista/MenuCliente.jsp?section=perfil&perfil=error");
        }
    }

    private String clean(String value) {
        return value == null ? "" : value.trim();
    }

    private String guardarFoto(HttpServletRequest request, int idUsuario) throws IOException, ServletException {
        Part foto = request.getPart("foto");
        if (foto == null || foto.getSize() == 0) return null;
        String tipo = foto.getContentType();
        if (!"image/jpeg".equals(tipo) && !"image/png".equals(tipo)) {
            throw new ServletException("La foto debe ser JPG o PNG.");
        }
        String extension = "image/png".equals(tipo) ? ".png" : ".jpg";
        String nombreArchivo = "perfil_" + idUsuario + "_" + System.currentTimeMillis() + extension;
        Path carpeta = Path.of(getServletContext().getRealPath("/Imagenes/perfiles"));
        Files.createDirectories(carpeta);
        try (java.io.InputStream entrada = foto.getInputStream()) {
            Files.copy(entrada, carpeta.resolve(nombreArchivo), StandardCopyOption.REPLACE_EXISTING);
        }
        return request.getContextPath() + "/Imagenes/perfiles/" + nombreArchivo;
    }
}
