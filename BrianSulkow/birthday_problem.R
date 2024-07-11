##find out if the people two or more people have the same birthday. 
library(ggplot2)
library(tidyverse)

##birthday -
#input - pop_size ,  the number of people included in "experiment"
#output - vector of bdays

birthday <- function(pop_size){
  bds <- rep(0,pop_size)
  for(i in 1:pop_size){
    bds[i] <- sample(1:365,1)
  }
  return(bds)
}


#birthdayProb simulates multiple populations and returns a probability estimate 
#of populations the containing 2 or more people with the same birthday. 
#input :  pop_size :  population size,  and num_sim: number of simulations 
#output: estimated probability that a population contains 2 or more people with the same birthday
birthdayProb<- function(pop_size , num_sims){
  
  no_match <- 0
  
  for(i in 1:num_sims)
  {
    bd <- birthday(pop_size)
    if(length(unique(table(bd)))== 1)
    {
      no_match <- no_match+1
      }
  }
  
  return(1-(no_match/num_sims))
}

##probBdayClosed
#input=  population size: pop_size
#output =  actual probability that a population of size pop_size that
#has two or more members with the same birthday. 
probBdayClosed <- function(pop_size){
  prod <- 1
  for (i in 1:pop_size){
    prod <- prod*((365-i)/365)
  }
  return( 1- prod)
}

##bdaydf -  creates a data frame with the actual and estimated probabilities. 
##input:  a vector of population sizes, number of sims for the estimated probability
# output: dataframe with actual and estimated probabilities 
bdaydf <- function(popVect,num_sims){
  probClosed <-c()
  probSim <- c()
  k <- 1
  for( i in popVect){
    probClosed[k] <- probBdayClosed(i)
    probSim[k] <-birthdayProb(i, num_sims)
    k <- k+1
  }
  
  df <- data.frame(popVect,probClosed, probSim)
  df <- df %>% 
    pivot_longer(
      cols = !popVect, 
      names_to = "type", 
      values_to = "prob")
  print(df)
}

##Example with plot
#bdf <- bdaydf(2:100,100)

#ggplot(bdf, aes(x=popVect, y=prob, col = type)) + geom_point() 
