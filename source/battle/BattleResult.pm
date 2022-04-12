#===================================================================
#        戦闘結果取得パッケージ
#-------------------------------------------------------------------
#            (C) 2022 @white_mns
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
package BattleResult;

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
    ($self->{PreviousResultNo}, $self->{PreviousGenerateNo}) = ($self->{ResultNo} - 1, 0);
    $self->{PreviousResultNo} = sprintf ("%02d", $self->{PreviousResultNo});

    #初期化
    $self->{Datas}{BattleResult} = StoreData->new();

    my $header_list = "";

    $header_list = [
        "result_no",
        "generate_no",
        "previous_result_no",
        "previous_generate_no",
        "left_party_no",
        "right_party_no",
        "battle_no",
        "battle_type",
        "battle_result",
        "enemy_party_name_id",
        "enemy_num",
        "enemy_names"
    ];

    $self->{Datas}{BattleResult}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{BattleResult}->SetOutputName( "./output/battle/battle_result_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    $self->{PreviousGenerateNo} = $self->ReadPreviousGenerateNo();
    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadPreviousGenerateNo(){
    my $self      = shift;

    my $file_name = "";
    # 前回結果の確定版ファイルを探索
    for (my $i=10; $i>=0; $i--){
        $file_name = "./output/battle/battle_result_" . ($self->{PreviousResultNo}) . "_" . $i . ".csv" ;

        if(-f $file_name) {return $i;}
    }

    return 0;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜p_no,サブタイトルデータノード一覧
#-----------------------------------#
sub GetData{
    my $self    = shift;
    $self->{BattleType} = shift;
    $self->{BattleNo}   = shift;
    my $th_subtitle_nodes = shift;

    my $result = $self->CrawlResultNode($th_subtitle_nodes);
    $self->CrawlStartNode($th_subtitle_nodes, $result);

    return;
}

#-----------------------------------#
#    戦闘開始時情報ノード探索
#------------------------------------
#    引数｜サブタイトルデータノード一覧
#-----------------------------------#
sub CrawlStartNode{
    my $self  = shift;
    my $th_subtitle_nodes = shift;
    my $battle_result = shift;

    my $battle_type_hash = {
        "通常戦闘" => 0,
        "朝練戦闘" => 1,
        "ランク戦" => 2,
        "風紀戦闘" => 3,
        "レイド戦" => 4,
        "魔闘大会" => 5,
    };

    foreach my $th_subtitle_node (@$th_subtitle_nodes) {
        my $subtitle = $th_subtitle_node->as_text;

        if ($subtitle && exists($$battle_type_hash{$subtitle})) {
            my $right_table_node = $th_subtitle_node->parent->parent->right;
            my $matching_table_nodes = &GetNode::GetNode_Tag("table", \$right_table_node);
            if (scalar(@$matching_table_nodes) > 2) {
                $self->GetBattleInfoData($$matching_table_nodes[2], $battle_result);
            }
        }
    }

    return;
}

#-----------------------------------#
#    戦闘結果ノード探索
#------------------------------------
#    引数｜サブタイトルデータノード一覧
#-----------------------------------#
sub CrawlResultNode{
    my $self  = shift;
    my $th_subtitle_nodes = shift;

    foreach my $th_subtitle_node (@$th_subtitle_nodes) {
        my $subtitle = $th_subtitle_node->as_text;

        if ($subtitle =~ /戦闘終了！/) {
            my $right_table_node = $th_subtitle_node->parent->parent->right;
            my $matching_table_nodes = &GetNode::GetNode_Tag("table", \$right_table_node);
            return $self->GetBattleResult($right_table_node);
        }
    }

    return -99;
}

#-----------------------------------#
#    対戦パーティ情報取得
#------------------------------------
#    引数｜サブタイトルデータノード
#          パーティ種別
#-----------------------------------#
sub GetBattleInfoData{
    my $self  = shift;
    my $matching_table_node = shift;
    my $battle_result = shift;

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

    my ($enemy_party_name_id, $enemy_num, $enemy_names) = (0, 0, ",");

    if ($right_party_no == 10000) { # 右側PTのPnoが取得できないとき、NPCとしてデータを解析
        $right_party_no = 0;
        $enemy_party_name_id = $self->GetEnemyPartyNameId($party_name_tr_node);
        $enemy_num = $self->GetEnemyNum($tr_nodes);
        $enemy_names = $self->GetEnemyNamesText($tr_nodes);
    }

    $self->{Datas}{BattleResult}->AddData(
        join(ConstData::SPLIT, (
            $self->{ResultNo}, $self->{GenerateNo},
            $self->{PreviousResultNo}, $self->{PreviousGenerateNo},
            $left_party_no, $right_party_no, $self->{BattleNo}, $self->{BattleType}, $battle_result, $enemy_party_name_id, $enemy_num, $enemy_names) ));

    return;
}

#-----------------------------------#
#    戦闘結果取得
#------------------------------------
#    引数｜戦闘結果TABLEノード
#          パーティ種別
#-----------------------------------#
sub GetBattleResult{
    my $self  = shift;
    my $result_table_node = shift;
    my $battle_result = shift;

    my $left_party_no = 0;
    my $right_party_no = 10000;

    my $left_win_nodes =  &GetNode::GetNode_Tag_Attr("span", "style", "Color:red",        \$result_table_node);
    my $right_win_nodes = &GetNode::GetNode_Tag_Attr("span", "style", "Color:aquamarine", \$result_table_node);

    if (scalar(@$left_win_nodes)  > 0) {return 1;}
    if (scalar(@$right_win_nodes) > 0) {return -1;}

    return 0;
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
