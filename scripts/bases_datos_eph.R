library(eph)
library(dplyr)
library(purrr) # Para unir las listas fácilmente

# 1. Definimos los años
anios_analisis <- 2016:2025

# 2. Descargamos año por año y forzamos CH05 a ser texto para que no choque
lista_bases <- lapply(anios_analisis, function(anio) {
  base_temporal <- get_microdata(year = anio, trimester = 4, type = "individual")
  
  # Si existe CH05, la convertimos a texto
  if("CH05" %in% names(base_temporal)) {
    base_temporal <- base_temporal %>% mutate(CH05 = as.character(CH05))
  }
  
  return(base_temporal)
})

# 3. Apilamos todas las bases en una sola tabla grande
bases_eph <- bind_rows(lista_bases)

# 4. Ahora sí, hacemos el filtrado que veníamos haciendo
datos_tp <- bases_eph %>%
  organize_labels() %>%
  filter(AGLOMERADO %in% c(13, 32, 33)) %>%
  mutate(
    Nombre_Aglomerado = case_when(
      AGLOMERADO == 13 ~ "Gran Córdoba",
      AGLOMERADO %in% c(32, 33) ~ "GBA"
    )
  ) %>%
  select(
    ANO4, TRIMESTRE, AGLOMERADO, Nombre_Aglomerado, 
    PONDERA, PONDIIO, CH04, CH06, NIVEL_ED, ESTADO, CAT_OCUP, 
    PP04B_COD, PP04D_COD, P21, P47T, ITF, IPCF
  )

# 5. Verificamos que funcionó
table(datos_tp$ANO4, datos_tp$Nombre_Aglomerado)
