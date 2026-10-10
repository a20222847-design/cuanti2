library(shiny)

if (.Platform$OS.type == "windows") {
  try(Sys.setlocale("LC_CTYPE", "English_United States.utf8"), silent = TRUE)
}

APP_VERSION <- "2.0.0-pilot"

named_choices <- function(labels, values) stats::setNames(values, labels)

choices_yes_no <- named_choices(c("Sí", "No"), c("si", "no"))
choices_warmup <- named_choices(
  c("Presencial", "Híbrido", "Virtual", "Me resulta indistinto", "Prefiero no responder"),
  c("presencial", "hibrido", "virtual", "indistinto", "pnr")
)
choices_frequency <- named_choices(
  c("Nunca", "Una o dos veces", "Varias veces al mes", "Todas o casi todas las semanas", "No estoy seguro/a", "Prefiero no responder"),
  c("nunca", "una_dos", "mensual", "semanal", "ns", "pnr")
)
choices_agreement <- named_choices(
  c(
    "1. Totalmente en desacuerdo", "2. En desacuerdo", "3. Ni de acuerdo ni en desacuerdo",
    "4. De acuerdo", "5. Totalmente de acuerdo", "No estoy seguro/a", "Prefiero no responder"
  ),
  c("1", "2", "3", "4", "5", "ns", "pnr")
)
choices_probability <- named_choices(
  c("1. Nada probable", "2", "3", "4", "5. Muy probable", "No estoy seguro/a", "Prefiero no responder"),
  c("1", "2", "3", "4", "5", "ns", "pnr")
)

# Banco piloto. Los dos últimos ítems se codifican en sentido inverso.
scale_items <- list(
  item_notes = list(
    text = "Si una integrante suele ser ordenada, resulta práctico que ella tome notas y recuerde las fechas en todos los trabajos.",
    reverse = FALSE
  ),
  item_voice = list(
    text = "No es necesario intervenir si una idea de una compañera se considera recién cuando otro integrante la repite.",
    reverse = FALSE
  ),
  item_exposure = list(
    text = "Cuando el tiempo es limitado, es razonable que los hombres expongan y las mujeres preparen los materiales si el grupo ya trabaja así.",
    reverse = FALSE
  ),
  item_emotional = list(
    text = "Es normal esperar que una compañera calme las tensiones o medie cuando surge un conflicto en el grupo.",
    reverse = FALSE
  ),
  item_no_rotation = list(
    text = "Si el trabajo sale bien, no hace falta revisar quién realiza las tareas de apoyo y quién ocupa los roles más visibles.",
    reverse = FALSE
  ),
  item_leadership = list(
    text = "En una decisión difícil, suele ser más práctico que un compañero tome la iniciativa y cierre la discusión.",
    reverse = FALSE
  ),
  item_rotate = list(
    text = "Las tareas de coordinación, apoyo y exposición deberían rotarse entre todas las personas del grupo.",
    reverse = TRUE
  ),
  item_ask = list(
    text = "Antes de repartir funciones, el equipo debería preguntar qué tareas desea asumir cada integrante.",
    reverse = TRUE
  )
)

required_answer <- function(value, message = "Selecciona una opción para continuar.") {
  if (is.null(value) || !length(value) || !nzchar(as.character(value[[1]]))) {
    showNotification(message, type = "warning", duration = 4)
    return(FALSE)
  }
  TRUE
}

as_field <- function(value) {
  if (is.null(value) || !length(value) || all(is.na(value)) || !nzchar(trimws(value[[1]]))) {
    return(NA_character_)
  }
  as.character(value[[1]])
}

score_item <- function(value, reverse = FALSE) {
  raw <- suppressWarnings(as.numeric(as_field(value)))
  if (is.na(raw) || !raw %in% 1:5) return(NA_real_)
  if (reverse) 6 - raw else raw
}

