library(dplyr)
library(leaflet)
library("readxl")
library(DT)
library(shinyWidgets)

# Importamos los datos y los limpiamos

bb_data <- read_excel("incendios.xlsx")
bb_data <- data.frame(bb_data)
bb_data$latitude <-  as.numeric(bb_data$latitude)
bb_data$longitude <-  as.numeric(bb_data$longitude)
bb_data = filter(bb_data, latitude != "NA") # eliminamos NAs
bb_data$fecha = as.Date(bb_data$fecha)
bb_data_fil = filter(bb_data, fecha >= "2012-01-01")
inc_min_fecha = as.Date(min(bb_data$fecha),"%Y-%m-%d")
inc_max_fecha = as.Date(max(bb_data$fecha),"%Y-%m-%d")
inc_min_date = as.Date(min(bb_data_fil$fecha),"%Y-%m-%d")
inc_max_date = as.Date(max(bb_data_fil$fecha),"%Y-%m-%d")

fluidPage(
  # Página principal
  navbarPage("Incendios en España 2001-2015", id = "main",
           # pestaña de Mapa
           tabPanel("Mapa", icon = icon("globe-americas"),
                    leafletOutput("bbmap", height = 1000),
                    absolutePanel(top = 80, left = 90,
                                  width = 250, fixed = TRUE,
                                  draggable = TRUE,
                                  style = "z-index:500; min-width: 200px;",
                                  # selector de zonas
                                  selectInput(inputId = "zonas",
                                              label = "Selecciona la zona:",
                                              selected = "Todas las zonas",
                                              multiple = FALSE,
                                              choices = list("Todas las zonas", 
                                                             "Noroeste", "Interior", "Mediterráneo", "Canarias")),
                                  span(h6("Las zonas agrupan similares condiciones meteorológicas,
                                            topográficas, vegetación o factores socioeconómicos."),
                                       style = "color:gray45"),
                                  hr(),
                                  # selector de fechas
                                  chooseSliderSkin(skin = "Flat",
                                                   color = "Grey"
                                                   ),
                                  sliderInput(inputId = "fechas", 
                                              label = "Rango de fechas:",
                                              min = inc_min_date, 
                                              max = inc_max_date,
                                              value = c(inc_min_date,inc_max_date),
                                              ticks = FALSE,
                                              step = 30,
                                              timeFormat = "%b %Y"),
                                  span(h6("En el mapa únicamente se muestran datos desde 2012 por fluidez."),
                                       style = "color:gray45")
                                  )
                    ),
           # pestaña Datos
           tabPanel("Datos", DT::dataTableOutput("data")),
           # pestañas de Análisis
           navbarMenu("Análisis", icon = icon("chart-bar"),
                   tabPanel("Hipótesis inicial",includeMarkdown("hipotesis.md")),
                   tabPanel("Análisis temporales",
                            sidebarLayout(
                              sidebarPanel(
                                span(h6("Selecciona diferentes valores para visualizarlos en las gráficas."),
                                     style = "color:gray18"),
                                # selector de zonas
                                selectInput(inputId = "zonas_graf",
                                            label = "Selecciona la zona:",
                                            selected = "Todas las zonas",
                                            multiple = FALSE,
                                            choices = list("Todas las zonas", 
                                                           "Noroeste", "Interior", "Mediterráneo", "Canarias")),
                                span(h6("Las zonas agrupan similares condiciones meteorológicas,
                                            topográficas, vegetación o factores socioeconómicos."),
                                     style = "color:gray45"),
                                hr(),
                                # selector de comunidad autónoma
                                pickerInput(inputId = "ccaa",
                                            label = "Selecciona la Comunidad Autónoma:",
                                            choices = as.character(sort(as.factor(unique(bb_data$idcomunidad)))),
                                            options = list(`actions-box` = TRUE, `none-selected-text` = "Por favor, 
                                                           selecciona una o varias opciones"),
                                            selected = as.character(sort(as.factor(unique(bb_data$idcomunidad)))),
                                            multiple = TRUE),
                                span(h6("Puedes seleccionar una o varias comunidades autónomas simultáneamente. Las
                                        provincias de León y Zamora pertenecen a la zona Noroeste."),
                                     style = "color:gray45"),
                                hr(),
                                # selector de causa del incendio
                                selectInput(inputId = "causas",
                                            label = "Selecciona la causa del incendio:",
                                            selected = "Todas las causas",
                                            multiple = FALSE,
                                            choices = list("Todas las causas", 
                                                           "Intencionado", "Desconocido", "Negligencia",
                                                           "Reproducción", "Rayo")),
                                span(h6("Los incendios causados por negligencias y los intencionados son
                                        debidos a la actividad humana. Los incendios de reproducción y por
                                        rayo se deben a causas naturales"),
                                     style = "color:gray45"),
                                hr(),
                                # selector de fechas
                                chooseSliderSkin(skin = "Flat",
                                                 color = "Grey"
                                ),
                                sliderInput(inputId = "fechas_graf", 
                                            label = "Rango de fechas:",
                                            min = inc_min_fecha, 
                                            max = inc_max_fecha,
                                            value = c(inc_min_fecha,inc_max_fecha),
                                            ticks = FALSE,
                                            step = 30,
                                            timeFormat = "%b %Y"),
                                span(h6("Se considera el dataset completo, de 2001 a 2015."),
                                     style = "color:gray45")
                              ),
                            mainPanel(
                              tabsetPanel(
                                # panel Trimestral con gráfica
                                tabPanel("Trimestral", 
                                         plotOutput(outputId = "trimes", height = 500),
                                         span(h3("Frente a lo supuesto, se observa que la serie temporal repite un
                                                 patrón con más incendios en invierno y en verano y descenso en
                                                 primavera y otoño."),
                                              style = "color:gray18")
                                         ),
                                # panel Mensual con gráfica
                                tabPanel("Mensual", 
                                         plotOutput(outputId = "barmonth", height = 500),
                                         span(h3("Si estudiamos la serie completa observamos que el mes con
                                                 más incendios es marzo (18%) seguido de agosto (15%). Hay tantos
                                                 incendios en febrero como en julio y septiembre (11%)."),
                                              style = "color:gray18")
                                         )
                                )
                              )  
                            )
                          ),
                   tabPanel("Análisis de las zonas",
                            span(h2("Análisis de las zonas"),
                                 style = "color:gray18"),
                            span(h4("Se representa el número total de incendios en cada zona,
                                      así como la superficie total quemada por zona."),
                                 style = "color:gray18"),
                            br(),
                            splitLayout(
                              plotOutput(outputId = "barbinc", width = "100%"),
                              plotOutput(outputId = "barburn", width = "100%")
                              ),
                            span(h3("La zona con más incendios (66%) es la Noroeste y representa el 51% de la
                                      superficie afectada. El Interior sufre el 24% de los incendios y 26% de la
                                      superficie quemada.
                                    
                                    En el Mediterráneo los incendios son más graves, pues representa un 20% de
                                      superficie quemada a pesar de tener el 9% de los incendios. Canarias no llega
                                      al 1% de incendios pero es un 3,5% de la superficie total quemada."),
                                 style = "color:gray18")
                            ),
                   tabPanel("¿Noroeste?",
                            fluidPage(
                              span(h2("¿Por qué tantos incendios en el Noroeste?"),
                                   style = "color:gray18"),
                              span(h4("Se representa el número de incendios en esta zona y las causas que
                                      los provocaron."),
                                   style = "color:gray18"),
                              br(),
                              fluidRow(
                                column(width = 6,
                                  plotOutput(outputId = "barhori", width = "100%")),
                                
                                column(width = 6,
                                         span(h4("Observamos que la actividad humana causa el 84% de los incendios,
                                                 ya sea intencionado o por negligencia."),
                                              align = "left"),
                                         span(h4("En esta zona los incendios intencionados son más del doble que en las
                                                 otras zonas (36% Interior y Canarias, 35% Mediterráneo)."),
                                              align = "left"),
                                         br(),
                                         h3("Los motivos son culturales:"),
                                         tags$ul(
                                           h4(tags$li("Quema de pastos (minifundios), antes de que el ganado vuelva al                                                       monte en primavera, para regenerar la vegetación.")),
                                           h4(tags$li("Los prados pastables están subvencionados por la PAC, para ello                                                       no debe haber  matorrales, se eliminan quemando.")),
                                           h4(tags$li("Las quemas deben ser autorizadas por las CCAA para poder                                                              controlarlas. Ante estos nuevos trámites y burocracia, se
                                                      prefiere prender fuego libremente y sin control.")),
                                           h4(tags$li("Los pirómanos sólo son causantes del 5% del total de los                                                              incendios."))
                                         )
                                      )
                                   )
                               )
                            ),
                   tabPanel("¿Aumentan los incendios?",
                            fluidPage(
                              span(h2("¿Están aumentando los incendios?"),
                                   style = "color:gray18"),
                              span(h4("Representamos la superficie quemada anual (barras naranjas) y el total de                                             incendios (línea azul)."),
                                   style = "color:gray18"),
                              br(),
                              plotOutput(outputId = "baraumen1", height = 700),
                              tags$ul(
                                h4(tags$li("Observamos que, salvo por la anomalía del año 2012 que es cuándo más                                                  superficie quemada se produjo en toda la serie, la tendencia tanto del                                                 número de incendios como de la superficie quemada es descendente.")),
                                ),
                              br(),
                              span(h4("Se muestra la evolución del índice de gravedad durante el periodo analizado.                                          Este índice se define como el porcentaje de superficie forestal afectada por                                           incendios respecto a la total existente."),
                                   style = "color:gray18"),
                              br(),
                              plotOutput(outputId = "baraumen2", height = 700),
                              tags$ul(
                                h4(tags$li("De nuevo, a pesar de los graves incendios del año 2012, observamos que la                                             tendencia del índice de gravedad es descendente lo cuál es un indicador de                                             mejora.")),
                                h4(tags$li("Otro factor que puede influir en la disminución de este índice es el hecho                                            de que cada año aumenta la superficie forestal total debido al abandono del                                            campo y a la despoblación."))
                              ),
                              br(),
                              span(h4("Se crea un ratio que resulta de dividir la superficie quemada entre el número de                                       incendios."),
                                   style = "color:gray18"),
                              br(),
                              plotOutput(outputId = "baraumen3", height = 700),
                              tags$ul(
                                h4(tags$li("Se observa que, aunque como vimos anteriormente tienden a disminuir tanto                                             la superficie quemada como el número de incendios, el ratio nos indica que                                             cada vez se queman más hectáreas por incendio.
                                           Un motivo que puede explicar este fenómeno es la aparición de los incendios                                            de sexta generación, en los que la masa de combustible es tan grande que el                                            fuego modifica las condiciones meteorológicas y son inapagables. Con el                                                cambio climático y el abandono del medio rural, cada vez irán a más.")),
                                h4(tags$li("El año 2012 provoca que la pendiente de la tendencia sea más acusada. Se ha                                            probado a eliminar este año y aún así la tendencia es positiva, por lo que                                             podemos considerar válida la interpretación anterior a lo largo del tiempo."                                 ))
                              )
                            )

                    )
           ),
           tabPanel("Conclusiones",includeMarkdown("conclusiones.md"))
           )
)
