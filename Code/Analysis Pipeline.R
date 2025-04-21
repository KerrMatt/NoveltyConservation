#### Analysis Code for [[manuscript name]]
# Author: M R Kerr
# Contact: matthew.kerr@bio.au.dk
# Description: Analysis pipeline for analysing conservation status of areas based on LIFE, Novelty, and Red List.

# Set up ----

## Clear space if starting fresh
rm(list = ls())

## Be projection smart
proj <- "+proj=moll +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
sf::sf_use_s2(F)

# Library load ----
## General quality of life
library(tidyverse)
library(data.table)

## Spatial
library(terra)
library(tidyterra)
library(sf)

## Visual
library(scico)
library(patchwork)

# Data load ----
## All layers loaded in will be resampled to the nov_total layer

## Novelty layers ----
# From Kerr et al 2025, downloaded from zenodo.org/records/14677612
nov.clim <- rast("Input Data/Novelty/NOVELTY_CLIMATE.tif")
nov.defa <- rast("Input Data/Novelty/NOVELTY_DEFAUNATION.tif")
nov.flor <- rast("Input Data/Novelty/NOVELTY_DISRUPTION.tif")

nov.total <- rast("Input Data/Novelty/NOVELTY_TOTAL.tif")

## LIFE metric ----
life.reduction <- rast("Input Data/LIFE Eyres et al 2025/Eyres_et_al_2025/scaled_arable_0.25.tif")
life.conversion <- rast("Input Data/LIFE Eyres et al 2025/Eyres_et_al_2025/scaled_restore_0.25.tif")

## IUCN Red List data ----
rl.mammal <- read_sf("Input Data/Red List/Mammals/MAMMALS_TERRESTRIAL_ONLY.shp") %>%
  sf::st_transform(., proj)
rl.amphibian <- rbind(read_sf("Input Data/Red List/Amphibians/AMPHIBIANS_PART1.shp"),
                      read_sf("Input Data/Red List/Amphibians/AMPHIBIANS_PART2.shp")) %>%
  sf::st_transform(., proj)
rl.reptile <- rbind(read_sf("Input Data/Red List/Reptiles/REPTILES_PART1.shp"),
                    read_sf("Input Data/Red List/Reptiles/REPTILES_PART2.shp")) %>%
  sf::st_transform(., proj)

# Birds need the category added
rl.bird <- read_sf(dsn = "Input Data/Red List/Birds/BOTW_2024_2.gpkg") %>%
  sf::st_transform(., proj)
rl.bird.meta <- readxl::read_xlsx("Input Data/Red List/Birds/HBW-BirdLife Checklist v9 Oct24/HBW-BirdLife Checklist v9 Oct24/HBW_BirdLife_List of Birds_v.9.xlsx")
rl.bird.meta$sci_name <- rl.bird.meta$`Scientific name`

rl.bird <- left_join(rl.bird, rl.bird.meta, by = "sci_name")
rl.bird$category <- rl.bird$`2024 IUCN Red List category`

## Blank background raster

base_raster <- nov_total
base_raster[] <- NA

# Analysis one: 