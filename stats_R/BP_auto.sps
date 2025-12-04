* Encoding: UTF-8.

* ----------------------*.
* SPSS + Python
* --------------------- *.

SET DECIMAL DOT.
SET UNICODE ON.
DATASET CLOSE ALL.

BEGIN PROGRAM.

import os
import spss
import spssaux

input_folder = r"C:\Users\pc2\Proyecto_Alphamini\python-nao\Results\_ERD_cbase"  
output_folder = r"C:\Users\pc2\Proyecto_Alphamini\python-nao\Results\_ERD_cbase"
output_folder_txt = r"C:\Users\pc2\Proyecto_Alphamini\python-nao\Results\_ERD_cbase\txt_spss"

csv_files = [f for f in os.listdir(input_folder) if f.endswith(".csv")]
print(csv_files)

if not csv_files:
    print("No se encontraron archivos CSV.")
else:
    for file in csv_files:
        base_name = os.path.splitext(file)[0]
        input_path = os.path.join(input_folder, file)
        output_path = os.path.join(output_folder, base_name + ".spv")
        output_path_txt = os.path.join(output_folder_txt, base_name + ".txt")

        print(f"\n Procesando: {file}")

        # Preparar output
        spss.Submit("OUTPUT CLOSE ALL.")
        spss.Submit(f'OUTPUT NEW NAME=out_{base_name}.')
        spss.Submit(f'OUTPUT SAVE OUTFILE="{output_path}".')

        # Importar CSV
        spss.Submit(f"""
        DATASET CLOSE ALL.
        GET DATA  /TYPE=TXT
          /FILE="{input_path}"
          /ENCODING='UTF8'
          /DELIMITERS=","
          /QUALIFIER='"'
          /ARRANGEMENT=DELIMITED
          /FIRSTCASE=2
          /DATATYPEMIN PERCENTAGE=95.0
          /VARIABLES=
          Participants AUTO
          Control_Right AUTO
          Control_Left AUTO
          Control_Both AUTO
          Video_Right AUTO
          Video_Left AUTO
          Video_Both AUTO
          Robot_Right AUTO
          Robot_Left AUTO
          Robot_Both AUTO
          VR_Right AUTO
          VR_Left AUTO
          VR_Both AUTO
          /MAP.
        DATASET NAME {base_name} WINDOW=FRONT.
        """)

        # Ejecutar análisis
        spss.Submit(f"""
        EXAMINE VARIABLES=Video_Right Video_Left Video_Both Robot_Right  Robot_Left Robot_Both VR_Right
            VR_Left VR_Both
          /PLOT BOXPLOT HISTOGRAM NPPLOT
          /COMPARE GROUPS
          /STATISTICS DESCRIPTIVES
          /CINTERVAL 95
          /MISSING LISTWISE
          /NOTOTAL.

        GLM Video_Right Robot_Right VR_Right
          /WSFACTOR=setting 3 Polynomial
          /MEASURE=psd
          /METHOD=SSTYPE(3)
          /PLOT=PROFILE(setting) TYPE=LINE ERRORBAR=NO MEANREFERENCE=NO YAXIS=AUTO
          /EMMEANS=TABLES(setting) COMPARE ADJ(BONFERRONI)
          /PRINT=DESCRIPTIVE ETASQ
          /CRITERIA=ALPHA(.05)
          /WSDESIGN=setting.

        GLM Video_Left Robot_Left VR_Left
          /WSFACTOR=setting 3 Polynomial
          /MEASURE=psd
          /METHOD=SSTYPE(3)
          /PLOT=PROFILE(setting) TYPE=LINE ERRORBAR=NO MEANREFERENCE=NO YAXIS=AUTO
          /EMMEANS=TABLES(setting) COMPARE ADJ(BONFERRONI)
          /PRINT=DESCRIPTIVE ETASQ
          /CRITERIA=ALPHA(.05)
          /WSDESIGN=setting.

        GLM Video_Both Robot_Both VR_Both
          /WSFACTOR=setting 3 Polynomial
          /MEASURE=psd
          /METHOD=SSTYPE(3)
          /PLOT=PROFILE(setting) TYPE=LINE ERRORBAR=NO MEANREFERENCE=NO YAXIS=AUTO
          /EMMEANS=TABLES(setting) COMPARE ADJ(BONFERRONI)
          /PRINT=DESCRIPTIVE ETASQ
          /CRITERIA=ALPHA(.05)
          /WSDESIGN=setting.
         
         NPAR TESTS
          /FRIEDMAN=Video_Right Robot_Right VR_Right
          /MISSING LISTWISE.
          
        NPAR TESTS
          /FRIEDMAN=Video_Left Robot_Left VR_Left
          /MISSING LISTWISE.
          
        NPAR TESTS
          /FRIEDMAN=Video_Both Robot_Both VR_Both
          /MISSING LISTWISE.

        NPAR TESTS
          /WILCOXON=Video_Right Video_Right Robot_Right Video_Left Video_Left Robot_Left Video_Both
            Video_Both Robot_Both WITH Robot_Right VR_Right VR_Right Robot_Left VR_Left VR_Left Robot_Both
            VR_Both VR_Both (PAIRED)
          /MISSING ANALYSIS.
          
          NPAR TESTS
          /WILCOXON=Control_Right Control_Left Control_Both Control_Right Control_Left Control_Both Control_Right 
            Control_Left Control_Both WITH Video_Right Video_Left Video_Both Robot_Right Robot_Left Robot_Both VR_Right VR_Left VR_Both (PAIRED)
          /MISSING ANALYSIS.

        * Guardar y cerrar output.
        OUTPUT SAVE OUTFILE="{output_path}".    
                
        OUTPUT EXPORT
          /CONTENTS EXPORT=VISIBLE
          /TEXT DOCUMENTFILE="{output_path_txt}".
        
        OUTPUT CLOSE NAME=out_{base_name}.

        """)

END PROGRAM.
