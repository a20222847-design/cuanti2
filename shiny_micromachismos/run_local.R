local_library <- normalizePath(".Rlib", winslash = "/", mustWork = FALSE)
if (dir.exists(local_library)) {
  .libPaths(c(local_library, .libPaths()))
}

if (!requireNamespace("shiny", quietly = TRUE)) {
  stop("Instala Shiny con install.packages('shiny') antes de ejecutar la app.")
}

shiny::runApp(".", launch.browser = TRUE)
