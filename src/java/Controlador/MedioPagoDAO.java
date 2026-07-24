package Controlador;

import Modelo.Medio_pago;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class MedioPagoDAO {
    Conexion conexion = new Conexion();

    public boolean insertar(Medio_pago m) {
        try {
            Connection con = conexion.getConnection();
            String sql = "INSERT INTO medio_pago (descripcion_medio_pago) VALUES (?)";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, m.getDescripcion_medio_pago());
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error insertar medio pago: " + e);
            return false;
        }
    }

    public List<Medio_pago> listar() {
        List<Medio_pago> lista = new ArrayList<>();
        try {
            Connection con = conexion.getConnection();
            String sql = "SELECT * FROM medio_pago";
            Statement st = con.createStatement();
            ResultSet rs = st.executeQuery(sql);
            while (rs.next()) {
                Medio_pago m = new Medio_pago();
                m.setId_medio_pago(rs.getInt("id_medio_pago"));
                m.setDescripcion_medio_pago(rs.getString("descripcion_medio_pago"));
                lista.add(m);
            }
        } catch (Exception e) {
            System.out.println("Error listar medios de pago: " + e);
        }
        return lista;
    }

    public boolean actualizar(Medio_pago m) {
        try {
            Connection con = conexion.getConnection();
            String sql = "UPDATE medio_pago SET descripcion_medio_pago=? WHERE id_medio_pago=?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, m.getDescripcion_medio_pago());
            ps.setInt(2, m.getId_medio_pago());
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error actualizar medio pago: " + e);
            return false;
        }
    }

    public boolean eliminar(int id) {
        try {
            Connection con = conexion.getConnection();
            String sql = "DELETE FROM medio_pago WHERE id_medio_pago=?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, id);
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error eliminar medio pago: " + e);
            return false;
        }
    }
}