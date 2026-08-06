package Pruebas.Listar;

import Controlador.TipoDocumentoDAO;
import Modelo.Tipo_documento;
import java.util.List;

public class PruebaListarTipoDocumento {
    public static void main(String[] args) {
        TipoDocumentoDAO dao = new TipoDocumentoDAO();
        List<Tipo_documento> lista = dao.listar();
        for (Tipo_documento t : lista) {
            System.out.println("ID: " + t.getId_tipo_documento() + " | Tipo: " + t.getTipo_documento());
        }
    }
}