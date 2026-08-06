<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="Controlador.UsuariosDAO, Modelo.Usuarios"%>

<%
    String error = null;
    Usuarios usuario = null;

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String correo = request.getParameter("correo");
        UsuariosDAO dao = new UsuariosDAO();
        usuario = dao.buscarPorCorreo(correo);
        if (usuario == null) {
            error = "No encontramos ninguna cuenta con ese correo.";
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recuperar Contraseña — Una Pa' La Sed</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@500;700&family=Inter:wght@300;400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../Estilos/global.css">
    <link rel="stylesheet" href="../Estilos/global.css">
</head>
<body>

<div class="form-container">

    <!-- Marca -->
    <div style="margin-bottom:28px;">
        <div style="width:56px;height:56px;margin:0 auto 14px;background:linear-gradient(135deg,rgba(212,175,55,.15),rgba(212,175,55,.05));border:1px solid rgba(212,175,55,.3);border-radius:16px;display:flex;align-items:center;justify-content:center;font-size:1.6rem;box-shadow:0 8px 24px rgba(212,175,55,.12);">
            🔑
        </div>
        <h1>Recuperar Contraseña</h1>
        <p class="subtitle">Cartera Digital</p>
    </div>

    <div class="divider"><span>Verificación</span></div>

    <!-- Estado: encontrado -->
    <% if (usuario != null) { %>
        <div class="alert alert-success">
            <strong>¡Hola, <%= usuario.getNombre() %>!</strong><br>
            Tu contraseña es: <strong><%= usuario.getClave() %></strong>
        </div>
        <a href="../index.html" class="btn-primary" style="display:block;text-align:center;text-decoration:none;margin-bottom:8px;">
            Ir al inicio de sesión →
        </a>
    <% } else { %>

        <!-- Error -->
        <% if (error != null) { %>
            <div class="alert alert-error">✕ &nbsp;<%= error %></div>
        <% } %>

        <!-- Formulario -->
        <form method="post" id="recover-form">
            <div class="form-group">
                <label for="correo">Correo electrónico</label>
                <input type="email" name="correo" id="correo"
                       placeholder="usuario@correo.com"
                       required autocomplete="email">
            </div>

            <button type="submit" class="btn-primary" id="btn-submit">
                Buscar cuenta
            </button>
        </form>

    <% } %>

    <!-- Volver -->
    <div class="back-link">
        <a href="../index.html">â† Volver al inicio</a>
    </div>

</div>

<script>
    document.getElementById('recover-form') && document.getElementById('recover-form').addEventListener('submit', function () {
        var btn = document.getElementById('btn-submit');
        if (btn) { btn.textContent = 'Buscando…'; btn.classList.add('loading'); }
    });
</script>

    <script src="../Scripts/premium-ui.js"></script>
</body>
</html>

