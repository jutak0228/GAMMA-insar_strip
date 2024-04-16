#!/bin/bash -e

#*************************************************************************************************************
#
# @script run_diff1.sh
# @brief 差分干渉SAR処理を行う
# @param[in] INPUTDIR 初期干渉SAR結果が格納されたディレクトリの親ディレクトリ
# @param[in] DEMDIR DEMデータが格納されたディレクトリ
# @param[in] INPUTDIR_SLC 位置合わせ済みSLCファイルが格納されたディレクトリ
# @param[in] MODE 処理ファイルリストを使用するかどうかの指定(ALL：ファイルリストを使用しない ADD：リストにないファイルを処理する)
# @param[in] METHOD 軌道縞、地形縞を除去する方法を指定 (EST:基線の推定による除去　ORB:軌道情報による除去)
# @return 
# @note
# 基本的に軌道情報のみから軌道縞、地形縞を除去する方法（phase_sim_orb）で差分干渉処理実施
#
#*************************************************************************************************************

######################################################################################################
# arguments
######################################################################################################

workdir="$1"
method="$2"
ref_date="$3"
polar="$4"

########################################################################
#
# @fn diff1
# @brief 基線の推定(base_init->phase_sim)による差分干渉SAR 
# @param[in] dir 初期干渉SARファイルが格納されているディレクトリ
# @return なし
# @note
# 差分干渉処理の方法によらず、最終出力ファイルは
# 拡張子diff,diff.parのシンボリックリンクとしている
# 中間ファイルは、差分干渉を行った方法がわかるように拡張子を付けている
# 拡張子:diff1.par,diff1.init
# ※基本的にこちらの処理は基線の再推定が必要になることが多く使用しない
# 
########################################################################
function diff1()
{
    dir="$1"
    cd ${workdir}/infero/${dir}
    file=`ls *.int`
    file="${file%.int}"
    master=`echo ${file} | awk -F"to" '{print $1}'`
    slave=`echo ${file}  | awk -F"to" '{print $2}'`

    dem="${workdir}/DEM/${ref_date}.hgt"

    base_init ${workdir}/rslc/${master}.rslc.par ${workdir}/rslc/${slave}.rslc.par ${file}.off ${file}.int ${file}.base 2
    phase_sim ${workdir}/rslc/${master}.rslc.par ${file}.off ${file}.base ${dem} ${file}.phase.sim
    create_diff_par ${file}.off - ${file}.diff1.par 0 < ${workdir}/gamma_mod/dif_par.txt
    sub_phase ${file}.int ${file}.phase.sim ${file}.diff1.par ${file}.diff1.init0 1 0
    rm -rf ${file}.phase.sim

    if [ -L "${file}.diff.par" ];then unlink ${file}.diff.par >/dev/null 2>&1; fi
    if [ -L "${file}.diff" ];then unlink ${file}.diff >/dev/null 2>&1; fi
    ln -s ${file}.diff1.par ${file}.diff.par >/dev/null 2>&1
    ln -s ${file}.diff1.init0 ${file}.diff >/dev/null 2>&1
}

########################################################################
#
# @fn diff_orb
# @brief 軌道情報による(phase_sim_orb)差分干渉SAR処理
# @param[in] dir 初期干渉SARファイルが格納されているディレクトリ
# @return なし
# @note
# 差分干渉処理の方法によらず、最終出力ファイルは
# 拡張子diff,diff.parのシンボリックリンクとしている
# 中間ファイルは、差分干渉を行った方法がわかるように拡張子を付けている
# 拡張子：diff1_orb.par diff1.init_orb(_orbを付けている)
#
########################################################################
function diff_orb()
{
    dir="$1"
    cd ${workdir}/infero/${dir}
    file=`ls *.int`
    file="${file%.int}"
    master=`echo ${file} | awk -F"to" '{print $1}'`
    slave=`echo ${file}  | awk -F"to" '{print $2}'`

    dem="${workdir}/DEM/${ref_date}.hgt"

    phase_sim_orb ${workdir}/rslc/${master}.rslc.par ${workdir}/rslc/${slave}.rslc.par ${file}.off ${dem} ${file}.phase.sim_orb
    create_diff_par ${file}.off - ${file}.diff1_orb.par 0 < ${workdir}/gamma_mod/dif_par.txt
    sub_phase ${file}.int ${file}.phase.sim_orb ${file}.diff1_orb.par ${file}.diff1.init_orb 1 0
    rm -rf ${file}.phase.sim_orb

    if [ -L "${file}.diff.par" ];then unlink ${file}.diff.par >/dev/null 2>&1; fi
    if [ -L "${file}.diff" ];then unlink ${file}.diff >/dev/null 2>&1; fi
    ln -s ${file}.diff1_orb.par ${file}.diff.par >/dev/null 2>&1
    ln -s ${file}.diff1.init_orb ${file}.diff >/dev/null 2>&1
    
}

export -f diff1
export -f diff_orb

#######################################################################################################
# main
#######################################################################################################
cd ${workdir}/infero

# 差分干渉SAR処理

list=()
counter=0
for dir in `ls -F | grep "/"`
do
    list[${counter}]="${dir%/}"
    counter=`expr ${counter} + 1`
done

if [ "${#list[@]}" -ne 0 ];then
    for dir in ${list[@]}
    do
        case ${method} in
        EST)
            diff1 $dir
            ;;
        ORB)
            diff_orb $dir
            ;;
        esac
    done
else
    echo "NO PROCESS DIR"
fi
