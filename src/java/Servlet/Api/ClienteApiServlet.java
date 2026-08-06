package Servlet.Api;

import Controlador.ClienteDAO;
import Controlador.JsonUtil;
import Modelo.Clientes;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

@WebServlet(name = "ClienteApiServlet", urlPatterns = {"/api/clientes"})
public class ClienteApiServlet extends HttpServlet {

    private ClienteDAO dao = new ClienteDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        List<Clientes> lista = dao.listar();

        StringBuilder json = new StringBuilder("[");
        for (int i = 0; i < lista.size(); i++) {
            Clientes c = lista.get(i);
            if (i > 0) json.append(",");
            json.append("{")
                .append("\"id_cliente\":").append(c.getId_clientes()).append(",")
                .append("\"nombre\":\"").append(JsonUtil.esc(c.getNombre())).append("\",")
                .append("\"telefono\":\"").append(JsonUtil.esc(c.getTelefono())).append("\",")
                .append("\"identificacion\":\"").append(JsonUtil.esc(c.getIdentificacion())).append("\",")
                .append("\"cupo_credito\":\"").append(JsonUtil.esc(c.getCupo_credito())).append("\"")
                .append("}");
        }
        json.append("]");
        resp.getWriter().write(json.toString());
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json; charset=UTF-8");

        String accion = req.getParameter("accion");
        Clientes c = new Clientes();
        c.setNombre(req.getParameter("nombre"));
        c.setTelefono(req.getParameter("telefono"));
        c.setIdentificacion(req.getParameter("identificacion"));
        c.setCupo_credito(req.getParameter("cupo_credito"));

        boolean ok;
        if ("eliminar".equals(accion)) {
            int id = Integer.parseInt(req.getParameter("id_cliente"));
            ok = dao.eliminar(id);
        } else if ("actualizar".equals(accion)) {
            c.setId_clientes(Integer.parseInt(req.getParameter("id_cliente")));
            ok = dao.actualizar(c);
        } else {
            ok = dao.insertar(c);
        }
        resp.getWriter().write("{\"ok\":" + ok + "}");
    }
}