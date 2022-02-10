#===================================================================
#        能力調律情報取得パッケージ
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
package TuningAbility;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class = shift;

  bless {
        Datas => {},
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
                "p_no",
                "s_no",
                "name",
                "merit_id",
                "merit_value",
                "demerit_id",
                "demerit_value",
    ];

    $self->{Datas}{Data}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/action/tuning_ability_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜p_no,アイテムデータノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $p_no    = shift;
    my $div_alter_spell_nodes = shift;

    $self->{ENo} = $p_no;

    $self->GetTuningAbilityData($div_alter_spell_nodes);

    return;
}
#-----------------------------------#
#    所持アイテムデータ取得
#------------------------------------
#    引数｜二つ名データノード
#          所持アイテムデータノード
#-----------------------------------#
sub GetTuningAbilityData{
    my $self  = shift;
    my $div_alter_spell_nodes = shift;

    foreach my $div_alter_spell_node (@$div_alter_spell_nodes) {
        my ($s_no, $name, $merit_id, $merit_value, $demerit_id, $demerit_value, $spell_id) = (-9999, "", 0, -9999, 0, -9999, 0);
        my @child_nodes = $div_alter_spell_node->content_list;

        if ($div_alter_spell_node->as_text !~ /(増加|減少)/) {next;}

        my $merit_text = $child_nodes[0];
        my $demerit_text = $child_nodes[2];

        if ($merit_text =~ /No.([-+]?\d+) (.+?) の/) {
            $s_no = $1;
            $name = $2;
        }

        if ($merit_text =~ / の(.+?)が (\d+) (増加|減少)！/) {
            $merit_id = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
            $merit_value = $2;
            if ($3 eq "減少") {
                $merit_value *= -1;
            }
        }

        if ($merit_text =~ /の(.+?)に変化はなかった/) {
            $merit_id = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
            $merit_value = 0;
        }

        if ($merit_text =~ /No.([-+]?\d+) (.+?)(射程|命中)に変化はなかった/) { # 表記不具合対応
            $s_no = $1;
            $name = $2;
            $merit_id = $self->{CommonDatas}{ProperName}->GetOrAddId("射程");
            $merit_value = 0;
        }

        if ($demerit_text =~ /(.+?)が (\d+) (増加|減少)！/) {
            $demerit_id = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
            $demerit_value = $2;
            if ($3 eq "減少") {
                $demerit_value *= -1;
            }
        }

        if ($demerit_text =~ /(スペル使用.+?)に(.+?)(\(\d+\))*追加/) {
            $demerit_id = $self->{CommonDatas}{ProperName}->GetOrAddId("【" . $1 . "】" . "自：" .$2);
            if ($3) {
                $demerit_value = $3;
                $demerit_value =~ s/[\(\)]//g;
            }
        }

        if ($demerit_text =~ /(.+?)に変化はなかった！/) {
            $demerit_id = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
            $demerit_value = 0;
        }

        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $s_no, $name, $merit_id, $merit_value, $demerit_id, $demerit_value) ));
    }

    return;
}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜
#-----------------------------------#
sub Output{
    my $self = shift;

    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
