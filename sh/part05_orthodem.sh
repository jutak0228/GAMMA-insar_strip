#!/bin/bash

workdir="$1"
ref_date="$2"
polar="$3"
dem_name="$4"

cd ${workdir}
if [ -e "DEM" ];then rm -r DEM; fi
mkdir -p "DEM"
cd DEM

dem="${workdir}/DEM_prep/${dem_name}.dem"
dem_par="${workdir}/DEM_prep/${dem_name}.dem_par"

# copy master mli image to demdir
cp ../rmli/${ref_date}_${polar}.rmli ./
cp ../rmli/${ref_date}_${polar}.rmli.par ./

# set parameters
range_samples=`cat ${ref_date}_${polar}.rmli.par | grep "range_samples" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
azimuth_lines=`cat ${ref_date}_${polar}.rmli.par | grep "azimuth_lines" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
range_pixel_spacing=`cat ${ref_date}_${polar}.rmli.par | grep "range_pixel_spacing"   | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`
azimuth_pixel_spacing=`cat ${ref_date}_${polar}.rmli.par | grep "azimuth_pixel_spacing" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`

# DEM oversampling factors:  3 in lat 3 in lon
# calculate geocoding lookup table using gc_map
if [ -e EQA.dem_par ];then rm EQA.dem_par; fi #  (to assure that the output DEM parameter file does not exist)
gc_map2 ${ref_date}_${polar}.rmli.par $dem_par $dem EQA.dem_par EQA.dem ${ref_date}.lt 5 5 ${ref_date}.ls_map - ${ref_date}.inc - - ${ref_date}.sim_sar - - - - - - 0 -
# gc_map2 ${ref_date}_${polar}.rmli.par $dem_par $dem EQA.dem_par EQA.dem ${ref_date}.lt - - ${ref_date}.ls_map - ${ref_date}.inc - - ${ref_date}.sim_sar - - - - - - 0 -

width=`cat EQA.dem_par | grep "width" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
nlines=`cat EQA.dem_par | grep "nlines" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`

# do refinement of lookup table using a simulated backscatter image calculated using pixel_area program
pixel_area ${ref_date}_${polar}.rmli.par EQA.dem_par EQA.dem ${ref_date}.lt ${ref_date}.ls_map ${ref_date}.inc ${ref_date}.pix_sigma0 ${ref_date}.pix_gamma0 20
raspwr ${ref_date}.pix_gamma0 $range_samples - - - - - - - ${ref_date}.pix_gamma0.bmp

# determine geocoding refinement using offset_pwrm
create_diff_par ${ref_date}_${polar}.rmli.par - ${ref_date}.diff_par 1 0
offset_pwrm ${ref_date}.pix_sigma0 ${ref_date}_${polar}.rmli ${ref_date}.diff_par ${ref_date}.offs ${ref_date}.ccp 128 128 ${ref_date}.offsets 1 64 64 0.1 5
offset_fitm ${ref_date}.offs ${ref_date}.ccp ${ref_date}.diff_par ${ref_date}.coffs ${ref_date}.coffsets 0.1 3

# refine geocoding lookup table
gc_map_fine ${ref_date}.lt ${width} ${ref_date}.diff_par ${ref_date}.lt_fine 1

# apply again pixel_area using the refined lookup table to assure that the
# simulated image uses the refined geometry
pixel_area ${ref_date}_${polar}.rmli.par EQA.dem_par EQA.dem ${ref_date}.lt_fine ${ref_date}.ls_map ${ref_date}.inc ${ref_date}.pix_sigma0_fine ${ref_date}.pix_gamma0_fine
raspwr ${ref_date}.pix_gamma0_fine $range_samples - - - - - - - ${ref_date}.pix_gamma0_fine.bmp

# resample the MLI data from the slant range to the map geometry and visualize it
geocode_back ${ref_date}_${polar}.rmli ${range_samples} ${ref_date}.lt_fine EQA.${ref_date}_${polar}.rmli $width $nlines 5 0 - - 3
raspwr EQA.${ref_date}_${polar}.rmli $width - - - - - - - EQA.${ref_date}_${polar}.rmli.bmp

# resample the DEM heights to the slant range MLI geometry
geocode ${ref_date}.lt_fine EQA.dem ${width} ${ref_date}.hgt ${range_samples} ${azimuth_lines} 2 0
