# Instrumento Shiny — TG1 Cuanti 2

Encuesta experimental sobre aceptación de prácticas que pueden reproducir desigualdades de género en trabajos universitarios.

## Versión aplicada

- Versión: `2.2.0-campo`.
- Campo: 10–15 de octubre de 2026.
- Base final: 104 respuestas válidas.
- Asignación observada: 47 en causa común y 57 en responsabilidad individual.

## Diseño vigente

- Ocho afirmaciones en escala Likert y orden aleatorio.
- Preguntas neutrales para no revelar el propósito específico al inicio.
- Dos mensajes asignados al azar: `responsabilidad` o `causa_comun`.
- Resultado causal principal: intención de proponer rotación de tareas, de 1 a 5.
- Comparación asociativa del índice de aceptación según género.
- Interacción mensaje por género como análisis exploratorio.
- Control de recuerdo del mensaje y debriefing final.

La escala es una adaptación exploratoria para este estudio. No debe presentarse como una escala validada; en la muestra final su consistencia interna fue α = .365.

## Ejecutar el proyecto

1. Abre `shiny_micromachismos.Rproj` en RStudio.
2. Instala las dependencias una sola vez:

```r
source("setup.R")
```

3. Inicia la aplicación:

```r
source("run_local.R")
```

## Archivos principales

- `app.R`: instrumento, aleatorización, puntuación y guardado.
- `www/styles.css`: diseño visual.
- `tests/smoke_test.R`: prueba automatizada del flujo completo.
- `supabase_schema.sql`: estructura de la tabla y política RLS.
- `.Renviron.example`: plantilla de variables, sin credenciales reales.
- `setup.R`: instalación de dependencias.

## Configuración de Supabase

`app.R` no contiene URL, API key, token ni contraseña real. La conexión se obtiene exclusivamente desde estas variables de entorno:

```text
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
SUPABASE_TABLE
```

Copia `.Renviron.example` como `.Renviron`, completa los valores localmente y reinicia R. `.Renviron` está excluido de Git. Nunca utilices una clave `secret` o `service_role` en la aplicación.

Si las variables no están disponibles o `SUPABASE_DISABLE=1`, las respuestas de prueba se guardan en `data/respuestas_piloto_v2.csv`. Este archivo no se versiona y el almacenamiento local de shinyapps.io es temporal.

## Criterio de respuesta válida

Una respuesta es válida para el análisis principal si la persona acepta participar, tiene 18 años o más, estudia actualmente en una universidad y completa el instrumento. Fallar el control de recuerdo no elimina la observación del análisis principal; se reporta por separado como control de manipulación.

`No estoy seguro/a` y `Prefiero no responder` se tratan como valores perdidos al construir el índice. El índice se calcula con al menos seis de los ocho ítems y recodifica en sentido inverso `item_voice`, `item_rotate` e `item_ask`.

## Análisis asociado

- H1: asociación entre género e índice de aceptación.
- H2: efecto del mensaje de responsabilidad individual frente al de causa común sobre la intención de proponer rotación.
- H3: interacción mensaje × género, reportada como exploratoria.
- Secundarios: reacción prevista, balance entre brazos y recuerdo del mensaje.

## Prueba antes de compartir o desplegar

Ejecuta desde esta carpeta:

```r
source("tests/smoke_test.R")
```

Debe finalizar con `SMOKE_TEST_OK`. El test no envía registros a Supabase.

## Seguridad y colaboración

- No subir `.Renviron`, datos, credenciales ni `rsconnect/`.
- Revisar los cambios antes de cada commit.
- Trabajar en ramas o coordinar la edición de `app.R`.
- Una sola persona integra y despliega la versión aprobada.
