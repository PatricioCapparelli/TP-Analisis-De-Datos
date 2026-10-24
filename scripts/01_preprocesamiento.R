library(eph)
library(dplyr)
library(purrr)
library(ggplot2)

# Desactivar notación científica en los gráficos
options(scipen = 999)

# 1. DESCARGA Y LIMPIEZA INICIAL
anios_analisis <- 2016:2025

lista_bases <- lapply(anios_analisis, function(anio) {
  base_temporal <- get_microdata(year = anio, trimester = 4, type = "individual")
  if("CH05" %in% names(base_temporal)) {
    base_temporal <- base_temporal %>% mutate(CH05 = as.character(CH05))
  }
  return(base_temporal)
})

datos_tp <- bind_rows(lista_bases) %>%
  organize_labels() %>%
  filter(AGLOMERADO %in% c(13, 32, 33)) %>%
  mutate(
    Nombre_Aglomerado = case_when(
      AGLOMERADO == 13 ~ "Gran Córdoba",
      AGLOMERADO %in% c(32, 33) ~ "GBA"
    )
  ) %>%
  select(ANO4, TRIMESTRE, AGLOMERADO, Nombre_Aglomerado, 
         PONDERA, PONDIIO, CH04, CH06, NIVEL_ED, ESTADO, CAT_OCUP, 
         PP04B_COD, PP04D_COD, P21, P47T, ITF, IPCF)

# 2. DEFLACTACIÓN CON IPC INDEC (Solución al error <labelled>)
ipc_df <- data.frame(
  ANO4 = as.numeric(rep(2016:2025, each = 2)),
  Nombre_Aglomerado = rep(c("GBA", "Gran Córdoba"), times = 10),
  valor_ipc = c(
    100.0,       100.0,       
    125.0392,    124.9703,    
    183.9381,    184.5080,    
    281.1775,    284.3991,    
    377.0507,    392.1591,    
    570.9981,    590.0958,    
    1114.5359,   1145.8755,   
    3456.6426,   3584.8439,   
    7678.7745,   7687.2760,   
    10115.6707,  10107.6074   
  )
)

# Romper la clase <labelled> forzando numérico puro antes del join
datos_tp$ANO4 <- as.numeric(as.character(datos_tp$ANO4))

datos_tp <- datos_tp %>%
  left_join(ipc_df, by = c("ANO4", "Nombre_Aglomerado")) %>%
  mutate(
    ipc_base = if_else(Nombre_Aglomerado == "GBA", 10115.6707, 10107.6074),
    P47T_real = P47T * (ipc_base / valor_ipc),
    IPCF_real = IPCF * (ipc_base / valor_ipc)
  )

# 3. LIMPIEZA PARA EL MODELO (Filtro de ceros y Outliers por IQR)
datos_tp_limpio <- datos_tp %>%
  filter(P47T_real > 0) %>%
  group_by(ANO4, Nombre_Aglomerado) %>%
  mutate(
    Q1 = quantile(P47T_real, 0.25, na.rm = TRUE),
    Q3 = quantile(P47T_real, 0.75, na.rm = TRUE),
    IQR = Q3 - Q1,
    Limite_Superior = Q3 + 1.5 * IQR
  ) %>%
  filter(P47T_real <= Limite_Superior) %>%
  ungroup() %>%
  select(-Q1, -Q3, -IQR, -Limite_Superior)

# 4. GRÁFICOS EXPLORATORIOS
# Gráfico A: Evolución de la muestra
conteo_casos <- datos_tp_limpio %>%
  group_by(ANO4, Nombre_Aglomerado) %>%
  summarise(Cantidad = n(), .groups = 'drop')

grafico_evolucion <- ggplot(conteo_casos, aes(x = ANO4, y = Cantidad, color = Nombre_Aglomerado)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_x_continuous(breaks = 2016:2025) +
  labs(
    title = "Evolución de la Muestra Válida de la EPH (4to Trimestre)",
    subtitle = "Casos con ingresos mayores a cero y sin valores atípicos",
    x = "Año", y = "Cantidad de Casos", color = "Aglomerado"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

# Gráfico B: Histograma de ingresos deflactados
grafico_histograma <- ggplot(datos_tp_limpio, aes(x = P47T_real, fill = Nombre_Aglomerado)) +
  geom_histogram(bins = 40, color = "black", alpha = 0.7) +
  facet_wrap(~Nombre_Aglomerado, ncol = 1, scales = "free_y") + 
  labs(
    title = "Distribución del Ingreso Total Individual",
    subtitle = "A precios constantes de diciembre 2025",
    x = "Ingreso Real (Pesos)",
    y = "Frecuencia",
    fill = "Aglomerado"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

# Imprimir los gráficos
print(grafico_evolucion)
print(grafico_histograma)
