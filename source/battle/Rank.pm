#===================================================================
#        ランク戦情報取得パッケージ
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
package Rank;

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
    $self->{Datas}{Rank} = StoreData->new();

    my $header_list = "";

    $header_list = [
        "result_no",
        "generate_no",
        "p_no",
        "rp",
        "total_match_num",
        "total_win_num",
        "total_draw_num",
        "total_lose_num",
    ];

    $self->{Datas}{Rank}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Rank}->SetOutputName( "./output/battle/rank_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    $self->{PreviousGenerateNo} = $self->ReadPreviousGenerateNo();
    $self->ReadPreviousData();
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
        $file_name = "./output/battle/rank_" . ($self->{PreviousResultNo}) . "_" . $i . ".csv" ;

        if(-f $file_name) {return $i;}
    }

    return 0;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadPreviousData(){
    my $self      = shift;

    my $file_name = "";
    # 前回結果の確定版ファイルを探索
    for (my $i=10; $i>=0; $i--){
        $file_name = "./output/battle/rank_" . ($self->{PreviousResultNo}) . "_" . $i . ".csv" ;

        if(-f $file_name) {last;}
    }

    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );

    my @file_data = split(/\n/, $content);
    shift (@file_data);

    foreach my  $data_set(@file_data){
        my $rank_datas = [];
        @$rank_datas   = split(ConstData::SPLIT, $data_set);

        my $p_no = $$rank_datas[2];
        my $rp   = $$rank_datas[3];
        my $total_match_num = $$rank_datas[4];
        my $total_win_num   = $$rank_datas[5];
        my $total_draw_num  = $$rank_datas[6];
        my $total_lose_num  = $$rank_datas[7];

        $self->{Rank}{$p_no} = {"rp" => $rp,
                                "total_match_num" => $total_match_num,
                                "total_win_num"   => $total_win_num,
                                "total_draw_num"  => $total_draw_num,
                                "total_lose_num"  => $total_lose_num,
                               }
    }

    return;
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
#    RP増減登録
#------------------------------------
#    引数｜p_no
#          RP増減値
#-----------------------------------#
sub GetRaidRewardData{
    my $self  = shift;
    my $p_no = shift;
    my $div_raid_nodes = shift;

    if (!$div_raid_nodes) {return;}

    if ($div_raid_nodes->as_text !~ /(\d+) RPを報酬として入手！/) {return;}

    my $raid_reward_rp = $1;
    $self->GainRp($p_no, $raid_reward_rp);

    return;
}

#-----------------------------------#
#    ランク戦結果登録
#------------------------------------
#    引数｜p_no
#          左右(1:左 -1:右)
#          勝敗(1:左が勝利 -1:右が勝利 0:引分)
#-----------------------------------#
sub SetBattleResult{
    my $self  = shift;
    my $p_no = shift;
    my $is_left = shift;
    my $battle_result = shift;

    $self->CheckNeedInit($p_no);

    $self->{Rank}{$p_no}{"total_match_num"} += 1;
    if ($battle_result == 0)           {$self->{Rank}{$p_no}{"total_draw_num"} += 1;}
    elsif ($is_left == $battle_result) {$self->{Rank}{$p_no}{"total_win_num"}  += 1;}
    else                               {$self->{Rank}{$p_no}{"total_lose_num"} += 1;}

    return;
}

#-----------------------------------#
#    RP増減登録
#------------------------------------
#    引数｜p_no
#          RP増減値
#-----------------------------------#
sub GainRp{
    my $self  = shift;
    my $p_no = shift;
    my $gain_rp = shift;

    $self->CheckNeedInit($p_no);

    $self->{Rank}{$p_no}{"rp"} += $gain_rp;

    return;
}

#-----------------------------------#
#    ランク戦結果登録
#------------------------------------
#    引数｜p_no
#          左右(1:左 -1:右)
#          勝敗(1:左が勝利 -1:右が勝利 0:引分)
#-----------------------------------#
sub CheckNeedInit{
    my $self  = shift;
    my $p_no = shift;

    if (!exists($self->{Rank}{$p_no})) {
        $self->{Rank}{$p_no} = {"rp" => 100,
                                "total_match_num" => 0,
                                "total_win_num" => 0,
                                "total_draw_num" => 0,
                                "total_lose_num" => 0,
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

    foreach my $p_no( sort { $a <=> $b } keys %{ $self->{Rank} } ) {
        my $rank_data = $self->{Rank}{$p_no};
        $self->{Datas}{Rank}->AddData(
            join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $p_no, $$rank_data{"rp"}, $$rank_data{"total_match_num"}, $$rank_data{"total_win_num"}, $$rank_data{"total_draw_num"}, $$rank_data{"total_lose_num"}) ));
    }

    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
