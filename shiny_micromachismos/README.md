# TG1 Cuanti 2 — Encuesta Shiny

Encuesta experimental sobre aceptación de conductas micromachistas en trabajos universitarios.

## Diseño vigente

- Ocho afirmaciones en escala Likert, con orden aleatorio.
- Una pregunta neutral de transición entre la escala y el mensaje.
- Un mensaje asignado al azar: responsabilidad individual o causa común.
- Resultado causal principal: intención de intervenir después del mensaje.
- Comparación asociativa del índice de aceptación según género.
- Interacción mensaje por género como análisis exploratorio.
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

La aplicación está conectada a la tabla `survey_responses_v2` del proyecto `tg1-micromachismos`. El código solo contiene la URL del proyecto y una **clave publicable** de Supabase. Esa clave identifica a la aplicación y su alcance está limitado por Row Level Security: puede insertar respuestas, pero no leerlas, modificarlas ni borrarlas.

El repositorio no incluye respuestas, claves administrativas, tokens de shinyapps.io ni bibliotecas instaladas. Nunca se debe subir `.Renviron`, la carpeta `data` ni `rsconnect`. En particular, jamás se debe colocar una clave `secret` o `service_role` en el código.

Si se eliminan la configuración pública y las variables de entorno, las pruebas locales se guardan en `data/respuestas_piloto_v2.csv`. Ese archivo no se versiona y el almacenamiento local de shinyapps.io es temporal.

## Piloto

Realizar entre 15 y 20 pruebas y revisar:

- duración y abandonos;
- comprensión de los ítems;
- distribución entre las dos condiciones;
- control de manipulación;
- distribución y consistencia del índice;
- funcionamiento en celular.

Las respuestas del piloto no deben mezclarse con las 200 encuestas válidas.

## Criterio de respuesta válida

Una respuesta es válida para el análisis principal si la persona acepta participar, tiene 18 años o más, estudia actualmente en una universidad y completa el instrumento. Fallar el control de recuerdo del mensaje no elimina la respuesta del análisis principal; ese resultado se reporta por separado como control de manipulación.

Las opciones `No estoy seguro/a` y `Prefiero no responder` se tratan como valores perdidos al construir el índice. El índice se calcula cuando existen al menos seis de los ocho ítems respondidos en la escala 1-5.

## Análisis previsto

- H1: asociación entre género e índice de aceptación.
- H2: efecto causal del mensaje colectivo frente al individual sobre la intención de intervenir.
- H3: interacción entre mensaje y género, reportada como heterogeneidad exploratoria.
- Resultados secundarios: reacción elegida, balance entre brazos y control de recuerdo del mensaje.

## Colaboración

Cada integrante debe trabajar en una rama o coordinar los cambios antes de editar `app.R`. Una sola persona debe integrar los cambios y desplegar la versión aprobada. Las credenciales de publicación permanecen fuera de GitHub.

Aplicación publicada: https://taller-de-herramientas-cuantitativas2.shinyapps.io/tg1-dinamicas-grupales/
