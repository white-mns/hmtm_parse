#===================================================================
#        陳腐化情報取得パッケージ
#-------------------------------------------------------------------
#            (C) 2021 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#
use strict;
use warnings;
require "./source/lib/Store_Data.pm";
require "./source/lib/Store_HashData.pm";
use ConstData;        #定数呼び出し
use source::lib::GetNode;

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package Obsolescence;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class = shift;

  bless {
        Datas => {},
        Tmps => {},
  }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init{
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;

    #初期化
    $self->{Datas}{Data} = StoreData->new();
    my $header_list = "";

    $header_list = [
                "result_no",
                "generate_no",
                "gems",
                "gem_num",
                "obsolescence",
    ];

    $self->{Datas}{Data}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/data/obsolescence_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜p_no,スペルデータノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $p_no    = shift;
    my $skilldata_nodes = shift;

    $self->{ENo} = $p_no;

    $self->GetSpellData($skilldata_nodes);

    return;
}

#-----------------------------------#
#    所持スペルデータ取得
#------------------------------------
#    引数｜陳腐化数値
#          TG文字列
#-----------------------------------#
sub SetObsolescenceData{
    my $self = shift;
    my $obsolescence = shift;
    my $orig_gems = shift;

    my ($gems, $gem_num) = ("", 0);

    if (!$orig_gems) {return;}

    my @sorted_gem_array = sort {$a cmp $b} split(",", $orig_gems);

    foreach my $tg_name (@sorted_gem_array) {
        if (!$tg_name) {next;}

        $gems = ($gems eq "") ? $tg_name : "$gems,$tg_name";
        $gem_num += 1;
    }

    $gems = ($gems) ? ",".$gems."," : $gems;

    $self->{Tmps}{Obsolescence}{$gems} = [$gem_num, $obsolescence];

    return;
}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜
#-----------------------------------#
sub Output{
    my $self = shift;

    foreach my $gems (sort {$a cmp $b} keys(%{$self->{Tmps}{Obsolescence}})){
        my $data = $self->{Tmps}{Obsolescence}{$gems};
        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $gems, $$data[0], $$data[1]) ));
    }

    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
