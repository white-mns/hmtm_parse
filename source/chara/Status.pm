#===================================================================
#        ステータス情報取得パッケージ
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
package Status;

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
                "mhp",
                "mmp",
                "msp",
                "cp",
                "str",
                "def",
                "tec",
                "eva",
                "agi",
                "luk",
                "cha",
                "rank_id",
                "tp",
                "ap",
                "pp",
                "sc",
    ];

    $self->{Datas}{Data}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/status_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜p_no,ステータスデータノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $p_no    = shift;
    my $status_node = shift;

    $self->{ENo} = $p_no;

    $self->GetStatusData($status_node);

    return;
}
#-----------------------------------#
#    ステータスデータ取得
#------------------------------------
#    引数｜ステータスデータノード
#-----------------------------------#
sub GetStatusData{
    my $self  = shift;
    my $status_node = shift;

    my $th_nodes      = &GetNode::GetNode_Tag("th", \$status_node);

    my ($mhp, $mmp, $msp, $cp, $str, $def, $tec, $eva, $agi, $luk, $cha, $rank_id, $tp, $ap, $pp, $sc) = (0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    foreach my $th_node (@$th_nodes) {
        my $td_node = $th_node->right;

        if (!$td_node || $td_node !~ /HASH/) {next;}

        my $th_text = $th_node->as_text;
        my $td_text = $td_node->as_text;

        if    ($th_text eq "MHP")     {$mhp = $td_text;}
        elsif ($th_text eq "MMP")     {$mmp = $td_text ne "-" ? $td_text : -1;}
        elsif ($th_text eq "MSP")     {$msp = $td_text;}
        elsif ($th_text eq "CP")      {$cp = $td_text;}
        elsif ($th_text eq "攻撃力") {$str = $td_text;}
        elsif ($th_text eq "防御力") {$def = $td_text;}
        elsif ($th_text eq "命中力") {$tec = $td_text;}
        elsif ($th_text eq "回避力") {$eva = $td_text;}
        elsif ($th_text eq "素早さ") {$agi = $td_text;}
        elsif ($th_text eq "運命力") {$luk = $td_text;}
        elsif ($th_text eq "魅力")   {$cha = $td_text;}
        elsif ($th_text eq "TP")     {$tp = $td_text;}
        elsif ($th_text eq "AP")     {$ap = $td_text;}
        elsif ($th_text eq "PP")     {$pp = $td_text;}
        elsif ($th_text eq "SC")     {$sc = $td_text;}
        elsif ($th_text eq "Rank")   {$rank_id = $td_text ? $self->{CommonDatas}{ProperName}->GetOrAddId($td_text) : 0;}
    }

    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $mhp, $mmp, $msp, $cp, $str, $def, $tec, $eva, $agi, $luk, $cha, $rank_id, $tp, $ap, $pp, $sc) ));

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
