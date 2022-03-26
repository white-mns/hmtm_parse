#!/bin/bash
function WGET_STATIC_PAGE() {
    MAX_P_NO=$1
    PREFIX=$2
    MAX_FAILED=$3

    FAILED=0
    for ((P_NO=1; P_NO <= MAX_P_NO; P_NO++)) {
        if [ $((FAILED)) -eq  $((MAX_FAILED)) ]; then # 指定回数以上失敗した場合、出力ページの最後に辿り着いたと判定して取得処理を終了する
            break
        fi

        for ((i=0;i < 2;i++)) { # 2回までリトライする
            if [ -s ./result/${PREFIX}/${P_NO}.html ]; then
                FAILED=0
                break
            fi

            wget -O ./result/${PREFIX}/${P_NO}.html http://www.sssloxia.jp/result/now/${PREFIX}/${P_NO}.html

            sleep 2

            if [ -s ./result/${PREFIX}/${P_NO}.html ]; then
                FAILED=0
                break
            fi
        }

        if [ ! -s /result/${PREFIX}/${P_NO}.html ]; then
            FAILED=$(( FAILED + 1 ))
        fi
    }
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
mkdir ./data/orig/result${ZIP_NAME}/result
mkdir ./data/orig/result${ZIP_NAME}/result/c
mkdir ./data/orig/result${ZIP_NAME}/result/d
mkdir ./data/orig/result${ZIP_NAME}/result/b
mkdir ./data/orig/result${ZIP_NAME}/result/pk
mkdir ./data/orig/result${ZIP_NAME}/result/prc
mkdir ./data/orig/result${ZIP_NAME}/result/rank

cd ./data/list

wget -O shoplist_${RESULT_NO0}.html http://www.sssloxia.jp/d/shoplist.aspx
wget -O spelllist_${RESULT_NO0}.html http://www.sssloxia.jp/d/spelllist.aspx
wget -O tglist_${RESULT_NO0}.html http://www.sssloxia.jp/d/tglist.aspx

find . -type f -not -name "*.gz" -not -name "*.sh" | xargs -P 3 -L 50 gzip -9f

cd $CURENT  #元のディレクトリに戻る
cd ./data/orig/result${ZIP_NAME}

wget -O template.css http://www.sssloxia.jp/template.css

for ((P_NO=1; P_NO <= MAX_P_NO; P_NO++)) {
    for ((i=0;i < 2;i++)) { # 2回までリトライする
        if [ -s ./result/d/${P_NO}.html ]; then
            break
        fi

        wget -O ./result/d/${P_NO}.html "http://www.sssloxia.jp/d/rp2.aspx?PNo=${P_NO}&Week=${RESULT_NO}"

        sleep 5

        if grep -q -e "キャラクターリスト" -e "backcircle2.png" ./result/d/${P_NO}.html; then
            rm ./result/d/${P_NO}.html
            break
        fi

        if grep -q -e "\"SubTitle\">エラーページ</TH>" ./result/d/${P_NO}.html; then
            rm ./result/d/${P_NO}.html
        fi

        if [ -s ./result/d/${P_NO}.html ]; then
            break
        fi
    }
}

WGET_STATIC_PAGE $MAX_P_NO c 100
WGET_STATIC_PAGE $MAX_P_NO b 100
WGET_STATIC_PAGE $MAX_P_NO pk 50
WGET_STATIC_PAGE $MAX_P_NO rank 100
WGET_STATIC_PAGE $MAX_P_NO prc 50

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
    rm  -r result${ZIP_NAME}

    cd ../../
fi

cd $CURENT  #元のディレクトリに戻る
