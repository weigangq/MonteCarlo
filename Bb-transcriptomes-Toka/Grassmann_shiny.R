library(shiny)
library(tidyverse)
library(readxl)


x <- read_excel("~/QiuLab-work/mmi70036-sup-0002-tables2.xlsx", sheet = 3)
y <- read_excel("~/QiuLab-work/mmi70036-sup-0003-tables3.xlsx", sheet = 3)


in_vitro <- x[, c(1, 8, 9, 10)]
colnames(in_vitro) <- c("GeneID", "WT_in_vitro_1", "WT_in_vitro_2", "WT_in_vitro_3")


DMC <- y[, c(1, 8:13)]
colnames(DMC) <- c("GeneID","WT_DMC1","WT_DMC2","WT_DMC3","WT_DMC4","WT_DMC5","WT_DMC6")


WT <- merge(in_vitro, DMC , by = "GeneID")


FC <- WT %>%
  mutate(in_vitro_mean = rowMeans(select(., 2:4)),
         DMC_mean = rowMeans(select(., 5:10)),
         fold_change = DMC_mean / in_vitro_mean,
         log2FC = log2(fold_change))

FC <- FC %>%
  rowwise() %>%
  mutate(pvalue = t.test(c_across(2:4), c_across(5:10))$p.value) %>%
  ungroup() %>%
  mutate(p_adj = p.adjust(pvalue, method = "BH"))

FC_clean <- FC %>% filter(is.finite(log2FC),is.finite(pvalue))


# UI


ui <- fluidPage(titlePanel("WT_in_vitro vs WT_DMC Volcano Plot"),
      sidebarLayout(
      sidebarPanel(
      sliderInput("pval",
                  "Adjusted P-value cutoff:",
                  min = 0.0001,
                  max = 0.1,
                  value = 0.05,
                  step = 0.0001),
      
      sliderInput("fc",
                  "Absolute Log2 Fold Change cutoff:",
                  min = 0,
                  max = 5,
                  value = 1,
                  step = 0.1),
      
      selectizeInput("gene",
                     "Highlight gene:",
                     choices = NULL,
                     options = list(placeholder = 'Type gene name...'))),
      mainPanel(plotOutput("volcanoPlot", height = "700px"))))


# Server


server <- function(input, output, session) {
  
 
  updateSelectizeInput(session,"gene",choices = 
  c("None", FC_clean$GeneID),server = TRUE)
  
output$volcanoPlot <- renderPlot({gene.sel <- 
if (is.null(input$gene) || input$gene == "None") 
{NULL} else {FC_clean[FC_clean$GeneID == input$gene, ]}
    
FC_clean %>% 
  ggplot(aes(log2FC, p_adj)) +
  geom_point(shape = 1) +
  geom_point(data = gene.sel,col = "red",size = 2) +
  scale_y_log10() +
  geom_vline(xintercept = c(-input$fc, input$fc),linetype = 2) +
  geom_hline(yintercept = input$pval,col = "blue") +
  theme_bw() +
  labs(x = "Log2 Fold Change",y = "Adjusted P-value")})}


# Run App

shinyApp(ui = ui, server = server)
