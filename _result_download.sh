#!/bin/bash

CURENT=`pwd`	#実行ディレクトリの保存
cd `dirname $0`	#解析コードのあるディレクトリで作業をする

#------------------------------------------------------------------
# 更新回数、再更新番号の定義確認、設定

RESULT_NO=`printf "%d" $1`
RESULT_NO0=`printf "%02d" $1`
GENERATE_NO=$2
MAX_P_NO=990

if [ -z "$2" ]; then
    exit
fi

if [ $GENERATE_NO -eq 0 ]; then
    ZIP_NAME=${RESULT_NO0}
else
    ZIP_NAME=${RESULT_NO0}-$GENERATE_NO
fi

mkdir ./data/orig/result${RESULT_NO0}
mkdir ./data/orig/result${RESULT_NO0}/result
mkdir ./data/orig/result${RESULT_NO0}/result/c
mkdir ./data/orig/result${RESULT_NO0}/result/d

cd ./data/list

wget -O shoplist_${RESULT_NO0}.html http://www.sssloxia.jp/d/shoplist.aspx
wget -O spelllist_${RESULT_NO0}.html http://www.sssloxia.jp/d/spelllist.aspx
wget -O tglist_${RESULT_NO0}.html http://www.sssloxia.jp/d/tglist.aspx

find . -type f -not -name "*.gz" -not -name "*.sh" | xargs -P 3 -L 50 gzip -9f

cd $CURENT  #元のディレクトリに戻る
cd ./data/orig/result${RESULT_NO0}

wget -O s.css http://www.sssloxia.jp/template.css

for ((P_NO=1; P_NO <= MAX_P_NO; P_NO++)) {
    for ((i=0;i < 2;i++)) { # 2回までリトライする
        if [ -s ./result/d/${P_NO}.html ]; then
            break
        fi

        wget -O ./result/d/${P_NO}.html "http://www.sssloxia.jp/d/rp2.aspx?PNo=${P_NO}&Week=${RESULT_NO}"

        sleep 5

        if grep -q "キャラクターリスト" ./result/d/${P_NO}.html; then
            rm ./result/d/${P_NO}.html
            break
        fi

        if [ -s ./result/d/${P_NO}.html ]; then
            break
        fi
    }
}

for ((P_NO=1; P_NO <= MAX_P_NO; P_NO++)) {
    for ((i=0;i < 2;i++)) { # 2回までリトライする
        if [ -s ./result/c/${P_NO}.html ]; then
            break
        fi

        wget -O ./result/c/${P_NO}.html http://www.sssloxia.jp/result/now/c/${P_NO}.html

        sleep 5

        if [ -s ./result/c/${P_NO}.html ]; then
            break
        fi
    }
}

# 更新結果上は削除されているキャラデータページを削除
for ((P_NO=1; P_NO <= MAX_P_NO; P_NO++)) {
    if [ ! -s ./result/c/${P_NO}.html ]; then
        rm ./result/d/${P_NO}.html
        break
    fi
}

cd $CURENT  #元のディレクトリに戻る

find ./data/orig/result${RESULT_NO0} -type f -empty -delete

# ファイルを圧縮
if [ -d ./data/orig/result${RESULT_NO0} ]; then

    cd ./data/orig/

    echo "orig zip..."
    zip -qr result${ZIP_NAME}.zip result${RESULT_NO0}
    echo "rm directory..."
    rm  -r result${RESULT_NO0}

    cd ../../
fi

cd $CURENT  #元のディレクトリに戻る
