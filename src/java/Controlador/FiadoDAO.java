package Controlador;

import Modelo.Fiado;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class FiadoDAO {
    Conexion conexion = new Conexion();

    public boolean insertar(Fiado f) {
        Connection con = null;
        try {
            con = conexion.getConnection();
            con.setAutoCommit(false);
            boolean estaPagado = f.getFecha_pago() != null && !f.getFecha_pago().trim().isEmpty();
            double saldoPendiente = estaPagado ? 0.00 : f.getValor();
            String sql = "INSERT INTO Fiado (fecha_fiado, fecha_limite_pago, fecha_pago, valor, saldo_pendiente, estado, id_cliente, id_medio_pago) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, f.getFecha_fiado());
            ps.setString(2, f.getFecha_limite_pago());
            ps.setString(3, f.getFecha_pago());
            ps.setDouble(4, f.getValor());
            ps.setDouble(5, saldoPendiente);
            ps.setString(6, estaPagado ? "Pagado" : "Pendiente");
            ps.setInt(7, f.getId_cliente());
            ps.setInt(8, f.getId_medio_pago());
            ps.executeUpdate();
            PreparedStatement psCliente = con.prepareStatement(
                    "UPDATE clientes SET saldo_pendiente_total = saldo_pendiente_total + ? WHERE id_cliente = ?");
            psCliente.setDouble(1, saldoPendiente);
            psCliente.setInt(2, f.getId_cliente());
            psCliente.executeUpdate();
            con.commit();
            return true;
        } catch (Exception e) {
            System.out.println("Error insertar fiado: " + e);
            try { if (con != null) con.rollback(); } catch (Exception ex) {}
            return false;
        } finally {
            try { if (con != null) con.setAutoCommit(true); } catch (Exception ex) {}
            try { if (con != null) con.close(); } catch (Exception ex) {}
        }
    }

    public List<Fiado> listar() {
        List<Fiado> lista = new ArrayList<>();
        try {
            Connection con = conexion.getConnection();
            String sql = "SELECT * FROM Fiado";
            Statement st = con.createStatement();
            ResultSet rs = st.executeQuery(sql);
            while (rs.next()) {
                Fiado f = new Fiado();
                f.setId_fiado(rs.getInt("id_fiado"));
                f.setFecha_fiado(rs.getString("fecha_fiado"));
                f.setFecha_limite_pago(rs.getString("fecha_limite_pago"));
                f.setFecha_pago(rs.getString("fecha_pago"));
                f.setValor(rs.getDouble("valor"));
                f.setSaldo_pendiente(rs.getDouble("saldo_pendiente"));
                f.setId_cliente(rs.getInt("id_cliente"));
                f.setId_medio_pago(rs.getInt("id_medio_pago"));
                lista.add(f);
            }
        } catch (Exception e) {
            System.out.println("Error listar fiados: " + e);
        }
        return lista;
    }

    public boolean actualizar(Fiado f) {
        try {
            Connection con = conexion.getConnection();
            String sql = "UPDATE Fiado SET fecha_fiado=?, fecha_limite_pago=?, fecha_pago=?, valor=?, id_cliente=?, id_medio_pago=? WHERE id_fiado=?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, f.getFecha_fiado());
            ps.setString(2, f.getFecha_limite_pago());
            ps.setString(3, f.getFecha_pago());
            ps.setDouble(4, f.getValor());
            ps.setInt(5, f.getId_cliente());
            ps.setInt(6, f.getId_medio_pago());
            ps.setInt(7, f.getId_fiado());
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error actualizar fiado: " + e);
            return false;
        }
    }

    public boolean eliminar(int id) {
        try {
            Connection con = conexion.getConnection();
            String sql = "DELETE FROM Fiado WHERE id_fiado=?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, id);
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error eliminar fiado: " + e);
            return false;
        }
    }
}
