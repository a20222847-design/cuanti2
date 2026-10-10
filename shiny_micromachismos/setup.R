required_packages <- c("shiny", "httr2", "jsonlite", "rsconnect")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages)) {
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
}

message("Entorno listo. Ejecuta source(\"run_local.R\") para abrir la encuesta.")
