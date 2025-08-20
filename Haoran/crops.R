setwd("~/Dropbox/MonteCarlo/Haoran")
library(tidyverse)
library(readxl)

# Part I. Data visual

# n=6 field types: n=54 plots
fields <- read_excel("appendix_1.xlsx", sheet = 1, range = "A1:E55", col_names = T) |> select(1,2,4)
fields |>
    ggplot(aes(x = field_type, y = field_acreage, col = growth_per_year)) +
    geom_jitter(shape = 1, size = 3) +
    coord_flip() +
    theme_bw()

fs <- fields |> group_by(field_type) |> summarise(n()) |> pull(field_type)
plots <- fields |> pull(field_id)

# n=41 crops:
crops <- read_excel("appendix_1.xlsx", sheet = 2, range = "A1:D42", col_names = T)

grow_2023 <- read_excel("appendix_2.xlsx", sheet = 1, range = "B1:G88", col_names = T)

grow_2023 <- grow_2023 |> left_join(fields, "plot")

grow_2023 |>
    ggplot(aes(x = crop_name, y = field_id, fill = crop_type)) +
    geom_tile() +
    facet_wrap(~as.factor(season), nrow = 2)

yields_2023 <- read_excel("appendix_2.xlsx", sheet = 2, col_names = T, range = "A1:H108")

yields_2023 <- yields_2023 |>
    separate_wider_delim(price_per_jin, delim = "-", names = c("price_lo", "price_hi")) |>
    mutate(price_lo = as.numeric(price_lo), price_hi = as.numeric(price_hi))

yields_2023 <- yields_2023 |>
    mutate(net_low = jin_per_acr * price_lo - cost_per_acr, net_high = jin_per_acr * price_hi - cost_per_acr, net_mean = jin_per_acr * (price_lo + price_hi)/2 - cost_per_acr)

#pdf("yield_2023.pdf", width = 10, height = 8)
yields_2023 |>
    ggplot(aes(x = crop_name, y = net_mean, col = growth)) +
    geom_pointrange(aes(ymin = net_low, ymax = net_high)) +
    facet_wrap(~field_type, scale = "free") +
    coord_flip() +
    theme_bw()
#dev.off()

# net gain consistent, regardless of field types
#pdf("yield_2023.pdf", width = 10, height = 8)
png("yield_2023.png", width = 1000, height = 800)
yields_2023 |>
    ggplot(aes(x = crop_name, y = net_mean, col = field_type, shape = growth)) +
    geom_pointrange(aes(ymin = net_low, ymax = net_high), position = position_dodge(width = 1)) +
#    facet_wrap(~growth, scale = "free") +
    coord_flip() +
    scale_y_log10() +
    theme_bw()
dev.off()

# Part II. Expected results:
s1.wide <- grow_2023 |>
    filter(season == 1) |>
    select(1,3,5) |>
    pivot_wider(names_from = "crop_name", values_from = "acreage")

s2.wide <- grow_2023 |>
    filter(season == 2) |>
    select(1,3,5) |>
    pivot_wider(names_from = "crop_name", values_from = "acreage")

# Part III. Random picks
# for each crop, list all possible field type and growth (this is already given by the 2023 data)
# then, assign randomly to each plot
# for years 2024-2030 (7 years)

