#===================================================================
#        装備情報取得パッケージ
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
use source::lib::GetHmtmNode;

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package Equip;

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
                "equip_no",
                "name",
                "range",
                "strength_1",
                "strength_2",
                "note",
    ];

    $self->{Datas}{Data}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/equip_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜p_no,装備データノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $p_no    = shift;
    my $skilldata_nodes = shift;

    $self->{ENo} = $p_no;

    $self->GetEquipData($skilldata_nodes);

    return;
}
#-----------------------------------#
#    装備データ取得
#------------------------------------
#    引数｜装備データノード
#-----------------------------------#
sub GetEquipData{
    my $self  = shift;
    my $skilldata_nodes = shift;

    my $table_node = &GetHmtmNode::SearchTableNodeFromSkillItemDataTd($skilldata_nodes, "装備");
    my $tr_nodes   = &GetNode::GetNode_Tag("tr", \$table_node);
    shift(@$tr_nodes);

    my $equip_no_data = {"武器" => 0, "防具" => 1, "装飾" => 2};

    foreach my $tr_node (@$tr_nodes) {
        my ($equip_no, $name, $range, $states_1, $states_2, $note) = (0, "", 0, 0, 0, "");
        my @child_nodes = $tr_node->content_list;

        if (scalar(@child_nodes) < 6) {next;}
        if (!exists($$equip_no_data{$child_nodes[0]->as_text})) {next;}

        $equip_no = $$equip_no_data{$child_nodes[0]->as_text};
        $name = $child_nodes[1]->as_text;
        $range = $child_nodes[2]->as_text;
        $states_1 = $child_nodes[3]->as_text;
        $states_2 = $child_nodes[4]->as_text;
        $note = $child_nodes[5]->as_text ? $child_nodes[0]->as_text : "";

        if ($range eq "-") {$range = -1;}
        $name =~ s/\*$//;

        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $equip_no, $name, $range, $states_1, $states_2, $note) ));
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
