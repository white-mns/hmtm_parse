#===================================================================
#        キャラステータス解析パッケージ
#-------------------------------------------------------------------
#            (C) 2019 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#
use strict;
use warnings;

use ConstData;
use HTML::TreeBuilder;
use source::lib::GetNode;

require "./source/lib/IO.pm";
require "./source/lib/time.pm";

require "./source/chara/Name.pm";
require "./source/chara/Profile.pm";
require "./source/chara/Status.pm";
require "./source/chara/Equip.pm";

use ConstData;        #定数呼び出し

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package Character;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class        = shift;

  bless {
    Datas         => {},
    DataHandlers  => {},
    Methods       => {},
    ResultNo      => "",
    GenerateNo    => "",
  }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init{
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;
    $self->{ResultNo0} = sprintf ("%02d", $self->{ResultNo});

    #インスタンス作成
    if (ConstData::EXE_CHARA_NAME)    { $self->{DataHandlers}{Name}    = Name->new();}
    if (ConstData::EXE_CHARA_PROFILE) { $self->{DataHandlers}{Profile} = Profile->new();}
    if (ConstData::EXE_CHARA_STATUS)  { $self->{DataHandlers}{Status}  = Status->new();}
    if (ConstData::EXE_CHARA_EQUIP)   { $self->{DataHandlers}{Equip}   = Equip->new();}

    #初期化処理
    foreach my $object( values %{ $self->{DataHandlers} } ) {
        $object->Init($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas});
    }

    return;
}

#-----------------------------------#
#    圧縮結果から詳細データファイルを抽出
#-----------------------------------#
#
#-----------------------------------#
sub Execute{
    my $self        = shift;

    print "read files...\n";

    my $start = 1;
    my $end   = 0;
    my $directory = './data/orig/result' . $self->{ResultNo0};
    $directory .= ($self->{GenerateNo} == 0) ? '' :  '-' . $self->{GenerateNo};
    $directory .= '/result/d';

    if (ConstData::EXE_ALLRESULT) {
        #結果全解析
        $end = GetMaxFileNo($directory,"");
    }else{
        #指定範囲解析
        $start = ConstData::FLAGMENT_START;
        $end   = ConstData::FLAGMENT_END;
    }

    print "$start to $end\n";

    for (my $p_no=$start; $p_no<=$end; $p_no++) {
        if ($p_no % 10 == 0) {print $p_no . "\n"};

        $self->ParsePage($directory."/".$p_no.".html", $p_no);
    }

    return ;
}
#-----------------------------------#
#       ファイルを解析
#-----------------------------------#
#    引数｜ファイル名
#    　　　ENo
##-----------------------------------#
sub ParsePage{
    my $self        = shift;
    my $file_name   = shift;
    my $p_no        = shift;

    #結果の読み込み
    my $content = "";
    $content = &IO::FileRead($file_name);

    if (!$content) { return;}

    #スクレイピング準備
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($content);

    my $nickname_nodes  = &GetNode::GetNode_Tag_Attr("span", "id", "Nickname", \$tree);
    my $pcname_nodes    = &GetNode::GetNode_Tag_Attr("span", "id", "Name2",    \$tree);
    my $plname_nodes    = &GetNode::GetNode_Tag_Attr("span", "id", "PLName",   \$tree);
    my $profile_nodes   = &GetNode::GetNode_Tag_Attr("td", "class", "Prof",   \$tree);
    my $pcdata_nodes    = &GetNode::GetNode_Tag_Attr("td", "class", "PCData", \$tree);
    my $skilldata_nodes = &GetNode::GetNode_Tag_Attr("td", "class", "SKillData", \$tree);

    # データリスト取得
    if (exists($self->{DataHandlers}{Name}))    {$self->{DataHandlers}{Name}->GetData    ($p_no, $$pcname_nodes[0],   $$plname_nodes[0])};
    if (exists($self->{DataHandlers}{Profile})) {$self->{DataHandlers}{Profile}->GetData ($p_no, $$nickname_nodes[0], $$profile_nodes[1])};
    if (exists($self->{DataHandlers}{Status}))  {$self->{DataHandlers}{Status}->GetData  ($p_no, $$pcdata_nodes[0])};
    if (exists($self->{DataHandlers}{Equip}))   {$self->{DataHandlers}{Equip}->GetData   ($p_no, $skilldata_nodes)};

    $tree = $tree->delete;
}

#-----------------------------------#
#       最大ファイル番号を取得
#-----------------------------------#
#    引数｜ディレクトリ名
#    　　　ファイル接頭辞
##-----------------------------------#
sub GetMaxFileNo{
    my $directory   = shift;
    my $prefix    = shift;

    #ファイル名リストを取得
    my @fileList = grep { -f } glob("$directory/$prefix*.html");

    my $max= 0;
    foreach (@fileList) {
        $_ =~ /$prefix(\d+).html/;
        if ($max < $1) {$max = $1;}
    }
    return $max
}

#-----------------------------------#
#    出力
#-----------------------------------#
#    引数｜ファイルアドレス
#-----------------------------------#
sub Output{
    my $self = shift;
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    foreach my $object( values %{ $self->{DataHandlers} } ) {
        $object->Output();
    }
    return;
}

1;
