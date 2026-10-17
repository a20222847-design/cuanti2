# ==============================================================================
# 1. CARGA DE LIBRERÍAS Y DATOS
# ==============================================================================
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, scales, ggplot2, rstatix, patchwork, broom, car, openxlsx)

# Carga del archivo desde tu ruta local
df <- read_csv("C:/Users/Brenda/Downloads/survey_responses_v2_rows (2).csv")

# Ajuste de tipos de datos
# ("ns" y "pnr" pasan a NA al convertir a numérico; suppressWarnings evita el aviso)
items_cols <- c('item_notes', 'item_voice', 'item_exposure', 'item_emotional', 
                'item_no_rotation', 'item_leadership', 'item_rotate', 'item_ask')

df <- df %>%
  mutate(
    across(all_of(items_cols), ~ suppressWarnings(as.numeric(.))),
    intervention_intent = suppressWarnings(as.numeric(intervention_intent))
  )

# ------------------------------------------------------------------------------
# 1B. VARIABLES PREDICTORAS PARA LOS MODELOS (recodificación)
# ------------------------------------------------------------------------------
# Se agrupan categorías con muy pocos casos para que los coeficientes sean estables:
#  - género: se excluye "no_binario" (n = 2) de los modelos
#  - ciclo: se excluyen "otra", "pnr" y "posgrado" (n pequeñas)
#  - área: sociales / ingeniería / otras
#  - formato de clase: presencial / híbrido / virtual o indistinto
#  - frecuencia de trabajo grupal: semanal / mensual / una_dos_o_menos
#  - canal de coordinación: mensajería / otro
df <- df %>%
  mutate(
    condicion = factor(condition_message,
                       levels = c("causa_comun", "responsabilidad")),   # referencia: causa_comun
    genero = factor(case_when(
      participant_gender %in% c("hombre", "mujer") ~ participant_gender,
      TRUE ~ NA_character_), levels = c("hombre", "mujer")),
    edad = factor(age_group, levels = c("18_20", "21_23", "24_26")),
    ciclo = factor(case_when(
      study_cycle %in% c("primer_tercio", "segundo_tercio", "ultimo_tercio") ~ study_cycle,
      TRUE ~ NA_character_), levels = c("primer_tercio", "segundo_tercio", "ultimo_tercio")),
    area = factor(case_when(
      study_area == "sociales"    ~ "sociales",
      study_area == "ingenieria"  ~ "ingenieria",
      TRUE                        ~ "otras"),
      levels = c("sociales", "ingenieria", "otras")),
    formato = factor(case_when(
      class_format == "presencial" ~ "presencial",
      class_format == "hibrido"    ~ "hibrido",
      TRUE                         ~ "virtual_indistinto"),
      levels = c("presencial", "hibrido", "virtual_indistinto")),
    frecuencia = factor(case_when(
      group_frequency == "semanal" ~ "semanal",
      group_frequency == "mensual" ~ "mensual",
      group_frequency %in% c("una_dos", "nunca") ~ "una_dos_o_menos",
      TRUE ~ NA_character_), levels = c("semanal", "mensual", "una_dos_o_menos")),
    canal = factor(if_else(coordination_channel == "mensajeria", "mensajeria", "otro"),
                   levels = c("mensajeria", "otro")),
    duracion_min = duration_seconds / 60,
    message_recall_numeric = as.numeric(message_recall_correct)
  )

# Base común para TODOS los modelos (misma muestra => los modelos son comparables con anova)
vars_modelo <- c("acceptance_index", "intervention_intent", "message_recall_numeric",
                 "condicion", "genero", "edad", "ciclo", "area",
                 "formato", "frecuencia", "canal", "duracion_min")

df_mod <- df %>% drop_na(all_of(vars_modelo))
cat("\nCasos totales:", nrow(df), "| Casos usados en los modelos:", nrow(df_mod), "\n")

# ==============================================================================
# 2. RESUMEN DEMOGRÁFICO Y DESCRIPTIVO
# ==============================================================================

# Total de participantes por condición
print(df %>% count(condition_message))

