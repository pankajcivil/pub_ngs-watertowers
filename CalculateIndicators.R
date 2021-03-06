##walter immerzeel 20190201 / arthurlutz 20190725
##Script to compute all final demand and supply indicators 
##updated for revised manuscript
rm(list=ls(all=TRUE))

##SETTINGS
# Specific base folder
base = "e:/Dropbox (FutureWater)/Team/Projects/Active/2019001_ngs_watertowers/data/"

# specify indicator files
pindf = paste(base, "ERA5/processed/WTU_P_indicators.csv",sep="")
sindf = paste(base,"Snow/processed/WTU_Snow_indicators.csv",sep="")
gindf = paste(base,"Glaciers/processed/WTU_Glacier_indicators.csv",sep="")
swindf = paste(base,"HydroLakes/processed/WTU_lake_storage_volume.csv",sep="")
dindf = paste(base,"WaterDemandsWRI/processed/WTU_Demand_indicators_v3.csv",sep="")
ddomindf = paste(base,"WaterDemandsWRI/processed/WTU_Domestic_Water_Gap_monthly_v2.csv",sep="")
dindindf = paste(base,"WaterDemandsWRI/processed/WTU_Industrial_Water_Gap_monthly_v2.csv",sep="")
dirrindf = paste(base,"WaterDemandsWRI/processed/WTU_Irrigation_Water_Gap_monthly_v2.csv",sep="")
dnatindf = paste(base,"WaterDemandsWRI/processed/WTU_Natural_Water_Gap_monthly_v3.csv",sep="")

# outputfile
indf = paste(base, "indicators/indicators.csv",sep="")

# specify file with WTU specs
wtuf = paste(base,"index/units/WTU_specs.csv",sep="")

# weights of indicators
w_ptot <- 1 #precipitation indicator
w_stot <- 1 #snow indicator
w_gtot <- 1 #glacier indicator
w_swtot <- 1 #lake and reservoir indicator
w_dem_irr <- 1 #irrigation demand indicator
w_dem_dom <- 1 #domestic demand indicator
w_dem_ind <- 1 #industrial demand indicator
w_dem_nat <- 1 #natural demand indicator

##SETTINGS END


## Read CSV with indicators
pind <- read.csv(file=pindf, header=TRUE, sep=",")
str(pind)
sind <- read.csv(file=sindf, header=TRUE, sep=",")
str(sind)
gind <- read.csv(file=gindf, header=TRUE, sep=",")
str(gind)
swind <- read.csv(file=swindf, header=TRUE, sep=",")
str(swind)
dind <- read.csv(file=dindf, header=TRUE, sep=",")
str(dind)
ddomind <- read.csv(file=ddomindf, header=TRUE, sep=",")
str(ddomind)
dindind <- read.csv(file=dindindf, header=TRUE, sep=",")
str(dindind)
dirrind <- read.csv(file=dirrindf, header=TRUE, sep=",")
str(dirrind)
dnatind <- read.csv(file=dnatindf, header=TRUE, sep=",")
str(dnatind)

#read CSV with WTU specs

wtu <- read.csv(file=wtuf, header=TRUE, sep=",")
str(wtu)

#create indicator df
indicator <- subset(wtu,select = c(WTU_ID,WTU_name))

# precipitation
indicator$pup_tot <- pind$Pannual_WT_km3 / pind$Pannual_basin_km3
indicator$pinter <- pind$Var_inter_upstream
indicator$pintra <- pind$Var_intra_upstream
# final indicator
# first average pinter and pintra, then multiply with pup_tot
indicator$ptot <- (0.5*(indicator$pintra+indicator$pinter))*indicator$pup_tot

# snow
indicator$snow_p <- sind$Mean_annual_snow_persistence_WT
indicator$snow_intra <- sind$Var_intraannual_snow_persistence_WT
indicator$snow_inter <- sind$Var_interannual_snow_persistence_WT
# final indicator
# first average snow_inter and snow_intra, then multiply with snow_p
indicator$stot <- (0.5*(indicator$snow_intra+indicator$snow_inter))*indicator$snow_p

