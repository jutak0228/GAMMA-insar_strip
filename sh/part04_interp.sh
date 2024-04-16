#!/bin/bash -e

#*************************************************************************************************************
#
# @script run_interp.sh
# @brief 初期干渉SAR処理を行う
# @param[in] INPUTDIR SLCファイルが格納されたディレクトリ
# @param[in] OUTPUTDIR 初期干渉SARファイルの保存先
# @param[in] MLIDIR 強度画像ディレクトリ
# @param[in] RLKS 処理ルック数（レンジ方向）
# @param[in] ALKS 処理ルック数（アジマス方向）
# @param[in] MODE 処理ファイルリストを使用するかどうかの指定(ALL：使用しない ADD：リストにないファイルを処理する)
# @return 
# @note
#
#*************************************************************************************************************

######################################################################################################
# arguments
######################################################################################################

workdir="$1"
ref_date="$2"
polar="$3"
rlks="$4"
azlks="$5"

########################################################################
#
# @fn interf
# @brief 初期干渉SAR処理
# @param[in] master マスターのファイル名（拡張子なし）
# @param[in] slave  スレーブのファイル名（拡張子なし）
# @param[in] rlks   レンジ方向のルック数
# @param[in] alks   アジマス方向のルック数
# @return なし
# @note
#
########################################################################
function interf()
{

    master="$1"
    slave="$2"
    rlks="$3"
    alks="$4"

    masdate=`echo ${master} | sed -e "s/[^0-9]//g"`
    slvdate=`echo ${slave}  | sed -e "s/[^0-9]//g"`

    output="${workdir}/infero/${masdate}to${slvdate}" 

    mkdir -p ${output}
    create_offset ${master}.rslc.par ${slave}.rslc.par ${output}/${master}to${slave}.off < ${workdir}/gamma_mod/prm.txt
    SLC_intf ${master}.rslc ${slave}.rslc ${master}.rslc.par ${slave}.rslc.par ${output}/${master}to${slave}.off ${output}/${master}to${slave}.int ${rlks} ${alks}
    if [ -L "${output}/${master}.rmli" ];then unlink ${output}/${master}.rmli >/dev/null 2>&1; fi
    ln -s ${workdir}/rmli/${master}.rmli ${output}/${master}.rmli >/dev/null 2>&1
}

########################################################################
#
# @fn createRMLI
# @brief 位置合わせ済みSLCファイルから強度画像ファイル(RMLI)を作成する
# @param[in] inputRslc RSLCファイル名
# @param[in] rlks   レンジ方向のルック数
# @param[in] alks   アジマス方向のルック数
# @return なし
# @note
#
########################################################################
function create_rmli()
{
    rslc="$1"
    rlks="$2"
    alks="$3"

    multi_look ${rslc}.rslc ${rslc}.rslc.par ${workdir}/rmli/${rslc}.rmli ${workdir}/rmli/${rslc}.rmli.par ${rlks} ${alks} 
}

#######################################################################################################
# main
#######################################################################################################

export -f interf
export -f create_rmli

###############################################
# 初期干渉SAR処理
###############################################
cd ${workdir}
if [ -e rmli ];then rm -r rmli; fi
mkdir -p rmli
if [ -e infero ];then rm -r infero; fi
mkdir -p infero

cd ${workdir}/rslc
cp ${ref_date}_${polar}.slc ${ref_date}_${polar}.rslc
cp ${ref_date}_${polar}.slc.par ${ref_date}_${polar}.rslc.par

# make array list
LIST_ARR_MASTER=()
LIST_ARR_SLAVE=()
counter=0

rslcNum=`ls -1 *.rslc 2>/dev/null | wc -l`

if [ "${rslcNum}" -ne 0 ];then

    for rslc_file in `ls -F *.rslc.par`
    do
        LIST_ARR_MASTER[${counter}]="${rslc_file%.rslc.par}"
        create_rmli ${rslc_file%.rslc.par} $rlks $azlks
        counter=`expr ${counter} + 1`
    done
    LIST_ARR_SLAVE=(${LIST_ARR_MASTER[@]})

    # interferometry
    for master in ${LIST_ARR_MASTER[@]}
    do
        for slave in ${LIST_ARR_SLAVE[@]}
        do
            masdate=`echo ${master} | sed -e "s/[^0-9]//g"`
            slvdate=`echo ${slave} | sed -e "s/[^0-9]//g"`

            if [ ${masdate} -lt ${slvdate} ];then
                echo "master date = ${masdate}"
                echo "slave date = ${slvdate}"
                interf ${master} ${slave} ${rlks} ${azlks}
            fi
        done
    done
else
    echo "NO PROCESS FILE"
fi
