# Windows can inherit an invalid C.UTF-8 locale from some terminals. Shiny loads
# global.R before parsing app.R, so set a valid UTF-8 locale first.
if (.Platform$OS.type == "windows") {
  try(Sys.setlocale("LC_CTYPE", "English_United States.utf8"), silent = TRUE)
}
