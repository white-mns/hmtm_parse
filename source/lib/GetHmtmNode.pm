#===================================================================
#        Secret Sphere用スクレイピング関数パッケージ
#-------------------------------------------------------------------
#            (C) 2021 @white_mns
#===================================================================

package GetHmtmNode;
use source::lib::GetNode;

#-----------------------------------#
#    キャラデータテーブルのTableノード取得
#    　「装備」「所持アイテム」などに続くテーブル要素を取得
#------------------------------------
#    引数｜TDノード
#          項目名
#-----------------------------------#
sub SearchTableNodeFromSkillItemDataTd{
    my $td_nodes = shift;
    my $text   = shift;

    foreach my $td_node (@$td_nodes) {
        my @child_nodes = $td_node->content_list;

        if (!scalar(@child_nodes)) {next;}

        if ($child_nodes[0] =~ /\[$text\]/) {return $child_nodes[1];}
    }

    return;
}

1;