new_response_id <- function() {
  stamp <- format(Sys.time(), "%Y%m%d%H%M%OS6", tz = "UTC")
  random <- paste(sample(c(letters, 0:9), 10, replace = TRUE), collapse = "")
  gsub("[^A-Za-z0-9]", "", paste0(stamp, random))
}

save_local_csv <- function(record) {
  dir.create("data", recursive = TRUE, showWarnings = FALSE)
  path <- file.path("data", "respuestas_piloto_v2.csv")
  exists <- file.exists(path)
  write.table(
    record, file = path, sep = ",", row.names = FALSE, col.names = !exists,
    append = exists, qmethod = "double", fileEncoding = "UTF-8", na = ""
  )
  list(ok = TRUE, mode = "csv", detail = normalizePath(path, winslash = "/", mustWork = FALSE))
}

save_supabase <- function(record) {
  base_url <- Sys.getenv("SUPABASE_URL", unset = "")
  api_key <- Sys.getenv("SUPABASE_PUBLISHABLE_KEY", unset = Sys.getenv("SUPABASE_ANON_KEY", unset = ""))
  table_name <- Sys.getenv("SUPABASE_TABLE", unset = "survey_responses_v2")

  if (!nzchar(base_url) || !nzchar(api_key)) return(save_local_csv(record))
  if (!grepl("^[A-Za-z_][A-Za-z0-9_]*$", table_name)) stop("SUPABASE_TABLE contiene caracteres no permitidos.")
  if (!requireNamespace("httr2", quietly = TRUE) || !requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Faltan los paquetes httr2 y jsonlite para guardar en Supabase.")
  }

  endpoint <- paste0(sub("/$", "", base_url), "/rest/v1/", table_name)
  body <- jsonlite::toJSON(as.list(record[1, , drop = FALSE]), auto_unbox = TRUE, na = "null")
  request <- httr2::request(endpoint) |>
    httr2::req_headers(apikey = api_key, `Content-Type` = "application/json", Prefer = "return=minimal") |>
    httr2::req_body_raw(body, type = "application/json")
  if (startsWith(api_key, "eyJ")) request <- request |> httr2::req_auth_bearer_token(api_key)

  response <- request |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_timeout(15) |>
    httr2::req_perform()
  if (httr2::resp_status(response) < 200 || httr2::resp_status(response) >= 300) stop("Supabase rechazó el registro.")
  list(ok = TRUE, mode = "supabase", detail = table_name)
}

progress_header <- function(step) {
  percentage <- c(8, 18, 38, 58, 78, 92, 100)[step + 1]
  tags$div(
    class = "progress-wrap",
    tags$div(class = "progress-label", paste0("Avance: ", percentage, "%")),
    tags$div(class = "progress-track", tags$div(class = "progress-fill", style = paste0("width:", percentage, "%")))
  )
}

ui <- fluidPage(
  tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap"),
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),
  tags$main(
    class = "survey-shell",
    tags$div(class = "brand-row", tags$span(class = "brand-mark", "TG1"), tags$span("Experiencias en trabajos universitarios")),
    uiOutput("screen")
  )
)

