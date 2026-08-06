package Pruebas.Actualizar;

import Controlador.TipoDocumentoDAO;
import Modelo.Tipo_documento;
import java.util.Scanner;

public class PruebaActualizarTipoDocumento {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        
        System.out.print("ID del tipo documento a actualizar: ");
        int id = sc.nextInt();
        sc.nextLine();
        
        System.out.print("Nuevo tipo de documento: ");
        String tipo = sc.nextLine();
        
        Tipo_documento t = new Tipo_documento();
        t.setId_tipo_documento(id);
        t.setTipo_documento(tipo);
        
        TipoDocumentoDAO dao = new TipoDocumentoDAO();
        boolean resultado = dao.actualizar(t);
        System.out.println(resultado ? "Tipo documento actualizado correctamente" : "Error al actualizar tipo documento");
    }
}