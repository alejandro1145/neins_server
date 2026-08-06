(function () {
    var cart = new Map();
    var money = new Intl.NumberFormat("es-CO", { maximumFractionDigits: 0 });
    // Un dato viejo o corrupto de localStorage no puede romper toda la navegación.
    var savedFavorites = [];
    try {
        savedFavorites = JSON.parse(localStorage.getItem("neinsFavorites") || "[]");
        if (!Array.isArray(savedFavorites)) savedFavorites = [];
    } catch (e) {
        savedFavorites = [];
    }
    var favorites = new Set(savedFavorites);

    function sectionName(name) {
        return "section-" + name;
    }

    function showSection(name) {
        document.querySelectorAll(".client-section").forEach(function (section) {
            section.classList.toggle("active", section.id === sectionName(name));
        });
        document.querySelectorAll("[data-section-target]").forEach(function (action) {
            action.classList.toggle("active", action.dataset.sectionTarget === name);
        });
        try {
            history.replaceState(null, "", "#/" + name);
        } catch (e) {}
        window.scrollTo({ top: 0, behavior: "smooth" });
    }

    function readInitialSection() {
        var fromHash = location.hash.replace("#/", "");
        var fromBody = document.body.dataset.section || "resumen";
        return fromHash || fromBody;
    }

    function renderCart() {
        var list = document.getElementById("cartList");
        var hidden = document.getElementById("cartHidden");
        var totalEl = document.getElementById("cartTotal");
        var checkout = document.getElementById("checkoutBtn");
        if (!list || !hidden || !totalEl || !checkout) return;

        list.innerHTML = "";
        hidden.innerHTML = "";
        var total = 0;

        cart.forEach(function (item) {
            total += item.price * item.qty;
            var row = document.createElement("div");
            row.className = "cart-item";
            row.innerHTML =
                "<div><b>" + escapeHtml(item.name) + "</b><br><small>$" + money.format(item.price * item.qty) + "</small></div>" +
                "<div class=\"qty-controls\">" +
                "<button type=\"button\" data-cart-action=\"minus\" data-id=\"" + item.id + "\">-</button>" +
                "<span>" + item.qty + "</span>" +
                "<button type=\"button\" data-cart-action=\"plus\" data-id=\"" + item.id + "\">+</button>" +
                "</div>";
            list.appendChild(row);

            addHidden(hidden, "producto_id", item.id);
            addHidden(hidden, "cantidad", item.qty);
        });

        if (cart.size === 0) {
            list.innerHTML = "<div class=\"empty-cart\"><span>🛒</span><h3>Tu carrito está vacío</h3><p>Agrega productos para ver tu resumen de compra.</p></div>";
        }
        totalEl.textContent = "$" + money.format(total);
        checkout.disabled = cart.size === 0;
    }

    function addHidden(container, name, value) {
        var input = document.createElement("input");
        input.type = "hidden";
        input.name = name;
        input.value = value;
        container.appendChild(input);
    }

    function escapeHtml(value) {
        return String(value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;");
    }

    function filterProducts() {
        var q = (document.getElementById("productSearch") || {}).value || "";
        var filter = (document.getElementById("stockFilter") || {}).value || "all";
        q = q.trim().toLowerCase();
        document.querySelectorAll(".product-card").forEach(function (card) {
            var stock = Number(card.dataset.stock || 0);
            var isFav = favorites.has(card.dataset.id);
            var visible = !q || (card.dataset.name || "").indexOf(q) >= 0;
            if (filter === "available") visible = visible && stock > 0;
            if (filter === "low") visible = visible && stock > 0 && stock <= 5;
            if (filter === "favorites") visible = visible && isFav;
            card.style.display = visible ? "" : "none";
        });
    }

    function syncFavorites() {
        try { localStorage.setItem("neinsFavorites", JSON.stringify(Array.from(favorites))); } catch (e) {}
        document.querySelectorAll(".product-card").forEach(function (card) {
            var btn = card.querySelector(".favorite-btn");
            if (!btn) return;
            var active = favorites.has(card.dataset.id);
            btn.classList.toggle("active", active);
            btn.textContent = active ? "★" : "♡";
        });
        var profileCount = document.getElementById("favProfileCount");
        if (profileCount) profileCount.textContent = favorites.size;
        filterProducts();
    }

    document.addEventListener("click", function (ev) {
        var target = ev.target.closest("[data-section-target]");
        if (target) {
            ev.preventDefault();
            showSection(target.dataset.sectionTarget);
            if (target.dataset.filterFavorites === "true") {
                var select = document.getElementById("stockFilter");
                if (select) select.value = "favorites";
                filterProducts();
            }
            return;
        }

        var favorite = ev.target.closest(".favorite-btn");
        if (favorite) {
            var card = favorite.closest(".product-card");
            if (!card) return;
            if (favorites.has(card.dataset.id)) favorites.delete(card.dataset.id);
            else favorites.add(card.dataset.id);
            syncFavorites();
            return;
        }

        var add = ev.target.closest(".add-cart-btn");
        if (add) {
            var id = add.dataset.id;
            var current = cart.get(id) || {
                id: id,
                name: add.dataset.name,
                price: Number(add.dataset.price),
                stock: Number(add.dataset.stock),
                qty: 0
            };
            if (current.qty < current.stock) current.qty += 1;
            cart.set(id, current);
            renderCart();
            return;
        }

        var cartAction = ev.target.closest("[data-cart-action][data-id]");
        if (cartAction) {
            var item = cart.get(cartAction.dataset.id);
            if (!item) return;
            if (cartAction.dataset.cartAction === "plus" && item.qty < item.stock) item.qty += 1;
            if (cartAction.dataset.cartAction === "minus") item.qty -= 1;
            if (item.qty <= 0) cart.delete(item.id);
            else cart.set(item.id, item);
            renderCart();
            return;
        }

        if (ev.target.closest("#clearCart")) {
            cart.clear();
            renderCart();
        }
    });

    var search = document.getElementById("productSearch");
    var filter = document.getElementById("stockFilter");
    if (search) search.addEventListener("input", filterProducts);
    if (filter) filter.addEventListener("change", filterProducts);

    var cartForm = document.getElementById("cartForm");
    if (cartForm) {
        cartForm.addEventListener("submit", function (ev) {
            if (cart.size === 0) ev.preventDefault();
        });
    }

    var avatarInput = document.getElementById("avatarInput");
    var avatarPreview = document.getElementById("avatarPreview");
    if (avatarInput && avatarPreview) {
        avatarInput.addEventListener("change", function () {
            var file = avatarInput.files && avatarInput.files[0];
            if (!file || file.size > 2 * 1024 * 1024) return;
            var reader = new FileReader();
            reader.onload = function (e) {
                avatarPreview.textContent = "";
                avatarPreview.style.backgroundImage = "url('" + e.target.result + "')";
            };
            reader.readAsDataURL(file);
        });
    }

    showSection(readInitialSection());
    syncFavorites();
    renderCart();
})();
