clear all
cls

net install ipachecksetup, all replace from("C:\Users\Ishamial Boako\Box Sync\git\dmsetup")

ipachecksetup using "sample xls/CAGE_Baseline (Current) 042319.xlsx", template(hfc_inputs.xlsm) outfile(sample_output/hfc_inputs_cage.xlsm) wide
