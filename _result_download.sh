#!/bin/bash

CURENT=`pwd`	#実行ディレクトリの保存
cd `dirname $0`	#解析コードのあるディレクトリで作業をする

#------------------------------------------------------------------
# 更新回数、再更新番号の定義確認、設定

RESULT_NO=`printf "%02d" $1`
GENERATE_NO=$2

if [ $GENERATE_NO -eq 0 ]; then
    ZIP_NAME=${RESULT_NO0}
else
    ZIP_NAME=${RESULT_NO0}-$GENERATE_NO
fi

mkdir ./data/orig/result${RESULT_NO}
mkdir ./data/orig/result${RESULT_NO}/result
mkdir ./data/orig/result${RESULT_NO}/result/c

cd ./data/orig/result${RESULT_NO}

wget -O s.css http://www.sssloxia.jp/template.css

for ((P_NO=1;P_NO <= 730;P_NO++)) {
    for ((i=0;i < 2;i++)) { # 2回までリトライする
        if [ -s ./result/c/${P_NO}.html ]; then
            break
        fi

        wget -O ./result/c/${P_NO}.html http://www.sssloxia.jp/d/rp.aspx?PNo=${P_NO}

        sleep 5

        if grep -q "キャラクターリスト" ./result/c/${P_NO}.html; then
            WGET_END=1
            rm ./result/c/${P_NO}.html
            break
        fi

        if [ -s ./result/c/${P_NO}.html ]; then
            break
        fi
    }
}

cd $CURENT  #元のディレクトリに戻る

find ./data/orig/result${RESULT_NO} -type f -empty -delete

# ファイルを圧縮
if [ -d ./data/orig/result${RESULT_NO} ]; then
    
    cd ./data/orig/

    echo "orig zip..."
    zip -qr result${ZIP_NAME}.zip result${RESULT_NO}
    echo "rm directory..."
    rm  -r result${RESULT_NO}
        
    cd ../../
fi

cd $CURENT  #元のディレクトリに戻る
