#===================================================================
#        ショップ・SS・TGリスト解析パッケージ
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

require "./source/list/SpellList.pm";

use ConstData;        #定数呼び出し

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package DataList;

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
    if (ConstData::EXE_DATA_SPELL) { $self->{DataHandlers}{SpellList} = SpellList->new();}

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
    my $directory = './data/list';

    if (exists($self->{DataHandlers}{SpellList})) {$self->GetSpellList($directory."/spelllist_".$self->{ResultNo}.".html.gz")};

    return ;
}
#-----------------------------------#
#       ファイルを解析
#-----------------------------------#
#    引数｜ファイル名
#    　　　ENo
##-----------------------------------#
sub GetSpellList{
    my $self        = shift;
    my $file_name   = shift;
    my $p_no        = shift;

    my $tree;
    $tree = $self->ParseContent($file_name, \$tree);

    my $table_backboard_nodes  = &GetNode::GetNode_Tag_Attr("table", "class", "BackBoard", \$tree);

    # データリスト取得
    $self->{DataHandlers}{SpellList}->GetData($$table_backboard_nodes[0]);

    $tree = $tree->delete;
}

#-----------------------------------#
#       ファイルを解析してツリー情報を返す
#-----------------------------------#
#    引数｜ファイル名
#    返り値 | ツリー情報
##-----------------------------------#
sub ParseContent{
    my $self        = shift;
    my $file_name   = shift;
    my $tree_ref    = shift;

    #結果の読み込み
    my $content = "";
    $content = &IO::GzipRead($file_name);

    if (!$content) {return;}

    #スクレイピング準備
    $$tree_ref = HTML::TreeBuilder->new;
    $$tree_ref->parse($content);

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
