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
    my $table_backboard_nodes = shift;

    if ($self->{ResultNo} >= 2) {
        $self->GetSpellData($table_backboard_nodes);

    } else {
        $self->GetSpellData_0_1($table_backboard_nodes);
    }

    return;
}

#-----------------------------------#
#    スペルデータ取得
#------------------------------------
#    引数｜スペルデータノード
#-----------------------------------#
sub GetSpellData{
    my $self = shift;
    my $table_backboard_nodes = shift;
    my $text = "";
    my ($base_spell_id, $base_spell_name) = (0, "");

    foreach my $table_node (@$table_backboard_nodes) {
        my $tr_nodes = &GetNode::GetNode_Tag("tr", \$table_node);

        foreach my $tr_node (@$tr_nodes) {
            my ($spell_name, $sp, $element_id, $range, $power, $hit, $gems, $timing_id, $class_id) = ("", 0, 0, 0, 0, 0, "", 0, 0);

            my @child_nodes = $tr_node->content_list;

            $spell_name = $child_nodes[0]->as_text;
            $sp = $child_nodes[1]->as_text;

            if ($sp eq "SP") { # 行の内容が項目の説明のとき、新しい魔法の種類に移ったと判定して説明データと派生元スペルIDを初期化する
                $text = "";
                $base_spell_id = 0;
                $base_spell_name = "";
                next;
            }

            $element_id = $self->{CommonDatas}{ProperName}->GetOrAddId($child_nodes[2]->as_text);
            $range = ($child_nodes[3]->as_text ne "-") ? $child_nodes[3]->as_text : -1;
            $power = $child_nodes[4]->as_text;
            $hit = ($child_nodes[5]->as_text ne "-") ? $child_nodes[5]->as_text : -1;
            $timing_id = $self->{CommonDatas}{ProperName}->GetOrAddId($child_nodes[6]->as_text);
            $class_id = $self->{CommonDatas}{ProperName}->GetOrAddId($child_nodes[7]->as_text);

            if ($text eq "") { # 保持している説明データが空のときは公式スペルと判定して説明を保存する
                $text = $child_nodes[8]->as_text;

            } else { # 説明情報が保存されているなら説明欄をTG情報として扱う
                $gems = $child_nodes[8]->as_text;
                $gems = ($gems) ? ",".$gems : $gems;
            }

            my $spell_id = $self->{CommonDatas}{SpellData}->GetOrAddId(1, [$spell_name, $sp, $element_id, $text, $range, $power, $hit, $gems, $timing_id, $class_id, $base_spell_id]);
            $self->{CommonDatas}{NameToBaseSpell}{$spell_name} = $base_spell_name;

            if ($base_spell_id == 0) {
                # 派生元の基本スペルの場合、自身を派生元スペルとして再登録
                $base_spell_id = $spell_id;
                $base_spell_name = $spell_name;
                $spell_id = $self->{CommonDatas}{SpellData}->GetOrAddId(1, [$spell_name, $sp, $element_id, $text, $range, $power, $hit, $gems, $timing_id, $class_id, $base_spell_id]);
                $self->{CommonDatas}{NameToBaseSpell}{$spell_name} = $base_spell_name;
            }
        }
    }

    return;
}

#-----------------------------------#
#    スペルデータ取得
#------------------------------------
#    引数｜スペルデータノード
#-----------------------------------#
sub GetSpellData_0_1{
    my $self = shift;
    my $table_backboard_nodes = shift;

    my $tr_nodes = &GetNode::GetNode_Tag("tr", \$$table_backboard_nodes[0]);
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
        $gems = ($gems) ? ",".$gems : $gems;

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
