#!/bin/bash -e
# generate SLC data
# argument: setting parameters for SLC generation

########################################################################
#
# @fn makeSLC_ALOS
# @brief ALOS PALSARデータの再生処理
# @param[in] LED LED file path
# @param[in] IMG IMG file path
# @param[in] DATE for observation
# @param[in] OUTPUTDIR output directory
# FBDのデータ（2重偏波）のオーバーサンプリング処理も実施している
#
########################################################################
function makeSLC_ALOS()
{
    LED="$1"
    IMG="$2"
    DATE="$3"
    OUTPUTDIR="$4"
    FILE_MODE="$5"

    FBDflag="false"
    if [ ! -d L10/log ];then mkdir -p L10/log; fi
    polar=`basename ${IMG} | awk -F"-" '{print $2}' | tr [:lower:] [:upper:]`
    if [ "${FILE_MODE}" = "FBD" ];then FBDflag="true"; fi
    productId=`basename ${IMG} | awk -F"-" '{print $4}'`
    node=${productId:6}
    if [ "${node^^}" = "A" ];then orbitDirec="Asc"; else orbitDirec="Des"; fi
    sceneId=`basename ${IMG} | awk -F"-" '{print $3}'`
    orbitPath=`python ${python}/getBeamId.py ${LED}`
    flame=${sceneId:11}
    outputFileBase="${DATE}_${polar}"
    if [ ! -e "${OUTPUTDIR}/${orbitDirec}/${orbitPath}_${flame}" ];then
        mkdir -p ${OUTPUTDIR}/${orbitDirec}/${orbitPath}_${flame}
    fi

    slcFile="${OUTPUTDIR}/${orbitDirec}/${orbitPath}_${flame}/${outputFileBase}.slc"
    slcparFile="${OUTPUTDIR}/${orbitDirec}/${orbitPath}_${flame}/${outputFileBase}.slc.par"
    
    ceos_list=$(mktemp /tmp/ALOS_L1.0.XXXXXX)
    echo "${LED} ${IMG} ${DATE} ${polar}" >> ${ceos_list}
    logfile="L10/log/log_${outputFileBase}"
    touch ${logfile}
    proc_list=$(mktemp /tmp/ALOS_L1.0_proc_all.XXXXXX)

    PALSAR_pre_proc ${ceos_list} ${PALSAR_ANT} L10 ${logfile} ${proc_list} 1
    PALSAR_pre_proc ${ceos_list} ${PALSAR_ANT} L10 ${logfile} ${proc_list} 2
    PALSAR_pre_proc ${ceos_list} ${PALSAR_ANT} L10 ${logfile} ${proc_list} 3
    PALSAR_pre_proc ${ceos_list} ${PALSAR_ANT} L10 ${logfile} ${proc_list} 5
    PALSAR_proc_all ${proc_list} L10 ${OUTPUTDIR}/${orbitDirec}/${orbitPath}_${flame} ${OUTPUTDIR}/${orbitDirec}/${orbitPath}_${flame}/ ${OUTPUTDIR}/${orbitDirec}/${orbitPath}_${flame}/ 1 1 0 16384 0.0
    
    if [ "${FBDflag}" = "true" ];then
        mkdir -p ${OUTPUTDIR}/${orbitDirec}/${orbitPath}_${flame}/org
        mv ${slcFile} ${OUTPUTDIR}/${orbitDirec}/${orbitPath}_${flame}/org/
        mv ${slcparFile} ${OUTPUTDIR}/${orbitDirec}/${orbitPath}_${flame}/org/
        orgSlcFile="${OUTPUTDIR}/${orbitDirec}/${orbitPath}_${flame}/org/${outputFileBase}.slc"
        orgSlcParFile="${OUTPUTDIR}/${orbitDirec}/${orbitPath}_${flame}/org/${outputFileBase}.slc.par"
        SLC_ovr ${orgSlcFile} ${orgSlcParFile} ${slcFile} ${slcparFile} 2
    fi

    rm -rf ${ceos_list} ${proc_list}

    org=`cat ${slcparFile} | grep "calibration_gain:"`
    NUM=`cat ${slcparFile} | grep "calibration_gain:" | awk -F":" '{print $2}' |tr -d [:space:] | awk -F"dB" '{print $1}'`
    calFactor=`expr -1 \* \( ${A} \)`
    rep=`echo -e $org | sed -e "s/${NUM}/\ \ ${calFactor}/g"`
    sed -i "s/${org}/${rep}/g" ${slcparFile}
}

