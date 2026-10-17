# TG1 Cuanti 2 — Micromachismos en trabajos grupales

Repositorio reproducible del Trabajo Grupal 1 del curso **Taller de Herramientas Cuantitativas para el Análisis Social 2**.

El proyecto combina una escala breve de actitudes con un experimento de mensaje aleatorio para estudiar dinámicas de género en trabajos universitarios. El instrumento evita preguntar si una persona “es micromachista”: presenta situaciones cotidianas y mide grados de acuerdo, reduciendo la deseabilidad social.

## Estado final del estudio

- Trabajo de campo: **10–15 de octubre de 2026**.
- Base cerrada: **104 respuestas válidas**.
- Condición causa común: **47 respuestas**.
- Condición responsabilidad individual: **57 respuestas**.
- Versión del instrumento: **2.2.0-campo**.
- Muestra: estudiantes universitarios de 18 años o más, reclutados por conveniencia.

El objetivo inicial de 200 respuestas se conserva como referencia de planificación, pero los análisis y el deck final utilizan exclusivamente la base cerrada de 104 casos.

## Preguntas e hipótesis

1. **Asociación:** ¿la aceptación de prácticas de distribución desigual varía según el género de la persona encuestada?
2. **Efecto del mensaje:** ¿un mensaje de responsabilidad individual cambia la intención de proponer rotación de tareas frente a un mensaje de causa común?
3. **Heterogeneidad exploratoria:** ¿la respuesta al mensaje varía entre mujeres y hombres?

La primera comparación es asociativa. El contraste entre mensajes aprovecha la asignación aleatoria y constituye el análisis causal principal.

## Instrumento

La aplicación Shiny se encuentra en [`shiny_micromachismos/`](shiny_micromachismos/). Su flujo es:

1. consentimiento y elegibilidad;
2. preguntas neutrales de entrada;
3. ocho situaciones en escala Likert, presentadas en orden aleatorio;
4. asignación aleatoria a uno de dos mensajes;
5. intención de proponer rotación de tareas y reacción prevista;
6. control de recuerdo, percepción del tema y variables demográficas;
7. debriefing final.

El índice de aceptación es el promedio de los ocho ítems recodificados y se calcula con al menos seis respuestas válidas. Los ítems `item_voice`, `item_rotate` e `item_ask` se invierten. El índice es **exploratorio**: en la muestra final obtuvo una consistencia interna baja (α = .365) y no debe presentarse como una escala validada.

## Estructura del repositorio

| Ruta | Contenido |
|---|---|
| `shiny_micromachismos/app.R` | Cuestionario, aleatorización, construcción del índice y guardado. |
| `shiny_micromachismos/www/styles.css` | Diseño visual adaptable a celular. |
| `shiny_micromachismos/tests/smoke_test.R` | Prueba automatizada del flujo y control para evitar credenciales en el código. |
| `shiny_micromachismos/supabase_schema.sql` | Esquema y política RLS de inserción para Supabase. |
| `shiny_micromachismos/.Renviron.example` | Plantilla sin valores reales para configurar variables de entorno. |
| `shiny_micromachismos/README.md` | Guía técnica del instrumento. |

Las bases de campo, copias raw, credenciales y archivos de despliegue no forman parte del repositorio público. Se conservan en la carpeta interna del equipo.

## Ejecutar localmente

1. Clona o descarga el repositorio.
2. Abre `shiny_micromachismos/shiny_micromachismos.Rproj` en RStudio.
3. Ejecuta una sola vez:

```r
source("setup.R")
```

4. Inicia la aplicación:

```r
source("run_local.R")
```

Si Supabase no está configurado, las pruebas se guardan localmente en `data/respuestas_piloto_v2.csv`. La carpeta `data/` está excluida de Git.

## Configuración segura de Supabase

El repositorio **no contiene ninguna API key, token ni contraseña real**. Para conectar una copia local:

1. copia `.Renviron.example` como `.Renviron`;
2. completa `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` y `SUPABASE_TABLE`;
3. reinicia la sesión de R;
4. nunca agregues `.Renviron` al repositorio.

La aplicación utiliza únicamente una clave publicable limitada por Row Level Security. La tabla permite insertar respuestas, pero no leerlas, modificarlas ni borrarlas desde el instrumento. Las claves `secret` y `service_role` nunca deben utilizarse en la aplicación.

## Verificación

Desde `shiny_micromachismos/`, ejecuta:

```r
source("tests/smoke_test.R")
```

El resultado esperado es `SMOKE_TEST_OK`. La prueba recorre el cuestionario, valida la aleatorización y el cálculo del índice, comprueba la opción de Gestión y confirma que `app.R` no contenga claves con prefijo `sb_publishable_`.

## Aplicación de campo

La última URL registrada de despliegue es:

<https://dinamicas-en-trabajos-grupales1.shinyapps.io/tg1-dinamicas-grupales/>

El trabajo de campo está cerrado; por ello la aplicación puede encontrarse detenida o archivada en shinyapps.io. El código de este repositorio constituye el insumo reproducible del instrumento aplicado.

## Colaboración

- Trabajar en una rama o coordinar antes de editar `app.R`.
- Revisar `git diff` antes de cada commit.
- Ejecutar el smoke test antes de publicar.
- No subir bases de respuestas, `.Renviron`, `rsconnect/`, tokens de shinyapps.io ni credenciales de Supabase.
- Una sola integrante integra los cambios y realiza el despliegue aprobado.
