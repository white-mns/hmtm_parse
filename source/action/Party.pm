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
    ($self->{PreviousResultNo}) = ($self->{ResultNo} - 1);
    $self->{PreviousResultNo} = sprintf ("%02d", $self->{PreviousResultNo});

    #初期化
    $self->{Datas}{Party}     = StoreData->new();
    $self->{Datas}{PartyInfo} = StoreData->new();
    $self->{Datas}{PKType}    = StoreData->new();

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
        "pk_type",
    ];

    $self->{Datas}{PartyInfo}->Init($header_list);

    $header_list = [
        "result_no",
        "generate_no",
        "p_no",
        "pk_type",
    ];

    $self->{Datas}{PKType}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Party}->SetOutputName    ( "./output/action/party_"       . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{PartyInfo}->SetOutputName( "./output/action/party_info_"  . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{PKType}->SetOutputName   ( "./output/action/pk_type_"     . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    $self->ReadPreviousPkType();

    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadPreviousPkType(){
    my $self      = shift;

    my $file_name = "";
    # 前回結果の確定版ファイルを探索
    for (my $i=10; $i>=0; $i--){
        $file_name = "./output/action/pk_type_" . ($self->{PreviousResultNo}) . "_" . $i . ".csv" ;

        if(-f $file_name) {last;}
    }

    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );

    my @file_data = split(/\n/, $content);
    shift (@file_data);

    foreach my  $data_set(@file_data){
        my @pk_type_data   = split(ConstData::SPLIT, $data_set);

        $self->{CommonDatas}{PreviousPKType}{$pk_type_data[2]} = $pk_type_data[3];
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


    if ($self->{ENo} == $party_no) { # パーティの先頭のキャラクター結果からのみパーティ情報を取得する
        my $parent_node = $matching_table_node->parent->parent;
        my $pk_text_font_nodes = &GetNode::GetNode_Tag_Attr("font", "color", "red", \$parent_node);

        $self->GetPkInfoData($$pk_text_font_nodes[0], $tr_nodes, $party_type);
        $self->GetPartyInfoData($$pk_text_font_nodes[0], $party_name_tr_node, $tr_nodes, $party_type);
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
    my $pk_text_font_node = shift;
    my $party_name_tr_node = shift;
    my $party_tr_nodes = shift;
    my $party_type = shift;

    my ($name, $member_num, $attacker_num, $supporter_num, $pk_type) = ("", 0, 0, 0, 0);

    my $party_name_td_nodes = &GetNode::GetNode_Tag("td", \$party_name_tr_node);

    $name = $$party_name_td_nodes[0]->as_text;

    foreach my $tr_node (@$party_tr_nodes) {
        $member_num += 1;

        my $td_nodes = &GetNode::GetNode_Tag("td", \$tr_node);

        if (($$td_nodes[2]->as_text !~ /CHEER/) ) {$attacker_num += 1;}
        else                                      {$supporter_num += 1;}
    }

    if ($pk_text_font_node && $pk_text_font_node =~ /HASH/) {
        my $pk_text = $pk_text_font_node->as_text;

        if    ($pk_text eq "風　紀　委　員　の　襲　撃") { $pk_type = 1;}
        elsif ($pk_text eq "不　良　を　発　見")         { $pk_type = 2;}
        elsif ($pk_text eq "風　紀　委　員　を　発　見") { $pk_type = 3;}
    }

    if ($party_type == 3 && exists($self->{CommonDatas}{PreviousPKType}{$self->{ENo}})) { # 前回予告時の不良・風紀情報を引き継ぎ
        $pk_type = $self->{CommonDatas}{PreviousPKType}{$self->{ENo}};
    }

    $self->{Datas}{PartyInfo}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $party_type, $self->{ENo}, $name, $member_num, $attacker_num, $supporter_num, $pk_type) ));

    return;
}


#-----------------------------------#
#    風紀戦情報取得
#------------------------------------
#    引数｜パーティ名
#          パーティ種別
#-----------------------------------#
sub GetPkInfoData{
    my $self  = shift;
    my $pk_text_font_node = shift;
    my $party_tr_nodes = shift;
    my $party_type = shift;

    my $pk_type = 0;

    if ($pk_text_font_node && $pk_text_font_node =~ /HASH/) {
        my $pk_text = $pk_text_font_node->as_text;

        if    ($pk_text eq "風　紀　委　員　の　襲　撃") { $pk_type = 1;}
        elsif ($pk_text eq "不　良　を　発　見")         { $pk_type = 2;}
        elsif ($pk_text eq "風　紀　委　員　を　発　見") { $pk_type = 3;}
    }

    if ($pk_type == 0) {return;}

    foreach my $tr_node (@$party_tr_nodes) {
        my $td_nodes = &GetNode::GetNode_Tag("td", \$tr_node);

        if ($$td_nodes[1]->as_text =~ /PNo\.(\d+) /) {
            my $p_no = $1;
            my $is_supporter = ($$td_nodes[2]->as_text =~ /CHEER/) ? 1 : 0;

            $self->{Datas}{PKType}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $p_no, $pk_type) ));

            if ($pk_type < 2) {next;}

            $self->{CommonDatas}{PkPkk}->SetBattleAnnouncement($p_no,  0, $is_supporter);
            $self->{CommonDatas}{PkPkk}->SetBattleAnnouncement($p_no,  $pk_type, $is_supporter);
        }
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
