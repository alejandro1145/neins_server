package Controlador;

import Modelo.Proveedores;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ProveedorDAO {
    Conexion conexion = new Conexion();

    // Insertar proveedor
    public boolean insertar(Proveedores p) {
        try {
            Connection con = conexion.getConnection();
            String sql = "INSERT INTO proveedores (razon_social, nit) VALUES (?, ?)";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, p.getRazon_social());
            ps.setString(2, p.getNit());
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error insertar proveedor: " + e);
            return false;
        }
    }

    // Listar todos
    public List<Proveedores> listar() {
        List<Proveedores> lista = new ArrayList<>();
        try {
            Connection con = conexion.getConnection();
            String sql = "SELECT * FROM proveedores";
            Statement st = con.createStatement();
            ResultSet rs = st.executeQuery(sql);
            while (rs.next()) {
                Proveedores p = new Proveedores();
                p.setId_proveedores(rs.getInt("id_proveedores"));
                p.setRazon_social(rs.getString("razon_social"));
                p.setNit(rs.getString("nit"));
                lista.add(p);
            }
        } catch (Exception e) {
            System.out.println("Error listar proveedores: " + e);
        }
        return lista;
    }

    // Actualizar
    public boolean actualizar(Proveedores p) {
        try {
            Connection con = conexion.getConnection();
            String sql = "UPDATE proveedores SET razon_social=?, nit=? WHERE id_proveedores=?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, p.getRazon_social());
            ps.setString(2, p.getNit());
            ps.setInt(3, p.getId_proveedores());
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error actualizar proveedor: " + e);
            return false;
        }
    }

    // Eliminar
    public boolean eliminar(int id) {
        try {
            Connection con = conexion.getConnection();
            String sql = "DELETE FROM proveedores WHERE id_proveedores=?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, id);
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error eliminar proveedor: " + e);
            return false;
        }
    }
}