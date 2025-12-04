# Load required libraries
# If not installed: install.packages(c("tidyverse", "psych", "rstatix"))
library(tidyverse)
library(ggprism)
library(ggpubr)
library(psych)       # describe()
library(rstatix)     # friedman_test(), pairwise_wilcox_test(), effect sizes

# -----------------------------
# Paths (edit to your setup)
# -----------------------------
#input_folder <- "/Users/dcarrillo/Alpha-mini/python-nao/Results/_ERD_cbase_true"
#output_folder <- "/Users/dcarrillo/Alpha-mini/python-nao/Results/_ERD_cbase_true"
#input_folder <- "/Users/dcarrillo/Alpha-mini/python-nao/Results/_ERD_test"
#output_folder <- "/Users/dcarrillo/Alpha-mini/python-nao/Results/_ERD_test"
input_folder <- "C:/Users/pc2/Proyecto_Alphamini/python-nao/Results/_ERD_cbase_true"
output_folder <- "C:/Users/pc2/Proyecto_Alphamini/python-nao/Results/_ERD_cbase_true"
#input_folder <- "C:/Users/pc2/Proyecto_Alphamini/python-nao/Results/_ERD_test"
#output_folder <- "C:/Users/pc2/Proyecto_Alphamini/python-nao/Results/_ERD_test"
output_folder_txt <- file.path(output_folder, "txt")
plot_folder <- file.path(output_folder, "plots")
sum_folder <- file.path(output_folder, "summaries")

# Create output folders if needed
if (!dir.exists(output_folder_txt)) dir.create(output_folder_txt, recursive = TRUE)
if (!dir.exists(plot_folder)) dir.create(plot_folder, recursive = TRUE)
if (!dir.exists(sum_folder)) dir.create(sum_folder, recursive = TRUE)

# -----------------------------
# Helper: Run Friedman + Wilcoxon (paired) for a set of 3 conditions
# -----------------------------da
run_rm_tests <- function(df, vars, subject_col) {
  stopifnot(length(vars) >= 3)
  dat <- df %>% select(any_of(c(subject_col , vars)))
  long <- dat %>% gather(key = "condition", value = "psd", vars[1], vars[2], vars[3]) %>% convert_as_factor(Participants, condition)
  
  fried <- friedman_test(long, psd ~ condition | Participants)
  fried_eff <- friedman_effsize(long, psd ~ condition | Participants)
  
  # Pairwise Wilcoxon signed-rank tests (Bonferroni adjusted)
  pw <- pairwise_wilcox_test(long, psd ~ condition, paired = TRUE, p.adjust.method = "bonferroni") %>%
    add_significance("p.adj")
  
  # Effect sizes (r) for each pair
  pairs <- combn(vars, 2, simplify = FALSE)
  eff_list <- lapply(pairs, function(p) {
    tmp_wide <- dat %>% select(all_of(c(subject_col, p)))
    tmp <- tmp_wide %>% pivot_longer(cols = all_of(p), names_to = "condition", values_to = "psd")
    ee <- suppressWarnings(wilcox_effsize(tmp, psd ~ condition, paired = TRUE))
    ee$group1 <- p[1]
    ee$group2 <- p[2]
    ee
  })
  w_eff <- bind_rows(eff_list) %>% select(group1, group2, effsize, magnitude)
  
  list(fried = fried, fried_eff = fried_eff, pairwise = pw, w_eff = w_eff )
}

# -----------------------------
# Storage for global summaries
# -----------------------------
friedman_summary <- list()
wilcoxon_summary <- list()

# -----------------------------
# Batch over CSV files
# -----------------------------
csv_files <- list.files(input_folder, pattern = "\\.csv$", full.names = TRUE)

