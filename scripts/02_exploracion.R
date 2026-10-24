library(dplyr)
library(ggplot2)
library(scales)

# Desactivar notación científica
options(scipen = 999) 

# 1. CARGAR LA BASE LIMPIA
# (Dejá esta línea comentada mientras la tabla siga viva en el Environment)
# datos_tp_limpio <- readRDS("datos_eph_limpios.rds") 

# TRUCO DEFINITIVO: Destruir los metadatos ocultos del INDEC antes de cualquier operación
datos_tp_limpio$P47T_real <- as.numeric(as.vector(datos_tp_limpio$P47T_real))
datos_tp_limpio$ANO4 <- as.numeric(as.vector(datos_tp_limpio$ANO4))

# 2. EXPLORACIÓN UNIVARIADA: EVOLUCIÓN DE LA MUESTRA
conteo_casos <- datos_tp_limpio %>%
  group_by(ANO4, Nombre_Aglomerado) %>%
  summarise(Cantidad = n(), .groups = 'drop')

grafico_evolucion <- ggplot(conteo_casos, aes(x = ANO4, y = Cantidad, color = Nombre_Aglomerado)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_x_continuous(breaks = 2016:2025) +
  labs(
    title = "Evolución de la Muestra Válida de la EPH (4to Trimestre)",
    x = "Año", y = "Cantidad de Casos", color = "Aglomerado"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

# 3. EXPLORACIÓN UNIVARIADA: HISTOGRAMA DE INGRESOS
grafico_histograma <- ggplot(datos_tp_limpio %>% filter(!is.na(P47T_real)), 
                             aes(x = P47T_real, fill = Nombre_Aglomerado)) +
  geom_histogram(bins = 40, color = "black", alpha = 0.7, na.rm = TRUE) +
  facet_wrap(~Nombre_Aglomerado, ncol = 1, scales = "free_y") + 
  scale_x_continuous(labels = comma) +
  labs(
    title = "Distribución del Ingreso Total Individual",
    subtitle = "A precios constantes de diciembre 2025",
    x = "Ingreso Real (Pesos)", y = "Frecuencia"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

# 4. ANÁLISIS MULTIVARIADO (Punto 2 del TP)
# Preparamos las etiquetas para cruzar variables
datos_multivariado <- datos_tp_limpio %>%
  mutate(
    Sexo = if_else(CH04 == 1, "Varón", "Mujer"),
    Educacion = case_when(
      NIVEL_ED %in% c(1, 2, 3) ~ "Hasta Secundario Incompleto",
      NIVEL_ED == 4 ~ "Secundario Completo",
      NIVEL_ED %in% c(5, 6) ~ "Superior/Universitario",
      TRUE ~ "Otro/Sin instrucción"
    )
  ) %>%
  filter(!is.na(P47T_real), Educacion != "Otro/Sin instrucción")

# Evolución de la Mediana de Ingresos por Sexo
evolucion_sexo <- datos_multivariado %>%
  group_by(ANO4, Sexo) %>%
  summarise(Mediana_Ingreso = median(P47T_real, na.rm = TRUE), .groups = 'drop')

grafico_brecha_sexo <- ggplot(evolucion_sexo, aes(x = ANO4, y = Mediana_Ingreso, color = Sexo)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_x_continuous(breaks = 2016:2025) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Evolución de la Mediana del Ingreso Real por Sexo",
    subtitle = "Brecha histórica (Precios constantes Dic 2025)",
    x = "Año", y = "Mediana del Ingreso (Pesos)", color = "Sexo"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

# Imprimir todos los gráficos en la consola
print(grafico_evolucion)
print(grafico_histograma)
print(grafico_brecha_sexo)