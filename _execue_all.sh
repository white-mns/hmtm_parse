#!/bin/bash

CURENT=`pwd`	#実行ディレクトリの保存
cd `dirname $0`	#解析コードのあるディレクトリで作業をする

for ((RESULT_NO=$1;RESULT_NO <= $2;RESULT_NO++)) {
    for ((GENERATE_NO=5;GENERATE_NO >=0;GENERATE_NO--)) {
        RESULT_NO0=`printf "%02d" $RESULT_NO`

        if [ $GENERATE_NO -eq 0 ]; then
            ZIP_NAME=${RESULT_NO0}
        else
            ZIP_NAME=${RESULT_NO0}-$GENERATE_NO
        fi

        if [ -f ./data/orig/result${ZIP_NAME}.zip ]; then
            echo "start $ZIP_NAME"
            ./execute.sh $RESULT_NO $GENERATE_NO
            break
        fi
    }
}

cd $CURENT  #元のディレクトリに戻る
