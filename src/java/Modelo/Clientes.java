package Modelo;

public class Clientes {
    private int id_clientes;
    private int idUsuario;
    private String nombre;
    private String apellidos;
    private String telefono;
    private String identificacion;
    private String tipoDocumento;
    private String correo;
    private String cupo_credito;
    private String saldoPendienteTotal;

    public int getId_clientes() { return id_clientes; }
    public void setId_clientes(int id_clientes) { this.id_clientes = id_clientes; }

    public int getIdUsuario() { return idUsuario; }
    public void setIdUsuario(int idUsuario) { this.idUsuario = idUsuario; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getApellidos() { return apellidos; }
    public void setApellidos(String apellidos) { this.apellidos = apellidos; }

    public String getNombreCompleto() {
        return ((nombre != null ? nombre : "") + " " + (apellidos != null ? apellidos : "")).trim();
    }

    public String getTelefono() { return telefono; }
    public void setTelefono(String telefono) { this.telefono = telefono; }

    public String getIdentificacion() { return identificacion; }
    public void setIdentificacion(String identificacion) { this.identificacion = identificacion; }

    public String getTipoDocumento() { return tipoDocumento; }
    public void setTipoDocumento(String tipoDocumento) { this.tipoDocumento = tipoDocumento; }

    public String getCorreo() { return correo; }
    public void setCorreo(String correo) { this.correo = correo; }

    public String getCupo_credito() { return cupo_credito; }
    public void setCupo_credito(String cupo_credito) { this.cupo_credito = cupo_credito; }

    public String getSaldoPendienteTotal() { return saldoPendienteTotal; }
    public void setSaldoPendienteTotal(String saldoPendienteTotal) { this.saldoPendienteTotal = saldoPendienteTotal; }
}
