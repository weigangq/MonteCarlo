# simulate the birthday problem
library(tidyverse)

days <- 1:365;

find.overlap <- function(x) { return(length(which(table(x)>1))) }

output <- sapply(1:100, function(x) { # num of people in the room
  ct.no.overlap <- 0;
  for (k in 1:100) { # number of repeats
    bdays <- sample(days, x, replace = T);
    ct <- find.overlap(bdays);
    if (!ct) { ct.no.overlap <- ct.no.overlap + 1}
  }
  return(ct.no.overlap);
})

# expected
p.no.share <- function(n) {
  log.p <- 0
  for(i in 1:n) {
    log.p <- log.p + log((365-i)/365) 
  }
  return(exp(log.p))
}

prob <- sapply(1:100, function(n) p.no.share(n))
p.df <- tibble(n = 1:100, p.exp = prob, p.sim = output/100)

p.df %>% 
  ggplot(aes(x = n, y = p.sim)) +
  geom_point(color = "red", shape = 1) +
  geom_line(aes(y=p.exp)) +
  geom_hline(yintercept = 0.5, linetype = 2) +
  theme_bw() +
  xlab("Number of individuals in a room") +
  ylab("Prob of no shared birthdays")

p.df %>% 
  ggplot(aes(x = n, y = 1-p.sim)) +
  geom_point(color = "red", shape = 1) +
  geom_line(aes(y=1-p.exp)) +
  geom_hline(yintercept = c(0.5,1), linetype = 2) +
  theme_bw() +
  xlab("Number of students") +
  ylab("Prob of at least one shared birthday")
