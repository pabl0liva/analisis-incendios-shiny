library(dplyr)
library(leaflet)
library("readxl")
library(DT)
library(shinyWidgets)
library(ggplot2)
library(wesanderson)
library(viridis)
library(ggrepel)

# Importamos los datos y los limpiamos

bb_data <- read_excel("incendios.xlsx")
bb_data <- data.frame(bb_data)
bb_data$latitude <-  as.numeric(bb_data$latitude)
bb_data$longitude <-  as.numeric(bb_data$longitude)
bb_data = filter(bb_data, latitude != "NA") # removing NA values
bb_data$fecha = as.Date(bb_data$fecha)
bb_data$month = as.factor(bb_data$month)
bb_data$month = factor(bb_data$month, levels = c("enero", "febrero", "marzo", "abril", "mayo",
                                                 "junio", "julio", "agosto", "septiembre", "octubre",
                                                 "noviembre", "diciembre"))

# creamos una nueva columna para la etiqueta de los puntos en el mapa

bb_data <- mutate(bb_data, cntnt = paste0('<strong>Municipio: </strong> ', municipio,
                                          '<br><strong>Provincia:</strong> ', idprovincia,
                                          '<br><strong>CCAA:</strong> ', idcomunidad,
                                          '<br><strong>Zona:</strong> ', zona,
                                          '<br><strong>Fecha:</strong> ', format(bb_data$fecha,"%d/%m/%Y"),
                                          '<br><strong>Categoría:</strong> ', tipoincendio,
                                          '<br><strong>Superficie (ha):</strong> ', superficie,
                                          '<br><strong>Causa:</strong> ', causa,
                                          '<br><strong>Horas controlarlo:</strong> ', time_ctrl,
                                          '<br><strong>Horas extinguirlo:</strong> ', time_ext,
                                          '<br><strong>Personal:</strong> ', personal,
                                          '<br><strong>Medios:</strong> ', medios)) 

bb_data_fil = filter(bb_data, fecha >= "2012-01-01")
bb_data_map = bb_data_fil = filter(bb_data, fecha >= "2012-01-01")

# Creamos una paleta de colores para las zonas
pal <- colorFactor(palette = c("dodgerblue4", "chocolate1", "brown2", "aquamarine4"), 
                   domain = c("Noroeste", "Interior", "Mediterráneo", "Canarias"))

# Preparamos los datos para la gráfica barmonth
# Creamos una función para transformar los datos y crear la etiqueta
porcent <- function(bbdd) {
  
  perc <- bbdd %>%
            group_by(month) %>%
            summarise(total = length(causa)) %>%
            summarize(
              month,
              total,
              porcentaje = round(total/sum(total)*100, 0),
              etiqueta = paste0(porcentaje, "%"))
  
  #perc$porcentaje = round(perc$porcentaje, 0)
  perc
}

# Preparamos los datos para la gráfica trimestres
# Creamos una función para transformar los datos y dibujar las paralelas
paralelas <- function(bbdd) {
  
  parall <- as.data.frame(table(bbdd$trimestre, bbdd$year))
  parall$Var1 <- as.numeric(parall$Var1)
  names(parall) = c("trimestre", "year", "Freq")
  parall

  }

# Extraemos los datos para la gráfica de superficie quemada por zona
zona_sup <- bb_data %>%
  group_by(zona) %>%
  summarise(total = sum(superficie)) %>%
  summarize(
    zona,
    total,
    porcentaje = total/sum(total)*100) %>%
  arrange(desc(porcentaje))

zona_sup$porcentaje = round(zona_sup$porcentaje, 1)
zona_sup$zona = as.factor(zona_sup$zona)
zona_sup$zona = factor(zona_sup$zona, levels = c("Noroeste", "Interior", "Mediterráneo", "Canarias"))

# Extraemos los datos para la gráfica de incendios por zona
zona_num <- bb_data %>%
  group_by(zona) %>%
  summarise(total = length(zona)) %>%
  summarize(
    zona,
    total,
    porcentaje = total/sum(total)*100) %>%
  arrange(desc(porcentaje))

