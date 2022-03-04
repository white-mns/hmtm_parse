#===================================================================
#        スレッド情報取得パッケージ
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
package Thread;

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
                "battle_type",
                "battle_no",
                "turn",
                "thread_id",
                "thread",
                "thread_tg",
                "thread_orig",
                "thread_orig_tg",
                "thread_base",
                "thread_base_tg",
                "depth",
                "length",
    ];

    $self->{Datas}{Data}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/battle/thread_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜p_no,スレッドデータノード
#-----------------------------------#
sub GetData{
    my $self = shift;
    $self->{Turn} = shift;
    my $battle_turn_node = shift;


    $self->GetThreadData($battle_turn_node);

    return;
}
#-----------------------------------#
#    スレッドデータ取得
#------------------------------------
#    引数｜スレッドデータノード
#-----------------------------------#
sub GetThreadData{
    my $self = shift;
    my $battle_turn_node = shift;

    my $td_tabletext_nodes   = &GetNode::GetNode_Tag_Attr("td", "class", "TABLETEXT", \$battle_turn_node);
    #my $tr_nodes   = &GetNode::GetNode_Tag_Attr("div", "class", "SSDL", \$battle_turn_node);

    if (scalar(@$td_tabletext_nodes) == 0) {return;}

    my @child_nodes = $$td_tabletext_nodes[0]->content_list;

    foreach my $child_node (@child_nodes) {
        $self->{Thread} = "";
        $self->{ThreadTg} = "";
        $self->{ThreadOrig} = "";
        $self->{ThreadOrigTg} = "";
        $self->{ThreadBase} = "";
        $self->{ThreadBaseTg} = "";
        $self->{ThreadLength} = 0;
        my $depth = 0;

        if ($child_node =~ /HASH/ && $child_node->attr("name") && $child_node->attr("name") eq "SSDL") {
            $depth = $self->GetSpellData($depth, $child_node);

            $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleType}, $self->{BattleNo}, $self->{Turn}, $self->{ThreadId},
                                                                $self->{Thread}, $self->{ThreadTg},
                                                                $self->{ThreadOrig}, $self->{ThreadOrigTg},
                                                                $self->{ThreadBase}, $self->{ThreadBaseTg},
                                                                $depth, $self->{ThreadLength}
                                                                ) ));

            $self->{ThreadId} += 1;
        }
    }

    return;
}

#-----------------------------------#
#    スレッド内スペル捜査
#------------------------------------
#    引数｜スペル発動ノード
#-----------------------------------#
sub GetSpellData{
    my $self = shift;
    my $depth = shift;
    my $div_SSDL_node = shift;

    my $div_spell_nodes   = &GetNode::GetNode_Tag_Attr_RegExp("div", "spell", ".", \$div_SSDL_node);

    if (!$$div_spell_nodes[0] || $$div_spell_nodes[0] !~ /HASH/) {return $depth;}

    {
        my @spell_child_nodes = $$div_spell_nodes[0]->content_list;

        my ($spell_name, $orig_spell_name, $base_spell_name, $depth_text) = ("", "", "", "");
        if (scalar(@spell_child_nodes) <= 1) {
            if ($$div_spell_nodes[0]->attr("spell") eq "通常攻撃") {
                $spell_name = "通常攻撃";
                $orig_spell_name = $spell_name;
                $base_spell_name = $spell_name;

            } else {
                return $depth;

            }
        } else {
            $spell_name = $spell_child_nodes[0]->as_text;
            $spell_name =~ s/！$//;

            $orig_spell_name = $spell_child_nodes[1]->as_text;
            $orig_spell_name =~ s/[ ]*No.[F]*\d+-\d //;
            $orig_spell_name =~ s/必殺魔法！ //;

            $base_spell_name =~ $orig_spell_name;
        }

        for (my $i=0;$i<$depth;$i++) {
            $depth_text .= ">"
        }

        $self->{Thread}       .= $depth_text ."," . $spell_name      ."," . "|";
        $self->{ThreadTg}     .= $depth_text ."," . $spell_name      ."," . "|";
        $self->{ThreadOrig}   .= $depth_text ."," . $orig_spell_name ."," . "|";
        $self->{ThreadOrigTg} .= $depth_text ."," . $orig_spell_name ."," . "|";
        #$self->{ThreadBase}   .= $depth_text ."," . $base_spell_name ."," . "|";
        #$self->{ThreadBaseTg} .= $depth_text ."," . $base_spell_name ."," . "|";
        $depth += 1;
        $self->{ThreadLength} += 1;
    }

    my @child_nodes = $div_SSDL_node->content_list;
    my $start_depth = $depth;

    foreach my $child_node (@child_nodes) {
        my $child_depth = $start_depth;
        if ($child_node =~ /HASH/ && $child_node->attr("name") && $child_node->attr("name") eq "TGDL") { # カウンター発動時のネスト構造を再帰探査
            my @tgdl_child_nodes = $child_node->content_list;

            foreach my $tgdl_child_node (@tgdl_child_nodes) {
                if ($tgdl_child_node =~ /HASH/ && $tgdl_child_node->attr("name") && $tgdl_child_node->attr("name") eq "SSDL") {
                    $child_depth = $self->GetSpellData($start_depth, $tgdl_child_node);
                }
            }
        }

        if ($child_node =~ /HASH/ && $child_node->attr("name") && $child_node->attr("name") eq "SSDL") {
            $child_depth = $self->GetSpellData($start_depth, $child_node);
        }
        $depth = ($child_depth > $depth) ? $child_depth : $depth;

    }

    return $depth;
}

#-----------------------------------#
#    戦闘開始時・行動番号をリセット
#------------------------------------
#    引数｜
#-----------------------------------#
sub BattleStart{
    my $self = shift;
    $self->{BattleType} = shift;
    $self->{BattleNo} = shift;

    $self->{ThreadId} = 0;
    $self->{ActId} = 0;
    $self->{NicknameToEno}  = {};
    $self->{NicknameToEnemyId} = {};

    #$self->{Datas}{Damage}->BattleStart($self->{BattleId});
    #$self->{Datas}{UseSkillConcatenation}->BattleStart($self->{BattleId});
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
