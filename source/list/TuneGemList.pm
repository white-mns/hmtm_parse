#===================================================================
#        チューンジェムリスト情報取得パッケージ
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
package TuneGemList;

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

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜チューンジェムデータノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $table_backboard_node = shift;

    $self->GetTuneGemData($table_backboard_node);

    return;
}

#-----------------------------------#
#    チューンジェムデータ取得
#------------------------------------
#    引数｜チューンジェムデータノード
#-----------------------------------#
sub GetTuneGemData{
    my $self  = shift;
    my $table_backboard_node = shift;

    my $tr_nodes   = &GetNode::GetNode_Tag("tr", \$table_backboard_node);
    shift(@$tr_nodes);

    my ($tg_name, $sp, $type_id, $text, $range, $power, $hit, $timing_id, $class_id) = ("", "", 0, "");

    foreach my $tr_node (@$tr_nodes) {
        my @child_nodes = $tr_node->content_list;

        $tg_name = $child_nodes[0]->as_text;
        $sp = $child_nodes[1]->as_text;
        $type_id = $self->{CommonDatas}{ProperName}->GetOrAddId($child_nodes[2]->as_text);
        $text = $child_nodes[3]->as_text;

        $self->{CommonDatas}{TuneGemData}->GetOrAddId(1, [$tg_name, $sp, $type_id, $text]);
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