########################################################################
#
# @fn makeSLC_ALOS2
# @brief ALOS2 PALSAR-2 SLC data generation
# @param[in] LED LED file path
# @param[in] IMG IMG file path
# @param[in] OUTPUTDIR outpur diretory 
#
########################################################################
function makeSLC_ALOS2()
{
    
    LED="$1"
    IMG="$2"
    OUTPUTDIR="$3"

    echo $OUTPUTDIR

    polar=`basename ${IMG} | awk -F"-" '{print $2}'`
    date=`basename ${IMG} | awk -F"-" '{print "20"$4}'`
    productId=`basename ${IMG} | awk -F"-" '{print $5}'`

    outputFileBase="${date}_${polar}"

    slcFile="${OUTPUTDIR}/${outputFileBase}.slc"
    slcparFile="${OUTPUTDIR}/${outputFileBase}.slc.par"
    par_EORC_PALSAR ${LED} ${slcparFile} ${IMG} ${slcFile}

    org=`cat ${slcparFile} | grep "calibration_gain:"`
    NUM=`cat ${slcparFile} | grep "calibration_gain:" | awk -F":" '{print $2}' |tr -d [:space:] | awk -F"dB" '{print $1}'`
    calFactor=`expr -1 \* \( ${A} \)`
    rep=`echo -e $org | sed -e "s/${NUM}/\ \ ${calFactor}/g"`
    sed -i "s/${org}/${rep}/g" ${slcparFile}
    
}

########################################################################
#
# @fn makeSLC_StriX
# @brief StriX SLC data generation
# @param[in] LED LED file path
# @param[in] IMG IMG file path
# @param[in] OUTPUTDIR outpur diretory 
#
########################################################################
function makeSLC_StriX()
{
    
    LED="$1"
    IMG="$2"
    OUTPUTDIR="$3"

    echo $OUTPUTDIR

    polar=`basename ${IMG} | awk -F"-" '{print $2}'`
    tmp_date=`basename ${IMG} | awk -F"-" '{print $4}'`
    date=`echo ${tmp_date} | awk -F"T" '{print $1}'`
    modeID=`basename ${IMG} | awk -F"-" '{print $5}'`

    outputFileBase="${date}_${polar}"

    slcFile="${OUTPUTDIR}/${outputFileBase}.slc"
    slcparFile="${OUTPUTDIR}/${outputFileBase}.slc.par"
    par_STRIX ${LED} ${slcparFile} ${IMG} ${slcFile}

    # org=`cat ${slcparFile} | grep "calibration_gain:"`
    # NUM=`cat ${slcparFile} | grep "calibration_gain:" | awk -F":" '{print $2}' |tr -d [:space:] | awk -F"dB" '{print $1}'`
    # calFactor=`expr -1 \* \( ${A} \)`
    # rep=`echo -e $org | sed -e "s/${NUM}/\ \ ${calFactor}/g"`
    # sed -i "s/${org}/${rep}/g" ${slcparFile}
    
}

