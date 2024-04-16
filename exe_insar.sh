#!/bin/bash 

# process setting
part00_unzip="off"
part01_makeslc="off"
part02_convertdem="off"
part03_regist="off"
part04_interp="off"
part05_orthodem="off" # you can change the oversampling values in gc_map2 command
part06_diff="off"
part07_filter="off"
part08_unw="off"
part09_ortho="off"
part10_demaux="off"
part11_ionospherechk="off"

#* tool and directory setting
workdir="/mnt/disks/sdb/oita/insar_strip"
python="${workdir}/python"
shell="${workdir}/sh"
gamma_mod="${workdir}/gamma_mod"
config="${gamma_mod}/makeslc.conf" # configuration file (please select satellite type)
dem_tiff="${workdir}/input_files_orig/output_COP30.tif" # "-" for automated DEM: SRTM 30m

#* Parameter Setting
ref_date="20230707" # registration master date
polar="HH" # target polarization (HH, HV, VV, VH)
rlks="3" # range look number for interferometry
azlks="3" # azimuth look number for interferometry
dem_name="XXX"
method="ORB" # methods of removing topographic and orbital fringes
wavelength="3000" # hp_filter wavelength cutoff (if 0 is set, No hp filter)
adf_nfft="32" # filtering FFT window size, 2**N, 8 --> 512 (used by adf)
unw_method="MCF" # methods for unwrap
range_ref="XXX" # phase reference point (used by mcf)
azimuth_ref="YYY" # phase reference point (used by mcf)
cc_thres="0.3" # coherence threshold for masking (used by rascc_mask)
calfactor="0" # calibration factor

if [ "${part00_unzip}" = "on" ];then bash ${shell}/part00_unzip.sh ${workdir} ${config}; fi
if [ "${part01_makeslc}" = "on" ];then bash ${shell}/part01_makeslc.sh ${workdir} ${config} ${python}; fi
if [ "${part02_convertdem}" = "on" ];then bash ${shell}/part02_convertdem.sh ${workdir} ${ref_date} ${polar} ${rlks} ${azlks} ${dem_name} ${dem_tiff}; fi
if [ "${part03_regist}" = "on" ];then bash ${shell}/part03_regist.sh ${workdir} ${ref_date} ${polar}; fi
if [ "${part04_interp}" = "on" ];then bash ${shell}/part04_interp.sh ${workdir} ${ref_date} ${polar} ${rlks} ${azlks}; fi
if [ "${part05_orthodem}" = "on" ];then bash ${shell}/part05_orthodem.sh ${workdir} ${ref_date} ${polar} ${dem_name}; fi
if [ "${part06_diff}" = "on" ];then bash ${shell}/part06_diff.sh ${workdir} ${method} ${ref_date} ${polar}; fi
if [ "${part07_filter}" = "on" ];then bash ${shell}/part07_filter.sh ${workdir} ${wavelength} ${adf_nfft} ${python}; fi
if [ "${part08_unw}" = "on" ];then bash ${shell}/part08_unw.sh ${workdir} ${wavelength} ${adf_nfft} ${range_ref} ${azimuth_ref} ${cc_thres} ${unw_method}; fi
if [ "${part09_ortho}" = "on" ];then bash ${shell}/part09_ortho.sh ${workdir} ${python} ${ref_date} ${polar} ${dem_name} ${wavelength} ${adf_nfft} ${calfactor}; fi
if [ "${part10_demaux}" = "on" ];then bash ${shell}/part10_demaux.sh ${workdir} ${ref_date} ${polar} ${python}; fi
if [ "${part11_ionospherechk}" = "on" ];then bash ${shell}/part11_ionospherechk.sh ${workdir} ${ref_date} ${polar}; fi 

