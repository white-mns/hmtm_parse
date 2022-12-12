#===================================================================
#        戦闘ターン別解析パッケージ
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

require "./source/battle/Thread.pm";

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package Turn;

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
    $self->{Datas}{Thread} = Thread->new();
    $self->{Datas}{Data}  = StoreData->new();
    my $header_list = "";

    $header_list = [
    ];

    $self->{Datas}{Data}->Init($header_list);
    $self->{Datas}{Thread}->Init($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas});

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜戦闘管理番号,PT番号,戦闘番号,戦闘開始時・Turn表記divノード
#-----------------------------------#
sub GetData{
    my $self            = shift;
    $self->{BattleType} = shift;
    $self->{BattleNo}   = shift;
    $self->{PageNo}     = shift;
    my $th_subtitle_nodes = shift;

    $self->{Datas}{Thread}->BattleStart($self->{BattleType}, $self->{BattleNo}, $self->{PageNo});

    $self->ParseTurnNodes($th_subtitle_nodes);

    return;
}


#-----------------------------------#
#    戦闘開始時・Turn表記に使われるsubtitleノードを解析
#------------------------------------
#    引数｜Turn表記ノード
#-----------------------------------#
sub ParseTurnNodes{
    my $self = shift;
    my $nodes = shift;

    if (!$nodes) {return;}

    foreach my $node (@$nodes) {
        if ($node->as_text =~ /ターン(\d+?)/) {
            my $turn = $1;
            my @subtitle_right_nodes = $node->parent->parent->right;
            my $battle_turn_node = $subtitle_right_nodes[4];
            $self->{Datas}{Thread}->GetData($turn, $battle_turn_node);
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
