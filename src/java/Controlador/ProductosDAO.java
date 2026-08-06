package Controlador;

import Modelo.Productos;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ProductosDAO {
    Conexion conexion = new Conexion();

    public boolean insertar(Productos p) {
        try {
            Connection con = conexion.getConnection();
            String sql = "INSERT INTO Productos (nombre, precio, stock) VALUES (?, ?, ?)";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, p.getNombre());
            ps.setFloat(2, p.getPrecio());
            ps.setInt(3, p.getStock());
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error insertar producto: " + e);
            return false;
        }
    }

    public List<Productos> listar() {
        List<Productos> lista = new ArrayList<>();
        try {
            Connection con = conexion.getConnection();
            String sql = "SELECT * FROM Productos";
            Statement st = con.createStatement();
            ResultSet rs = st.executeQuery(sql);
            while (rs.next()) {
                Productos p = new Productos();
                p.setId_productos(rs.getInt("id_productos"));
                p.setNombre(rs.getString("nombre"));
                p.setPrecio(rs.getFloat("precio"));
                p.setStock(rs.getInt("stock"));
                lista.add(p);
            }
        } catch (Exception e) {
            System.out.println("Error listar productos: " + e);
        }
        return lista;
    }

    public boolean actualizar(Productos p) {
        try {
            Connection con = conexion.getConnection();
            String sql = "UPDATE Productos SET nombre=?, precio=?, stock=? WHERE id_productos=?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, p.getNombre());
            ps.setFloat(2, p.getPrecio());
            ps.setInt(3, p.getStock());
            ps.setInt(4, p.getId_productos());
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error actualizar producto: " + e);
            return false;
        }
    }

    public boolean eliminar(int id) {
        try {
            Connection con = conexion.getConnection();
            String sql = "DELETE FROM Productos WHERE id_productos=?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, id);
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error eliminar producto: " + e);
            return false;
        }
    }
}