# Libraries
library(tidyverse)
library(ggprism)
library(ggpubr)
library(psych)     
library(rstatix)     
library(openxlsx)
library(ggplot2)
library(dplyr)
library(tidyr)


# -------
#  Paths 
# -------

input_folder = "./Alpha-mini/python-nao/results/_ERD_cbase_plot/"
output_folder = "./Alpha-mini/python-nao/results/_ERD_cbase_plot/"
plot_folder = file.path(output_folder, "plots")

# Create output folders if needed
if (!dir.exists(plot_folder)) dir.create(plot_folder, recursive = TRUE)

# ----------------------
#  Batch over CSV files
# ----------------------
channels = c("FC1","FCz","FC2","C3","C4","CP1","CPz","CP2")
bands = c("theta", "alpha", "beta")

for (ch in channels) {
    for (bd in bands) {
      
      mean_name = paste(input_folder,ch,"_", bd, "_avg.csv",sep = "")
      std_name = paste(input_folder,ch, "_",bd, "_std.csv", sep = "")
      
      mean_df = read_csv(mean_name, skip = 0)
      std_df = read_csv(std_name, skip = 0)
      
      #right_vars = c("Control_Right", "Robot_Right","Video_Right", "VR_Right")
      #left_vars = c("Control_Left", "Robot_Left", "Video_Left", "VR_Left")
      #both_vars    = c("Control_Both", "Robot_Both","Video_Both", "VR_Both") 
      
      right_vars = c("Robot_Right","Video_Right", "VR_Right")
      left_vars = c("Robot_Left", "Video_Left", "VR_Left")
      both_vars    = c("Robot_Both","Video_Both", "VR_Both") 
      
      vars_all = c(right_vars, left_vars, both_vars)
      
      # ----------------- Plots (boxplots + histograms) -------------
      var_indices = c(4,7,10)
      base_name = paste(ch, "_", bd)
      movs = c('right','left','both')
      
      for (i in 1:3) {
          
          selected_mean = mean_df %>% select(any_of(c(1,var_indices+1)))
          selected_std = std_df %>% select(any_of(c(1,var_indices+1)))
          
          means_long <- pivot_longer(selected_mean, -Time, values_to = "mean", names_to = "setting")
          sd_long <- pivot_longer(selected_std, -Time, values_to = "sd", names_to = "setting")
          
          df_join <- means_long %>% 
            left_join(sd_long)
          #> Joining, by = c("date", "variable")
          
          custom_colors <- c(rgb(0.07, 0.54, 0.7), rgb(0.51, 0.83, 0.51), rgb(0.97, 0.55, 0.42))  # azul, naranja, verde
          legend_labels <- c("Robot", "Video", "VR")
          
          p1 = ggplot(data = df_join, aes(x = Time, group = setting)) + 
            geom_line(aes(y = mean, color = setting), linewidth = 1) + 
            geom_ribbon(aes(y = mean, ymin = mean - sd, ymax = mean + sd, fill = setting), alpha = .2) +
            xlab("Time (ms)") + 
            ylab("Mean ERD (%)") +
            ggtitle(paste("Channel:", ch, "| Band:", bd, "| Move:", movs[i])) +
            scale_color_manual(values = custom_colors, labels = legend_labels) +
            scale_fill_manual(values = custom_colors, labels = legend_labels) +
            geom_vline(xintercept = c(500, 3500), color = "coral4", linetype = "dashed", linewidth = 0.7) +
            xlim(min(df_join$Time), max(df_join$Time)) +
            theme_bw() +  
            theme(legend.key = element_blank()) + 
            theme(plot.margin=unit(c(1,1,1,1),"cm"))+
            theme(legend.position.inside = c(0.8,0.8), legend.direction = "vertical") +
            theme(legend.title = element_blank())
            theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 13),
            axis.title = element_text(size = 12),
            axis.text = element_text(size = 10))
          
          ggsave(file.path(plot_folder, paste0(base_name,"_", movs[i], ".png")), p1, width = 7, height = 4, dpi = 150)
      
      }
    }
}

