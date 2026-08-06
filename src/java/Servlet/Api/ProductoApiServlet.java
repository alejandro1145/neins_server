package Servlet.Api;

import Controlador.ProductosDAO;
import Controlador.JsonUtil;
import Modelo.Productos;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

@WebServlet(name = "ProductoApiServlet", urlPatterns = {"/api/productos"})
public class ProductoApiServlet extends HttpServlet {

    private ProductosDAO dao = new ProductosDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        List<Productos> lista = dao.listar();

        StringBuilder json = new StringBuilder("[");
        for (int i = 0; i < lista.size(); i++) {
            Productos p = lista.get(i);
            if (i > 0) json.append(",");
            json.append("{")
                .append("\"id_producto\":").append(p.getId_productos()).append(",")
                .append("\"nombre\":\"").append(JsonUtil.esc(p.getNombre())).append("\",")
                .append("\"precio\":").append(p.getPrecio()).append(",")
                .append("\"stock\":").append(p.getStock())
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
        Productos p = new Productos();
        p.setNombre(req.getParameter("nombre"));
        p.setPrecio(Float.parseFloat(req.getParameter("precio")));
        p.setStock(Integer.parseInt(req.getParameter("stock")));

        boolean ok;
        if ("eliminar".equals(accion)) {
            int id = Integer.parseInt(req.getParameter("id_producto"));
            ok = dao.eliminar(id);
        } else if ("actualizar".equals(accion)) {
            p.setId_productos(Integer.parseInt(req.getParameter("id_producto")));
            ok = dao.actualizar(p);
        } else {
            ok = dao.insertar(p);
        }
        resp.getWriter().write("{\"ok\":" + ok + "}");
    }
}