# Distribución por género, edad y carrera
print(df %>% count(participant_gender))
print(df %>% count(age_group))
print(df %>% count(study_area, sort = TRUE))

# Tiempo de respuesta (en segundos)
summary(df$duration_seconds)

# ==============================================================================
# 3. PRUEBAS ESTADÍSTICAS BÁSICAS
# ==============================================================================

# A. Chi-cuadrado: Recordatorio del mensaje por condición
tabla_recall <- table(df$condition_message, df$message_recall_correct)
print(tabla_recall)
print(chisq.test(tabla_recall))

# B. Prueba T: Índice de Aceptación por condición
print(t.test(acceptance_index ~ condition_message, data = df))

# C. Promedios de cada Ítem por Condición
promedios_items <- df %>%
  group_by(condition_message) %>%
  summarise(across(all_of(items_cols), ~ mean(., na.rm = TRUE)))

print(promedios_items)

# ==============================================================================
# 4. REGRESIÓN LINEAL (OLS) – MODELOS ANIDADOS CON MÁS VARIABLES
# ==============================================================================

# Etiquetas legibles para la tabla
etiquetas <- c(
  "(Intercept)"                      = "Intercepto",
  "condicionresponsabilidad"         = "Condición: Responsabilidad (vs Causa común)",
  "generomujer"                      = "Género: Mujer (vs Hombre)",
  "edad21_23"                        = "Edad: 21-23 (vs 18-20)",
  "edad24_26"                        = "Edad: 24-26 (vs 18-20)",
  "ciclosegundo_tercio"              = "Ciclo: Segundo tercio (vs Primer tercio)",
  "cicloultimo_tercio"               = "Ciclo: Último tercio (vs Primer tercio)",
  "areaingenieria"                   = "Área: Ingeniería (vs Sociales)",
  "areaotras"                        = "Área: Otras (vs Sociales)",
  "formatohibrido"                   = "Clase: Híbrido (vs Presencial)",
  "formatovirtual_indistinto"        = "Clase: Virtual/Indistinto (vs Presencial)",
  "frecuenciamensual"                = "Trabajo grupal: Mensual (vs Semanal)",
  "frecuenciauna_dos_o_menos"        = "Trabajo grupal: 1-2 veces o nunca (vs Semanal)",
  "canalotro"                        = "Canal: Otro (vs Mensajería)",
  "duracion_min"                     = "Duración de la encuesta (minutos)"
)

# Función para ordenar resultados: coeficiente, EE, IC 95%, p-value y estrellas
tabla_modelo <- function(modelo, nombre = "") {
  tidy(modelo, conf.int = TRUE) %>%
    mutate(
      Variable = dplyr::recode(term, !!!etiquetas),
      Sig = case_when(p.value < 0.001 ~ "***",
                      p.value < 0.01  ~ "**",
                      p.value < 0.05  ~ "*",
                      p.value < 0.10  ~ ".",
                      TRUE            ~ ""),
      Modelo = nombre
    ) %>%
    select(Modelo, Variable, Beta = estimate, EE = std.error,
           IC_inf = conf.low, IC_sup = conf.high, p = p.value, Sig) %>%
    mutate(across(c(Beta, EE, IC_inf, IC_sup), ~ round(., 3)),
           p = round(p, 4))
}

# --- A. Modelo 1: Regresión simple (solo condición) ---
mod_lin_simple <- lm(acceptance_index ~ condicion, data = df_mod)

# --- B. Modelo 2: + demografía (género, edad, ciclo, área) ---
mod_lin_demo <- lm(acceptance_index ~ condicion + genero + edad + ciclo + area,
                   data = df_mod)

# --- C. Modelo 3: + contexto de trabajo grupal (formato, frecuencia, canal) ---
mod_lin_contexto <- lm(acceptance_index ~ condicion + genero + edad + ciclo + area +
                         formato + frecuencia + canal,
                       data = df_mod)

# --- D. Modelo 4 (completo): + duración de la encuesta ---
mod_lin_mult <- lm(acceptance_index ~ condicion + genero + edad + ciclo + area +
                     formato + frecuencia + canal + duracion_min,
                   data = df_mod)

