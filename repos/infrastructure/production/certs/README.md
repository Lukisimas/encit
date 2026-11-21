Este directorio contiene certificados institucionales de producción para los virtual hosts
que aún utilizan certificados provistos por la institución:

- encit.crt/key
- siia.crt/key
- cursos.crt/key
- ec.crt/key

Xitle (`xitle.encit.unam.mx`) utiliza Certbot/Let's Encrypt. Su estado y certificados se
persisten en `/srv/encit/platform/production/letsencrypt`; no se debe copiar un certificado
manual de Xitle en este directorio.

Nunca versionar claves privadas.
