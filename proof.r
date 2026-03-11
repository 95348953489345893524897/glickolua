# Now calculate the example manually to be sure (the paper uses rounding, I don't, I want to make sure my numbers are absolutely correct.): 
OpponentRatings <- c(1400, 1550, 1700)
OpponentRDs <- c(30, 100, 300)
MatchOutcomes <- c(1, 0, 0)
##########
# Step 1 #
##########

# Player Rating: 1500 (the default) 
# Player RD:     200
# RD = min(sqrt(RD^2_old) + c ^ 2, 350)
# Where c = 0 (example calculation does not use c)
PlayerRD <- min(sqrt(200^2) + 0 ^ 2, 350) # 200
PlayerRating <- 1500 # Directly taken 

##########
# Step 2 #
##########

# "Assume that the player’s pre-period rating is r"
r <- PlayerRating
RD <- PlayerRD

# "Where q = ln(10) / 400"
q <- log(10) / 400 # 0.005756463
# "Where g(RD) = 1 / sqrt(1 + 3q^2(RD^2) / pi^2)"
g <- function(RD_num){
    return(1 / sqrt(1 + 3 * q^2 * (RD_num^2) / pi^2))
}


dSquared <- 0
for(j in 1:length(MatchOutcomes)){
    E <- function(){
           return(1 / ( 1 + 10^(-g(OpponentRDs[j]) * (r - OpponentRatings[j]) / 400)))
    }
    dSquared <- dSquared + g(OpponentRDs[j])^2 * E() * (1 - E())
}
dSquared <- (q^2 * dSquared)^-1
PrimeSum <- 0
for(j in 1:length(MatchOutcomes)){
    PrimeSum <- PrimeSum + g(OpponentRDs[j]) * (MatchOutcomes[j] - E())
}
rPrime <- r + (q / (1 / RD^2 + 1 / dSquared)) * PrimeSum
RDPrime <- sqrt((1 / RD^2 + 1 / dSquared)^-1)
print(rPrime)
print(RDPrime)

#Output:
#[1] 1464.106
#[1] 151.3989
