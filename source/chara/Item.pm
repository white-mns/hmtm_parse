#===================================================================
#        所持アイテム情報取得パッケージ
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
package Item;

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
                "i_no",
                "name",
                "type_id",
                "strength",
                "note",
    ];

    $self->{Datas}{Data}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/item_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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
    my $itemdata_nodes = shift;

    $self->{ENo} = $p_no;

    $self->GetItemData($itemdata_nodes);

    return;
}
#-----------------------------------#
#    所持アイテムデータ取得
#------------------------------------
#    引数｜二つ名データノード
#          所持アイテムデータノード
#-----------------------------------#
sub GetItemData{
    my $self  = shift;
    my $itemdata_nodes = shift;

    my $table_node = &GetHmtmNode::SearchTableNodeFromSkillItemDataTd($itemdata_nodes, "所持アイテム");
    my $tr_nodes   = &GetNode::GetNode_Tag("tr", \$table_node);
    shift(@$tr_nodes);
    shift(@$tr_nodes);

    my ($i_no, $name, $type_id, $strength, $note) = (0, "", 0, 0, "");

    foreach my $tr_node (@$tr_nodes) {
        my @child_nodes = $tr_node->content_list;

        if (scalar(@child_nodes) < 5) {next;}

        $i_no = $child_nodes[0]->as_text;
        $name = $child_nodes[1]->as_text;

        if (!$name) {next;}

        $type_id = $self->{CommonDatas}{ProperName}->GetOrAddId($child_nodes[2]->as_text);
        $strength = $child_nodes[3]->as_text;
        $note = $child_nodes[4]->as_text;

        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $i_no, $name, $type_id, $strength, $note) ));
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
