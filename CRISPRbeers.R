library(shiny)
library(shinythemes)
library(tidyverse)

#######################################################################################
### ENTER YOUR WORKING DIRECTORY CONTAINING THE CRISPR BEERS DATABASE HERE: 
setwd("~/Desktop/Research/CRISPR/Review4/App/proj12")
#######################################################################################

CRISPRbeers <- as.data.frame(read.csv("BEERS_database.csv"))

colnames(CRISPRbeers)[28] = 'increased_product_purity'
colnames(CRISPRbeers)[29] = 'increased_on_target'
colnames(CRISPRbeers)[31] = 'Reduced_DNA_off_targets'
colnames(CRISPRbeers)[32] = 'Reduced_RNA_off_targets'

sort(CRISPRbeers$MAX, decreasing = TRUE)

b64 <- base64enc::dataURI(file="BEpos1.png", mime="image/png")


### UI ####
ui <- fluidPage(
  theme = shinytheme("united"),
  
  tags$style('.container-fluid {
                             background-color: #F0F8FF;
              }'),
  fluidRow(
    column(2,
  img(src=b64)),
  column(5,offset = 5,
  titlePanel(
    h1(p("CRISPR Base Editor Exchange Repository", style = "color:purple", align = "center"))
  )
  )
  ),
  hr(),

  


  
  sidebarLayout(
    sidebarPanel(tags$style(".well {background-color:#FFFFDB;}"),

                 checkboxGroupInput(inputId = "A",
                                    label = "Single Effector:",
                                    choices = unique(CRISPRbeers$single_effector),
                                    inline = TRUE),
                
                 
                 checkboxGroupInput(inputId = "B_",
                             label = "Editing Class:",
                             choices = unique(CRISPRbeers$editing_class),
                             inline = T),
                
                 
                 checkboxGroupInput(inputId = "B",
                                    label = "Endonuclease:",
                                    choices = unique(CRISPRbeers$endonuclease),
                                    inline= T),
                 
                 checkboxGroupInput(inputId = "C",
                                    label = "PAM Requirement:",
                                    choices = unique(CRISPRbeers$PAM_requirement),
                                    inline = TRUE),
                 
                 checkboxGroupInput(inputId = "D",
                                    label = "Reduced DNA Off-Targets:",
                                    choices = unique(CRISPRbeers$Reduced_DNA_off_targets),
                                    inline = TRUE),
                 
                 checkboxGroupInput(inputId = "E",
                                    label = "Reduced RNA Off-Targets:",
                                    choices = unique(CRISPRbeers$Reduced_RNA_off_targets),
                                    inline = TRUE),
                 
                 
                 checkboxGroupInput(inputId = "F_",
                                    label = "Increased Product Purity:",
                                    choices = unique(CRISPRbeers$increased_product_purity),
                                    inline = TRUE),
                 
                 checkboxGroupInput(inputId = "G",
                                    label = "Increased on Target:",
                                    choices = unique(CRISPRbeers$increased_on_target),
                                    inline = TRUE),
                 # selectizeInput(inputId = "mode","View Mode",choices=c("mode 1","mode 2"),selected= "mode 1"),
                 uiOutput("modeUI1"),
                 uiOutput("sortby"),
                 #img(src="BEpos.png",style="width:100%;height:auto")
                 
                 
    ),

    mainPanel(
      dataTableOutput("DataTable"),
      h4("This repository of CRISPR Base Editors can be used to prioritise effector enzymes to be used to target your sequence of interest. This database 
contains base editors which been manually curated, and experimentally derived servers for some specific editors can be found elsewhere.
")
    )
  )
)



### Server ####
server <- function(input, output,session) {
  
  r<-reactiveValues(cols=NULL,sortCol=NULL,asc=FALSE)
  
  
  df<-reactive({
    single_effector_sel <- if (is.null(input$A)) unique(as.vector(CRISPRbeers$single_effector)) else input$A
    endonuclease_sel <- if (is.null(input$B)) unique(as.vector(CRISPRbeers$endonuclease)) else input$B
    editing_class_sel <- if (is.null(input$B_)) unique(as.vector(CRISPRbeers$editing_class)) else input$B_
    PAM_requirement_sel <- if (is.null(input$C)) unique(as.vector(CRISPRbeers$PAM_requirement)) else input$C
    Reduced_DNA_off_targets_sel <- if (is.null(input$D)) unique(as.vector(CRISPRbeers$Reduced_DNA_off_targets)) else input$D
    Reduced_RNA_off_targets_sel <- if (is.null(input$E)) unique(as.vector(CRISPRbeers$Reduced_RNA_off_targets)) else input$E
    increased_product_purity_sel <- if (is.null(input$F_)) unique(as.vector(CRISPRbeers$increased_product_purity)) else input$F_
    increased_on_target_sel <- if (is.null(input$G)) unique(as.vector(CRISPRbeers$increased_on_target)) else input$G
    
    A = dplyr::filter(CRISPRbeers, single_effector %in% single_effector_sel,
                      endonuclease %in% endonuclease_sel,
                      editing_class %in% editing_class_sel,
                      PAM_requirement %in% PAM_requirement_sel,
                      Reduced_DNA_off_targets %in% Reduced_DNA_off_targets_sel,
                      Reduced_RNA_off_targets %in% Reduced_RNA_off_targets_sel,
                      increased_product_purity %in% increased_product_purity_sel,
                      increased_on_target %in% increased_on_target_sel)
    
    A <- A[,c(2,3,5,33:58)]
    names(A)<-c("base_editor","PMID","MAX",as.character(-6:-1),as.character(1:20))
    
    if(!is.null(r$cols)){
      A<-A[,c("base_editor","PMID","MAX",r$cols)]
    }
    
    if(!is.null(r$sortCol)){
      A<-A%>%
        arrange(... = if(!r$asc){A[,r$sortCol]}else{desc(A[,r$sortCol])}
        )
      
    }
    
    A
  })
  
  output$DataTable <- renderDataTable({
    df()
  },options = list(scrollX = TRUE))
  
  observe(
  print(r$asc)
  )
  output$sortby<-renderUI({tagList(
    selectizeInput("sortCol","Column to sort by",choices=names(df()),selected=r$sortCol,multiple=F),
    checkboxInput("asc","Descending",value = r$asc)
  )})
  
  observeEvent(input$sortCol,{
    r$sortCol<-input$sortCol
  })
  
  observeEvent(input$asc,{
    r$asc<-input$asc
  })
  
  # output$modeUI<-renderUI({
  #   if(input$mode=="mode 2"){
  #     vars<-names(CRISPRbeers)[33:58]
  #     selectizeInput(inputId = "cols","Editing Window to Display",choices=vars,multiple = TRUE)
  #   }
  # })
  
  observeEvent(input$cols,{
    r$cols<-input$cols
  })
  
  output$modeUI1<-renderUI({
      sliderInput("slideCol","Editing Window to Display:",min = -6,max = 20,step = 1,value = c(4,9))
  })
  
  observeEvent(input$slideCol,{
    k<-as.character(input$slideCol[1]:input$slideCol[2])
    k<-k[k!="0"]
    r$cols<-k
    print(k)
    if(!input$sortCol%in%c("base_editor","PMID","MAX",input$slideCol)){
      r$sortCol<-as.character(min(as.integer(k)))
      # updateSelectizeInput(inputId = "sortCol",selected = min(input$slideCol),session=session)
    }
  })
  
  # observeEvent(input$mode,{
  #   updateSelectizeInput(session = session,inputId = "cols",selected = NULL)
  # })
  
  
}
shinyApp(ui, server)