summary(mod_lin_mult)

# Tabla ordenada del modelo completo (coeficientes, EE, IC 95%, p-values)
tabla_completa <- tabla_modelo(mod_lin_mult, "Modelo 4 (completo)")
print(tabla_completa, n = Inf)

# Tabla con los 4 modelos lado a lado (Beta + estrellas)
tabla_comparativa <- bind_rows(
  tabla_modelo(mod_lin_simple,   "M1 Simple"),
  tabla_modelo(mod_lin_demo,     "M2 +Demografía"),
  tabla_modelo(mod_lin_contexto, "M3 +Contexto"),
  tabla_modelo(mod_lin_mult,     "M4 Completo")
) %>%
  mutate(Resultado = paste0(sprintf("%.3f", Beta), Sig)) %>%
  select(Modelo, Variable, Resultado) %>%
  pivot_wider(names_from = Modelo, values_from = Resultado, values_fill = "")

print(tabla_comparativa, n = Inf)


# --- E. Regresión Lineal sobre Intención de Intervención (mismas variables) ---
mod_intent <- lm(intervention_intent ~ condicion + genero + edad + ciclo + area +
                   formato + frecuencia + canal + duracion_min,
                 data = df_mod)
summary(mod_intent)
print(tabla_modelo(mod_intent, "Intención de intervención"), n = Inf)

# ==============================================================================
# 5. REGRESIÓN LOGÍSTICA BINARIA (GLM)
# ==============================================================================

# Predicción del recuerdo correcto del mensaje (0 = Incorrecto, 1 = Correcto)
mod_logit <- glm(
  message_recall_numeric ~ condicion + genero + edad + ciclo + area +
    formato + frecuencia + canal + duracion_min,
  data = df_mod,
  family = binomial(link = "logit")
)

summary(mod_logit)

# Coeficientes expresados como Odds Ratios (OR) con sus intervalos de confianza
tabla_or <- tidy(mod_logit, exponentiate = TRUE, conf.int = TRUE) %>%
  mutate(
    Variable = dplyr::recode(term, !!!etiquetas),
    Sig = case_when(p.value < 0.001 ~ "***", p.value < 0.01 ~ "**",
                    p.value < 0.05 ~ "*", p.value < 0.10 ~ ".", TRUE ~ "")
  ) %>%
  select(Variable, OR = estimate, EE = std.error,
         IC_inf = conf.low, IC_sup = conf.high, p = p.value, Sig) %>%
  mutate(across(c(OR, EE, IC_inf, IC_sup), ~ round(., 3)), p = round(p, 4))

print(tabla_or, n = Inf)

# ------------------------------------------------------------------------------
# EXPORTAR TABLAS A EXCEL (.xlsx) con formato
# ------------------------------------------------------------------------------
tabla_intent <- tabla_modelo(mod_intent, "Intención de intervención")

wb <- createWorkbook()
estilo_encabezado <- createStyle(textDecoration = "bold", fgFill = "#2B5C8F",
                                 fontColour = "white", halign = "center",
                                 valign = "center", border = "TopBottomLeftRight",
                                 wrapText = TRUE)
estilo_cuerpo <- createStyle(border = "TopBottomLeftRight", valign = "center")
estilo_num    <- createStyle(numFmt = "0.000", halign = "center",
                             border = "TopBottomLeftRight")
estilo_p      <- createStyle(numFmt = "0.0000", halign = "center",
                             border = "TopBottomLeftRight")
estilo_sig    <- createStyle(halign = "center", border = "TopBottomLeftRight",
                             textDecoration = "bold")
estilo_signif <- createStyle(bgFill = "#E6F4EA")   # filas con p < 0.05