rand_assign_year <-  function(field){
    out <- list()
    plot <- fields$plot[field]
    cat(plot, "\t")
    plot_type <- fields$field_type[field]
    cat(plot_type, "\t")

    if(plot_type %in% c("平旱地", "山坡地", "梯田")) {
        crops.single <- yields_2023 |> filter(field_type == plot_type) |> pull(crop_name)
        pick.single <- sample(crops.single, 1)
        cat(pick.single, "\t", "NA\n")
        df.pick <- yields_2023 |> filter(field_type == plot_type & crop_name == pick.single) |> select(3:9) |>  mutate(plot = plot, disct.acr = 1)
        out[[length(out)+1]] <- df.pick 
    } else if(plot_type == "水浇地") {
        crops.water <- yields_2023 |> filter(field_type == plot_type) |> pull(crop_name)
        crop.pick <- sample(crops.water, 1)
        if(crop.pick == "水稻") {
            df.pick <- yields_2023 |> filter(field_type == plot_type & crop_name == crop.pick) |> select(3:9) |>  mutate(plot = plot, disct.acr = 1)
        out[[length(out)+1]] <- df.pick 
            cat(crop.pick, "\t", "NA\n")
        } else {
            crops.1st <- yields_2023 |> filter(field_type == plot_type & growth == "第一季") |> pull(crop_name)
            pick1 <- sample(crops.1st, 1)
            df.pick <- yields_2023 |> filter(field_type == plot_type & crop_name == pick1) |> select(3:9) |>  mutate(plot = plot, disct.acr = 1)
            out[[length(out)+1]] <- df.pick 
            crops.2nd <- yields_2023 |> filter(field_type == plot_type & growth == "第二季") |> pull(crop_name)
            pick2 <- sample(crops.2nd, 1)
            df.pick <- yields_2023 |> filter(field_type == plot_type & crop_name == pick2) |> select(3:9) |>  mutate(plot = plot, disct.acr = 1)
            out[[length(out)+1]] <- df.pick 
            cat(pick1, "\t", pick2, "\n")
        }
    } else if(plot_type == "普通大棚") { 
        crops.1st <- yields_2023 |> filter(field_type == plot_type & growth == "第一季") |> pull(crop_name) 
        pick1 <- sample(crops.1st, 1)
        df.pick <- yields_2023 |> filter(field_type == plot_type & crop_name == pick1) |> select(3:9) |>  mutate(plot = plot, disct.acr = 1)
        out[[length(out)+1]] <- df.pick 

        crops.2nd <- yields_2023 |> filter(field_type == plot_type & growth == "第二季") |> pull(crop_name)
        pick2 <- sample(crops.2nd, 1)
        df.pick <- yields_2023 |> filter(field_type == plot_type & crop_name == pick2) |> select(3:9) |>  mutate(plot = plot, disct.acr = 1)
        out[[length(out)+1]] <- df.pick 
        cat(pick1, "\t", pick2, "\n")
    } else { # 智慧大棚 (could be halved or whole for each season)
        crops.1st <- yields_2023 |> filter(field_type == "普通大棚" & growth == "第一季") |> pull(crop_name)
        divide <- rbinom(n=1, size = 1, prob = 0.5) 
        if(divide == 0) {
            pick1 <- sample(crops.1st, 1)
            df.pick <- yields_2023 |> filter(field_type == "普通大棚" & crop_name == pick1) |> select(3:9) |>  mutate(plot = plot, disct.acr = 1)
            out[[length(out)+1]] <- df.pick 
            cat(pick1, "\t")
        } else { # discount acreage by 1/2
            picks <- sample(crops.1st, 2)
            df.pick1 <- yields_2023 |> filter(field_type == "普通大棚" & crop_name == picks[1]) |> select(3:9) |>  mutate(plot = plot, disct.acr = 0.5)
            out[[length(out)+1]] <- df.pick1
            df.pick2 <- yields_2023 |> filter(field_type == "普通大棚" & crop_name == picks[2]) |> select(3:9) |>  mutate(plot = plot, disct.acr = 0.5)
            out[[length(out)+1]] <- df.pick2 
            cat(picks[1], "\t", picks[2], "\t")
        }

        crops.2nd <- yields_2023 |> filter(field_type == plot_type & growth == "第二季") |> pull(crop_name)
        divide <- rbinom(n=1, size = 1, prob = 0.5)
        if(divide == 0) {
            pick1 <- sample(crops.2nd, 1)
            df.pick <- yields_2023 |> filter(field_type == plot_type & crop_name == pick1) |> select(3:9) |>  mutate(plot = plot, disct.acr = 1)
            out[[length(out)+1]] <- df.pick 
            cat(pick1, "\n")
        } else {
            picks <- sample(crops.2nd, 2)
            df.pick1 <- yields_2023 |> filter(field_type == plot_type & crop_name == picks[1]) |> select(3:9) |>  mutate(plot = plot, disct.acr = 0.5)
            out[[length(out)+1]] <- df.pick1
            df.pick2 <- yields_2023 |> filter(field_type == plot_type & crop_name == picks[2]) |> select(3:9) |>  mutate(plot = plot, disct.acr = 0.5)
            out[[length(out)+1]] <- df.pick2 
            cat(picks[1], "\t", picks[2], "\n")
        }
    }
    return(bind_rows(out))
}

