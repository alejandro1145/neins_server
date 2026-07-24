package Modelo;

public class Usuarios {

    private int id_usuarios;
    private String nombre;
    private String apellido;
    private String identificacion;
    private int idTipoDocumento = 1;
    private String correo;
    private String telefono;
    private String clave;
    private int idRol = 2;
    private String rol;
    private String fotoPerfil;
    private String fechaNacimiento;
    private String claveExpira;
    private boolean aceptoTerminos;
    private String fechaAceptoTerminos;
    private String ipAceptoTerminos;
    private String versionTerminos = "1.0";

    public int getId_usuarios() { return id_usuarios; }
    public void setId_usuarios(int id_usuarios) { this.id_usuarios = id_usuarios; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getApellido() { return apellido; }
    public void setApellido(String apellido) { this.apellido = apellido; }

    public String getIdentificacion() { return identificacion; }
    public void setIdentificacion(String identificacion) { this.identificacion = identificacion; }

    public int getIdTipoDocumento() { return idTipoDocumento; }
    public void setIdTipoDocumento(int idTipoDocumento) { this.idTipoDocumento = idTipoDocumento; }

    public String getCorreo() { return correo; }
    public void setCorreo(String correo) { this.correo = correo; }

    public String getTelefono() { return telefono; }
    public void setTelefono(String telefono) { this.telefono = telefono; }

    public String getClave() { return clave; }
    public void setClave(String clave) { this.clave = clave; }

    public int getIdRol() { return idRol; }
    public void setIdRol(int idRol) { this.idRol = idRol; }

    public String getRol() { return rol; }
    public void setRol(String rol) { this.rol = rol; }

    public String getFotoPerfil() { return fotoPerfil; }
    public void setFotoPerfil(String fotoPerfil) { this.fotoPerfil = fotoPerfil; }

    public String getFechaNacimiento() { return fechaNacimiento; }
    public void setFechaNacimiento(String fechaNacimiento) { this.fechaNacimiento = fechaNacimiento; }

    public String getClaveExpira() { return claveExpira; }
    public void setClaveExpira(String claveExpira) { this.claveExpira = claveExpira; }

    public boolean isAceptoTerminos() { return aceptoTerminos; }
    public void setAceptoTerminos(boolean aceptoTerminos) { this.aceptoTerminos = aceptoTerminos; }

    public String getFechaAceptoTerminos() { return fechaAceptoTerminos; }
    public void setFechaAceptoTerminos(String fechaAceptoTerminos) { this.fechaAceptoTerminos = fechaAceptoTerminos; }

    public String getIpAceptoTerminos() { return ipAceptoTerminos; }
    public void setIpAceptoTerminos(String ipAceptoTerminos) { this.ipAceptoTerminos = ipAceptoTerminos; }

    public String getVersionTerminos() { return versionTerminos; }
    public void setVersionTerminos(String versionTerminos) { this.versionTerminos = versionTerminos; }

    public String getNombreCompleto() {
        return ((nombre != null ? nombre : "") + " " + (apellido != null ? apellido : "")).trim();
    }
}
