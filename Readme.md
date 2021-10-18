# Análisis descriptivo de incendios en España 2001-2015
## _Gráfico interactivo en R-Shiny_
### Objetivo
Dentro de un estudio sobre los incendios en España, necesitaba contrastar las siguientes hipótesis:
- La mayoría de incendios suceden en verano debido al aumento de las temperaturas y la ausencia de lluvias.
- La mayoría de los incendios suceden en la mitad sur de la península al ser clima más seco y en Galicia por los incendios intencionados.
- Cada vez hay más incendios debido al cambio climático o la falta de recursos.

Necesitaba que los gráficos fueran interactivos y en una herramienta _open source_. Tras evaluar diferentes opciones, opté por realizar un análisis descriptivo utilizando Shiny en R, creando un cuadro de mando interactivo en web en el que el usuario puede modificar diferentes parámetros y se visualizan los cambios de inmediato.

##### Evaluación
Este proyecto se ha presentado como Trabajo de Visualización Avanzada en el máster en Big Data & Data Science impartido en la Universidad Complutense de Madrid en el curso 20/21, siendo evaluado con un **10**.

### Tecnologías utilizadas
Para llevar a cabo el proyecto se han utilizado las siguientes herramientas:
- Lenguaje R y RStudio.
- Paquete Shiny de RStudio.
- Librería _leaflet_ para visualizar el mapa.
- Otras librerías como _dplyr_, _DT_, _shinyWidgets_, _viridis_, _ggrepel_ o _ggplot2_.

Los datos de incendios son de acceso público y los proporciona el Ministerio de Agricultura.
### Descripción
Se van a analizar datos de la Estadística General de Incendios Forestales (EGIF) que contiene información recogida en los Partes de Incendio. Recoge datos de más de 82.000 incendios ocurridos en España desde 2001 hasta 2015. Incluye superficie quemada, coordenadas, localización, fecha o causa del incendio entre otros.

![hipotesis.png](https://www.dropbox.com/s/qwq1y69qk9byoqm/hipotesis.png?dl=0&raw=1)
Antes de comenzar el análisis se han completado los valores nulos, corregido puntos geográficos y creado campos nuevos como zona y tipo de incendio.

Al ejecutar la aplicación, en primer lugar se muestra un mapa de España con la ubicación de todos los incendios ocurridos en el periodo. El usuario puede filtrar por zona geográfica y por fecha. Al seleccionar un incendio, una ventana emergente proporciona información detallada sobre el mismo.

![portada2.png](https://www.dropbox.com/s/nmnfy3juixhmbi4/portada2.png?dl=0&raw=1)

Se ha añadido una ventana en la que se pueden visualizar y filtrar todos los datos contenidos en el dataset, con todas las columnas de interés para nuestro análisis.

![tablas.png](https://www.dropbox.com/s/hjcggrmm5xtb1ly/tablas.png?dl=0&raw=1)
Para contrastar la primera hipótesis representamos el número de incendios anual por trimestres comprobando que, frente a lo asumido, ocurren más incendios en invierno que en verano y que existe un comportamiento estacional.

![analisis1.png](https://www.dropbox.com/s/xv4nqrifew7hptq/analisis1.png?dl=0&raw=1)
Al analizar el porcentaje de incendios cada mes comprobamos que el mes con más incendios es marzo seguido de agosto.

![analisis2.png](https://www.dropbox.com/s/mkv74kr7ealu2m8/analisis2.png?dl=0&raw=1)
Nuestra segunda hipótesis plantea que la mayoría de los incendios ocurren en la mitad sur de la península al ser el clima más seco, sin embargo observamos que el 65% de los incendios de la muestra sucedieron en la zona Noroeste, lo cual es inesperado y nos lleva a profundizar en el análisis de esta zona y estudiamos la causa de los incendios.

![analisis3.png](https://www.dropbox.com/s/krz3m4lx7tuwezf/analisis3.png?dl=0&raw=1)
Como hemos observado, el 84% de los incendios son provocados por la acción del hombre y por motivos culturales relacionados con la agricultura y la ganadería. Por otra parte, contrario a lo que nos podíamos imaginar, sólo el 5% de los incendios son causados por pirómanos.

Para contrastar la última de nuestras hipótesis de partida representamos la superficie quemada y el número de incendios anuales. Observamos que salvo en 2012, que es cuando más superficie quemada se produjo en toda la serie, la tendencia tanto del número de incendios como de superficie quemada es descendente.

![analisis4.png](https://www.dropbox.com/s/9un0xjozhlmysmo/analisis4.png?dl=0&raw=1)

También representamos el índice de gravedad, que se define como el porcentaje de superficie forestal afectada por incendios respecto a la total existente, observándose una tendencia descendente, lo cual es un indicador de mejora.

![analisis5.png](https://www.dropbox.com/s/yskcehqv4jjgutw/analisis5.png?dl=0&raw=1)

Para profundizar en el análisis he ideado un ratio que resulta de dividir la superficie quemada entre el número de incendios, observándose que cada vez se queman más hectáreas por incendio. Un motivo que puede explicar este fenómeno es la aparición de los incendios de sexta generación, en los que la masa de combustible es tan grande que el fuego modifica las condiciones meteorológicas y son inapagables. Con el cambio climático y el abandono del medio rural, cada vez irán a más.

![analisis6.png](https://www.dropbox.com/s/ahfq4d15x9qz97h/analisis6.png?dl=0&raw=1)

Para finalizar, se muestran las conclusiones a las que hemos llegado y algunas de las medidas que se podrían tomar para reducir los incendios.

![conclusiones.png](https://www.dropbox.com/s/bjii4e58v96k10b/conclusiones.png?dl=0&raw=1)

También se indican cosas a mejorar en la propia herramienta que he creado con la librería de _Shiny_.

### Instalación
Para ejecutar la aplicación se requiere tener instalado RStudio y cargar tanto el fichero server.R como el fichero ui.R. Todos los ficheros facilitados deben estar en la misma carpeta y es importante que la ruta a esa carpeta no contenga espacios en blanco porque entonces la aplicación no cargará.

Una vez en RStudio y seguidos los pasos anteriores, hay que pulsar en Run App y la aplicación se ejecutará en el navegador.

### Autor
**Pablo Oliva Gómez**
- [Perfil](https://github.com/pabl0liva "Pablo Oliva")
- [Email](mailto:pabloliva@gmail.com "¡Hola!")
- [LinkedIn](https://www.linkedin.com/in/pabloliva/ "Bienvenidos")

### Licencia
Este proyecto está bajo la Licencia MIT - mira el archivo [LICENSE](LICENSE) para más detalles.