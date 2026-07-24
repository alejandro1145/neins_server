package Controlador;

import Modelo.Tipo_documento;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class TipoDocumentoDAO {
    Conexion conexion = new Conexion();

    public boolean insertar(Tipo_documento t) {
        try {
            Connection con = conexion.getConnection();
            String sql = "INSERT INTO Tipo_documento (tipo_documento) VALUES (?)";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, t.getTipo_documento());
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error insertar tipo documento: " + e);
            return false;
        }
    }

    public List<Tipo_documento> listar() {
        List<Tipo_documento> lista = new ArrayList<>();
        try {
            Connection con = conexion.getConnection();
            String sql = "SELECT * FROM Tipo_documento";
            Statement st = con.createStatement();
            ResultSet rs = st.executeQuery(sql);
            while (rs.next()) {
                Tipo_documento t = new Tipo_documento();
                t.setId_tipo_documento(rs.getInt("id_tipo_documento"));
                t.setTipo_documento(rs.getString("tipo_documento"));
                lista.add(t);
            }
        } catch (Exception e) {
            System.out.println("Error listar tipos documento: " + e);
        }
        return lista;
    }

    public boolean actualizar(Tipo_documento t) {
        try {
            Connection con = conexion.getConnection();
            String sql = "UPDATE Tipo_documento SET tipo_documento=? WHERE id_tipo_documento=?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, t.getTipo_documento());
            ps.setInt(2, t.getId_tipo_documento());
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error actualizar tipo documento: " + e);
            return false;
        }
    }

    public boolean eliminar(int id) {
        try {
            Connection con = conexion.getConnection();
            String sql = "DELETE FROM Tipo_documento WHERE id_tipo_documento=?";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setInt(1, id);
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            System.out.println("Error eliminar tipo documento: " + e);
            return false;
        }
    }
}