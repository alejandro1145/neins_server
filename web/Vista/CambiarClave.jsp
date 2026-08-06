<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    Integer idUsuario = (Integer) session.getAttribute("clave_vencida_id_usuario");
    String correo = (String) session.getAttribute("clave_vencida_correo");
    if (idUsuario == null) {
        response.sendRedirect(request.getContextPath() + "/index.html");
        return;
    }
    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Actualizar clave - Neins</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;600;700&family=Playfair+Display:wght@700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../Estilos/global.css">
    <style>
        *{box-sizing:border-box}body{margin:0;min-height:100vh;display:grid;place-items:center;background:#101115;color:#f4f0e7;font-family:'DM Sans',sans-serif;padding:20px}
        .box{width:100%;max-width:430px;background:#171a21;border:1px solid rgba(216,169,61,.25);border-radius:16px;padding:28px;box-shadow:0 24px 70px rgba(0,0,0,.5)}
        h1{font-family:'Playfair Display',serif;margin:0 0 8px;color:#d8a93d}p{color:#aeb8c8;line-height:1.5}label{display:block;margin:16px 0 7px;font-size:12px;text-transform:uppercase;color:#adc0df;font-weight:700}
        input{width:100%;padding:12px;border-radius:9px;border:1px solid rgba(173,192,223,.18);background:#10141f;color:#fff;font:inherit}.btn{width:100%;margin-top:20px;border:0;border-radius:10px;padding:14px;background:linear-gradient(135deg,#f0c96a,#c8942e);font-weight:800;cursor:pointer}.err{background:rgba(255,107,107,.12);border:1px solid rgba(255,107,107,.3);color:#ffb0b0;border-radius:10px;padding:12px;margin-top:14px}
    </style>
</head>
<body>
    <form class="box" method="post" action="<%= request.getContextPath() %>/CambiarClaveServlet">
        <h1>Clave vencida</h1>
        <p>Por seguridad debes crear una clave nueva para <strong><%= correo != null ? correo : "tu cuenta" %></strong>. La nueva clave vencera automaticamente en 30 dias.</p>
        <% if (error != null) { %><div class="err">La clave debe tener minimo 6 caracteres y coincidir en ambos campos.</div><% } %>
        <label>Nueva clave</label>
        <input type="password" name="clave" minlength="6" required>
        <label>Confirmar clave</label>
        <input type="password" name="confirmar" minlength="6" required>
        <button class="btn" type="submit">Actualizar clave</button>
    </form>
</body>
</html>
