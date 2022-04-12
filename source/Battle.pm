#===================================================================
#        戦闘解析パッケージ
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

require "./source/battle/BattleResult.pm";
require "./source/battle/Turn.pm";

use ConstData;        #定数呼び出し

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package Battle;

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
    if (ConstData::EXE_BATTLE_RESULT) {$self->{DataHandlers}{BattleResult} = BattleResult->new();}
    if (ConstData::EXE_BATTLE_THREAD) {$self->{DataHandlers}{Turn}         = Turn->new();}

    #初期化処理
    foreach my $object( values %{ $self->{DataHandlers} } ) {
        $object->Init($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas});
    }

    return;
}

#-----------------------------------#
#    圧縮結果から戦闘結果ファイルを抽出
#-----------------------------------#
#
#-----------------------------------#
sub Execute{
    my $self        = shift;


    my @battle_directories = ('b','prc','rank','pk');
    #my @battle_directories = ('prc');
    foreach my $battle_directory (@battle_directories) {
        $self->CrawlBattledirectory($battle_directory);
    }

    return ;
}

#-----------------------------------#
#    ディレクトリ内の戦闘結果ファイルを抽出
#-----------------------------------#
#
#-----------------------------------#
sub CrawlBattledirectory{
    my $self = shift;
    my $battle_directory = shift;

    print "read battle files '" . $battle_directory . "'...\n";

    my $start = 1;
    my $end   = 0;
    my $directory = './data/orig/result' . $self->{ResultNo0};
    $directory .= ($self->{GenerateNo} == 0) ? '' :  '-' . $self->{GenerateNo};
    $directory .= '/result/' . $battle_directory;

    if (ConstData::EXE_ALLRESULT) {
        #結果全解析
        $end = GetMaxFileNo($directory,"");
    }else{
        #指定範囲解析
        $start = ConstData::FLAGMENT_START;
        $end   = ConstData::FLAGMENT_END;
    }

    print "$start to $end\n";

    for (my $battle_no=$start; $battle_no<=$end; $battle_no++) {
        if ($battle_no % 10 == 0) {print $battle_no . "\n"};

        $self->ParsePage($directory."/".$battle_no.".html", $battle_directory, $battle_no);
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
    my $battle_directory = shift;
    my $battle_no        = shift;

    my $battle_type_hash = {'b'=> 0,'prc' => 1,'rank' => 2,'pk' => 3};

    #結果の読み込み
    my $content = "";
    $content = &IO::FileRead($file_name);

    if (!$content) { return;}

    $content = &NumCode::EncodeEscape($content);

    #スクレイピング準備
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($content);

    my $th_subtitle_nodes  = &GetNode::GetNode_Tag_Attr("th",  "class", "SubTitle", \$tree);
    my $div_get_rank_nodes = &GetNode::GetNode_Tag_Attr("div", "name",  "GetRank",  \$tree);

    # データリスト取得
    if (exists($self->{DataHandlers}{BattleResult})) {$self->{DataHandlers}{BattleResult}-> GetData($$battle_type_hash{$battle_directory}, $battle_no, $th_subtitle_nodes, $div_get_rank_nodes)};
    if (exists($self->{DataHandlers}{Turn}))         {$self->{DataHandlers}{Turn}->         GetData($$battle_type_hash{$battle_directory}, $battle_no, $th_subtitle_nodes)};

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
