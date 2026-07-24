package Servlet;

import Controlador.Conexion;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet(name = "ClienteCompraServlet", urlPatterns = {"/ClienteCompraServlet"})
public class ClienteCompraServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("id_usuario") == null) {
            response.sendRedirect(request.getContextPath() + "/Vista/Login.jsp");
            return;
        }

        String[] ids = request.getParameterValues("producto_id");
        String[] cantidades = request.getParameterValues("cantidad");
        if (ids == null || cantidades == null || ids.length == 0 || ids.length != cantidades.length) {
            response.sendRedirect(request.getContextPath() + "/Vista/MenuCliente.jsp?section=productos&compra=carrito");
            return;
        }

        Connection con = null;
        try {
            con = new Conexion().getConnection();
            con.setAutoCommit(false);

            int idUsuario = (Integer) session.getAttribute("id_usuario");
            int idCliente = resolverCliente(con, idUsuario);
            BigDecimal total = BigDecimal.ZERO;

            for (int i = 0; i < ids.length; i++) {
                int idProducto = Integer.parseInt(ids[i]);
                int cantidad = Math.max(1, Integer.parseInt(cantidades[i]));
                BigDecimal precio = precioProducto(con, idProducto, cantidad);
                total = total.add(precio.multiply(new BigDecimal(cantidad)));
            }

            // El crédito no se asigna al registrarse: debe ser aprobado por el admin.
            // Esta validación en servidor evita compras que excedan el cupo, incluso si
            // alguien altera el formulario desde el navegador.
            validarCupoDisponible(con, idCliente, total);

            PreparedStatement psFiado = con.prepareStatement(
                    "INSERT INTO Fiado (fecha_fiado, fecha_limite_pago, valor, saldo_pendiente, estado, id_cliente, id_medio_pago) "
                  + "VALUES (CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), ?, ?, 'Pendiente', ?, 1)",
                    Statement.RETURN_GENERATED_KEYS);
            psFiado.setBigDecimal(1, total);
            psFiado.setBigDecimal(2, total);
            psFiado.setInt(3, idCliente);
            psFiado.executeUpdate();

            ResultSet keys = psFiado.getGeneratedKeys();
            if (!keys.next()) throw new IllegalStateException("No se genero el fiado");
            int idFiado = keys.getInt(1);

            PreparedStatement psDetalle = con.prepareStatement(
                    "INSERT INTO Detalle_Fiado (id_fiado, id_productos, cantidad, precio_venta, observacion) "
                  + "VALUES (?, ?, ?, ?, ?)");
            StringBuilder resumenProductos = new StringBuilder();

            for (int i = 0; i < ids.length; i++) {
                int idProducto = Integer.parseInt(ids[i]);
                int cantidad = Math.max(1, Integer.parseInt(cantidades[i]));
                ProductoInfo info = productoInfo(con, idProducto, cantidad);
                psDetalle.setInt(1, idFiado);
                psDetalle.setInt(2, idProducto);
                psDetalle.setInt(3, cantidad);
                psDetalle.setBigDecimal(4, info.precio);
                psDetalle.setString(5, info.nombre);
                psDetalle.addBatch();
                descontarStock(con, idProducto, cantidad);
                if (resumenProductos.length() > 0) resumenProductos.append(", ");
                resumenProductos.append(cantidad).append(" x ").append(info.nombre);
            }
            psDetalle.executeBatch();

            registrarAlertasFiado(con, idUsuario, idFiado, total, resumenProductos.toString());

            con.commit();
            response.sendRedirect(request.getContextPath() + "/Vista/MenuCliente.jsp?section=productos&compra=ok");
        } catch (CupoInsuficienteException e) {
            try { if (con != null) con.rollback(); } catch (Exception ignored) {}
            response.sendRedirect(request.getContextPath() + "/Vista/MenuCliente.jsp?section=productos&compra=cupo");
        } catch (Exception e) {
            try { if (con != null) con.rollback(); } catch (Exception ignored) {}
            System.out.println("Error compra cliente: " + e);
            response.sendRedirect(request.getContextPath() + "/Vista/MenuCliente.jsp?section=productos&compra=error");
        } finally {
            try { if (con != null) con.setAutoCommit(true); } catch (Exception ignored) {}
            try { if (con != null) con.close(); } catch (Exception ignored) {}
        }
    }

    private int resolverCliente(Connection con, int idUsuario) throws Exception {
        PreparedStatement ps = con.prepareStatement("SELECT id_cliente FROM clientes WHERE id_usuario=?");
        ps.setInt(1, idUsuario);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) return rs.getInt(1);

        PreparedStatement ins = con.prepareStatement(
                "INSERT INTO clientes (id_usuario, cupo_credito, saldo_pendiente_total) VALUES (?, 0.00, 0.00)",
                Statement.RETURN_GENERATED_KEYS);
        ins.setInt(1, idUsuario);
        ins.executeUpdate();
        ResultSet keys = ins.getGeneratedKeys();
        if (keys.next()) return keys.getInt(1);
        throw new IllegalStateException("No se pudo crear cliente");
    }

    private BigDecimal precioProducto(Connection con, int idProducto, int cantidad) throws Exception {
        return productoInfo(con, idProducto, cantidad).precio;
    }

    private void validarCupoDisponible(Connection con, int idCliente, BigDecimal total) throws Exception {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT cupo_credito FROM clientes WHERE id_cliente = ? FOR UPDATE")) {
            ps.setInt(1, idCliente);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) throw new CupoInsuficienteException();
            BigDecimal cupo = rs.getBigDecimal("cupo_credito");
            if (cupo == null) cupo = BigDecimal.ZERO;
            BigDecimal saldo = BigDecimal.ZERO;
            try (PreparedStatement saldoPs = con.prepareStatement(
                    "SELECT COALESCE(SUM(saldo_pendiente), 0) FROM Fiado WHERE id_cliente = ?")) {
                saldoPs.setInt(1, idCliente);
                ResultSet saldoRs = saldoPs.executeQuery();
                if (saldoRs.next() && saldoRs.getBigDecimal(1) != null) saldo = saldoRs.getBigDecimal(1);
            }
            if (cupo.subtract(saldo).compareTo(total) < 0) throw new CupoInsuficienteException();
        }
    }

    private void descontarStock(Connection con, int idProducto, int cantidad) throws Exception {
        try (PreparedStatement ps = con.prepareStatement(
                "UPDATE Productos SET stock = stock - ? WHERE id_productos = ? AND stock >= ?")) {
            ps.setInt(1, cantidad);
            ps.setInt(2, idProducto);
            ps.setInt(3, cantidad);
            if (ps.executeUpdate() != 1) throw new IllegalArgumentException("Stock insuficiente");
        }
    }

    private void registrarAlertasFiado(Connection con, int idUsuario, int idFiado,
            BigDecimal total, String productos) throws Exception {
        String detalle = productos.length() > 150 ? productos.substring(0, 147) + "..." : productos;
        String mensajeCliente = "Registraste un fiado por $" + total + ": " + detalle + ".";
        String nombreCliente = "Cliente #" + idUsuario;
        try (PreparedStatement buscarCliente = con.prepareStatement(
                "SELECT CONCAT(nombre, ' ', apellidos) FROM Usuarios WHERE id_usuarios = ?")) {
            buscarCliente.setInt(1, idUsuario);
            ResultSet rs = buscarCliente.executeQuery();
            if (rs.next()) nombreCliente = rs.getString(1);
        }
        String mensajeAdmin = "El cliente " + nombreCliente + " registró un fiado por $" + total + ": " + detalle + ".";

        try (PreparedStatement cliente = con.prepareStatement(
                    "INSERT INTO Alertas (tipo, descripcion, id_referencia, tabla_referencia, id_usuarios_destino) VALUES ('nuevo_fiado', ?, ?, 'Fiado', ?)");
             PreparedStatement admin = con.prepareStatement(
                    "INSERT INTO Alertas (tipo, descripcion, id_referencia, tabla_referencia, id_usuarios_destino) VALUES ('nuevo_fiado', ?, ?, 'Fiado', NULL)")) {
            cliente.setString(1, mensajeCliente);
            cliente.setInt(2, idFiado);
            cliente.setInt(3, idUsuario);
            cliente.executeUpdate();

            admin.setString(1, mensajeAdmin);
            admin.setInt(2, idFiado);
            admin.executeUpdate();
        }
    }

    private ProductoInfo productoInfo(Connection con, int idProducto, int cantidad) throws Exception {
        PreparedStatement ps = con.prepareStatement("SELECT nombre, precio, stock FROM Productos WHERE id_productos=?");
        ps.setInt(1, idProducto);
        ResultSet rs = ps.executeQuery();
        if (!rs.next()) throw new IllegalArgumentException("Producto no existe: " + idProducto);
        if (rs.getInt("stock") < cantidad) throw new IllegalArgumentException("Stock insuficiente para " + rs.getString("nombre"));
        return new ProductoInfo(rs.getString("nombre"), rs.getBigDecimal("precio"));
    }

    private static class ProductoInfo {
        final String nombre;
        final BigDecimal precio;
        ProductoInfo(String nombre, BigDecimal precio) {
            this.nombre = nombre;
            this.precio = precio;
        }
    }

    private static class CupoInsuficienteException extends Exception {
        private static final long serialVersionUID = 1L;
    }
}