out.list <- lapply(1:54, \(x) rand_assign_year(x))
df1 <- bind_rows(out.list)

# Part IV. Define net yield per year and optimize with GA

df1 <- df1 |> left_join(fields, "plot")
df1 <- df1 |> mutate(net_lo = (jin_per_acr * price_lo - cost_per_acr) * field_acreage * disct.acr, net_hi = (jin_per_acr * price_hi - cost_per_acr) * field_acreage * disct.acr, net_mean = (jin_per_acr * (price_lo + price_hi)/2 - cost_per_acr) * field_acreage * disct.acr)
df1.sum <- df1 |> summarise(lo = sum(net_lo), hi = sum(net_hi), total = sum(net_mean))

# function for batch run
sim.crop <- function(iter){
    out.list <- lapply(1:54, \(x) rand_assign_year(x))
    df <- bind_rows(out.list)
    df <- df |> left_join(fields, "plot")
    df <- df |> mutate(net_lo = (jin_per_acr * price_lo - cost_per_acr) * field_acreage * disct.acr, net_hi = (jin_per_acr * price_hi - cost_per_acr) * field_acreage * disct.acr, net_mean = (jin_per_acr * (price_lo + price_hi)/2 - cost_per_acr) * field_acreage * disct.acr)
    df.sum <- df |> summarise(lo = sum(net_lo), hi = sum(net_hi), total = sum(net_mean)) |> mutate(rep = iter)
    return(df.sum)
}

out.list <- lapply(1:20, \(x) sim.crop(x))
df.out <- bind_rows(out.list)

# compare with 2023 yields
grow_acr <- grow_2023 |> group_by(crop_name, field_type) |> summarise(crop_acr = sum(field_acreage))

# not all crops has acreages:
df.2023 <- yields_2023 |> left_join(grow_acr, c("crop_name", "field_type")) |> filter(!is.na(crop_acr))

df.2023 <-  df.2023 |>  separate_wider_delim(price_per_jin, delim = "-", names = c("price_lo", "price_hi")) |> mutate(price_lo = as.numeric(price_lo), price_hi = as.numeric(price_hi))

df.2023 <- df.2023 |> mutate(net_lo = (jin_per_acr * price_lo - cost_per_acr) * crop_acr, net_hi = (jin_per_acr * price_hi - cost_per_acr) * crop_acr, net_mean = (jin_per_acr * (price_lo + price_hi)/2 - cost_per_acr) * crop_acr)

df.sum.2023 <- df.2023 |> summarise(lo = sum(net_lo), hi = sum(net_hi), total = sum(net_mean)) |> mutate(rep = 2023)

pdf("sim-crops.pdf", width = 7, height = 5)
df.out |>
    ggplot(aes(x = rep, y = total)) +
    geom_pointrange(aes(ymin = lo, ymax = hi)) +
    geom_hline(yintercept = unlist(df.sum.2023[1,])[1:3], col = "red", linetype = 2) +
    coord_flip() +
    scale_y_log10() +
    xlab("simulated year") +
    ylab("sales") +
    labs(title = "Simulated crop production (n=20), based on 2023 yields (red lines)") +
    theme_bw()
dev.off()