########################################################################
#
# @fn makeSLC_TSX
# @brief TerraSAR-X data generation
# @param[in] COS COS file (signal data) path
# @param[in] XML XML file (annotation file) path
# @param[in] OUTPUTDIR output directory
#
########################################################################
function makeSLC_TSX()
{

    COS="$1"
    XML="$2"
    OUTPUTDIR="$3"

    polar=`basename ${COS} | awk -F"_" '{print $2}'  | sed -e "s/[^a-zA-Z]*//g"`
    date=`basename ${XML}  | awk -F"_" '{print $13}' | awk -F"T" '{print $1}' | sed -e "s/[^0-9]*//g"`

    # orbitDirection=`cat ${XML} | grep "<orbitDirection>" | sed -e "s/>/,/g" | sed -e "s/<\//,/g" | awk -F"," '{print $2}' | sed -e "s/[^a-zA-Z]*//g"`
    # if [ "${orbitDirection^^}" = "DESCENDING" ];then orbitDirec="Des"; else orbitDirec="Asc"; fi
    # relOrbit=`cat ${XML} | grep "<relOrbit>" | sed -e "s/>/,/g" | sed -e "s/<\//,/g" | awk -F"," '{print $2}' | sed -e "s/[^0-9]*//g"`

    outputFileBase="${date}_${polar}"

    slcFile="${OUTPUTDIR}/${outputFileBase}.slc"
    slcparFile="${OUTPUTDIR}/${outputFileBase}.slc.par"
    par_TX_SLC ${XML} ${COS} ${slcparFile} ${slcFile}
    
}

########################################################################
#
# @fn makeSLC_RSAT2
# @brief RADARSAT2 data generation
# @param[in] IMG IMG file (signal data) path
# @param[in] INPUTDIR input file directory
# @param[in] OUTPUTDIR output data directory
# メタファイル(product.xml)ルックアップテーブル(lutSigma.xml)はINPUTDIR
# に含まれている必要がある
#
########################################################################
function makeSLC_RSAT2()
{
    
    IMG="$1"
    INPUTDIR="$2"
    OUTPUTDIR="$3"

    date=`cat ${INPUTDIR}/product.xml       | grep "<rawDataStartTime>" | sed -e "s/>/#/g" | sed -e "s/<\//#/g" | awk -F"#" '{print $2}' | awk -F"T" '{print $1}' | sed -e "s/[^0-9]//g"`
    polar=`cat ${INPUTDIR}/product.xml      | grep "<polarizations>"    | sed -e "s/>/,/g" | sed -e "s/<\//,/g" | awk -F"," '{print $2}' | sed -e "s/[^a-zA-Z]*//g"`
    passDirec=`cat ${INPUTDIR}/product.xml | grep "<passDirection>"    | sed -e "s/>/,/g" | sed -e "s/<\//,/g" | awk -F"," '{print $2}' | sed -e "s/[^a-zA-Z]*//g"`

    if [ "${passDirec^^}" = "DESCENDING"  ];then orbitDirec="Des"; else orbitDirec="Asc"; fi
    beamId=`cat ${INPUTDIR}/product.xml | grep "<beamModeMnemonic>" | sed -e "s/>/,/g" | sed -e "s/<\//,/g" | awk -F"," '{print $2}' | sed -e "s/[^a-zA-Z0-9]*//g"`

    outputFileBase="${date}_${polar}"
    if [ ! -e "${OUTPUTDIR}/${orbitDirec}/${beamId}" ];then
        mkdir -p ${OUTPUTDIR}/${orbitDirec}/${beamId}
    fi

    slcFile="${OUTPUTDIR}/${orbitDirec}/${beamId}/${outputFileBase}.slc"
    slcparFile="${OUTPUTDIR}/${orbitDirec}/${beamId}/${outputFileBase}.slc.par"
    par_RSAT2_SLC ${INPUTDIR}/product.xml ${INPUTDIR}/lutSigma.xml ${IMG} ${polar} ${slcparFile} ${slcFile}
    
}