agregar_hoja <- function(wb, nombre, tabla, cols_num = NULL, col_p = NULL, col_sig = NULL) {
  addWorksheet(wb, nombre)
  writeData(wb, nombre, tabla, headerStyle = estilo_encabezado)
  filas <- 2:(nrow(tabla) + 1)
  addStyle(wb, nombre, estilo_cuerpo, rows = filas, cols = 1:ncol(tabla),
           gridExpand = TRUE)
  if (!is.null(cols_num)) addStyle(wb, nombre, estilo_num, rows = filas,
                                   cols = cols_num, gridExpand = TRUE)
  if (!is.null(col_p))    addStyle(wb, nombre, estilo_p, rows = filas,
                                   cols = col_p, gridExpand = TRUE)
  if (!is.null(col_sig))  addStyle(wb, nombre, estilo_sig, rows = filas,
                                   cols = col_sig, gridExpand = TRUE)
  setColWidths(wb, nombre, cols = 1:ncol(tabla), widths = "auto")
  freezePane(wb, nombre, firstRow = TRUE)
}

# Hoja 1: modelo completo (variable dependiente: índice de aceptación)
agregar_hoja(wb, "Modelo completo", tabla_completa %>% select(-Modelo),
             cols_num = 2:5, col_p = 6, col_sig = 7)
filas_sig <- which(tabla_completa$p < 0.05) + 1
if (length(filas_sig) > 0)
  addStyle(wb, "Modelo completo", estilo_signif, rows = filas_sig,
           cols = 1:7, gridExpand = TRUE, stack = TRUE)

# Hoja 2: comparación de los 4 modelos
agregar_hoja(wb, "Comparacion modelos", tabla_comparativa)
setColWidths(wb, "Comparacion modelos", cols = 1, widths = 48)

# Hoja 3: intención de intervención
agregar_hoja(wb, "Intencion intervencion", tabla_intent %>% select(-Modelo),
             cols_num = 2:5, col_p = 6, col_sig = 7)

# Hoja 4: odds ratios (recuerdo correcto)
agregar_hoja(wb, "Odds Ratios recuerdo", tabla_or,
             cols_num = 2:5, col_p = 6, col_sig = 7)

# Hoja 5: leyenda
addWorksheet(wb, "Leyenda")
writeData(wb, "Leyenda", data.frame(Nota = c(
  "*** p < 0.001   ** p < 0.01   * p < 0.05   . p < 0.10",
  "Beta = cambio esperado en la variable dependiente respecto a la categoría de referencia.",
  "IC = intervalo de confianza al 95%. EE = error estándar.",
  "Filas en verde = coeficientes con p < 0.05."
)), headerStyle = estilo_encabezado)
setColWidths(wb, "Leyenda", cols = 1, widths = 90)

saveWorkbook(wb, "tablas_regresion.xlsx", overwrite = TRUE)
cat("\nTablas guardadas en:", file.path(getwd(), "tablas_regresion.xlsx"), "\n")

# ==============================================================================
# 6. EVALUACIÓN Y COMPARACIÓN DE MODELOS
# ==============================================================================

# Métricas globales de ajuste (R², R² ajustado, AIC, BIC, etc.)
bind_rows(
  "M1 Simple"      = glance(mod_lin_simple),
  "M2 +Demografía" = glance(mod_lin_demo),
  "M3 +Contexto"   = glance(mod_lin_contexto),
  "M4 Completo"    = glance(mod_lin_mult),
  .id = "Modelo"
) %>%
  select(Modelo, r.squared, adj.r.squared, sigma, AIC, BIC, df, nobs) %>%
  print()

# Comparación estadística entre modelos anidados (F-test secuencial)
anova(mod_lin_simple, mod_lin_demo, mod_lin_contexto, mod_lin_mult)

# Multicolinealidad (GVIF; valores < 5 son aceptables)
vif(mod_lin_mult)

# ==============================================================================
# 7. DIAGNÓSTICO Y VISUALIZACIÓN DE COEFICIENTES
# ==============================================================================

# A. Diagnóstico visual de supuestos OLS (Normalidad, Homocedasticidad, Residuos)
par(mfrow = c(2, 2))
plot(mod_lin_mult)
par(mfrow = c(1, 1))

