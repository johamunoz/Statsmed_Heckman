library(here)
library(data.table)
library(ggplot2)

# Arrange dataset
data<-as.data.table(readxl::read_xlsx(here('2.Simulation','Sim_results.xlsx'),sheet="Sheet1"))
#data<-data[,grep("Scenario|Method|Variation|^Bias|^EmpSE|^RMSE|^CIW|^Cov|^SE", names(data)), with = FALSE]
#colnames(data)<-c("Scenario","Variation","Method", paste0("p_Coverage_",0:2), paste0("p_Bias_",0:6),paste0("p_RMSE_",0:6),paste0("p_Width_",0:2),paste0("p_EmpSE_",0:6),paste0("SE_Bias_",0:6),paste0("SE_EmpSE_",0:6),paste0("SE_RMSE_",0:6),paste0("SE_Width_",0:2), paste0("SE_Coverage_",0:2))
#data<- setDT(melt(data, measure.vars = c( paste0("p_Bias_",0:6), paste0("p_Coverage_",0:2), paste0("p_EmpSE_",0:6), paste0("p_RMSE_",0:6),paste0("p_Width_",0:2),paste0("SE_Bias_",0:6), paste0("SE_Coverage_",0:2),paste0("SE_EmpSE_",0:6),paste0("SE_RMSE_",0:6),paste0("SE_Width_",0:2)),variable.name = "Statistic", value.name = "Value"))
data<-data[Variation!="10;50",]
data<-data[,grep("Scenario|Method|Variation|^Bias|^RMSE|^CIW|^Cov|^SE_B|^SE_C|^SE_W|^SE_RM", names(data)), with = FALSE]
colnames(data)<-c("Scenario","Variation","Method", paste0("p_Coverage_",0:2), paste0("p_Bias_",0:6),
                  paste0("p_RMSE_",0:6),paste0("p_Width_",0:2),paste0("SE_Bias_",0:6),paste0("SE_RMSE_",0:6),paste0("SE_Width_",0:2), paste0("SE_Coverage_",0:2))
data<- setDT(melt(data, measure.vars = c( paste0("p_Bias_",0:6), paste0("p_Coverage_",0:2), paste0("p_RMSE_",0:6),paste0("p_Width_",0:2),
                                          paste0("SE_Bias_",0:6), paste0("SE_Coverage_",0:2),paste0("SE_RMSE_",0:6),paste0("SE_Width_",0:2)),variable.name = "Statistic", value.name = "Value"))



data[, c("Type","Statistic", "Parameter") := tstrsplit(Statistic, "_", fixed=TRUE)]
data<- setDT(dcast(data, Scenario+ Variation+ Method +  Parameter+Statistic~Type, value.var = "Value"))
param_val <- c("0"="beta_0", "1"="beta_1", "2"="beta_2", 
               "3"="psi_b0", "4"="psi_b1", "5"="psi_b2","6"= "psi_e")
data[,Method:=factor(Method, levels = c("CC","1l.Heckman","2l.MAR","2l.Heckman"))]
levels(data$Method)<-c("CC","1l.heckman","2l.MAR","2l.2stage.heckman")
data[,Parameter := as.factor(param_val[data$Parameter])]
data[,Parameter := factor(Parameter, levels = c("beta_0","beta_1","beta_2","psi_b0","psi_b1","psi_b2","psi_e"),
                          ordered = TRUE, labels=c(expression(beta[0]**O),expression(beta[1]**O),expression(beta[2]**O),
                                                   expression(sqrt(psi[oo]**O)),expression(sqrt(psi[11]**O)),expression(sqrt(psi[22]**O)),
                                                   expression(psi[e])))]


plotsim<-function(Scenariov,levelsvar,yaxis){
datagraph<-data[Scenario==Scenariov,]
datalines <- data.table(Parameter = c("beta_0","beta_1", "beta_2","psi_b0", "psi_b1","psi_b2","psi_e"),
                        Z = c(rep(0,7),rep(0.95,7),rep(0,7),rep(0,7)),
                        Statistic=c(rep("Bias",7),rep("Coverage",7),rep("RMSE",7),rep("Width",7)))


datalines[,Parameter := factor(Parameter, levels = c("beta_0","beta_1","beta_2","psi_b0","psi_b1","psi_b2","psi_e"),
                               ordered = TRUE, labels=c(expression(beta[0]**O),expression(beta[1]**O),expression(beta[2]**O),
                                                        expression(sqrt(psi[oo]**O)),expression(sqrt(psi[11]**O)),expression(sqrt(psi[22]**O)),
                                                        expression(psi[e])))]



unique(datalines$Parameter)
datagraph[, Variation:=as.factor(Variation)]
datagraph[, Variation:=factor(Variation,levels=levelsvar)]

pd = position_dodge(.1)
datalines1<-datalines[!Parameter%in%c("psi[e]")]

plot<-ggplot(datagraph[!Parameter%in%c("psi[e]")],
       aes(y= Variation, x     = p, color = Method)) +
  geom_point(shape = 1,size  = 1,position = pd) +
  geom_vline(data = datalines1, aes(xintercept = Z),linetype='dotted')+
  geom_errorbar(aes(xmin  = p - 1.96*SE, xmax  = p + 1.96*SE),
                width = 0.2,size  = 0.5,position = pd) +
  facet_grid(Parameter~Statistic, scales="free",labeller = label_parsed)+
  scale_color_brewer(palette="Dark2")+
  guides(color=guide_legend(title="Imputation method"))+
  theme_light()+  
  theme(strip.background =element_rect(fill="white"),legend.position="bottom",legend.margin=margin(t=-12))+
  theme(strip.text = element_text(colour = 'black'))+
  theme(axis.text.x = element_text(angle = 45, vjust = 0.15,size=7),
        axis.title=element_text(size=8))+
  theme(axis.text.y = element_text(size=7))+
  xlab("Performance measure")+ylab(yaxis)+
  theme(legend.text=element_text(size=6))+
  theme(legend.title=element_text(size=7))

return(plot)
}

width=5
height=width/1.1
width/height

plot_rho<-plotsim(Scenariov="Rho",levelsvar=c("0","0.3","0.6","0.9"),yaxis=expression(rho))
plot_rho
ggsave(filename = "Figure2.png", width = width, height = height, dpi=380)
plot_bin<-plotsim(Scenariov="Bin",levelsvar=c("0","0.3","0.6","0.9"),yaxis=expression(rho))
plot_bin
ggsave(filename = "Figure3.png", width = width, height = height, dpi=380)
plot_N<-plotsim(Scenariov="N",levelsvar=c("10;50","10;100","10;1000","50;1000","100;1000"),yaxis="Number of clusters; sample size per cluster")
plot_N
ggsave(filename = "Figure4.png", width = width, height = height, dpi=380)
plot_S<-plotsim(Scenariov="S",levelsvar=c("Skewed-t","Normal","Self-masking"),yaxis="Missing process")
plot_S
ggsave(filename = "Figure5.png", width = width, height = height, dpi=380)