zona_num$porcentaje = round(zona_num$porcentaje, 1)
zona_num$zona = as.factor(zona_num$zona)
zona_num$zona = factor(zona_num$zona, levels = c("Noroeste", "Interior", "Mediterráneo", "Canarias"))

# Extraemos los datos para la gráfica de incendios en la zona Noroeste
noroeste <- bb_data %>%
  filter(zona == "Noroeste") %>%
  group_by(causa) %>%
  summarise(total = length(causa)) %>%
  summarize(
    causa,
    total,
    porcentaje = total/sum(total)*100) %>%
  arrange(porcentaje)

noroeste$porcentaje = round(noroeste$porcentaje, 0)
noroeste <- arrange(noroeste, porcentaje)
noroeste$causa <- factor(noroeste$causa, levels = noroeste$causa)

# Extraemos los datos para las gráficas de aumento de incendios
baraumen_data <- bb_data %>%
  group_by(year) %>%
  summarise(numero = length(year),
            superficie = sum(superficie)) %>%
  summarize(
    year,
    numero,
    superficie,
    porcentaje_num = round(numero/sum(numero)*100,2),
    porcentaje_sup = round(superficie/sum(superficie)*100,2),
    ind_gravedad = round((superficie/26280281.4)*100,2),
    ratio = round(superficie/numero,0),
    etiqueta_num = paste0(porcentaje_num, "%"),
    etiqueta_sup = paste0(porcentaje_sup, "%"),
    etiqueta_indice = (paste0(ind_gravedad, "%"))) %>%
  arrange(year)

