#===================================================================
#        キャラ行動解析パッケージ
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

require "./source/action/TuningAbility.pm";
require "./source/action/Party.pm";
require "./source/action/TeachSpell.pm";

use ConstData;        #定数呼び出し

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package Action;

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
    if (ConstData::EXE_ACTION_TUNING_ABILITY) {$self->{DataHandlers}{TuningAbility} = TuningAbility->new();}
    if (ConstData::EXE_ACTION_PARTY)          {$self->{DataHandlers}{Party}         = Party->new();}
    if (ConstData::EXE_ACTION_TEACH_SPELL)    {$self->{DataHandlers}{TeachSpell}    = TeachSpell->new();}

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
    $directory .= '/result/c';

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

    my $div_alter_skill_nodes = &GetNode::GetNode_Tag_Attr("div", "name", "AlterSkill", \$tree);
    my $div_alter_spell_nodes = &GetNode::GetNode_Tag_Attr("div", "name", "AlterSpell", \$tree);
    my $th_subtitle_nodes     = &GetNode::GetNode_Tag_Attr("th", "class", "SubTitle", \$tree);
    my $div_teach_spell_nodes = &GetNode::GetNode_Tag_Attr("div", "name", "TeachSpell", \$tree);
    push (@$div_alter_spell_nodes, @$div_alter_skill_nodes);

    # データリスト取得
    if (exists($self->{DataHandlers}{TuningAbility})) {$self->{DataHandlers}{TuningAbility}->GetData($p_no, $div_alter_spell_nodes)};
    if (exists($self->{DataHandlers}{Party}))         {$self->{DataHandlers}{Party}->        GetData($p_no, $th_subtitle_nodes)};
    if (exists($self->{DataHandlers}{TeachSpell}))    {$self->{DataHandlers}{TeachSpell}->   GetData($p_no, $div_teach_spell_nodes)};

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
