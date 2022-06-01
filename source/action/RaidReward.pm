#===================================================================
#        レイド報酬情報取得パッケージ
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
package RaidReward;

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
                "sc",
                "tp",
                "rp",
    ];

    $self->{Datas}{Data}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/action/raid_reward_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜p_no,レイド報酬データノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $p_no    = shift;
    my $div_raid_nodes = shift;

    $self->{ENo} = $p_no;

    $self->GetRaidRewardData($div_raid_nodes);

    return;
}
#-----------------------------------#
#    レイド報酬データ取得
#------------------------------------
#    引数｜レイド報酬データノード
#-----------------------------------#
sub GetRaidRewardData{
    my $self  = shift;
    my $div_raid_nodes = shift;
    my ($sc, $tp, $rp) = (0, 0, 0);

    if (!$div_raid_nodes) {return;}
    if ($div_raid_nodes->as_text !~ /(\d+) SCを報酬として入手！/) {return;}

    $sc = $1;
    if ($div_raid_nodes->as_text =~ /(\d+) TPを報酬として入手！/) {$tp = $1;}
    if ($div_raid_nodes->as_text =~ /(\d+) RPを報酬として入手！/) {$rp = $1;}

    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $sc, $tp, $rp) ));

    if (exists($self->{CommonDatas}{Rank})) {$self->{CommonDatas}{Rank}->GainRp($self->{ENo}, $rp)}; # ランク情報のRP増加登録

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