# glaciers
# ice volume indicator
indicator$glac_v <- gind$Ice_Volume_WT_km3 / (pind$Pannual_WT_km3 + gind$Ice_Volume_WT_km3)
#melt water yield indicator
indicator$glac_m <- gind$Meltwater_Yield_WTU_km3yr.1/(gind$Meltwater_Yield_WTU_km3yr.1+pind$Pannual_WT_km3)
#final indicator
#indicator$gtot <- indicator$glac_v*indicator$glac_m
indicator$gtot <- (indicator$glac_v+indicator$glac_m)/2

# surface water
indicator$swtot <- swind$Lake_Storage_Volume_WT_km3 / (pind$Pannual_WT_km3 + swind$Lake_Storage_Volume_WT_km3)
indicator$swtot[is.na(indicator$swtot)] <- 0

# demand indicators
indicator$dem_irr <- dirrind$Water_gap_total / dind$Irr_demand_basin_km3yr.1
indicator$dem_irr[is.na(indicator$dem_irr)] <- 0
indicator$dem_ind <- dindind$Water_gap_total / dind$Ind_demand_basin_km3yr.1
indicator$dem_ind[is.na(indicator$dem_ind)] <- 0
indicator$dem_dom <- ddomind$Water_gap_total / dind$Dom_demand_basin_km3yr.1
indicator$dem_dom[is.na(indicator$dem_dom)] <- 0
indicator$dem_nat <- dnatind$Water_gap_total / dind$Nat_demand_basin_km3yr.1
indicator$dem_nat[is.na(indicator$dem_nat)] <- 0
indicator$demtot <- ((indicator$dem_irr * w_dem_irr) + (indicator$dem_ind * w_dem_ind) + (indicator$dem_dom * w_dem_dom) + (indicator$dem_nat * w_dem_nat))/sum(w_dem_irr,w_dem_ind,w_dem_dom,w_dem_nat)
indicator$suptot <-  ((indicator$ptot * w_ptot) + (indicator$stot * w_stot) + (indicator$gtot * w_gtot) + (indicator$swtot * w_swtot))/sum(w_ptot,w_stot,w_gtot,w_swtot)
indicator$fin_sd <- indicator$demtot * indicator$suptot
indicator$fin_sd_nor <- (indicator$fin_sd-min(indicator$fin_sd))/(max(indicator$fin_sd)-min(indicator$fin_sd))

# Save results
write.csv(indicator, file=indf)

# check results wit barplots
# blue = sub indicator / red = final indicators
par(mar=c(3,4.5,0.5,0.5), mgp=c(2,0.5,0), cex.axis=0.9)
laymat <- matrix(1:21, nc=3, byrow=T)
layout(laymat, widths=c(1,1), heights=c(1,1,1))
barplot(indicator$pup_tot,col="blue", ylab="pup_tot", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$pinter,col="blue", ylab="pinter", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$pintra,col="blue", ylab="pintra", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$ptot,col="red", ylab="ptot", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$snow_p,col="blue", ylab="snow_p", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$snow_intra,col="blue", ylab="snow_intra", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$snow_inter,col="blue", ylab="snow_inter", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$stot,col="red", ylab="stot", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$glac_v,col="blue", ylab="glac_v", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$glac_m,col="blue", ylab="glac_m", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$gtot,col="red", ylab="gtot", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$swtot,col="red", ylab="swtot", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$dem_irr,col="blue", ylab="dem_irr", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$dem_ind,col="blue", ylab="dem_ind", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$dem_dom,col="blue", ylab="dem_dom", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$dem_nat,col="blue", ylab="dem_nat", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$suptot,col="red", ylab="suptot", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$demtot,col="red", ylab="demtot", space = 0.5,las=2,ylim=c(0,1))
barplot(indicator$fin_sd_nor,col="red", ylab="FINAL_NORM", space = 0.5,las=2,ylim=c(0,1))



