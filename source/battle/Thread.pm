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

require "./source/battle/BattleRanking.pm";

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
    $self->{Datas}{BattleRanking} = BattleRanking->new();
    $self->{Datas}{Thread} = StoreData->new();
    $self->{Datas}{ThreadMember} = StoreData->new();
    my $header_list = "";

    $header_list = [
                "result_no",
                "generate_no",
                "battle_type",
                "battle_no",
                "page_no",
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

    $self->{Datas}{Thread}->Init($header_list);

    $header_list = [
                "result_no",
                "generate_no",
                "battle_type",
                "battle_no",
                "page_no",
                "turn",
                "thread_id",
                "p_no",
                "name",
    ];

    $self->{Datas}{ThreadMember}->Init($header_list);
    $self->{Datas}{BattleRanking}->Init($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas});

    #出力ファイル設定
    $self->{Datas}{Thread}->SetOutputName      ( "./output/battle/thread_"        . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{ThreadMember}->SetOutputName( "./output/battle/thread_member_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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
        $self->{ThreadMember} = {};
        my $depth = 0;

        if ($child_node =~ /HASH/ && $child_node->attr("name") && $child_node->attr("name") eq "SSDL") {
            $depth = $self->GetSpellData(1, $depth, $child_node);

            $self->OutputThreadMember();
            $self->{Datas}{Thread}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleType}, $self->{BattleNo}, $self->{PageNo}, $self->{Turn}, $self->{ThreadId},
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
#    スレッド内スペル再帰捜査
#------------------------------------
#    引数｜スペル発動ノード
#-----------------------------------#
sub GetSpellData{
    my $self = shift;
    my $is_SSDL = shift;
    my $depth = shift;
    my $div_SSDL_node = shift;

    my $div_normalspell_nodes = &GetNode::GetNode_Tag_Attr_RegExp("div", "spell", ".", \$div_SSDL_node);
    my $div_syncspell_nodes   = &GetNode::GetNode_Tag_Attr_RegExp("div", "syncspell", ".", \$div_SSDL_node);

    my $div_spell_node = ($$div_normalspell_nodes[0] && $$div_normalspell_nodes[0] =~ /HASH/) ? $$div_normalspell_nodes[0] : $$div_syncspell_nodes[0];

    if ($is_SSDL && $div_spell_node && $div_spell_node =~ /HASH/) {
        my ($spell_name, $orig_spell_name, $base_spell_name, $depth_text) = ("", "", "", "");

        my @spell_child_nodes = $div_spell_node->content_list;

        if (scalar(@spell_child_nodes) <= 1) {
            if ($div_spell_node->attr("spell") && $div_spell_node->attr("spell") eq "通常攻撃") {
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

            if (exists($self->{CommonDatas}{NameToBaseSpell}{$orig_spell_name})) {
                $base_spell_name = $self->{CommonDatas}{NameToBaseSpell}{$orig_spell_name};

            } else {
                $base_spell_name = "？";
            }
        }

        for (my $i=0;$i<$depth;$i++) {
            $depth_text .= ">"
        }

        $self->AddThreadMember($div_spell_node);

        $self->{Thread}       .= $depth_text ."," . $spell_name      ."," . "|";
        $self->{ThreadTg}     .= $depth_text ."," . $spell_name      ."," . "|";
        $self->{ThreadOrig}   .= $depth_text ."," . $orig_spell_name ."," . "|";
        $self->{ThreadOrigTg} .= $depth_text ."," . $orig_spell_name ."," . "|";
        $self->{ThreadBase}   .= $depth_text ."," . $base_spell_name ."," . "|";
        $self->{ThreadBaseTg} .= $depth_text ."," . $base_spell_name ."," . "|";
        $depth += 1;
        $self->{ThreadLength} += 1;

        $self->{Datas}{BattleRanking}->CalcBattleRanking($self->{BattleType}, $self->{BattleNo}, $self->{PageNo}, $self->{Turn}, $self->{ThreadId}, $is_SSDL, $depth, $spell_name, $orig_spell_name, $base_spell_name, $div_SSDL_node);
    }


    my @child_nodes = $div_SSDL_node->content_list;
    my $start_depth = $depth;

    foreach my $child_node (@child_nodes) {
        my $child_depth = $start_depth;
        if ($child_node =~ /HASH/ && $child_node->attr("name") && $child_node->attr("name") eq "TGDL") {
            my @tgdl_child_nodes = $child_node->content_list;

            foreach my $tgdl_child_node (@tgdl_child_nodes) {
                # 発動TGを記述
                if ($tgdl_child_node =~ /HASH/ && $tgdl_child_node->tag eq "span" && $tgdl_child_node->attr("style") && $tgdl_child_node->attr("style") eq "Color:WHITE"
                                                                    && $tgdl_child_node->attr("class") && $tgdl_child_node->attr("class") eq "F1") {

                    my $tg_depth_text = "";
                    for (my $i=0;$i<$start_depth;$i++) {
                        $tg_depth_text .= "<"
                    }

                    my $tg_text = $tgdl_child_node->as_text;
                    $tg_text =~ s/ //;
                    my @tgs = split("！", $tg_text);

                    foreach my $tg (@tgs) {
                        if (length($tg) <= 1) {next;}

                        $self->{ThreadTg}     .= $tg_depth_text ."," . $tg ."," . "|";
                        $self->{ThreadOrigTg} .= $tg_depth_text ."," . $tg ."," . "|";
                        $self->{ThreadBaseTg} .= $tg_depth_text ."," . $tg ."," . "|";

                    }
                }
            }
        }

        if ($child_node =~ /HASH/ && $child_node->attr("name") && $child_node->attr("name") eq "SSDL") {
            $child_depth = $self->GetSpellData(1, $start_depth, $child_node);
        }
        if ($child_node =~ /HASH/ && $child_node->attr("name") && $child_node->attr("name") eq "TGDL") {
            $child_depth = $self->GetSpellData(0, $start_depth, $child_node);
        }
        $depth = ($child_depth > $depth) ? $child_depth : $depth;

    }

    return $depth;
}

#-----------------------------------#
#    対抗発動スレッド参加者追加
#------------------------------------
#    引数｜
#-----------------------------------#
sub AddThreadMember{
    my $self = shift;
    my $div_spell_node = shift;

    my $name = $div_spell_node->attr("name");
    my $pno = $div_spell_node->attr("pno");

    $self->{ThreadMember}{$name} = $pno;
}

#-----------------------------------#
#    対抗発動スレッド参加者を出力データに追加
#------------------------------------
#    引数｜
#-----------------------------------#
sub OutputThreadMember{
    my $self = shift;

    foreach my $name( sort { $a cmp $b } keys %{ $self->{ThreadMember} } ) {
        my $p_no = $self->{ThreadMember}{$name};
        $self->{Datas}{ThreadMember}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattleType}, $self->{BattleNo}, $self->{PageNo}, $self->{Turn}, $self->{ThreadId},
                                                            $p_no, $name,
                                                            ) ));
    }
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
    $self->{PageNo} = shift;

    $self->{ThreadId} = 0;
    $self->{ActId} = 0;
    $self->{NicknameToEno}  = {};
    $self->{NicknameToEnemyId} = {};
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
