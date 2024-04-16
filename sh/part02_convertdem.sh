#!/bin/bash

# Part 2: Prepare DEM and geocode reference

work_dir="$1"
ref_date="$2"
polar="$3"
rlks="$4"
azlks="$5"
dem_name="$6"
dem_tiff="$7"

cd ${work_dir}
if [ -e DEM_prep ];then rm -r DEM_prep; fi
mkdir -p DEM_prep
slc_dir="${work_dir}/rslc"
cd ${slc_dir}

# multilook reference
multi_look ${ref_date}_${polar}.slc ${ref_date}_${polar}.slc.par ${ref_date}_${polar}.mli ${ref_date}_${polar}.mli.par ${rlks} ${azlks} 1
# estimate corber latitude and longitude
if [ -e SLC_corners.txt ]; then rm -f SLC_corners.txt; fi
SLC_corners ${ref_date}_${polar}.mli.par > SLC_corners.txt
rm -f ${ref_date}_${polar}.mli ${ref_date}_${polar}.mli.par

# setting variable for clipping dem data
# -->
# lower left  corner longitude, latitude (deg.): 139.06  35.15
# upper right corner longitude, latitude (deg.): 140.29  36.06

lowleft_lat=`cat SLC_corners.txt | grep "lower left" | awk -F" " '{print $8}' | tr -d [:space:]`
lowleft_lon=`cat SLC_corners.txt | grep "lower left" | awk -F" " '{print $7}' | tr -d [:space:]`
uppright_lat=`cat SLC_corners.txt | grep "upper right" | awk -F" " '{print $8}' | tr -d [:space:]`
uppright_lon=`cat SLC_corners.txt | grep "upper right" | awk -F" " '{print $7}' | tr -d [:space:]`

# generate dem file: SRTM (auto) or other manural dem files
if [ ${dem_tiff} = "-" ]; then
    # download filled SRTM1 using elevation module
    eio clip -o ${work_dir}/DEM_prep/SRTM.tif --bounds $lowleft_lon $lowleft_lat $uppright_lon $uppright_lat
    # DEM definition with manual processing
    dem="${work_dir}/DEM_prep/SRTM.tif"
elif [ ${dem_tiff} != "-" ]; then
    dem="${dem_tiff}"
fi

cd ${work_dir}/DEM_prep

# convert the GeoTIFF DEM into Gamma Software format, including geoid to ellipsoid height reference conversion
dem_import ${dem} ${dem_name}.dem ${dem_name}.dem_par 0 1 $DIFF_HOME/scripts/egm96.dem $DIFF_HOME/scripts/egm96.dem_par 0
