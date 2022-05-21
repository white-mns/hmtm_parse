#===================================================================
#        共通データ管理パッケージ
#-------------------------------------------------------------------
#            (C) 2022 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#
use strict;
use warnings;

use ConstData;
use HTML::TreeBuilder;
use source::lib::GetNode;

require "./source/data/StoreProperName.pm";
require "./source/data/StoreProperData.pm";

require "./source/data/PkPkk.pm";

use ConstData;        #定数呼び出し

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package CommonData;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class        = shift;

  bless {
    Datas         => {},
    DataHandlers  => {},
    Methods       => {},
  }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init{
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;

    #インスタンス作成
    $self->{DataHandlers}{ProperName}     = StoreProperName->new();
    $self->{DataHandlers}{SpellData}      = StoreProperData->new();
    $self->{DataHandlers}{TuneGemData}    = StoreProperData->new();
    $self->{DataHandlers}{PkPkk}          = PkPkk->new();

    #他パッケージへの引き渡し用インスタンス
    $self->{CommonDatas}{ProperName}      = $self->{DataHandlers}{ProperName};
    $self->{CommonDatas}{SpellData}       = $self->{DataHandlers}{SpellData};
    $self->{CommonDatas}{TuneGemData}     = $self->{DataHandlers}{TuneGemData};
    $self->{CommonDatas}{PkPkk}           = $self->{DataHandlers}{PkPkk};
    $self->{CommonDatas}{NameToBaseSpell} = {};

    my $header_list = "";
    my $output_file = "";

    # 固有名詞の初期化
    $header_list = [
                "proper_id",
                "name",
    ];
    $output_file = "./output/data/". "proper_name" . ".csv";
    $self->{DataHandlers}{ProperName}->Init($header_list, $output_file," ");

    # スキル情報の初期化
    $header_list = [
                "spell_id",
                "name",
                "sp",
                "element_id",
                "text",
                "range",
                "power",
                "hit",
                "gems",
                "timing_id",
                "class_id",
                "base_spell_id",
    ];
    $output_file = "./output/data/". "spell_data" . ".csv";
    $self->{DataHandlers}{SpellData}->Init($header_list, $output_file, [" ", 0, 0, " ", 0, 0, 0, " ", 0, 0, 0]);

    # チューンジェム情報の初期化
    $header_list = [
                "tg_id",
                "name",
                "sp",
                "type_id",
                "text",
    ];
    $output_file = "./output/data/". "tune_gem_data" . ".csv";
    $self->{DataHandlers}{TuneGemData}->Init($header_list, $output_file, [" ", " ", 0, " "]);

    $self->{DataHandlers}{PkPkk}->Init($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas});

    return;
}

#-----------------------------------#
#   このパッケージでデータ解析はしない
#-----------------------------------#
#
#-----------------------------------#
sub Execute{
    my $self        = shift;
    return ;
}

#-----------------------------------#
#    出力
#-----------------------------------#
#    引数｜ファイルアドレス
#-----------------------------------#
sub Output{
    my $self = shift;
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    foreach my $object( values %{ $self->{DataHandlers} } ) {
        $object->Output();
    }
    return;
}

1;
