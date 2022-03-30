#!/bin/bash
function WGET_GREP_OLD_BATTLE_PAGE() {
    RESULT_NO=$1
    GENERATE_NO=$2
    PREFIX=$3

    # grepを用いてキャラ結果から戦闘結果の番号のみを抽出する。その後sortとuniqによって重複番号を除外する。
    GREP_TARGET=`grep -rhoP "a href=\"\.\.\/${PREFIX}\/\d+\.html" ./result/c | grep -oP "\d+" | sort | uniq`

    for FILE_NO in ${GREP_TARGET}
    do
        for ((i=0;i < 2;i++)) { # 2回までリトライする
            if [ -s ./result/${PREFIX}/${FILE_NO}.html ]; then
                FAILED=0
                break
            fi

            wget -O ./result/${PREFIX}/${FILE_NO}.html http://www.sssloxia.jp/result/${RESULT_NO}-${GENERATE_NO}/${PREFIX}/${FILE_NO}.html

            sleep 2

            if [ -s ./result/${PREFIX}/${FILE_NO}.html ]; then
                FAILED=0
                break
            fi
        }
    done
}

CURENT=`pwd`	#実行ディレクトリの保存
cd `dirname $0`	#解析コードのあるディレクトリで作業をする

#------------------------------------------------------------------
# 更新回数、再更新番号の定義確認、設定

RESULT_NO=`printf "%d" $1`
RESULT_NO0=`printf "%02d" $1`
GENERATE_NO=$2
MAX_P_NO=1100

if [ -z "$2" ]; then
    exit
fi

if [ $GENERATE_NO -eq 0 ]; then
    ZIP_NAME=${RESULT_NO0}
else
    ZIP_NAME=${RESULT_NO0}-$GENERATE_NO
fi

mkdir ./data/orig/result${ZIP_NAME}

cd ./data/orig/result${ZIP_NAME}

WGET_GREP_OLD_BATTLE_PAGE $RESULT_NO $GENERATE_NO b
WGET_GREP_OLD_BATTLE_PAGE $RESULT_NO $GENERATE_NO pk
WGET_GREP_OLD_BATTLE_PAGE $RESULT_NO $GENERATE_NO rank
WGET_GREP_OLD_BATTLE_PAGE $RESULT_NO $GENERATE_NO prc

# 更新結果上は削除されているキャラデータページを削除
for ((P_NO=1; P_NO <= MAX_P_NO; P_NO++)) {
    if [ ! -s ./result/c/${P_NO}.html ] && [ -s ./result/d/${P_NO}.html ]; then
        rm ./result/d/${P_NO}.html
        break
    fi
}

cd $CURENT  #元のディレクトリに戻る

find ./data/orig/result${ZIP_NAME} -type f -empty -delete

# ファイルを圧縮
if [ -d ./data/orig/result${ZIP_NAME} ]; then

    cd ./data/orig/

    echo "orig zip..."
    zip -qr result${ZIP_NAME}.zip result${ZIP_NAME}
    echo "rm directory..."
    #rm  -r result${ZIP_NAME}

    cd ../../
fi

cd $CURENT  #元のディレクトリに戻る
