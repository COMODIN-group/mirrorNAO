import re
import os 

import pandas as pd

def wilcoxon_search(file):

    results = []

    with open(file, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, start=1):
            if "Asymp. Sig. (2-tailed)" in line:
                # Buscar los números precedidos por "|,"
                values = re.findall(r"\|\s*(?:,|<\.)\s*([0-9]*\.?[0-9]+)", line)
                results.append(values[:9]) # Solo los primeros 9

    return results

def friedmann_search(file):

    pattern = r"Asymp\. Sig\.\|\s*(?:,|<\.)\s*([0-9]*\.?[0-9]+)"
    results= []

    with open(file, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, start=1):
            matches= re.findall(pattern,line)
            for value in matches:
                results.append(value)

    return results

friedmann = []

wilcoxon = []

wilcoxon_c = []

ch_names = ['FC1', 'FCz', 'FC2', 'C3', 'C4', 'CP1', 'CPz', 'CP2']

band_names = ["theta","alpha","beta"]

txt_folder = "C:/Users/pc2/Proyecto_Alphamini/python-nao/Results/_ERD_cbase/txt_spss/"  
output_folder = "C:/Users/pc2/Proyecto_Alphamini/python-nao/Results/_ERD_cbase/"  

for i in ch_names:
    for j in band_names:
        txt_file = i + "_" + j + "PSD_erd_pos.txt"
        input_path = txt_folder + txt_file

        print(input_path)

        resultados_f = friedmann_search(input_path)
        print(resultados_f)

        friedmann.append(resultados_f)

        resultados_w = wilcoxon_search(input_path)
        resultados_w_c = resultados_w[1]
        resultados_w = resultados_w[0]

        wilcoxon.append(resultados_w)
        wilcoxon_c.append(resultados_w_c)

friedmann_df = pd.DataFrame(friedmann)

print(friedmann_df)

wilcoxon_df = pd.DataFrame(wilcoxon)
#wilcoxon_df.iloc[4,8] = wilcoxon_df.iloc[4,3]
#wilcoxon_df.iloc[4,3] = 999

wilcoxon_c_df = pd.DataFrame(wilcoxon_c)
#wilcoxon_df.iloc[4,8] = wilcoxon_df.iloc[4,3]
#wilcoxon_df.iloc[4,3] = 999

print(wilcoxon_df)

np_test = pd.concat([friedmann_df, wilcoxon_df, wilcoxon_c_df], axis=1)

np_test = np_test.replace("000","999")
np_test = np_test.map(lambda x: '.' + str(x))
np_test = np_test.apply(pd.to_numeric)

print(np_test.shape)  # (24, 12)
print(np_test.head())

np_test.to_excel("NP_tests_ERD_pos.xlsx")