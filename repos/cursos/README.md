# cursos.encit.unam.mx — Astro

Portal estático para la oferta de Educación Continua.

Características:
- Una carpeta por actividad.
- `curso.json` + `programa.pdf` opcional.
- Diseño sin imágenes de banner; seis paletas institucionales.
- Carrusel por ventana `publicar_desde/publicar_hasta`.
- Oferta actual hasta `fecha_fin`.
- Histórico después de `fecha_fin`, organizado por año.
- Página de detalle permanente.
- La clasificación temporal se realiza en cliente con zona `America/Mexico_City`;
  no requiere reconstrucción diaria.
- Build estático Astro → imagen Nginx.
