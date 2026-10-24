# Evolución de indicadores socioeconómicos y laborales en Argentina (2016-2025)

## Introducción y Contexto del Estudio

El presente informe analiza la evolución de los principales indicadores socioeconómicos y laborales en Argentina durante la última década (2016-2025). El estudio se estructura sobre un análisis comparativo de dos de los principales centros urbanos del país: el **Gran Buenos Aires (GBA)** y el **Gran Córdoba**.

La fuente principal de información son las bases de microdatos individuales de la Encuesta Permanente de Hogares (EPH), provistas por el Instituto Nacional de Estadística y Censos (INDEC). Se seleccionó el cuarto trimestre de cada año para evitar sesgos de estacionalidad y establecer una ventana de observación consistente a lo largo de los diez períodos continuos.

---

## `01-preprocesamiento.R`

### Procesamiento de los Datos

Automatizamos la descarga y el ordenamiento de los datos utilizando el lenguaje R. Durante el proceso, notamos que las bases de datos históricas del INDEC tenían problemas de coherencia: una misma variable demográfica podía aparecer como texto en un período y como número en otro. Para resolverlo, diseñamos un filtro que unifica el formato de los datos de manera automática durante la misma descarga. Esto nos permitió consolidar toda la información histórica en una única base limpia y completa.

### Metodología de Extracción y Procesamiento (Pipeline de Datos)

La obtención y estructuración de los datos se automatizó mediante un script en lenguaje R, implementando los paquetes `eph`, `dplyr` y `purrr`. Durante la extracción iterativa, se identificaron inconsistencias estructurales en las bases históricas del INDEC (mutaciones en el tipo de dato de variables demográficas entre formato entero y cadena de texto). Esto se resolvió mediante rutinas de coerción de tipos integradas al ciclo de descarga, logrando consolidar el dataset longitudinal sin pérdida de registros.

El flujo de procesamiento de los microdatos consistió en:

- **Estandarización categórica:** traducción de la codificación numérica original del INDEC a etiquetas descriptivas legibles para facilitar el análisis estadístico posterior.
- **Filtro geográfico espacial:** aislamiento de las observaciones estrictamente correspondientes a la jurisdicción del Gran Córdoba (Aglomerado 13) y el conglomerado metropolitano del Gran Buenos Aires (Aglomerados 32 de CABA y 33 de Partidos del GBA).
- **Reducción de dimensionalidad:** depuración de la matriz de datos, reteniendo exclusivamente las variables pertinentes para dimensiones demográficas (`CH04`, `CH06`, `NIVEL_ED`), laborales (`ESTADO`, `CAT_OCUP`, `PP04B_COD`, `PP04D_COD`) y métricas de ingresos (`P21`, `P47T`, `ITF`, `IPCF`), junto con sus respectivos ponderadores poblacionales.

### Estructura de la Muestra y Restricciones Operativas

La consolidación arrojó un volumen muestral que promedia anualmente los 10.000 casos en GBA y 2.300 en Gran Córdoba. Como restricción metodológica central, los datos auditan una contracción atípica de la muestra durante el año 2020, registrando una caída superior al 50% en la recolección de campo (3.975 casos en GBA y 1.133 en Gran Córdoba). Esta anomalía se explica por las limitaciones operativas del INDEC frente al Aislamiento Social, Preventivo y Obligatorio (ASPO), un factor que introduce márgenes de error más amplios en las estimaciones de ese período específico.

### Deflactación y Construcción de Ingresos Reales

Para permitir una comparación longitudinal precisa de los niveles de ingreso a lo largo de una década con alta volatilidad inflacionaria, se procedió a deflactar las variables nominales. Se construyó una matriz con la serie histórica del Índice de Precios al Consumidor (IPC) del INDEC para las regiones pampeana y metropolitana, emparejando cada año y aglomerado con su respectivo índice.

Mediante este cruce, variables clave como el Ingreso Total Individual (`P47T`) y el Ingreso Per Cápita Familiar (`IPCF`) fueron transformadas a precios constantes, tomando como base de referencia el nivel general de precios a diciembre de 2025 (`P47T_real`, `IPCF_real`).

### Detección de Valores Atípicos y Análisis Univariado

Una vez construidas las variables de ingreso real, se procedió a la depuración estadística de la base para corregir distorsiones en la distribución. El tratamiento a nivel univariado consistió en dos etapas metodológicas:

1. **Tratamiento de no respuesta y ceros:** se descartaron las observaciones correspondientes a encuestados que declararon no tener ingresos o que decidieron no responder a las preguntas de ingresos (valores nulos o inválidos), reteniendo exclusivamente los casos con ingresos reales estrictamente mayores a cero.
2. **Eliminación de outliers (método IQR):** dado que las variables económicas de ingresos presentan una distribución fuertemente asimétrica hacia la derecha (sesgo positivo), la presencia de sueldos extremadamente altos inflaba artificialmente las medidas de tendencia central. Para corregirlo, se aplicó el método del Rango Intercuartílico (IQR) agrupado por año y aglomerado. Se calculó el primer (Q1) y tercer cuartil (Q3), y se eliminaron todas las observaciones que superaban el límite superior ($Q3 + 1.5 \times IQR$).

### Exploración Visual de los Datos

La aplicación de estos filtros permitió consolidar una base de datos robusta. La exploración visual inicial mediante histogramas de ingresos reales confirmó la asimetría positiva esperada del mercado laboral, donde la gran mayoría de la población concentra sus ingresos en los estratos más bajos, evidenciando una caída progresiva en las frecuencias a medida que aumenta el nivel de ingresos. Asimismo, los gráficos validaron el éxito de la poda de valores atípicos, truncando la extensa cola derecha de la distribución sin comprometer la masa principal de la muestra de GBA y Gran Córdoba.

---

## `02-exploracion.R`

### Análisis Multivariado y Evolución Histórica

Para el desarrollo del análisis multivariado, se evaluó la trayectoria de la mediana del ingreso total individual a precios constantes de diciembre de 2025, desagregando la muestra según la variable de sexo. Se priorizó el uso de la mediana como medida de tendencia central para garantizar una representación estadística precisa del trabajador típico, mitigando las distorsiones que los sueldos más altos generarían sobre el promedio tradicional debido a la fuerte asimetría de la distribución.

La visualización longitudinal del período 2016-2025 evidencia una brecha salarial de género estructural y persistente en los aglomerados del Gran Buenos Aires y el Gran Córdoba. A lo largo de la década analizada, la curva correspondiente a los ingresos de los varones se posiciona de manera sostenida por encima de la curva de las mujeres. Adicionalmente, las fluctuaciones interanuales en ambas trayectorias reflejan el impacto directo de los ciclos macroeconómicos sobre el poder adquisitivo real, exponiendo caídas y recuperaciones que afectan a ambos grupos de forma sincronizada, pero sin lograr achicar la disparidad de ingresos base.