########################################################################
#
# @fn makeSLC_CSK
# @brief COSMO-SkyMed SLC data generation
# @param[in] 
# @param[in] 
# @param[in] 
#
########################################################################
function makeSLC_CSK()
{
        
    HDF5="$1"
    OUTPUTDIR="$2"

    polar=`basename ${HDF5} | awk -F"_" '{print $6}'`
    date=`basename ${HDF5}  | awk -F"_" '{print $9}' | cut -c 1-8`

    # outputFileBase="${date}_${polar}"
    # slcFile="${OUTPUTDIR}/${outputFileBase}.slc"
    # slcparFile="${OUTPUTDIR}/${outputFileBase}.slc.par"
    # par_CS_SLC ${HDF5} ${slcparFile} ${slcFile}
    par_CS_SLC $HDF5 ${OUTPUTDIR}/${date} ${OUTPUTDIR}/${date}

    # rename slc and slc.par from YYYYMMDD_polar_beamid to YYYYMMDD_polar
    mv ${OUTPUTDIR}/${date}_${polar}_??.slc ${OUTPUTDIR}/${date}_${polar}.slc
    mv ${OUTPUTDIR}/${date}_${polar}_??.slc.par ${OUTPUTDIR}/${date}_${polar}.slc.par
}

########################################################################
#
# @fn radcal_para
# @brief SLCファイルの放射補正を行う
# @param[in] SLCFILE SLCファイルパス
# @param[in] FCASE データ型設定（衛星種により決まる）
# @param[in] OUTPUTDIR 放射補正データの出力先
# @return
# @note
# FCASE:1or3 設定は以下の通り
#  1: fcomplex --> fcomplex (pairs of float)
#  2: fcomplex --> scomplex (pairs of short integer)
#  3: scomplex --> fcomplex
#  4: scomplex --> scomplex 
#
########################################################################
function radcal_para()
{
    
    SLCFILE="$1"
    FCASE="$2"
    OUTPUTDIR="$3"

    baseSlcName=`basename ${SLCFILE}`

    slcFile="${SLCFILE}"
    slcparFile="${slcFile}.par"
    cslcfile="${OUTPUTDIR}/${baseSlcName%.slc}.slc"
    cslcparFile="${OUTPUTDIR}/${baseSlcName%.slc}.slc.par"

    radcal_SLC ${slcFile} ${slcparFile} ${cslcfile} ${cslcparFile} ${FCASE}
    
}

export -f makeSLC_ALOS
export -f makeSLC_ALOS2
export -f makeSLC_TSX
export -f makeSLC_RSAT2
export -f makeSLC_StriX
export -f radcal_para

echo "START PROCESS..."

######################################################################################################
# main process
######################################################################################################

workdir="$1"
config="$2"
python="$3"

##################################################
#  load config file
##################################################

source ${config}

##################################################
#  create SLC
##################################################

echo "**************** creating SLC file ********************"

cd ${workdir}
if [ -e slc ];then rm -r slc; fi
mkdir -p slc
slcdir="${workdir}/slc"
if [ -e rslc ];then rm -r rslc; fi
mkdir -p rslc
rslcdir="${workdir}/rslc"
cd ${workdir}/input_files

