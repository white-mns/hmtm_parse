#===================================================================
#        伝授情報取得パッケージ
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
package TeachSpell;

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
    $self->{Datas}{Data} = StoreData->new();
    my $header_list = "";

    $header_list = [
                "result_no",
                "generate_no",
                "previous_result_no",
                "previous_generate_no",
                "p_no",
                "s_no",
                "num",
                "op",
    ];

    $self->{Datas}{Data}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/action/teach_spell_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

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
        $file_name = "./output/action/teach_spell_" . ($self->{PreviousResultNo}) . "_" . $i . ".csv" ;

        if(-f $file_name) {return $i;}
    }

    return 0;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜p_no,伝授データノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $p_no    = shift;
    my $div_teach_spell_nodes = shift;

    $self->{ENo} = $p_no;

    $self->GetTeachSpellData($div_teach_spell_nodes);

    return;
}
#-----------------------------------#
#    伝授データ取得
#------------------------------------
#    引数｜伝授データノード
#-----------------------------------#
sub GetTeachSpellData{
    my $self  = shift;
    my $div_teach_spell_nodes = shift;

    foreach my $div_teach_spell_node (@$div_teach_spell_nodes) {
        my ($s_no, $num, $op) = (0, 0, 0);

        if ($div_teach_spell_node->as_text !~ /スペルNo\.(\d+) .+?を(\d+)人に伝授した！/) {next;}

        $s_no = $1;
        $num = $2;

        if ($div_teach_spell_node->as_text =~ /OPを(\d+)入手！/) {
            $op = $1;
        }

        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{PreviousResultNo}, $self->{PreviousGenerateNo}, $self->{ENo}, $s_no, $num, $op) ));
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