server <- function(input, output, session) {
  step <- reactiveVal(0L)
  status <- reactiveVal("active")
  submitted <- reactiveVal(FALSE)
  start_time <- Sys.time()
  condition_message <- sample(c("responsabilidad", "causa_comun"), 1)
  item_order <- sample(names(scale_items))
  answers <- reactiveValues()

  scale_block <- function(ids) {
    tagList(lapply(ids, function(id) radioButtons(id, scale_items[[id]]$text, choices_agreement, selected = character(0))))
  }

  page_answered <- function(ids) {
    ok <- all(vapply(ids, function(id) {
      value <- input[[id]]
      !is.null(value) && length(value) && nzchar(as.character(value[[1]]))
    }, logical(1)))
    if (!ok) showNotification("Responde todas las afirmaciones para continuar. Puedes elegir NS o PNR.", type = "warning", duration = 5)
    ok
  }

  save_scale_answers <- function(ids) {
    for (id in ids) answers[[id]] <- input[[id]]
  }

  output$screen <- renderUI({
    if (status() == "declined") {
      return(tags$section(class = "card end-card", tags$div(class = "end-icon", "✓"), tags$h1("Gracias por tu tiempo"), tags$p("La encuesta termina aquí porque decidiste no participar.")))
    }
    if (status() == "ineligible") {
      return(tags$section(class = "card end-card", tags$div(class = "end-icon", "i"), tags$h1("Gracias por tu interés"), tags$p("La encuesta está dirigida a estudiantes universitarios de 18 años o más.")))
    }
    if (status() == "complete") {
      return(tagList(
        progress_header(6),
        tags$section(
          class = "card end-card", tags$div(class = "end-icon", "✓"), tags$h1("¡Respuesta registrada!"),
          tags$p("Gracias por participar. Puedes cerrar esta ventana."),
          tags$div(
            class = "debrief", tags$strong("¿De qué trataba el estudio?"),
            tags$p("Evaluamos la aceptación de conductas sutiles que pueden reproducir desigualdades de género en trabajos grupales. También estudiamos si la forma de comunicar el problema cambia la intención de intervenir. El mensaje que viste fue asignado al azar.")
          )
        )
      ))
    }

    current <- step()
    if (current == 0) {
      return(tagList(
        progress_header(current),
        tags$section(
          class = "card", tags$span(class = "eyebrow", "ENCUESTA ACADÉMICA · 5 MIN"), tags$h1("Antes de comenzar"),
          tags$p("Tu participación es voluntaria y anónima. Responderás preguntas sobre experiencias y decisiones en trabajos universitarios. No pediremos tu nombre, correo ni código universitario. Puedes dejar de responder cuando quieras."),
          radioButtons("consent", "¿Aceptas participar voluntariamente?", choices_yes_no, selected = character(0)),
          radioButtons("adult", "¿Tienes 18 años o más?", choices_yes_no, selected = character(0)),
          radioButtons("student", "¿Actualmente estudias en una universidad?", choices_yes_no, selected = character(0)),
          actionButton("next_intro", "Continuar", class = "btn-primary")
        )
      ))
    }
    if (current == 1) {
      return(tagList(
        progress_header(current),
        tags$section(
          class = "card", tags$span(class = "eyebrow", "PARA COMENZAR"), tags$h1("Un par de preguntas cotidianas"),
          radioButtons("class_format", "Para aprender un tema nuevo, ¿qué formato de clase prefieres?", choices_warmup, selected = character(0)),
          radioButtons("group_frequency", "Durante este ciclo, ¿con qué frecuencia has trabajado en grupo?", choices_frequency, selected = character(0)),
          actionButton("next_warmup", "Continuar", class = "btn-primary")
        )
      ))
    }
    if (current == 2) {
      return(tagList(
        progress_header(current),
        tags$section(
          class = "card", tags$span(class = "eyebrow", "DINÁMICAS DE TRABAJO EN GRUPO · PARTE 1"),
          tags$h1("Responde según tu primera impresión"), tags$p(class = "muted", "Indica qué tan de acuerdo estás con cada afirmación."),
          scale_block(item_order[1:4]), actionButton("next_scale_1", "Continuar", class = "btn-primary")
        )
      ))
    }
    if (current == 3) {
      return(tagList(
        progress_header(current),
        tags$section(
          class = "card", tags$span(class = "eyebrow", "DINÁMICAS DE TRABAJO EN GRUPO · PARTE 2"),
          tags$h1("Cuatro afirmaciones más"), tags$p(class = "muted", "Mantén el mismo criterio de respuesta."),
          scale_block(item_order[5:8]), actionButton("next_scale_2", "Continuar", class = "btn-primary")
        )
      ))
    }
    if (current == 4) {
      message_text <- if (condition_message == "responsabilidad") {
        "Cuando una persona asigna sistemáticamente tareas de apoyo a las mujeres y reserva los roles visibles para los hombres, contribuye a una distribución desigual. Cada estudiante debe revisar y corregir su propio comportamiento."
      } else {
        "En los trabajos grupales pueden repetirse, incluso sin intención, patrones que asignan tareas de apoyo a las mujeres y roles visibles a los hombres. Reconocerlos como equipo ayuda a redistribuir las oportunidades."
      }
      return(tagList(
        progress_header(current),
        tags$section(
          class = "card", tags$span(class = "eyebrow", "MENSAJE"), tags$div(class = "message-box", message_text),
          radioButtons("intervene", "En tu próximo trabajo grupal, ¿qué tan probable sería que propusieras rotar las tareas de apoyo, coordinación y exposición?", choices_probability, selected = character(0)),
          radioButtons(
            "reaction", "Si observaras una distribución desigual, ¿qué harías principalmente?",
            named_choices(
              c("No intervendría", "Preguntaría si las personas están de acuerdo", "Propondría rotar las tareas", "Plantearía el tema durante una reunión", "Esperaría a que otra persona intervenga", "Otra reacción", "No estoy seguro/a", "Prefiero no responder"),
              c("no_intervenir", "preguntar", "rotar", "reunion", "esperar", "otra", "ns", "pnr")
            ), selected = character(0)
          ),
          conditionalPanel(condition = "input.reaction == 'otra'", textInput("reaction_other", "Si deseas, cuéntanos cuál:", placeholder = "Respuesta breve (opcional)")),
          actionButton("next_outcomes", "Continuar", class = "btn-primary")
        )
      ))
    }

    tagList(
      progress_header(current),
      tags$section(
        class = "card", tags$span(class = "eyebrow", "ÚLTIMA PARTE"), tags$h1("Para cerrar"),
        radioButtons(
          "message_recall", "¿Qué idea destacó principalmente el mensaje que leíste?",
          named_choices(
            c("Cada estudiante debe revisar y corregir su comportamiento", "Estos patrones pueden aparecer sin intención y corregirse como equipo", "No lo recuerdo", "Prefiero no responder"),
            c("responsabilidad", "causa_comun", "no_recuerda", "pnr")
          ), selected = character(0)
        ),
        textAreaInput("perceived_topic", "Antes de terminar, ¿de qué crees que trataba principalmente esta encuesta?", placeholder = "Respuesta opcional y breve", rows = 2),
        selectInput(
          "participant_gender", "¿Con qué género te identificas?",
          named_choices(c("Selecciona una opción", "Mujer", "Hombre", "Persona no binaria", "Otra identidad", "Prefiero no responder"), c("", "mujer", "hombre", "no_binario", "otra", "pnr"))
        ),
        selectInput(
          "age_group", "¿En qué rango de edad te encuentras?",
          named_choices(c("Selecciona una opción", "18–20", "21–23", "24–26", "27 o más", "Prefiero no responder"), c("", "18_20", "21_23", "24_26", "27_mas", "pnr"))
        ),
        selectInput(
          "study_cycle", "¿En qué etapa de tu carrera te encuentras?",
          named_choices(c("Selecciona una opción", "Primer tercio", "Segundo tercio", "Último tercio", "Posgrado", "Otra etapa", "Prefiero no responder"), c("", "primer_tercio", "segundo_tercio", "ultimo_tercio", "posgrado", "otra", "pnr"))
        ),
        selectInput(
          "study_area", "¿En qué área se encuentra principalmente tu carrera?",
          named_choices(c("Selecciona una opción", "Ciencias", "Ingeniería y tecnología", "Ciencias sociales", "Humanidades y derecho", "Arte y diseño", "Negocios y economía", "Ciencias de la salud", "Otra área", "Prefiero no responder"), c("", "ciencias", "ingenieria", "sociales", "humanidades", "arte", "negocios", "salud", "otra", "pnr"))
        ),
        actionButton("submit_survey", "Enviar respuesta", class = "btn-primary")
      )
    )
  })

  observeEvent(input$next_intro, {
    if (!required_answer(input$consent)) return()
    if (input$consent == "no") { status("declined"); return() }
    if (!required_answer(input$adult) || !required_answer(input$student)) return()
    if (input$adult == "no" || input$student == "no") { status("ineligible"); return() }
    answers$consent <- input$consent
    answers$adult <- input$adult
    answers$student <- input$student
    step(1L)
  })

  observeEvent(input$next_warmup, {
    if (!required_answer(input$class_format) || !required_answer(input$group_frequency)) return()
    answers$class_format <- input$class_format
    answers$group_frequency <- input$group_frequency
    step(2L)
  })

  observeEvent(input$next_scale_1, {
    ids <- item_order[1:4]
    if (!page_answered(ids)) return()
    save_scale_answers(ids)
    step(3L)
  })

  observeEvent(input$next_scale_2, {
    ids <- item_order[5:8]
    if (!page_answered(ids)) return()
    save_scale_answers(ids)
    step(4L)
  })

  observeEvent(input$next_outcomes, {
    if (!required_answer(input$intervene) || !required_answer(input$reaction)) return()
    answers$intervene <- input$intervene
    answers$reaction <- input$reaction
    answers$reaction_other <- as_field(input$reaction_other)
    step(5L)
  })

  observeEvent(input$submit_survey, {
    if (submitted()) return()
    if (!required_answer(input$message_recall) || !required_answer(input$participant_gender) ||
        !required_answer(input$age_group) || !required_answer(input$study_cycle) || !required_answer(input$study_area)) return()

    scores <- vapply(names(scale_items), function(id) score_item(answers[[id]], scale_items[[id]]$reverse), numeric(1))
    answered_count <- sum(!is.na(scores))
    acceptance_index <- if (answered_count >= 6) mean(scores, na.rm = TRUE) else NA_real_

    record <- data.frame(
      response_id = new_response_id(),
      submitted_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%OS3Z", tz = "UTC"),
      app_version = APP_VERSION,
      condition_message = condition_message,
      item_order = paste(item_order, collapse = "|"),
      consent = answers$consent,
      adult = answers$adult,
      university_student = answers$student,
      class_format = answers$class_format,
      group_frequency = answers$group_frequency,
      item_notes = as_field(answers$item_notes),
      item_voice = as_field(answers$item_voice),
      item_exposure = as_field(answers$item_exposure),
      item_emotional = as_field(answers$item_emotional),
      item_no_rotation = as_field(answers$item_no_rotation),
      item_leadership = as_field(answers$item_leadership),
      item_rotate = as_field(answers$item_rotate),
      item_ask = as_field(answers$item_ask),
      scale_answered = answered_count,
      acceptance_index = round(acceptance_index, 3),
      intervention_intent = answers$intervene,
      reaction = answers$reaction,
      reaction_other = as_field(answers$reaction_other),
      message_recall = input$message_recall,
      message_recall_correct = identical(input$message_recall, condition_message),
      perceived_topic = as_field(input$perceived_topic),
      participant_gender = input$participant_gender,
      age_group = input$age_group,
      study_cycle = input$study_cycle,
      study_area = input$study_area,
      duration_seconds = round(as.numeric(difftime(Sys.time(), start_time, units = "secs"))),
      stringsAsFactors = FALSE
    )

    tryCatch({
      result <- save_supabase(record)
      submitted(TRUE)
      status("complete")
      showNotification(if (result$mode == "supabase") "Respuesta guardada correctamente." else "Respuesta guardada en el archivo local del piloto.", type = "message", duration = 5)
    }, error = function(error) {
      showNotification(paste("No pudimos guardar tu respuesta. Intenta nuevamente.", conditionMessage(error)), type = "error", duration = 10)
    })
  })
}

shinyApp(ui = ui, server = server)
