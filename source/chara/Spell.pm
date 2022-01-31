#===================================================================
#        習得スペル情報取得パッケージ
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
package Spell;

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
                "sp",
                "power",
                "hit",
                "range",
                "timing_id",
                "gems",
                "spell_id",
    ];

    $self->{Datas}{Data}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/spell_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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
#    引数｜二つ名データノード
#          所持スペルデータノード
#-----------------------------------#
sub GetSpellData{
    my $self  = shift;
    my $skilldata_nodes = shift;

    my $table_node = &GetHmtmNode::SearchTableNodeFromSkillItemDataTd($skilldata_nodes, "習得スペル");
    my $tr_nodes   = &GetNode::GetNode_Tag("tr", \$table_node);
    shift(@$tr_nodes);
    shift(@$tr_nodes);

    foreach my $tr_node (@$tr_nodes) {
        my ($s_no, $name, $sp, $power, $hit, $range, $timing_id, $spell_id, $gems) = (0, "", 0, 0, 0, 0, 0, 0, "");
        my @child_nodes = $tr_node->content_list;

        $s_no = $child_nodes[0]->as_text;

        my @child1_child_nodes = $child_nodes[1]->content_list;
        $name = ($child1_child_nodes[0] =~ /HASH/) ? $child1_child_nodes[0]->as_text : $name;

        if ($s_no eq "") {next;}
        if (!$name) {next;}

        $sp         = $child_nodes[2]->as_text;
        $power      = $child_nodes[3]->as_text;
        $hit        = ($child_nodes[4]->as_text ne "-") ? $child_nodes[4]->as_text : -1;
        $range      = ($child_nodes[5]->as_text ne "-") ? $child_nodes[5]->as_text : -1;
        $timing_id  = $self->{CommonDatas}{ProperName}->GetOrAddId($child_nodes[6]->as_text);

        $spell_id = $self->GetOrigSpell($tr_node);
        $gems = $self->GetGems($tr_node);

        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $s_no, $name, $sp, $power, $hit, $range, $timing_id, $gems, $spell_id) ));
    }

    return;
}

#-----------------------------------#
#    元スペルデータ取得
#------------------------------------
#    引数｜スペルtrノード
#-----------------------------------#
sub GetOrigSpell{
    my $self  = shift;
    my $tr_node = shift;

    my $tr_orig_skill = $tr_node->right;

    if (!$tr_orig_skill) {return 0;}

    my @child_nodes = $tr_orig_skill->content_list;

    my $name = $child_nodes[1]->as_text;
    $name =~ s/┗//;

    return $self->{CommonDatas}{SpellData}->GetOrAddId(0, [$name, -1, 0, "", -1, -1, -1, "", 0, 0]);
}

#-----------------------------------#
#    装着TGデータ連結文字列取得
#------------------------------------
#    引数｜スペルtrノード
#-----------------------------------#
sub GetGems{
    my $self  = shift;
    my $tr_node = shift;

    my $gems = "";

    my $tr_gem = $tr_node->right->right;

    while($tr_gem && $tr_gem =~ /HASH/ && $tr_gem->tag eq "tr"){
        my @child_nodes = $tr_gem->content_list;

        if(scalar(@child_nodes) == 0 || $child_nodes[0]->as_text ne "") {last;}

        my $name = $child_nodes[1]->as_text;
        $name =~ s/┗//;
        $name =~ s/　//g;

        $gems = $gems eq "" ? $name : "$gems,$name";

        $tr_gem = $tr_gem->right;
    }
    $gems = ($gems) ? ",".$gems."," : $gems;

    return $gems;
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
