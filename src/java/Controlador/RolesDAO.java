package Controlador;

import Modelo.Roles;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class RolesDAO {
    Conexion conexion = new Conexion();

    public boolean insertar(Roles r) {
        try {
            Connection con = conexion.getConnection();
            String sql = "INSERT INTO roles (descripcion_roles) VALUES (?)";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, r.getDescrpcion_roles());
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error insertar rol: " + e);
            return false;
        }
    }

    public List<Roles> listar() {
        List<Roles> lista = new ArrayList<>();
        try {
            Connection con = conexion.getConnection();
            String sql = "SELECT * FROM roles";
            Statement st = con.createStatement();
            ResultSet rs = st.executeQuery(sql);
            while (rs.next()) {
                Roles r = new Roles();
                r.setId_roles(rs.getInt("id_roles"));
                r.setDescrpcion_roles(rs.getString("descripcion_roles"));
                lista.add(r);
            }
        } catch (Exception e) {
            System.out.println("Error listar roles: " + e);
        }
        return lista;
    }

    public boolean actualizar(Roles r) {
        try {
            Connection con = conexion.getConnection();
            String sql = "UPDATE roles SET descripcion_roles=? WHERE id_roles=?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, r.getDescrpcion_roles());
            ps.setInt(2, r.getId_roles());
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error actualizar rol: " + e);
            return false;
        }
    }

    public boolean eliminar(int id) {
        try {
            Connection con = conexion.getConnection();
            String sql = "DELETE FROM roles WHERE id_roles=?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, id);
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error eliminar rol: " + e);
            return false;
        }
    }
}