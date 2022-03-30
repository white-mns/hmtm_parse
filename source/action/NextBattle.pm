#===================================================================
#        パーティ情報取得パッケージ
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
package NextBattle;

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
    $self->{Datas}{NextBattleInfo} = StoreData->new();

    my $header_list = "";

    $header_list = [
        "result_no",
        "generate_no",
        "left_party_no",
        "right_party_no",
        "battle_type",
        "enemy_party_name_id",
        "enemy_num",
        "enemy_names"
    ];

    $self->{Datas}{NextBattleInfo}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{NextBattleInfo}->SetOutputName( "./output/action/next_battle_info_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜p_no,サブタイトルデータノード一覧
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $p_no    = shift;
    my $th_subtitle_nodes = shift;

    $self->{ENo} = $p_no;

    $self->CrawlMatchingNode($th_subtitle_nodes);

    return;
}

#-----------------------------------#
#    対戦組み合わせ情報ノード探索
#------------------------------------
#    引数｜サブタイトルデータノード一覧
#-----------------------------------#
sub CrawlMatchingNode{
    my $self  = shift;
    my $th_subtitle_nodes = shift;

    my $battle_type_hash = {
        "次回予告" => 10,
        "次回朝練予告" => 11,
        "次回ランク戦予告" => 12,
        "次回風紀戦闘予告" => 13,
        "次回レイド戦予告" => 14,
        "次回魔闘大会予告" => 15
    };

    foreach my $th_subtitle_node (@$th_subtitle_nodes) {
        my $subtitle =  $th_subtitle_node->as_text;

        if ($subtitle && exists($$battle_type_hash{$subtitle})) {
            my $right_table_node = $th_subtitle_node->parent->parent->right;
            my $matching_table_nodes = &GetNode::GetNode_Tag("table", \$right_table_node);
            if (scalar(@$matching_table_nodes) > 2) {
                $self->GetNextBattleData($$matching_table_nodes[2], $$battle_type_hash{$subtitle});
            }
        }
    }

    return;
}

#-----------------------------------#
#    パーティ所属情報取得
#------------------------------------
#    引数｜サブタイトルデータノード
#          パーティ種別
#-----------------------------------#
sub GetNextBattleData{
    my $self  = shift;
    my $matching_table_node = shift;
    my $battle_type = shift;

    my $left_party_no = 0;
    my $right_party_no = 10000;

    my $tr_nodes = &GetNode::GetNode_Tag("tr", \$matching_table_node);

    my $party_name_tr_node = shift(@$tr_nodes);
    my $party_top_td_nodes = &GetNode::GetNode_Tag("td", \$$tr_nodes[0]);

    if ($$party_top_td_nodes[1]->as_text =~ /PNo\.(\d+) /) {
        $left_party_no = $1;
    }

    if ($$party_top_td_nodes[5]->as_text =~ /PNo\.(\d+) /) {
        $right_party_no = $1;
    }

    if ($self->{ENo} == $left_party_no && $left_party_no < $right_party_no) {
        # パーティの先頭かつ相手PTより先頭Pnoが若いキャラクター結果からのみパーティ情報を取得する
        my ($enemy_party_name_id, $enemy_num, $enemy_names) = (0, 0, ",");

        if ($right_party_no == 10000) { # 右側PTのPnoが取得できないとき、NPCとしてデータを解析
            $right_party_no = 0;
            $enemy_party_name_id = $self->GetEnemyPartyNameId($party_name_tr_node);
            $enemy_num = $self->GetEnemyNum($tr_nodes);
            $enemy_names = $self->GetEnemyNamesText($tr_nodes);
        }

        $self->{Datas}{NextBattleInfo}->AddData(
            join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo},
            $left_party_no, $right_party_no, $battle_type, $enemy_party_name_id, $enemy_num, $enemy_names) ));
    }

    return;
}

#-----------------------------------#
#    敵パーティ名情報取得
#------------------------------------
#    引数｜パーティ名ノード
#-----------------------------------#
sub GetEnemyPartyNameId{
    my $self  = shift;
    my $party_name_tr_node = shift;

    my ($name, $enemy_party_name_id) = ("", 0);

    my $party_name_td_nodes = &GetNode::GetNode_Tag("td", \$party_name_tr_node);

    $name = $$party_name_td_nodes[2]->as_text;

    $enemy_party_name_id = $self->{CommonDatas}{ProperName}->GetOrAddId($name);

    return $enemy_party_name_id;
}

#-----------------------------------#
#    敵パーティ人数取得
#------------------------------------
#    引数｜パーティ情報ノード
#-----------------------------------#
sub GetEnemyNum{
    my $self  = shift;
    my $party_tr_nodes = shift;
    my $enemy_num = 0;

    foreach my $tr_node (@$party_tr_nodes) {
        my $td_nodes = &GetNode::GetNode_Tag("td", \$tr_node);

        if ($$td_nodes[4]->as_text ne "" || $$td_nodes[5]->as_text ne "") {$enemy_num += 1;}
    }

    return $enemy_num;
}

#-----------------------------------#
#    敵名連結文字情報取得
#------------------------------------
#    引数｜パーティ情報ノード
#-----------------------------------#
sub GetEnemyNamesText{
    my $self  = shift;
    my $party_tr_nodes = shift;
    my $enemy_names = ",";

    foreach my $tr_node (@$party_tr_nodes) {
        my $td_nodes = &GetNode::GetNode_Tag("td", \$tr_node);

        if (($$td_nodes[4]->as_text eq "" && $$td_nodes[5]->as_text eq "") ) {next;}

        my $enemy_name = ($$td_nodes[4]->as_text ne "") ? $$td_nodes[4]->as_text : $$td_nodes[5]->as_text;

        $enemy_names .= $enemy_name . ",";
    }

    return $enemy_names;
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
