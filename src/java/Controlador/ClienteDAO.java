package Controlador;

import Modelo.Clientes;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ClienteDAO {
    private final Conexion conexion = new Conexion();

    public boolean insertar(Clientes c) {
        try (Connection con = conexion.getConnection()) {
            String sql = "INSERT INTO clientes (id_usuario, cupo_credito, saldo_pendiente_total) VALUES (?, ?, 0.00)";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, c.getIdUsuario());
            ps.setString(2, c.getCupo_credito());
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error insertar cliente: " + e);
            return false;
        }
    }

    public List<Clientes> listar() {
        List<Clientes> lista = new ArrayList<>();
        String sql = "SELECT * FROM v_clientes_completo ORDER BY nombre, apellidos";
        try (Connection con = conexion.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapear(rs));
        } catch (Exception e) {
            System.out.println("Error listar clientes: " + e);
        }
        return lista;
    }

    public boolean actualizar(Clientes c) {
        try (Connection con = conexion.getConnection()) {
            String sql = "UPDATE clientes SET cupo_credito=? WHERE id_cliente=?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, c.getCupo_credito());
            ps.setInt(2, c.getId_clientes());
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error actualizar cliente: " + e);
            return false;
        }
    }

    public boolean eliminar(int id) {
        try (Connection con = conexion.getConnection()) {
            String sql = "DELETE FROM clientes WHERE id_cliente=?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, id);
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error eliminar cliente: " + e);
            return false;
        }
    }

    public String validarDuplicado(String telefono, String identificacion) {
        try (Connection con = conexion.getConnection()) {
            PreparedStatement ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM Usuarios WHERE telefono = ? OR identificacion = ?");
            ps.setString(1, telefono);
            ps.setString(2, identificacion);
            ResultSet rs = ps.executeQuery();
            if (rs.next() && rs.getInt(1) > 0) return "usuario";
        } catch (Exception e) {
            System.out.println("Error validarDuplicado cliente: " + e);
        }
        return null;
    }

    public List<Clientes> listarUsuariosClienteSinFicha() {
        List<Clientes> lista = new ArrayList<>();
        String sql = "SELECT u.id_usuarios, u.nombre, u.apellidos, u.identificacion, u.telefono, u.correo "
                + "FROM Usuarios u JOIN roles r ON r.id_roles = u.id_roles "
                + "LEFT JOIN clientes c ON c.id_usuario = u.id_usuarios "
                + "WHERE LOWER(r.descripcion_roles) = 'cliente' AND c.id_cliente IS NULL "
                + "ORDER BY u.nombre, u.apellidos";
        try (Connection con = conexion.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Clientes c = new Clientes();
                c.setIdUsuario(rs.getInt("id_usuarios"));
                c.setNombre(rs.getString("nombre"));
                c.setApellidos(rs.getString("apellidos"));
                c.setIdentificacion(rs.getString("identificacion"));
                c.setTelefono(rs.getString("telefono"));
                c.setCorreo(rs.getString("correo"));
                lista.add(c);
            }
        } catch (Exception e) {
            System.out.println("Error listar usuarios sin ficha cliente: " + e);
        }
        return lista;
    }

    private Clientes mapear(ResultSet rs) throws SQLException {
        Clientes c = new Clientes();
        c.setId_clientes(rs.getInt("id_cliente"));
        c.setIdUsuario(rs.getInt("id_usuarios"));
        c.setNombre(rs.getString("nombre"));
        c.setApellidos(rs.getString("apellidos"));
        c.setIdentificacion(rs.getString("identificacion"));
        c.setTipoDocumento(rs.getString("tipo_documento"));
        c.setTelefono(rs.getString("telefono"));
        c.setCorreo(rs.getString("correo"));
        c.setCupo_credito(rs.getString("cupo_credito"));
        c.setSaldoPendienteTotal(rs.getString("saldo_pendiente_total"));
        return c;
    }
}
