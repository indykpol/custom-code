require(parallel)
require(MASS)

transform <- function(vector,targetMean,targetSd) {
	s1 <- sd(vector)
	m1 <- mean(vector)
	s2 <- targetSd
	m2 <- targetMean
	return(m2 + (vector-m1) * (s2/s1))
}

read_counts <- 500
error_m <- 0.14
error_e <- sqrt(read_counts)
diff_m <- 0.015
diff_e <- 2
delta_correlations <- seq(0,1,0.1)
sim.params <- expand.grid(read_counts,delta_correlations,diff_m,diff_e,error_m,error_e)
sim.params <- as.data.frame(sim.params)
colnames(sim.params) <- c("read_counts","delta_correlations","difference_m","difference_e","error_m","error_e")

numJobs <- nrow(sim.params)*1000
sim.data <- mclapply(1:numJobs, mc.cores=47, mc.cleanup = TRUE, mc.preschedule = TRUE, function(i) {
	current_param <- ceiling(i / 1000)
	read_count <- sim.params[current_param,1]
	delta_correlation <- sim.params[current_param,2]
	diff_m <- sim.params[current_param,3]
	diff_e <- sim.params[current_param,4]
	error_m <- sim.params[current_param,5]
	error_e <- sim.params[current_param,6]
	
	# Normals
	n = 100
	Sigma <- matrix(c(3,1.5,-1.5,1.5,3,-3,-1.5,-3,3),3,3,byrow=TRUE)
	temp <- mvrnorm(n=n, c(0,0,0), Sigma)
	temp_counts <- temp[,1]
	temp_gb <- temp[,2]
	temp_gb <- transform(vector=temp_gb,targetMean=0,targetSd=2*error_m)
	temp_pr <- temp[,3]
	temp_pr <- transform(vector=temp_pr,targetMean=0,targetSd=2*error_m)
	temp_counts <- trunc(transform(vector=temp_counts,targetMean=read_count,targetSd=error_e*2) + rnorm(n,0,error_e))
	temp_an <- cbind(temp_counts,temp_gb,temp_pr)
	
	temp_pr_cpg <- matrix(ncol=11,nrow=nrow(temp_an))
	temp_gb_cpg <- matrix(ncol=11,nrow=nrow(temp_an))
	for (an in 1:nrow(temp_an)) {
		temp_pr_cpg[an,] <- rnorm(n=11,mean=temp_an[an,3],sd=2*error_m) + rnorm(11,0,error_m/1.5)
		temp_gb_cpg[an,] <- rnorm(n=11,mean=temp_an[an,2],sd=2*error_m) + rnorm(11,0,error_m/1.5)
	}
	
	temp_an <- cbind(temp_an,temp_gb_cpg,temp_pr_cpg)
	colnames(temp_an) <- c("count","gb","pr",paste("gb",seq(1,11,1),sep=""),paste("pr",seq(1,11,1),sep=""))
	
	# True Ts
	n = 100
	Sigma <- matrix(c(3,1.5-3*delta_correlation,-1.5+3*delta_correlation,1.5-3*delta_correlation,3,-3,-1.5+3*delta_correlation,-3,3),3,3,byrow=TRUE)
	temp <- mvrnorm(n=n, c(0,0,0), Sigma)
	temp_counts <- temp[,1]
	temp_gb <- temp[,2]
	temp_gb <- transform(vector=temp_gb,targetMean=0+diff_m,targetSd=2.5*error_m)
	temp_pr <- temp[,3]
	temp_pr <- transform(vector=temp_pr,targetMean=0-diff_m,targetSd=2.5*error_m)
	temp_counts <- trunc(transform(vector=temp_counts,targetMean=read_count+diff_e,targetSd=error_e*2.5) + rnorm(n,0,error_e))
	temp_t <- cbind(temp_counts,temp_gb,temp_pr)
	temp_pr_cpg <- matrix(ncol=11,nrow=nrow(temp_t[1:n,]))
	temp_gb_cpg <- matrix(ncol=11,nrow=nrow(temp_t[1:n,]))
	for (t in 1:nrow(temp_t)) {
		temp_pr_cpg[t,] <- rnorm(n=11,mean=temp_t[t,3],sd=2.5*error_m) + rnorm(11,0,error_m/1.5)
		temp_gb_cpg[t,] <- rnorm(n=11,mean=temp_t[t,2],sd=2.5*error_m) + rnorm(11,0,error_m/1.5)
	}
	temp_t <- cbind(temp_t,temp_gb_cpg,temp_pr_cpg)
	colnames(temp_t) <- c("count","gb","pr",paste("gb",seq(1,11,1),sep=""),paste("pr",seq(1,11,1),sep=""))
	list(temp_an,temp_t)
	})
