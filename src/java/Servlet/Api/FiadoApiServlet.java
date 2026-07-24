package Servlet.Api;

import Controlador.Conexion;
import Controlador.FiadoDAO;
import Controlador.JsonUtil;
import Modelo.Fiado;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

@WebServlet(name = "FiadoApiServlet", urlPatterns = {"/api/fiados"})
public class FiadoApiServlet extends HttpServlet {

    private FiadoDAO dao = new FiadoDAO();
    private Conexion conexion = new Conexion();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        StringBuilder json = new StringBuilder("[");
        try {
            Connection con = conexion.getConnection();
            String sql = "SELECT f.id_fiado, f.fecha_fiado, f.fecha_limite_pago, f.fecha_pago, "
                        + "f.valor, f.id_cliente, f.id_medio_pago, "
                        + "vc.nombre_completo AS nombre_cliente, "
                        + "m.descripcion_medio_pago AS medio_pago "
                        + "FROM Fiado f "
                        + "LEFT JOIN v_clientes_completo vc ON f.id_cliente = vc.id_cliente "
                        + "LEFT JOIN medio_pago m ON f.id_medio_pago = m.id_medio_pago "
                        + "ORDER BY f.id_fiado DESC";
            Statement st = con.createStatement();
            ResultSet rs = st.executeQuery(sql);
            boolean primero = true;
            while (rs.next()) {
                if (!primero) json.append(",");
                primero = false;
                json.append("{")
                    .append("\"id_fiado\":").append(rs.getInt("id_fiado")).append(",")
                    .append("\"fecha_fiado\":\"").append(JsonUtil.esc(rs.getString("fecha_fiado"))).append("\",")
                    .append("\"fecha_limite_pago\":\"").append(JsonUtil.esc(rs.getString("fecha_limite_pago"))).append("\",")
                    .append("\"fecha_pago\":\"").append(JsonUtil.esc(rs.getString("fecha_pago"))).append("\",")
                    .append("\"valor\":").append(rs.getDouble("valor")).append(",")
                    .append("\"id_cliente\":").append(rs.getInt("id_cliente")).append(",")
                    .append("\"id_medio_pago\":").append(rs.getInt("id_medio_pago")).append(",")
                    .append("\"nombre_cliente\":\"").append(JsonUtil.esc(rs.getString("nombre_cliente"))).append("\",")
                    .append("\"medio_pago\":\"").append(JsonUtil.esc(rs.getString("medio_pago"))).append("\"")
                    .append("}");
            }
        } catch (Exception e) {
            System.out.println("Error listar fiados (API): " + e);
        }
        json.append("]");
        resp.getWriter().write(json.toString());
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json; charset=UTF-8");

        String accion = req.getParameter("accion");

        if ("eliminar".equals(accion)) {
            int id = Integer.parseInt(req.getParameter("id_fiado"));
            boolean ok = dao.eliminar(id);
            resp.getWriter().write("{\"ok\":" + ok + "}");
            return;
        }

        Fiado f = new Fiado();
        f.setFecha_fiado(req.getParameter("fecha_fiado"));
        f.setFecha_limite_pago(req.getParameter("fecha_limite_pago"));
        String fechaPago = req.getParameter("fecha_pago");
        f.setFecha_pago((fechaPago == null || fechaPago.isEmpty()) ? null : fechaPago);
        f.setValor(Double.parseDouble(req.getParameter("valor")));
        f.setId_cliente(Integer.parseInt(req.getParameter("id_cliente")));
        f.setId_medio_pago(Integer.parseInt(req.getParameter("id_medio_pago")));

        boolean ok;
        if ("actualizar".equals(accion)) {
            f.setId_fiado(Integer.parseInt(req.getParameter("id_fiado")));
            ok = dao.actualizar(f);
        } else {
            ok = dao.insertar(f);
        }
        resp.getWriter().write("{\"ok\":" + ok + "}");
    }
}
