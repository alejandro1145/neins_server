package Pruebas.Insertar;

import Controlador.TipoDocumentoDAO;
import Modelo.Tipo_documento;
import java.util.Scanner;

public class PruebaInsertarTipoDocumento {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        
        System.out.print("Tipo de documento: ");
        String tipo = sc.nextLine();
        
        Tipo_documento t = new Tipo_documento();
        t.setTipo_documento(tipo);
        
        TipoDocumentoDAO dao = new TipoDocumentoDAO();
        boolean resultado = dao.insertar(t);
        System.out.println(resultado ? "Tipo documento insertado correctamente" : "Error al insertar tipo documento");
    }
}