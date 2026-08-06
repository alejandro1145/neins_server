package Controlador;

import Modelo.Usuarios;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class UsuariosDAO {
    private final Conexion conexion = new Conexion();

    public boolean insertar(Usuarios u) {
        Connection con = null;
        try {
            con = conexion.getConnection();
            con.setAutoCommit(false);

            int idRol = resolverIdRol(con, u.getRol(), u.getIdRol());
            String sql = "INSERT INTO Usuarios "
                    + "(nombre, apellidos, identificacion, id_tipo_documento, correo, telefono, clave, id_roles, foto_perfil, "
                    + "fecha_nacimiento, clave_expira, acepto_terminos, fecha_acepto_terminos, ip_acepto_terminos, version_terminos) "
                    + "VALUES (?, ?, ?, ?, ?, ?, SHA2(?, 256), ?, ?, ?, ?, ?, NOW(), ?, ?)";
            PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, u.getNombre());
            ps.setString(2, u.getApellido());
            ps.setString(3, u.getIdentificacion());
            ps.setInt(4, u.getIdTipoDocumento() > 0 ? u.getIdTipoDocumento() : 1);
            ps.setString(5, u.getCorreo());
            ps.setString(6, u.getTelefono());
            ps.setString(7, u.getClave());
            ps.setInt(8, idRol);
            ps.setString(9, u.getFotoPerfil());
            ps.setString(10, u.getFechaNacimiento());
            ps.setString(11, u.getClaveExpira());
            ps.setBoolean(12, u.isAceptoTerminos());
            ps.setString(13, u.getIpAceptoTerminos());
            ps.setString(14, u.getVersionTerminos() != null ? u.getVersionTerminos() : "1.0");
            ps.executeUpdate();

            int idUsuario = 0;
            ResultSet keys = ps.getGeneratedKeys();
            if (keys.next()) idUsuario = keys.getInt(1);

            if ("cliente".equalsIgnoreCase(nombreRol(con, idRol)) && idUsuario > 0) {
                String sqlCliente = "INSERT INTO clientes (id_usuario, cupo_credito, saldo_pendiente_total) VALUES (?, ?, 0.00)";
                PreparedStatement psCliente = con.prepareStatement(sqlCliente);
                psCliente.setInt(1, idUsuario);
                psCliente.setDouble(2, 0.00);
                psCliente.executeUpdate();
            }

            con.commit();
            return true;
        } catch (Exception e) {
            System.out.println("Error insertar usuario: " + e);
            try { if (con != null) con.rollback(); } catch (Exception ex) {}
            return false;
        } finally {
            try { if (con != null) con.setAutoCommit(true); } catch (Exception ex) {}
            try { if (con != null) con.close(); } catch (Exception ex) {}
        }
    }

    public List<Usuarios> listar() {
        List<Usuarios> lista = new ArrayList<>();
        String sql = "SELECT u.*, r.descripcion_roles FROM Usuarios u "
                + "JOIN roles r ON r.id_roles = u.id_roles ORDER BY u.id_usuarios DESC";
        try (Connection con = conexion.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) lista.add(mapear(rs));
        } catch (Exception e) {
            System.out.println("Error listar usuarios: " + e);
        }
        return lista;
    }

    public Usuarios buscarPorCorreo(String correo) {
        String sql = "SELECT u.*, r.descripcion_roles FROM Usuarios u "
                + "JOIN roles r ON r.id_roles = u.id_roles WHERE u.correo = ?";
        try (Connection con = conexion.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, correo);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapear(rs);
        } catch (Exception e) {
            System.out.println("Error buscarPorCorreo: " + e);
        }
        return null;
    }

    public String validarDuplicado(String correo, String telefono, String identificacion) {
        try (Connection con = conexion.getConnection()) {
            if (existe(con, "correo", correo)) return "correo";
            if (existe(con, "telefono", telefono)) return "telefono";
            // identificacion ya no se valida como unica: varios usuarios pueden compartir documento
        } catch (Exception e) {
            System.out.println("Error validarDuplicado: " + e);
        }
        return null;
    }

    public String validarDuplicadoEdicion(int idUsuario, String correo, String telefono, String identificacion) {
        try (Connection con = conexion.getConnection()) {
            if (existeEdicion(con, idUsuario, "correo", correo)) return "correo";
            if (existeEdicion(con, idUsuario, "telefono", telefono)) return "telefono";
            // identificacion ya no se valida como unica: varios usuarios pueden compartir documento
        } catch (Exception e) {
            System.out.println("Error validarDuplicadoEdicion: " + e);
        }
        return null;
    }

    public boolean actualizar(Usuarios u) {
        Connection con = null;
        try {
            con = conexion.getConnection();
            con.setAutoCommit(false);
            int idRol = resolverIdRol(con, u.getRol(), u.getIdRol());

            String sql;
            boolean cambiaClave = u.getClave() != null && !u.getClave().trim().isEmpty();
            if (cambiaClave) {
                sql = "UPDATE Usuarios SET nombre=?, apellidos=?, identificacion=?, id_tipo_documento=?, "
                        + "correo=?, telefono=?, clave=SHA2(?, 256), id_roles=?, foto_perfil=?, "
                        + "fecha_nacimiento=?, clave_expira=?, acepto_terminos=?, "
                        + "fecha_acepto_terminos=IF(?=1 AND acepto_terminos=0, NOW(), fecha_acepto_terminos), "
                        + "ip_acepto_terminos=IF(?=1 AND (ip_acepto_terminos IS NULL OR ip_acepto_terminos=''), ?, ip_acepto_terminos), "
                        + "version_terminos=? WHERE id_usuarios=?";
            } else {
                sql = "UPDATE Usuarios SET nombre=?, apellidos=?, identificacion=?, id_tipo_documento=?, "
                        + "correo=?, telefono=?, id_roles=?, foto_perfil=?, "
                        + "fecha_nacimiento=?, clave_expira=?, acepto_terminos=?, "
                        + "fecha_acepto_terminos=IF(?=1 AND acepto_terminos=0, NOW(), fecha_acepto_terminos), "
                        + "ip_acepto_terminos=IF(?=1 AND (ip_acepto_terminos IS NULL OR ip_acepto_terminos=''), ?, ip_acepto_terminos), "
                        + "version_terminos=? WHERE id_usuarios=?";
            }

            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, u.getNombre());
            ps.setString(2, u.getApellido());
            ps.setString(3, u.getIdentificacion());
            ps.setInt(4, u.getIdTipoDocumento() > 0 ? u.getIdTipoDocumento() : 1);
            ps.setString(5, u.getCorreo());
            ps.setString(6, u.getTelefono());
            if (cambiaClave) {
                ps.setString(7, u.getClave());
                ps.setInt(8, idRol);
                ps.setString(9, u.getFotoPerfil());
                ps.setString(10, u.getFechaNacimiento());
                ps.setString(11, u.getClaveExpira());
                ps.setBoolean(12, u.isAceptoTerminos());
                ps.setBoolean(13, u.isAceptoTerminos());
                ps.setBoolean(14, u.isAceptoTerminos());
                ps.setString(15, u.getIpAceptoTerminos());
                ps.setString(16, u.getVersionTerminos() != null ? u.getVersionTerminos() : "1.0");
                ps.setInt(17, u.getId_usuarios());
            } else {
                ps.setInt(7, idRol);
                ps.setString(8, u.getFotoPerfil());
                ps.setString(9, u.getFechaNacimiento());
                ps.setString(10, u.getClaveExpira());
                ps.setBoolean(11, u.isAceptoTerminos());
                ps.setBoolean(12, u.isAceptoTerminos());
                ps.setBoolean(13, u.isAceptoTerminos());
                ps.setString(14, u.getIpAceptoTerminos());
                ps.setString(15, u.getVersionTerminos() != null ? u.getVersionTerminos() : "1.0");
                ps.setInt(16, u.getId_usuarios());
            }
            ps.executeUpdate();

            String rol = nombreRol(con, idRol);
            if ("cliente".equalsIgnoreCase(rol)) {
                PreparedStatement psCliente = con.prepareStatement(
                        "INSERT INTO clientes (id_usuario, cupo_credito, saldo_pendiente_total) "
                      + "SELECT ?, 0.00, 0.00 WHERE NOT EXISTS (SELECT 1 FROM clientes WHERE id_usuario = ?)");
                psCliente.setInt(1, u.getId_usuarios());
                psCliente.setInt(2, u.getId_usuarios());
                psCliente.executeUpdate();
            }

            con.commit();
            return true;
        } catch (Exception e) {
            System.out.println("Error actualizar usuario: " + e);
            try { if (con != null) con.rollback(); } catch (Exception ex) {}
            return false;
        } finally {
            try { if (con != null) con.setAutoCommit(true); } catch (Exception ex) {}
            try { if (con != null) con.close(); } catch (Exception ex) {}
        }
    }

    public boolean eliminar(int id) {
        Connection con = null;
        try {
            con = conexion.getConnection();
            con.setAutoCommit(false);
            PreparedStatement psCliente = con.prepareStatement("DELETE FROM clientes WHERE id_usuario=?");
            psCliente.setInt(1, id);
            psCliente.executeUpdate();

            PreparedStatement ps = con.prepareStatement("DELETE FROM Usuarios WHERE id_usuarios=?");
            ps.setInt(1, id);
            ps.executeUpdate();

            con.commit();
            return true;
        } catch (Exception e) {
            System.out.println("Error eliminar usuario: " + e);
            try { if (con != null) con.rollback(); } catch (Exception ex) {}
            return false;
        } finally {
            try { if (con != null) con.setAutoCommit(true); } catch (Exception ex) {}
            try { if (con != null) con.close(); } catch (Exception ex) {}
        }
    }

    private Usuarios mapear(ResultSet rs) throws SQLException {
        Usuarios u = new Usuarios();
        u.setId_usuarios(rs.getInt("id_usuarios"));
        u.setNombre(rs.getString("nombre"));
        u.setApellido(rs.getString("apellidos"));
        u.setIdentificacion(rs.getString("identificacion"));
        u.setIdTipoDocumento(rs.getInt("id_tipo_documento"));
        u.setCorreo(rs.getString("correo"));
        u.setTelefono(rs.getString("telefono"));
        u.setClave(rs.getString("clave"));
        u.setIdRol(rs.getInt("id_roles"));
        u.setRol(rs.getString("descripcion_roles"));
        u.setFotoPerfil(rs.getString("foto_perfil"));
        u.setFechaNacimiento(rs.getString("fecha_nacimiento"));
        u.setClaveExpira(rs.getString("clave_expira"));
        u.setAceptoTerminos(rs.getBoolean("acepto_terminos"));
        u.setFechaAceptoTerminos(rs.getString("fecha_acepto_terminos"));
        u.setIpAceptoTerminos(rs.getString("ip_acepto_terminos"));
        u.setVersionTerminos(rs.getString("version_terminos"));
        return u;
    }

    private boolean existe(Connection con, String columna, String valor) throws SQLException {
        String sql = "SELECT COUNT(*) FROM Usuarios WHERE " + columna + " = ?";
        PreparedStatement ps = con.prepareStatement(sql);
        ps.setString(1, valor);
        ResultSet rs = ps.executeQuery();
        return rs.next() && rs.getInt(1) > 0;
    }

    private boolean existeEdicion(Connection con, int idUsuario, String columna, String valor) throws SQLException {
        String sql = "SELECT COUNT(*) FROM Usuarios WHERE " + columna + " = ? AND id_usuarios <> ?";
        PreparedStatement ps = con.prepareStatement(sql);
        ps.setString(1, valor);
        ps.setInt(2, idUsuario);
        ResultSet rs = ps.executeQuery();
        return rs.next() && rs.getInt(1) > 0;
    }

    private int resolverIdRol(Connection con, String rol, int idRol) throws SQLException {
        if (rol != null && !rol.trim().isEmpty()) {
            PreparedStatement ps = con.prepareStatement("SELECT id_roles FROM roles WHERE LOWER(descripcion_roles)=LOWER(?)");
            ps.setString(1, rol.trim());
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        }
        return idRol > 0 ? idRol : 2;
    }

    private String nombreRol(Connection con, int idRol) throws SQLException {
        PreparedStatement ps = con.prepareStatement("SELECT descripcion_roles FROM roles WHERE id_roles=?");
        ps.setInt(1, idRol);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) return rs.getString(1);
        return "cliente";
    }
}