case ${SATELLITE_TYPE} in
  ALOS)
    export PALSAR_ANT
    export CF1
    export A

    for dir in `ls -F | grep "/"`
    do
        cd ${dir}
	    fileNum=`ls -1 IMG* | wc -l`
    	if [ ${fileNum} -eq 2 ];then
            FILE_MODE="FBD"
        else
	        FILE_MODE="FBS"
	    fi
        
        for file in `ls -1 IMG*`
        do
            polar=`echo ${file}     | awk -F"-" '{print $2}'`
            sceneID=`echo ${file}   | awk -F"-" '{print $3}'`
            productID=`echo ${file} | awk -F"-" '{print $4}'`
            proc_level=`echo ${productID} | sed -e "s/[^0-9]//g"`
            if [ $proc_level = "1.0" ]; then
                date=`cat workreport | grep "Img_SceneCenterDateTime" | awk -F"=" '{print $2}' | awk -F" " '{print $1}' | sed -e "s/[^0-9]//g"`
            elif [ $proc_level = "1.1" ]; then
                date=`cat summary.txt   | grep "Lbi_ObservationDate" | awk -F"=" '{print $2}' | sed -e "s/[^0-9]//g"`
            fi

            IMGfile="${file}"
            LEDfile="LED-${sceneID}-${productID}"
            makeSLC_ALOS ${LEDfile} ${IMGfile} ${date} ${slcdir} ${FILE_MODE}
        done
        cd ../
    done
    ;;

  ALOS2)
    export CF1
    export A
    for dir in `ls -F | grep "/"`
    do
        cd ${dir}
        for file in `ls -1 IMG*`
        do
            sceneID=`echo ${file}   | awk -F"-" '{print $3"-"$4}'`
            productID=`echo ${file} | awk -F"-" '{print $5}'`
            IMGfile="${file}"
            LEDfile="LED-${sceneID}-${productID}"
            makeSLC_ALOS2 $LEDfile $IMGfile $slcdir
        done
        cd ../
    done
    ;;

  RSAT2)
    #make list
    LIST_ARR_INPUTRSDIR=()
    LIST_ARR_IMAGERY=()
    # counter=0
    # init=$(pwd)
    for dir in `ls -F | grep "/" | grep -v "00_SLC" | grep -v "01_CSLC"`
    do
        cd ${dir}
        IMAGERYfile=`ls imagery_*.tif`
        LIST_ARR_IMAGERY[${counter}]="${dir}/${IMAGERYfile}"
        LIST_ARR_INPUTRSDIR[${counter}]="${dir}"
        # counter=`expr ${counter} + 1`
        # cd ${init}
    done
    makeSLC_RSAT2 ${LIST_ARR_IMAGERY[@]} ${LIST_ARR_INPUTRSDIR[@]} ${slcdir}
    ;;

  TSX)
    # counter=0
    # init=$(pwd)
    for dir in `ls -F | grep "/"`
    do
        cd ${dir}
        cd IMAGEDATA
        cos=`ls *.cos`
        COSfile="${workdir}/input_files/${dir}IMAGEDATA/${cos}"
        XMLfile="${workdir}/input_files/${dir}${dir%/}.xml"
        makeSLC_TSX ${COSfile} ${XMLfile} ${slcdir}
        # counter=`expr ${counter} + 1`
    done
    cd ../../
    ;;

  CSK)
    # make list
    # LIST_ARR_H5=()
    # LIST_ARR_XML=()
    # counter=0
    # init=$(pwd)
    for dir in `ls -F | grep "/"`
    do
        cd ${dir}
        hdf5=`ls *.h5`
        HDF5file="${workdir}/input_files/${dir}${hdf5}"
        makeSLC_CSK ${HDF5file} ${slcdir}
        # counter=`expr ${counter} + 1`
        cd ../
    done
    ;;

  StriX)
    for dir in `ls -F | grep "/"`
    do
        cd ${dir}
        for file in `ls -1 IMG*`
        do
            sceneID=`echo ${file}   | awk -F"-" '{print $3"-"$4}'`
            modeID=`echo ${file} | awk -F"-" '{print $5}'`
            IMGfile="${file}"
            LEDfile="LED-${sceneID}-${modeID}"
            makeSLC_StriX $LEDfile $IMGfile $slcdir
        done
        cd ../
    done
    ;;

  *)
    # ここには基本的に来ない
    echo "ERROR : invalid parameter"
    ;;
esac

##########################################################
# 放射補正処理
##########################################################

if [ "${RADCAL_FLAG}" = "ON" ];then
    cd ${workdir}
    if [ -e "cslc" ];then rm -r cslc; fi
    mkdir -p cslc
    cslcdir="${workdir}/cslc"
    cd ${slcdir}
    for file in `ls *.slc`
    do
        case ${SATELLITE_TYPE} in
          TSX)
               fcase=3
               ;;
          CSK)
               fcase=3
               ;;
           *)
               fcase=1
               ;;
        esac
    radcal_para ${file} ${fcase} ${cslcdir}
    done
    cp -r ${cslcdir}/* ${rslcdir}
    rm -rf ${slcdir} ${cslcdir}
else
    cp -r ${slcdir}/* ${rslcdir}
    rm -rf ${slcdir}
fi
