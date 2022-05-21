#===================================================================
#        風紀委員・風紀狩り情報取得パッケージ
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
package PkPkk;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class = shift;

  bless {
        Datas => {},
        Tmps => {},
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
    $self->{Datas}{Data} = StoreData->new();
    my $header_list = "";

    $header_list = [
        "result_no",
        "generate_no",
        "p_no",
        "pvp_type",
        "total_match_num",
        "total_battle_num",
        "total_cheer_num",
        "total_win_num",
        "total_draw_num",
        "total_lose_num",
        "total_income",
        "last_announcement_result_no",
    ];

    $self->{Datas}{Data}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/data/pk_pkk_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

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
        $file_name = "./output/battle/pk_pkk_" . ($self->{PreviousResultNo}) . "_" . $i . ".csv" ;

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
        $file_name = "./output/data/pk_pkk_" . ($self->{PreviousResultNo}) . "_" . $i . ".csv" ;

        if(-f $file_name) {last;}
    }

    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );

    my @file_data = split(/\n/, $content);
    shift (@file_data);

    foreach my  $data_set(@file_data){
        my $pk_pkk_datas = [];
        @$pk_pkk_datas   = split(ConstData::SPLIT, $data_set);

        my $p_no = $$pk_pkk_datas[2];
        my $pvp_type = $$pk_pkk_datas[3];
        my $total_match_num  = $$pk_pkk_datas[4];
        my $total_battle_num = $$pk_pkk_datas[5];
        my $total_cheer_num  = $$pk_pkk_datas[6];
        my $total_win_num    = $$pk_pkk_datas[7];
        my $total_draw_num   = $$pk_pkk_datas[8];
        my $total_lose_num   = $$pk_pkk_datas[9];
        my $total_income     = $$pk_pkk_datas[10];
        my $last_announcement_result_no  = $$pk_pkk_datas[11];

        $self->{PkPkk}{$p_no}{$pvp_type} = {
                                 "total_match_num"  => $total_match_num,
                                 "total_battle_num" => $total_battle_num,
                                 "total_cheer_num"  => $total_cheer_num,
                                 "total_win_num"    => $total_win_num,
                                 "total_draw_num"   => $total_draw_num,
                                 "total_lose_num"   => $total_lose_num,
                                 "total_income"     => $total_income,
                                 "last_announcement_result_no"  => $last_announcement_result_no,
                               };
    }

    return;
}

#-----------------------------------#
#    風紀戦戦結果登録
#------------------------------------
#    引数｜p_no
#          風紀戦種別(0:合計 1:不良 2:風紀委員 3:風紀狩り)
#          結果上の左右PT(1:左 -1:右)
#          勝敗(1:左が勝利 -1:右が勝利 0:引分)
#-----------------------------------#
sub SetBattleResult{
    my $self  = shift;
    my $p_no = shift;
    my $pvp_type = shift;
    my $is_left = shift;
    my $battle_result = shift;

    if ($p_no <= 0) {return;}

    $self->CheckNeedInit($p_no);

    $self->{PkPkk}{$p_no}{$pvp_type}{"total_battle_num"} += 1;
    if ($battle_result == 0)           {$self->{PkPkk}{$p_no}{$pvp_type}{"total_draw_num"} += 1;}
    elsif ($is_left == $battle_result) {$self->{PkPkk}{$p_no}{$pvp_type}{"total_win_num"}  += 1;}
    else                               {$self->{PkPkk}{$p_no}{$pvp_type}{"total_lose_num"} += 1;}

    return;
}

#-----------------------------------#
#    風紀戦戦予告登録
#------------------------------------
#    引数｜p_no
#          風紀戦種別(0:合計 1:不良 2:風紀委員 3:風紀狩り)
#-----------------------------------#
sub SetBattleAnnouncement{
    my $self  = shift;
    my $p_no = shift;
    my $pvp_type = shift;
    my $is_supporter = shift;

    if ($p_no <= 0) {return;}

    $self->CheckNeedInit($p_no);

    $self->{PkPkk}{$p_no}{$pvp_type}{"total_match_num"} += 1;

    if (!$is_supporter) {
        $self->{PkPkk}{$p_no}{$pvp_type}{"last_announcement_result_no"} = $self->{ResultNo};

    } else {
        $self->{PkPkk}{$p_no}{$pvp_type}{"total_cheer_num"} += 1;
    }

    return;
}

#-----------------------------------#
#    風紀戦戦結果登録
#------------------------------------
#    引数｜p_no
#          左右(1:左 -1:右)
#          勝敗(1:左が勝利 -1:右が勝利 0:引分)
#-----------------------------------#
sub CheckNeedInit{
    my $self  = shift;
    my $p_no = shift;

    my $pvp_types = {"total" => 0, "fallen" => 1, "monitor" => 2, "monitor_hunter" => 3};
    if (!exists($self->{PkPkk}{$p_no})) {
        $self->{PkPkk}{$p_no} = {};
        foreach my $pvp_type (values %$pvp_types) {
            $self->{PkPkk}{$p_no}{$pvp_type} = {
                                     "total_match_num"  => 0,
                                     "total_battle_num" => 0,
                                     "total_cheer_num"  => 0,
                                     "total_win_num"    => 0,
                                     "total_draw_num"   => 0,
                                     "total_lose_num"   => 0,
                                     "total_income"     => 0,
                                     "last_announcement_result_no"  => 0,
                                    }
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

    foreach my $p_no ( sort { $a <=> $b } keys %{ $self->{PkPkk} } ) {
        foreach my $pvp_type ( sort { $a <=> $b } keys %{ $self->{PkPkk}{$p_no} } ) {
            my $rank_data = $self->{PkPkk}{$p_no}{$pvp_type};
            $self->{Datas}{Data}->AddData(
                join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $p_no, $pvp_type, $$rank_data{"total_match_num"}, $$rank_data{"total_battle_num"}, $$rank_data{"total_cheer_num"}, $$rank_data{"total_win_num"}, $$rank_data{"total_draw_num"}, $$rank_data{"total_lose_num"}, $$rank_data{"total_income"}, $$rank_data{"last_announcement_result_no"}) ));
        }
    }

    foreach my $object ( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
