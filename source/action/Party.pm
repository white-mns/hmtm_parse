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
package Party;

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
    $self->{Datas}{Party}     = StoreData->new();
    $self->{Datas}{PartyInfo} = StoreData->new();

    my $header_list = "";

    $header_list = [
        "result_no",
        "generate_no",
        "p_no",
        "party_type",
        "party_no",
        "is_supporter",
    ];

    $self->{Datas}{Party}->Init($header_list);

    $header_list = [
        "result_no",
        "generate_no",
        "party_type",
        "party_no",
        "name",
        "member_num",
        "attacker_num",
        "supporter_num",
    ];

    $self->{Datas}{PartyInfo}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Party}->SetOutputName    ( "./output/action/party_"       . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{PartyInfo}->SetOutputName( "./output/action/party_info_"  . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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

    my $party_type_hash = {
        "通常戦闘" => 0,
        "朝練戦闘" => 1,
        "ランク戦" => 2,
        "風紀戦闘" => 3,
        "レイド戦" => 4,
        "魔闘大会" => 5,
        "次回予告" => 10,
        "次回朝練予告" => 11,
        "次回ランク戦予告" => 12,
        "次回風紀戦闘予告" => 13,
        "次回レイド戦予告" => 14,
        "次回魔闘大会予告" => 15
    };

    foreach my $th_subtitle_node (@$th_subtitle_nodes) {
        my $subtitle =  $th_subtitle_node->as_text;

        if ($subtitle && exists($$party_type_hash{$subtitle})) {
            my $right_table_node = $th_subtitle_node->parent->parent->right;
            my $matching_table_nodes = &GetNode::GetNode_Tag("table", \$right_table_node);
            if (scalar(@$matching_table_nodes) > 2) {
                $self->GetPartyData($$matching_table_nodes[2], $$party_type_hash{$subtitle});
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
sub GetPartyData{
    my $self  = shift;
    my $matching_table_node = shift;
    my $party_type = shift;

    my $party_no = 0;

    my $tr_nodes = &GetNode::GetNode_Tag("tr", \$matching_table_node);

    my $party_name_tr_node = shift(@$tr_nodes);
    my $party_top_td_nodes = &GetNode::GetNode_Tag("td", \$$tr_nodes[0]);

    if ($$party_top_td_nodes[1]->as_text =~ /PNo\.(\d+) /) {
        $party_no = $1;
    }

    if ($self->{ENo} == $party_no) { # パーティの戦闘のキャラクター結果からのみパーティ情報を取得する
        $self->GetPartyInfoData($party_name_tr_node, $tr_nodes, $party_type);
    }

    foreach my $tr_node (@$tr_nodes) {
        my $td_nodes = &GetNode::GetNode_Tag("td", \$tr_node);

        if ($$td_nodes[1]->as_text =~ /PNo\.(\d+) / && $self->{ENo} == $1) {
            my $is_supporter = ($$td_nodes[2]->as_text =~ /CHEER/) ? 1 : 0;
            $self->{Datas}{Party}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $party_type, $party_no, $is_supporter) ));
        }
    }

    return;
}

#-----------------------------------#
#    パーティ情報取得
#------------------------------------
#    引数｜パーティ名
#          パーティ種別
#-----------------------------------#
sub GetPartyInfoData{
    my $self  = shift;
    my $party_name_tr_node = shift;
    my $party_tr_nodes = shift;
    my $party_type = shift;

    my ($name, $member_num, $attacker_num, $supporter_num) = ("", 0, 0, 0);

    my $party_name_td_nodes = &GetNode::GetNode_Tag("td", \$party_name_tr_node);

    $name = $$party_name_td_nodes[0]->as_text;

    foreach my $tr_node (@$party_tr_nodes) {
        $member_num += 1;

        my $td_nodes = &GetNode::GetNode_Tag("td", \$tr_node);

        if (($$td_nodes[2]->as_text !~ /CHEER/) ) {$attacker_num += 1;}
        else                                      {$supporter_num += 1;}
    }

    $self->{Datas}{PartyInfo}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $party_type, $self->{ENo}, $name, $member_num, $attacker_num, $supporter_num) ));

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
