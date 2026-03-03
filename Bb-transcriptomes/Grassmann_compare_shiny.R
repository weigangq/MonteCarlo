library(shiny)
library(tidyverse)
library(readxl)
library(ggplot2)
library(preprocessCore)

#load data
WT_vs_bosR_in_vitro <- read_excel("mmi70036-sup-0002-tables2.xlsx", sheet = 3)
WT_vs_bosR_R39A_in_vitro <- read_excel("mmi70036-sup-0002-tables2.xlsx", sheet = 4)
WT_vs_bosR_DMC <- read_excel("mmi70036-sup-0003-tables3.xlsx", sheet = 3)
WT_vs_bosR_R39A_DMC <- read_excel("mmi70036-sup-0003-tables3.xlsx", sheet = 4)

#----------
x <- read_excel("~/QiuLab-work/mmi70036-sup-0002-tables2.xlsx", sheet = 3)
y <- read_excel("~/QiuLab-work/mmi70036-sup-0003-tables3.xlsx", sheet = 3)


in_vitro <- x[, c(1, 8, 9, 10)]
colnames(in_vitro) <- c("GeneID", "WT_in_vitro_1", "WT_in_vitro_2", "WT_in_vitro_3")


DMC <- y[, c(1, 8:13)]
colnames(DMC) <- c("GeneID","WT_DMC1","WT_DMC2","WT_DMC3","WT_DMC4","WT_DMC5","WT_DMC6")


WT <- merge(in_vitro, DMC , by = "GeneID")

normalized_data <- normalize.quantiles(as.matrix(WT[, -1]))

WT <- data.frame(GeneID = WT$GeneID, normalized_data)
colnames(WT)[-1] <- c("WT_in_vitro_1","WT_in_vitro_2","WT_in_vitro_3",
                      "WT_DMC1","WT_DMC2","WT_DMC3",
                      "WT_DMC4","WT_DMC5","WT_DMC6")

WT[, -1] <- log2(WT[, -1] + 1)

WT_in_vitro_vs_WT_DMC <- WT %>%
  mutate(in_vitro_mean = rowMeans(select(., 2:4)),
         DMC_mean = rowMeans(select(., 5:10)),
         log2FoldChange = log2(DMC_mean / in_vitro_mean)) %>%
  rowwise() %>%
  mutate(padj = if(sd(c_across(2:4)) == 0 |
                   sd(c_across(5:10)) == 0) NA_real_
         else t.test(c_across(2:4),
                     c_across(5:10))$p.value) %>%
  ungroup() %>%
  mutate(padj = p.adjust(padj, method = "BH")) %>%
  select(GeneID, log2FoldChange, padj) %>%
  filter(!is.na(padj), padj > 0)
#----------

  gene_lists <- unique(c(
    WT_vs_bosR_in_vitro$GeneID,
    WT_in_vitro_vs_WT_DMC$GeneID
  ))
#----------

  
volcano_plot <- function(df, title, gene, fc_cut, p_cut){
  
  df <- df %>% filter(!is.na(padj), padj > 0)
  
  gene.sel <- if(is.null(gene) || gene == "None"){
    NULL
  } else {
    df[df$GeneID == gene, ]
  }
  
  ggplot(df, aes(log2FoldChange, padj)) +
    geom_point(shape = 1) +
    geom_point(data = gene.sel, col = "red", size = 3) +
    scale_y_log10() +
    geom_vline(xintercept = c(-fc_cut, fc_cut), linetype = 2) +
    geom_hline(yintercept = p_cut, col = "blue") +
    theme_bw() +
    labs(title = title,
         x = "log2 Fold Change",
         y = "Adjusted p-value")
}
#----------
#Ui
  ui <- fluidPage(
    titlePanel("Borrelia Transcriptome Volcano Plots"),
    sidebarLayout(
      sidebarPanel(
        sliderInput("pval","Adjusted p-value cutoff:",
                    min = 0.0001,
                    max = 0.1,
                    value = 0.05,
                    step = 0.0001),
        
        sliderInput("fc","Absolute log2FC cutoff:",
                    min = 0,
                    max = 5,
                    value = 1,
                    step = 0.1),
        
        selectizeInput("gene","Highlight gene:",
                       choices = c("None", gene_lists),
                       selected = "None")
      ),
      
      mainPanel(
        tabsetPanel(
          tabPanel("WT vs ΔbosR in vitro",
                   plotOutput("plot1", height=600)),
          
          tabPanel("WT vs bosR-R39A in vitro",
                   plotOutput("plot2", height=600)),
          
          tabPanel("WT vs ΔbosR DMC",
                   plotOutput("plot3", height=600)),
          
          tabPanel("WT vs bosR-R39A DMC",
                   plotOutput("plot4", height=600)),
          
          tabPanel("WT in vitro vs WT DMC",
                   plotOutput("plot5", height=600))
        )
      )
    )
  )

#Server
server <- function(input, output, session){
  
  output$plot1 <- renderPlot({
    volcano_plot(WT_vs_bosR_in_vitro,
                 "WT vs ΔbosR in vitro",
                 input$gene, input$fc, input$pval)
  })
  
  output$plot2 <- renderPlot({
    volcano_plot(WT_vs_bosR_R39A_in_vitro,
                 "WT vs bosR-R39A in vitro",
                 input$gene, input$fc, input$pval)
  })
  
  output$plot3 <- renderPlot({
    volcano_plot(WT_vs_bosR_DMC,
                 "WT vs ΔbosR DMC",
                 input$gene, input$fc, input$pval)
  })
  
  output$plot4 <- renderPlot({
    volcano_plot(WT_vs_bosR_R39A_DMC,
                 "WT vs bosR-R39A DMC",
                 input$gene, input$fc, input$pval)
  })
  
  output$plot5 <- renderPlot({
    volcano_plot(WT_in_vitro_vs_WT_DMC,
                 "WT in vitro vs WT DMC",
                 input$gene, input$fc, input$pval)
  })
}

shinyApp(ui, server)