# Shiny server
shinyServer(function(input, output, session) {
  
  # cuando pulsamos los botones del mapa se ejecuta este código
  reactive_buttons <- reactive({
    
    if (input$zonas == "Todas las zonas") {
      bb_data_map = bb_data_fil
    } else {
      
      if (input$zonas == "Noroeste") {
        bb_data_map = filter(bb_data_fil, zona == "Noroeste")
      } else {
        
        if (input$zonas == "Interior") {
          bb_data_map = filter(bb_data_fil, zona == "Interior")
        } else {
          
          if (input$zonas == "Mediterráneo") {
            bb_data_map = filter(bb_data_fil, zona == "Mediterráneo")
          } else {
            
            bb_data_map = filter(bb_data_fil, zona == "Canarias")
          }
          
        }
        
      }
      
    }
    
    bb_data_map = filter(bb_data_map, fecha >= input$fechas[1])
    bb_data_map = filter(bb_data_map, fecha <= input$fechas[2])
    
  })
  
  # Reactivo para transformar los datos en función de los botones de las gráficas
  transformacion <- reactive({
    
    if (input$zonas_graf == "Todas las zonas") {
      bb_data_graf = bb_data
      
    } else {
      
      if (input$zonas_graf == "Noroeste") {
        bb_data_graf = filter(bb_data, zona == "Noroeste")
        
      } else {
        
        if (input$zonas_graf == "Interior") {
          bb_data_graf = filter(bb_data, zona == "Interior")
          
        } else {
          
          if (input$zonas_graf == "Mediterráneo") {
            bb_data_graf = filter(bb_data, zona == "Mediterráneo")
            
          } else {
            
            bb_data_graf = filter(bb_data, zona == "Canarias")
            
          }
          
        }
        
      }
      
    }
    
    if (input$causas == "Todas las causas") {
      bb_data_graf
      
    } else {
      
      if (input$causas == "Intencionado") {
        bb_data_graf = filter(bb_data_graf, causa == "Intencionado")
        
      } else {
        
        if (input$causas == "Desconocido") {
          bb_data_graf = filter(bb_data_graf, causa == "Desconocido")
          
        } else {
          
          if (input$causas == "Negligencia") {
            bb_data_graf = filter(bb_data_graf, causa == "Negligencia")
            
          } else {
            
            if (input$causas == "Reproducción") {
              bb_data_graf = filter(bb_data_graf, causa == "Reproducción")
              
            } else {
              
              bb_data_graf = filter(bb_data_graf, causa == "Rayo")
              
            }
            
          }
          
        }
        
      }
      
    }
    
    bb_data_graf = filter(bb_data_graf, fecha >= input$fechas_graf[1])
    bb_data_graf = filter(bb_data_graf, fecha <= input$fechas_graf[2])
    
    bb_data_graf %>% filter(idcomunidad %in% input$ccaa)
    
  })
  
  reactive_buttons_graf_perc <- reactive({
    
    bb_data_graf <- transformacion()
    perc <- porcent(bb_data_graf)
    
  })
  
  reactive_buttons_graf_parall <- reactive({
    
    bb_data_graf <- transformacion()
    parall <- paralelas(bb_data_graf)
    
  })
  
  # creamos un objeto reactivo para actualizar las CCAA en función de la zona (gráficas)
  observeEvent(input$zonas_graf, {
    bb_data_picker = bb_data
    if (input$zonas_graf == "Todas las zonas") {
      updatePickerInput(session = session, inputId = "ccaa", 
                        choices = as.character(sort(as.factor(unique(bb_data_picker$idcomunidad)))),
                        selected = as.character(sort(as.factor(unique(bb_data_picker$idcomunidad)))))
    }
    
    if (input$zonas_graf == "Noroeste") {
      bb_data_picker = filter(bb_data, zona == input$zonas_graf)
      updatePickerInput(session = session, inputId = "ccaa", 
                        choices = as.character(sort(as.factor(unique(bb_data_picker$idcomunidad)))), 
                        selected = as.character(sort(as.factor(unique(bb_data_picker$idcomunidad)))))
    }
    
    if (input$zonas_graf == "Interior") {
      bb_data_picker = filter(bb_data, zona == input$zonas_graf)
      updatePickerInput(session = session, inputId = "ccaa", 
                        choices = as.character(sort(as.factor(unique(bb_data_picker$idcomunidad)))), 
                        selected = as.character(sort(as.factor(unique(bb_data_picker$idcomunidad)))))
    }
    
    if (input$zonas_graf == "Mediterráneo") {
      bb_data_picker = filter(bb_data, zona == input$zonas_graf)
      updatePickerInput(session = session, inputId = "ccaa", 
                        choices = as.character(sort(as.factor(unique(bb_data_picker$idcomunidad)))), 
                        selected = as.character(sort(as.factor(unique(bb_data_picker$idcomunidad)))))
    }
    
    if (input$zonas_graf == "Canarias") {
      updatePickerInput(session = session, inputId = "ccaa", 
                        choices = c("Canarias"), 
                        selected = c("Canarias"))
    }
  }, ignoreInit = TRUE)
  
  # creamos el mapa con leaflet
  output$bbmap <- renderLeaflet({
      
      leaflet(bb_data_map) %>% 
      addProviderTiles("CartoDB.Positron") %>% # elegimos este mapa por estética
      addCircles(lng = ~longitude, lat = ~latitude) %>% 
      addCircleMarkers(data = bb_data_map, lat =  ~latitude, lng = ~longitude, 
                       radius = 3, 
                       popup = ~as.character(cntnt), 
                       color = ~pal(zona),
                       stroke = FALSE, 
                       fillOpacity = 0.8) %>%
      addLegend(pal = pal, values = bb_data_fil$zona, opacity = 1, na.label = "Sin ubicación")
        })
  
  # evento que se activa cuando pulsamos los botones del mapa
  observeEvent(reactive_buttons(), {
    
      leafletProxy("bbmap", data = reactive_buttons()) %>%
      clearMarkers() %>%
      clearShapes() %>%
      addCircles(lng = ~longitude, lat = ~latitude) %>% 
      addCircleMarkers(data = reactive_buttons(), lat =  ~latitude, lng = ~longitude, 
                       radius = 3, popup = ~as.character(cntnt), 
                       color = ~pal(zona),
                       stroke = FALSE, fillOpacity = 0.8)
  })

   # objeto para mostrar los datos como tabla en Datos
   output$data <- DT::renderDataTable(datatable(
       bb_data[,c(-1:-4,-17:-22)],
       filter = list(position = 'top'),
       colnames = c("Municipio", "Provincia", "CCAA", "Zona", "Fecha", "Categoría",
                    "Superficie afectada (ha)", "Causa", "Horas controlarlo", "Horas extinguirlo",
                    "Personal", "Medios")
   ))

   # Creamos objetos para representar las gráficas
   
   # Gráfica de líneas paralelas de incendios anuales por trimestre
   output$trimes <- renderPlot({
     
     ggplot(data = reactive_buttons_graf_parall(), aes(x = trimestre, y = Freq , by = year, color = year)) +
       geom_line(show.legend = FALSE) +
       xlab("Trimestres") + ylab("") + ggtitle("Número de incendios cada año en trimestres") +
       scale_y_continuous(breaks = NULL) +
       theme_minimal() +
       scale_color_viridis(discrete = TRUE, option = "turbo") +
       theme(plot.title = element_text(hjust = 0, size = 18), axis.text = element_text(size = 16),
             panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
       geom_text_repel(data = reactive_buttons_graf_parall() %>% filter(trimestre == 1),
                       aes(label = year),
                       show.legend = FALSE,
                       max.overlaps = 10)
   })
   
   # Gráfica de barras porcentaje de incendios cada mes
   output$barmonth <- renderPlot({
     
     ggplot(data = reactive_buttons_graf_perc(), aes(x = month, y = porcentaje, fill = month)) +
        geom_bar(stat = "identity", show.legend = FALSE) +
        geom_label(aes(y = porcentaje, label = etiqueta), fill = "white", hjust = 0.5, vjust = 1.2,
                  show.legend = FALSE, colour = "black", fontface = "bold") +
        scale_y_continuous(breaks = NULL) +
        xlab("") + ylab("") + ggtitle("Porcentaje de incendios cada mes") +
        theme_minimal() +
        scale_fill_manual(values = wes_palette(12, name = "IsleofDogs1", type = "continuous"), name = "") +
        theme(plot.title = element_text(hjust = 0, size = 18), axis.text = element_text(size = 16),
             panel.grid.major = element_blank(), panel.grid.minor = element_blank())
   })
   
   # Gráfica de barras porcentaje de incendios por zona
   output$barbinc <- renderPlot({
     
     ggplot(data = zona_num, aes(x = zona, y = porcentaje, fill = zona)) +
       geom_bar(stat = "identity", show.legend = FALSE, width = 0.8) +
       geom_text(aes(label = paste0(porcentaje,"%")), hjust = 0.5, vjust = -0.3, size = 6) +
       scale_y_continuous(labels = scales::percent_format(scale = 1, accuracy = 1)) +
       xlab("") + ylab("") + ggtitle("Porcentaje de incendios por zona") +
       theme_minimal() +
       scale_fill_manual(values = c("aquamarine4", "chocolate1", "brown2", "dodgerblue4")) +
       theme(plot.title = element_text(hjust = 0.5, size = 18), axis.text = element_text(size = 12),
             panel.grid.major = element_blank(), panel.grid.minor = element_blank())
   })
   
   # Gráfica de barras porcentaje de superficie quemada por zona
   output$barburn <- renderPlot({
     
     ggplot(data = zona_sup, aes(x = zona, y = porcentaje, fill = zona)) +
       geom_bar(stat = "identity", show.legend = FALSE, width = 0.8) +
       geom_text(aes(label = paste0(porcentaje,"%")), hjust = 0.5, vjust = -0.3, size = 6) +
       scale_y_continuous(labels = scales::percent_format(scale = 1, accuracy = 1)) +
       xlab("") + ylab("") + ggtitle("Porcentaje de superficie quemada por zona") +
       theme_minimal() +
       scale_fill_manual(values = c("aquamarine4", "chocolate1", "brown2", "dodgerblue4")) +
       theme(plot.title = element_text(hjust = 0.5, size = 18), axis.text = element_text(size = 12),
             panel.grid.major = element_blank(), panel.grid.minor = element_blank())
   })
   
   # Gráfica de barras horizontal causa incendios en el noroeste
   output$barhori <- renderPlot({
     
     ggplot(data = noroeste, aes(x = causa, y = porcentaje, fill = causa)) +
       geom_bar(stat = "identity", show.legend = FALSE, width = 0.8) +
       coord_flip() +
       geom_text(aes(label = paste0(porcentaje,"%"), hjust = -0.2, vjust = 0.5)) +
       scale_y_continuous(labels = scales::percent_format(scale = 1, accuracy = 1)) +
       xlab("") + ylab("") + ggtitle("Noroeste: causa de los incendios (%)") +
       theme_minimal() +
       scale_fill_manual(values = wes_palette(5, name = "GrandBudapest1", type = "continuous"), name = "") +
       theme(plot.title = element_text(hjust = 0.5, size = 18), axis.text = element_text(size = 12),
             panel.grid.major = element_blank(), panel.grid.minor = element_blank())
   })
   
   # Gráfica de total incendios y superficie quemada
   output$baraumen1 <- renderPlot({
     
     ggplot(data = baraumen_data, aes(x = year, y = porcentaje_sup)) +
       geom_bar(stat = "identity",
                show.legend = FALSE,
                fill = "chocolate3") +
       geom_smooth(method = "lm",
                   se = FALSE, aes(x = year, y = porcentaje_num),
                   colour = "dodgerblue4", size = 1.3, 
                   linetype = "longdash") +
       geom_line(aes(y = porcentaje_num),
                 stat = "identity",
                 show.legend = FALSE,
                 color = "dodgerblue4",
                 size = 1.6) +
       scale_y_continuous(labels = scales::percent_format(scale = 1, accuracy = 1)) +
       xlab("") + ylab("") + ggtitle("Superficie quemada y número de incendios (%)") +
       theme_minimal() +
       theme(plot.title = element_text(hjust = 0, size = 18), axis.text = element_text(size = 12),
             panel.grid.minor = element_blank()) +
       scale_x_continuous(labels = as.character(baraumen_data$year), breaks = baraumen_data$year)
     
   })
   
   # Gráfica índice de gravedad
   output$baraumen2 <- renderPlot({
     
     ggplot(data = baraumen_data, aes(x = year, y = ind_gravedad)) +
       geom_hline(yintercept = 0.42, color = "azure4", size = 0.5) +
       geom_smooth(method = "lm", se = FALSE, colour = "dodgerblue4",
                   size = 1.3, linetype = "longdash") +
       geom_line(stat = "identity",
                 show.legend = FALSE, 
                 size = 1.5,
                 color = "dodgerblue4") +
       geom_text_repel(aes(label = etiqueta_indice),
                       show.legend = FALSE) +
       scale_y_continuous(breaks = NULL) +
       xlab("") + ylab("") + ggtitle("Evolución del índice de gravedad (%)") +
       theme_minimal() +
       theme(plot.title = element_text(hjust = 0, size = 18), axis.text = element_text(size = 12),
             panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
       scale_x_continuous(labels = as.character(baraumen_data$year), breaks = baraumen_data$year)
     
   })
   # Gráfica ratio superficie quemada entre número de incendios
   output$baraumen3 <- renderPlot({
     
     ggplot(data = baraumen_data, aes(x = year, y = ratio)) +
       geom_hline(yintercept = 20, color = "azure4", size = 0.5) +
       geom_smooth(method = "lm", se = FALSE, 
                   colour = "dodgerblue4", size = 1.3, 
                   linetype = "longdash") +
       geom_line(stat = "identity",
                 show.legend = FALSE, 
                 size = 1.5,
                 color = "dodgerblue4") +
       geom_text_repel(aes(label = ratio),
                       show.legend = FALSE) +
       scale_y_continuous(breaks = NULL) +
       xlab("") + ylab("") + ggtitle("Ratio Superficie quemada/Número de incendios") +
       theme_minimal() +
       theme(plot.title = element_text(hjust = 0, size = 18), axis.text = element_text(size = 12),
             panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
       scale_x_continuous(labels = as.character(baraumen_data$year), breaks = baraumen_data$year)
     
   })
   
})
