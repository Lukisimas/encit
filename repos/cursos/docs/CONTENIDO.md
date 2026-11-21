# Gestión de contenido

1. `./scripts/new-activity.sh curso <slug>` o `diplomado <slug>`.
2. Editar `curso.json`.
3. Opcional: añadir `programa.pdf` y configurar `/programas/<slug>.pdf`.
4. Commit/push.
5. Jenkins valida, compila y despliega.

`publicar_*` controla promoción; `fecha_*` controla oferta/histórico.
Nunca se elimina la página de detalle por haber concluido.
