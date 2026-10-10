args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
test_dir <- if (length(file_arg)) dirname(normalizePath(file_arg)) else getwd()
app_dir <- normalizePath(file.path(test_dir, ".."), mustWork = TRUE)
project_library <- file.path(app_dir, ".Rlib")

if (dir.exists(project_library)) .libPaths(c(project_library, .libPaths()))
stopifnot(requireNamespace("shiny", quietly = TRUE))

old_dir <- getwd()
scratch <- tempfile("shiny-smoke-")
dir.create(scratch)
setwd(scratch)
on.exit(setwd(old_dir), add = TRUE)

source(file.path(app_dir, "global.R"), local = globalenv())
source(file.path(app_dir, "app.R"), local = globalenv())

shiny::testServer(server, {
  session$setInputs(
    next_intro = 0, next_warmup = 0, next_scale_1 = 0,
    next_scale_2 = 0, next_outcomes = 0, submit_survey = 0
  )
  session$flushReact()

  session$setInputs(consent = "si", adult = "si", student = "si", next_intro = 1)
  session$flushReact()
  stopifnot(step() == 1L)

  session$setInputs(class_format = "hibrido", group_frequency = "semanal", next_warmup = 1)
  session$flushReact()
  stopifnot(step() == 2L)

  session$setInputs(
    item_notes = "4", item_voice = "4", item_exposure = "5", item_emotional = "3",
    item_no_rotation = "4", item_leadership = "4", item_rotate = "5", item_ask = "5"
  )
  session$setInputs(next_scale_1 = 1)
  session$flushReact()
  stopifnot(step() == 3L)

  # Los inputs mantienen su valor aunque el orden aleatorio reparta los ítems entre pantallas.
  session$setInputs(next_scale_2 = 1)
  session$flushReact()
  stopifnot(step() == 4L)

  session$setInputs(intervene = "4", reaction = "rotar", next_outcomes = 1)
  session$flushReact()
  stopifnot(step() == 5L)

  session$setInputs(
    message_recall = condition_message,
    perceived_topic = "Distribución de tareas",
    participant_gender = "mujer",
    age_group = "21_23",
    study_cycle = "segundo_tercio",
    study_area = "sociales",
    submit_survey = 1
  )
  session$flushReact()
  stopifnot(submitted(), status() == "complete")
})

csv_path <- file.path(scratch, "data", "respuestas_piloto_v2.csv")
stopifnot(file.exists(csv_path))
rows <- read.csv(csv_path, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(rows) == 1L)
stopifnot(rows$message_recall_correct[[1]])
stopifnot(rows$condition_message[[1]] %in% c("responsabilidad", "causa_comun"))
stopifnot(rows$scale_answered[[1]] == 8L)
stopifnot(abs(rows$acceptance_index[[1]] - 3.25) < 0.001)
stopifnot(!"condition_gender" %in% names(rows))

shiny::testServer(server, {
  session$setInputs(next_intro = 0)
  session$flushReact()
  session$setInputs(consent = "no", next_intro = 1)
  session$flushReact()
  stopifnot(status() == "declined", !submitted())
})

rows_after_decline <- read.csv(csv_path, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(rows_after_decline) == 1L)

cat("SMOKE_TEST_OK\n")
