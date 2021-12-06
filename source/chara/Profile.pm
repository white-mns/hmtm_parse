#===================================================================
#        プロフィール情報取得パッケージ
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
package Profile;

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
                "title",
                "nickname",
                "subject_id",
                "course_id",
                "species",
                "sexuality",
                "age",
    ];

    $self->{Datas}{Data}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/profile_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜p_no,プロフィールデータノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $p_no    = shift;
    my $nickname_node = shift;
    my $profile_node = shift;

    $self->{ENo} = $p_no;

    $self->GetProfileData($nickname_node, $profile_node);

    return;
}
#-----------------------------------#
#    プロフィールデータ取得
#------------------------------------
#    引数｜二つ名データノード
#          プロフィールデータノード
#-----------------------------------#
sub GetProfileData{
    my $self  = shift;
    my $nickname_node = shift;
    my $profile_node = shift;

    my $th_nodes      = &GetNode::GetNode_Tag("th", \$profile_node);

    my ($title, $nickname, $subject_id, $course_id, $species, $sexuality, $age) = ("", "", 0, 0, "", "", "");
    my $course = "";

    $title = $nickname_node->as_text;

    foreach my $th_node (@$th_nodes) {
        my $td_node = $th_node->right;

        if (!$td_node || $td_node !~ /HASH/) {next;}

        my $th_text = $th_node->as_text;
        my $td_text = $td_node->as_text;

        if    ($th_text eq "愛称")     {$nickname  = $td_text ? $td_text : $nickname;}
        elsif ($th_text eq "所属")     {$course    = $td_text ? $td_text : $course;}
        elsif ($th_text eq "種族")     {$species   = $td_text ? $td_text : $species;}
        elsif ($th_text eq "性別")     {$sexuality = $td_text ? $td_text : $sexuality;}
        elsif ($th_text eq "外見年齢") {$age       = $td_text ? $td_text : $age;}
    }

    if ($course) {
        my @subject_course = split(' ', $course);
        $subject_id = $subject_course[0] eq "魔術科" ? 0 : 1;
        $course_id = $subject_course[1] ? $self->{CommonDatas}{ProperName}->GetOrAddId($subject_course[1]) : 0;
    }

    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $title, $nickname, $subject_id, $course_id, $species, $sexuality, $age) ));

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