if (length(csv_files) == 0) {
  cat("No CSV files found in:", input_folder, "\n")
} else {
  for (file in csv_files) {
    base_name <- tools::file_path_sans_ext(basename(file))
    cat("\nProcessing:", base_name, "\n")
    
    df <- suppressMessages(readr::read_csv(file, skip = 0))
    
    subject_col <- "Participants"
    df <- df %>% mutate(Participants = row_number())
    
    right_vars <- c("Video_Right", "Robot_Right", "VR_Right")
    left_vars <- c("Video_Left", "Robot_Left", "VR_Left")
    both_vars    <- c("Video_Both", "Robot_Both", "VR_Both")
    
    vars_all <- c(right_vars, left_vars, both_vars)
    df_selected <- df %>% select(any_of(c(subject_col,vars_all)))
    df_vars <- df %>% select(any_of(vars_all))
    
    # ----------------- Descriptives & Normality -----------------
    descr <- tryCatch(psych::describe(df_vars), error = function(e) NULL)
    
    shapiro_results <- lapply(df_vars, function(x) {
      x <- x[is.finite(x)]
      if (length(x) >= 3 && length(x) <= 5000) {
        tryCatch(shapiro.test(x), error = function(e) NA)
      } else {
        NA
      }
    })
    
    # ----------------- Friedman & Wilcoxon (paired) -------------
    tests <- list()
    if (all(right_vars %in% names(df))) tests$Right <- run_rm_tests(df_selected, right_vars, subject_col)
    if (all(left_vars %in% names(df))) tests$Left <- run_rm_tests(df_selected, left_vars, subject_col)
    if (all(both_vars %in% names(df)))    tests$Both    <- run_rm_tests(df_selected, both_vars, subject_col)
    
    # ----------------- Collect summaries ------------------------
    for (block in names(tests)) {
      friedman_summary[[length(friedman_summary)+1]] <- tests[[block]]$fried %>% mutate(file = base_name, block = block)
      wilcoxon_summary[[length(wilcoxon_summary)+1]] <- tests[[block]]$pairwise %>% mutate(file = base_name, block = block)
    }
    
    # ----------------- Write TXT report -------------------------
    txt_path <- file.path(output_folder_txt, paste0(base_name, ".txt"))
    sink(txt_path)
    
    cat("FILE:", basename(file), "\n\n")
    
    cat("== Descriptive Statistics ==\n")
    if (!is.null(descr)) print(descr) else cat("(descriptives failed)\n")
    
    cat("\n== Normality (Shapiro-Wilk) ==\n")
    for (nm in names(shapiro_results)) {
      cat("\n--", nm, "--\n")
      print(shapiro_results[[nm]])
    }
    
    for (block in names(tests)) {
      cat("\n\n==============================\n")
      cat("Repeated-Measures Block:", block, "\n")
      cat("==============================\n")
      
      cat("\nFriedman Test\n")
      print(tests[[block]]$fried)
      cat("\nKendall's W (effect size)\n")
      print(tests[[block]]$fried_eff)
      
      cat("\nPairwise Wilcoxon Signed-Rank (Bonferroni-adjusted)\n")
      print(tests[[block]]$pairwise)
      cat("\nWilcoxon Effect Sizes (r)\n")
      print(tests[[block]]$w_eff)
    }
    
     sink()

    
    # ----------------- Plots (boxplots + histograms) -------------
    var_indices <- c(1, 2, 3)
    movs = names(tests)
    for (i in 1:3) {
       
       if (tests[[movs[i]]]$fried$p < 0.05) {
          
        base_title = substr(base_name, 1, nchar(base_name) - 9)
        
        dat <- df_selected %>% select(any_of(c(1 , var_indices+1)))
        plot_df <- dat %>% gather(key = "setting", value = "ERD", vars_all[var_indices[1]], vars_all[var_indices[2]], vars_all[var_indices[3]]) %>% convert_as_factor(Participants, setting)
        plot_df[plot_df==0]<- NA

        p1 = ggboxplot(plot_df, x = "setting", y = "ERD", color = "setting", palette = "simpsons", add = "jitter") + 
          #stat_pvalue_manual(test_pwc, label = "p.adj.signif", hide.ns = TRUE, tip.length = 0.01) +
          theme(legend.position="none") + 
          labs(
            title = paste(base_title,movs[i]),
            subtitle = get_test_label(tests[[movs[i]]]$fried),
            caption = paste("* Wilcoxon test | p.adjust: Bonferroni")
          )
        
        test_pwc <- tests[[movs[i]]]$pairwise  %>% add_y_position(step.increase = 0.2) %>% filter(p.adj < 0.05)
        if (nrow(test_pwc) != 0) {p1 + add_pvalue(test_pwc, label = "p.adj.signif")} 
        
        ggsave(file.path(plot_folder, paste0(base_name,"_", movs[i], "_boxplot.png")), p1, width = 5, height = 4, dpi = 150)
        }
        
        var_indices = var_indices + 3
    }
  }
  
  # ----------------- Save global summaries ---------------------
  if (length(friedman_summary) > 0) {
    fried_df <- bind_rows(friedman_summary)
    write_csv(fried_df, file.path(sum_folder, "friedman_summary.csv"))
  }
  if (length(wilcoxon_summary) > 0) {
    wilcox_df <- bind_rows(wilcoxon_summary)
    write_csv(wilcox_df, file.path(sum_folder, "wilcoxon_summary.csv"))
  }
}

