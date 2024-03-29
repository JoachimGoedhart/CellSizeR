#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)



df_sheet <- read.csv("https://docs.google.com/spreadsheets/d/e/2PACX-1vSc-nI1-s_u-XkNXEn_u2l6wkBafxJMHQ_Cd3kStrnToh7kawqjQU3y2l_1riLigKRkIqlNOqPrgkdW/pub?output=csv", na.strings = "")
df_sheet <- df_sheet %>% na.omit()
colnames(df_sheet) <- c("Timestamp", "Group", "Cell", "Nucleus")
df_tidy <-
    pivot_longer(
        df_sheet,
        cols = -c("Timestamp", "Group"),
        names_to = "Sample",
        values_to = "Size"
    )

df_tidy <- df_tidy %>% mutate(Size = gsub(" ", "", Size)) %>% separate_rows(Size, sep=",") 

df_tidy <- df_tidy %>% mutate(Size = as.numeric(Size)) %>% filter(Size>0 & Size<1000)

df_tidy <- df_tidy %>% separate('Timestamp', c("Date", "Time"), sep=" ") %>%
    separate('Date', c("day", "month", "year"), sep="/", convert = TRUE)


# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("CellSizeR"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(width=3,
            
            selectInput("year", label = "Show data from:", choices = "2021"),
            sliderInput("alpha",
                        "Transaparency:",
                        min = 0,
                        max = 1,
                        value = .8),
            numericInput(inputId = "bins",
                          label = "Number of bins",
                         value = 60,
                          min = 10,
                         max=100),
            checkboxInput(inputId = "scale_log_10",
                          label = "Log scale",
                          value = FALSE),
            checkboxInput("multiples", "Separate plots", value = FALSE),
            # checkboxInput("exact", "Exact distribution", value = FALSE),  
            NULL
        ),


        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("distPlot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
    
    year.selected <- "2021"
    
    #Uncomment to update the years based on the Google Sheet
    observe({
        yrs  <- unique(df_tidy$year)
        updateSelectInput(session, "year", choices = yrs, selected = year.selected)
    })
    
    

    output$distPlot <- renderPlot({
        # generate bins based on input$bins from ui.R
        
        
        df <- df_tidy %>% filter(year == input$year)
        
        p <- ggplot(df, aes(x=Size, fill=Sample))

        if (input$scale_log_10)
            p <- p + scale_x_log10()

        p <- p+ geom_histogram(bins = input$bins, alpha=input$alpha, color='grey20')
        
        if (input$multiples)
            p <- p+ facet_wrap(~Sample)

                
        p <- p + labs(y="Count", x="Size [µm]")
        
        p <- p + coord_cartesian(xlim = c(0.5,120))
        
        p + theme_light(base_size = 16) + theme(axis.text.y = element_blank())
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
