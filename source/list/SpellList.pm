#===================================================================
#        スペルリスト情報取得パッケージ
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
package SpellList;

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
#    引数｜スペルデータノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $table_backboard_node = shift;

    $self->GetSpellData($table_backboard_node);

    return;
}

#-----------------------------------#
#    スペルデータ取得
#------------------------------------
#    引数｜スペルデータノード
#-----------------------------------#
sub GetSpellData{
    my $self  = shift;
    my $table_backboard_node = shift;

    my $tr_nodes   = &GetNode::GetNode_Tag("tr", \$table_backboard_node);
    shift(@$tr_nodes);

    my ($spell_name, $sp, $element_id, $text, $range, $power, $hit, $gems, $timing_id, $class_id) = ("", 0, 0, "", 0, 0, 0, "", 0, 0);

    foreach my $tr_node (@$tr_nodes) {
        my @child_nodes = $tr_node->content_list;

        $spell_name = $child_nodes[0]->as_text;
        $sp = $child_nodes[1]->as_text;
        $element_id = $self->{CommonDatas}{ProperName}->GetOrAddId($child_nodes[2]->as_text);
        $text = $child_nodes[3]->as_text;
        $range = ($child_nodes[4]->as_text ne "-") ? $child_nodes[4]->as_text : -1;
        $power = $child_nodes[5]->as_text;
        $hit = ($child_nodes[6]->as_text ne "-") ? $child_nodes[6]->as_text : -1;
        $timing_id = $self->{CommonDatas}{ProperName}->GetOrAddId($child_nodes[7]->as_text);
        $class_id = $self->{CommonDatas}{ProperName}->GetOrAddId($child_nodes[8]->as_text);
        $gems = (scalar(@child_nodes) >= 10 && $child_nodes[9] =~ /HASH/) ? $child_nodes[9]->as_text : "";

        $self->{CommonDatas}{SpellData}->GetOrAddId(1, [$spell_name, $sp, $element_id, $text, $range, $power, $hit, $gems, $timing_id, $class_id]);
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
