# TG1 Cuanti 2 — Encuesta Shiny

Encuesta experimental sobre aceptación de conductas micromachistas en trabajos universitarios.

## Diseño vigente

- Ocho afirmaciones en escala Likert, con orden aleatorio.
- Un mensaje asignado al azar: responsabilidad individual o causa común.
- Resultado causal principal: intención de intervenir después del mensaje.
- Comparación asociativa del índice de aceptación según género.
- Meta de campo: 200 encuestas válidas.

La escala constituye un índice adaptado para el piloto. No debe presentarse como una escala validada hasta revisar comprensión, consistencia interna y estructura.

## Ejecutar el proyecto

1. Descarga o clona el repositorio.
2. Abre `shiny_micromachismos.Rproj` en RStudio.
3. Ejecuta una sola vez:

```r
source("setup.R")
```

4. Inicia la aplicación:

```r
source("run_local.R")
```

## Archivos principales

- `app.R`: instrumento, aleatorización y guardado de respuestas.
- `www/styles.css`: diseño visual.
- `tests/smoke_test.R`: prueba automatizada del flujo completo.
- `supabase_schema.sql`: tabla y política de inserción para Supabase.
- `.Renviron.example`: nombres de las variables necesarias para Supabase.
- `setup.R`: instalación de dependencias.

## Datos y seguridad

El repositorio no incluye respuestas, credenciales, tokens de shinyapps.io ni bibliotecas instaladas. Nunca se debe subir `.Renviron`, la carpeta `data` ni `rsconnect`.

Sin Supabase, las pruebas locales se guardan en `data/respuestas_piloto_v2.csv`. Ese archivo no se versiona. El almacenamiento local de shinyapps.io es temporal, por lo que debe conectarse Supabase antes del campo final.

## Piloto

Realizar entre 15 y 20 pruebas y revisar:

- duración y abandonos;
- comprensión de los ítems;
- distribución entre las dos condiciones;
- control de manipulación;
- distribución y consistencia del índice;
- funcionamiento en celular.

Las respuestas del piloto no deben mezclarse con las 200 encuestas válidas.

## Colaboración

Cada integrante debe trabajar en una rama o coordinar los cambios antes de editar `app.R`. Una sola persona debe integrar los cambios y desplegar la versión aprobada. Las credenciales de publicación permanecen fuera de GitHub.

Aplicación publicada: https://taller-de-herramientas-cuantitativas2.shinyapps.io/tg1-dinamicas-grupales/
