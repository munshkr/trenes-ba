# Estadísticas sobre el servicio de trenes Mitre / Sarmiento / Roca #

## Scrapping ##

* Cada minuto, se obtiene del sitio del [Ministerio del Interior y
Transporte](http://trenes.mininterior.gov.ar/) los tiempos de arribo de cada
estación, para cada ramal, y el estado actual del servicio.  También se
obtienen por minuto las coordenadas de las formaciones.

* Cada semana se obtiene la tablilla de horarios del sitio web de [Mitre
Sarmiento S.A.](http://www.mitresarmiento.com.ar/).

## Instalación ##

Se requiere Ruby 1.9+. Luego ejecutar lo siguiente para instalar dependecias y
configurar Cron para comenzar a scrapear:

```bash
  $ bundle install
  $ whenever --write-crontab
```

En el directorio `data/` se irán guardando los CSVs con las respuestas *raw* de
los servicios.