# B. Gráfico de Coeficientes (Forest Plot) para la Regresión Múltiple completa
tidy(mod_lin_mult, conf.int = TRUE) %>%
  filter(term != "(Intercept)") %>%
  mutate(
    term = dplyr::recode(term, !!!etiquetas),
    significativo = if_else(p.value < 0.05, "p < 0.05", "n.s.")
  ) %>%
  ggplot(aes(x = estimate, y = reorder(term, estimate),
             xmin = conf.low, xmax = conf.high, color = significativo)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "firebrick") +
  geom_pointrange(size = 0.7) +
  scale_color_manual(values = c("p < 0.05" = "#2b5c8f", "n.s." = "grey55")) +
  theme_minimal() +
  labs(
    title = "Efectos estimados sobre el Índice de Aceptación",
    x = "Coeficiente Beta (IC 95%)",
    y = "Variables Predictoras",
    color = NULL
  )

# ==============================================================================
# GENERACIÓN DE GRÁFICOS (ggplot2)
# ==============================================================================

# GRÁFICO 1: Recordatorio del mensaje (%)
p1 <- df %>%
  group_by(condition_message) %>%
  summarise(pct_correct = mean(message_recall_correct, na.rm = TRUE) * 100) %>%
  ggplot(aes(x = condition_message, y = pct_correct, fill = condition_message)) +
  geom_col(width = 0.5) +
  geom_text(aes(label = sprintf("%.1f%%", pct_correct)), vjust = -0.5, fontface = "bold") +
  scale_fill_manual(values = c("causa_comun" = "#3ecf8e", "responsabilidad" = "#4A5568")) +
  scale_y_continuous(limits = c(0, 100)) +
  theme_minimal() +
  labs(
    title = "Recordatorio Correcto del Mensaje",
    x = "Condición Experimental",
    y = "% Correcto"
  ) +
  theme(legend.position = "none")
print(p1)


# GRÁFICO 2: Distribución de Reacciones por Condición
p2 <- df %>%
  count(condition_message, reaction) %>%
  ggplot(aes(x = reaction, y = n, fill = condition_message)) +
  geom_col(position = position_dodge(preserve = "single")) +
  scale_fill_manual(values = c("causa_comun" = "#3ecf8e", "responsabilidad" = "#2B6CB0")) +
  theme_minimal() +
  labs(
    title = "Reacciones por Condición",
    x = "Acción Específica",
    y = "Cantidad de Respuestas",
    fill = "Condición"
  )
print(p2)

# GRÁFICO 3: Comparación de Promedios por Ítem
p3 <- df %>%
  pivot_longer(cols = all_of(items_cols), names_to = "item", values_to = "score") %>%
  group_by(condition_message, item) %>%
  summarise(mean_score = mean(score, na.rm = TRUE), .groups = "drop") %>%
  ggplot(aes(x = item, y = mean_score, fill = condition_message)) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = c("causa_comun" = "#3ecf8e", "responsabilidad" = "#2B6CB0")) +
  coord_cartesian(ylim = c(1, 5)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(
    title = "Puntuación Promedio por Ítem según Condición",
    x = "Ítems Evaluados",
    y = "Promedio (Escala 1 - 5)",
    fill = "Condición"
  )

print(p3)

# GRÁFICO 4: Índice de Aceptación por Género y Condición
p4 <- df %>%
  filter(participant_gender %in% c("hombre", "mujer")) %>%
  group_by(participant_gender, condition_message) %>%
  summarise(
    mean_acceptance = mean(acceptance_index, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = participant_gender, y = mean_acceptance, fill = condition_message)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(
    aes(label = sprintf("%.2f", mean_acceptance)),
    position = position_dodge(width = 0.8),
    vjust = -0.5,
    fontface = "bold"
  ) +
  scale_fill_manual(values = c("causa_comun" = "#3ecf8e", "responsabilidad" = "#2B6CB0")) +
  scale_x_discrete(labels = c("hombre" = "Hombres", "mujer" = "Mujeres")) +
  coord_cartesian(ylim = c(1, 4)) +
  theme_minimal() +
  labs(
    title = "Índice de Aceptación por Género y Condición",
    subtitle = "Comparación entre Hombres y Mujeres según la condición recibida",
    x = "Género del Participante",
    y = "Aceptación Promedio (Escala 1 - 5)",
    fill = "Condición"
  )

print(p4)