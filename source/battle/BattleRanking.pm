#===================================================================
#        戦闘内容ランキング取得パッケージ
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
package BattleRanking;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class = shift;

  bless {
        Datas => {},
        DataHandlers  => {},
  }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init{
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;

    #初期化
    $self->{Datas}{BattleRanking} = StoreData->new();

    my $header_list = "";

    $header_list = [
        "result_no",
        "generate_no",
        "p_no",
        "name",
        "ranking_type",
        "value",
        "battle_type",
        "battle_no",
        "page_no",
        "turn",
        "thread_id",
        "abnormal_type",
    ];

    $self->{Datas}{BattleRanking}->Init($header_list);

    $self->{BattleRanking} = {};

    #出力ファイル設定
    $self->{Datas}{BattleRanking}->SetOutputName( "./output/battle/battle_ranking_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    #子クラスの初期化処理
    foreach my $object( values %{ $self->{DataHandlers} } ) {
        $object->Init($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas});
    }

    return;
}

#-----------------------------------#
#    戦闘内容ランキングデータ格納用変数の定義
#------------------------------------
#    引数｜p_no<>表示名,
#          戦闘種別
#          戦闘番号
#          ページ番号
#-----------------------------------#
sub InitRankingData{
    my $self = shift;
    my $p_no_name = shift;
    my $battle_type = shift;
    my $battle_no = shift;
    my $page_no = shift;

    if (!exists($self->{BattleRanking}{$p_no_name})) {$self->{BattleRanking}{$p_no_name} = {};}

    if (exists($self->{BattleRanking}{$p_no_name}{$battle_type})) {return;}

    my $ranking_type_keys = [
        "TotalDamage",
        "TotalBossDamage",
        "TotalNamedDamage",
        "TotalThunderDamage",
        "SpellMaxDamage",
        "TurnMaxDamage",
        "TotalHpHeal",
        "TotalSpHeal",
        "TotalCpHeal",
        "SpellMaxHpHeal",
        "SpellMaxSpHeal",
        "TotalSummon",
        "TotalAbnormal",
        "TotalAction",
        "TotalCounter",
        "MaxDamage",
        "TotalNoBarrierDamage",
    ];

    foreach my $ranking_type_key (@$ranking_type_keys) {
        $self->{BattleRanking}{$p_no_name}{$battle_type}{$ranking_type_key} = {
            "Value" => 0,
            "BattleNo" => $battle_no,
            "PageNo" => $page_no,
            "Turn" => 0,
            "ThreadId" => 0,
            "AbnormalType" => 0,
        }
    }
    $self->{BattleRanking}{$p_no_name}{$battle_type}{"TurnMaxDamage"}{"TurnDamages"} = {};
    $self->{BattleRanking}{$p_no_name}{$battle_type}{"TotalAbnormal"}{"Abnormals"} = {};
}
#-----------------------------------#
#    レイドの戦闘URL情報を1ターン目の結果で初期化
#------------------------------------
#    引数｜p_no<>表示名,
#          戦闘種別
#          戦闘番号
#          ページ番号
#-----------------------------------#
sub InitRaidPage{
    my $self = shift;
    my $p_no_name = shift;
    my $battle_type = shift;
    my $battle_no = shift;
    my $page_no = shift;

    if ($battle_type != 4 || $page_no != 1) {return;}

    my $ranking_type_keys = [
        "TotalDamage",
        "TotalBossDamage",
        "TotalNamedDamage",
        "TotalThunderDamage",
        "TotalHpHeal",
        "TotalSpHeal",
        "TotalCpHeal",
        "SpellMaxHpHeal",
        "SpellMaxSpHeal",
        "TotalSummon",
        "TotalAbnormal",
        "TotalAction",
        "TotalCounter",
        "TotalNoBarrierDamage",
    ];

    foreach my $ranking_type_key (@$ranking_type_keys) {
        $self->{BattleRanking}{$p_no_name}{$battle_type}{$ranking_type_key}{"BattleNo"} = $battle_no;
        $self->{BattleRanking}{$p_no_name}{$battle_type}{$ranking_type_key}{"PageNo"} = $page_no;
    }
}

#-----------------------------------#
#    戦闘内容ランキング計算
#------------------------------------
#    引数｜スペル発動ノード
#          パーティ種別
#-----------------------------------#
sub CalcBattleRanking{
    my $self  = shift;
    my $battle_type = shift;
    my $battle_no = shift;
    my $page_no = shift;
    my $turn = shift;
    my $thread_id = shift;
    my $is_SSDL = shift;
    my $depth = shift;
    my $spell_name = shift;
    my $orig_spell_name = shift;
    my $base_spell_name = shift;
    my $div_SSDL_node = shift;

    my $div_normalspell_nodes = &GetNode::GetNode_Tag_Attr_RegExp("div", "spell", ".", \$div_SSDL_node);
    my $div_syncspell_nodes   = &GetNode::GetNode_Tag_Attr_RegExp("div", "syncspell", ".", \$div_SSDL_node);

    my $div_spell_node = ($$div_normalspell_nodes[0] && $$div_normalspell_nodes[0] =~ /HASH/) ? $$div_normalspell_nodes[0] : $$div_syncspell_nodes[0];

    my $name = $div_spell_node->attr("name");
    my $p_no = $div_spell_node->attr("pno");
    my $p_no_name = "$p_no<>$name";

    $self->{NicknameToPno}{$name} = $p_no;

    my $left_node = $div_SSDL_node->left;
    if ($left_node && $left_node =~ /HASH/ && $left_node->attr("name") && $left_node->attr("name") eq "Aria") {

        my @left_childs = $left_node->content_list;
        if ($left_childs[0] =~ /HASH/) {
            $name = $left_childs[0]->as_text;
            $p_no = $self->{NicknameToPno}{$name};
            if (!$p_no) {
                print "詠唱特定不可！ $name, $battle_type, $battle_no, $page_no\n";
                return;
            }
            $p_no_name = "$p_no<>$name";
        }
    }

    $self->InitRankingData($p_no_name, $battle_type, $battle_no, $page_no);
    $self->InitRaidPage($p_no_name, $battle_type, $battle_no, $page_no);

    my @child_nodes = $div_SSDL_node->content_list;

    my $spellTotalDamage = 0;

    $self->{Check} = $orig_spell_name;

    $spellTotalDamage = $self->AddTotalValues(\@child_nodes, $p_no_name, $name, $spell_name, $battle_type, $battle_no, $page_no, $turn, $thread_id, $spellTotalDamage);

    if ($self->{BattleRanking}{$p_no_name}{$battle_type}{"SpellMaxDamage"}{"Value"} < $spellTotalDamage) {
        $self->{BattleRanking}{$p_no_name}{$battle_type}{"SpellMaxDamage"}{"Value"} = $spellTotalDamage;
        $self->{BattleRanking}{$p_no_name}{$battle_type}{"SpellMaxDamage"}{"BattleNo"} = $battle_no;
        $self->{BattleRanking}{$p_no_name}{$battle_type}{"SpellMaxDamage"}{"PageNo"} = $page_no;
        $self->{BattleRanking}{$p_no_name}{$battle_type}{"SpellMaxDamage"}{"Turn"} = $turn;
        $self->{BattleRanking}{$p_no_name}{$battle_type}{"SpellMaxDamage"}{"ThreadId"} = $thread_id;
    }
    $self->{BattleRanking}{$p_no_name}{$battle_type}{"TurnMaxDamage"}{"TurnDamages"}{$turn}{"Damage"} += $spellTotalDamage;
    $self->{BattleRanking}{$p_no_name}{$battle_type}{"TurnMaxDamage"}{"TurnDamages"}{$turn}{"BattleNo"} = $battle_no;
    $self->{BattleRanking}{$p_no_name}{$battle_type}{"TurnMaxDamage"}{"TurnDamages"}{$turn}{"PageNo"} = $page_no;

    if ($depth == 1) {
        $self->{BattleRanking}{$p_no_name}{$battle_type}{"TotalAction"}{"Value"} += 1;

    } else {
        $self->{BattleRanking}{$p_no_name}{$battle_type}{"TotalCounter"}{"Value"} += 1;
    }

    return;
}

#-----------------------------------#
#    戦闘内容ランキング計算
#------------------------------------
#    引数｜スペル発動ノード
#          パーティ種別
#-----------------------------------#
sub AddTotalValues{
    my $self = shift;
    my $child_nodes = shift;
    my $p_no_name = shift;
    my $name = shift;
    my $spell_name = shift;
    my $battle_type = shift;
    my $battle_no = shift;
    my $page_no = shift;
    my $turn = shift;
    my $thread_id = shift;
    my $spellTotalDamage = shift;

    foreach my $child_node (@$child_nodes) {
        if ($child_node =~ /HASH/ && $child_node->attr("spell")) {
            if ($spell_name ne $child_node->attr("spell") || $name ne $child_node->attr("name")) {
                # スキル表記と実際のダメージ表記までの入れ子設定が状況により大きく変わるため、他のスペル名のノードが出現するまで再帰処理を行う
                return $spellTotalDamage;
            }
        }

        if ($child_node =~ /HASH/ && $child_node->attr("name") && ($child_node->attr("name") eq "SSDL" || $child_node->attr("name") eq "TGDL")) {

            my @child_child_nodes = $child_node->content_list;
            $spellTotalDamage = $self->AddTotalValues(\@child_child_nodes, $p_no_name, $name, $spell_name, $battle_type, $battle_no, $page_no, $turn, $thread_id, $spellTotalDamage);
        }

        if ($child_node =~ /HASH/ && $child_node->attr("name") && $child_node->attr("name") eq "Damage") {
            if ($child_node->as_text =~ /(.+?)に (\d+) のダメージ！/) {
                my $target_name = $1;
                my $damage = $2;
                $spellTotalDamage += $damage;
                $self->{BattleRanking}{$p_no_name}{$battle_type}{"TotalDamage"}{"Value"} += $damage;
                if($target_name =~ /岩嵐のジャノン/) {
                    $self->{BattleRanking}{$p_no_name}{$battle_type}{"TotalBossDamage"}{"Value"} += $damage;

                }
                if($target_name =~ /(岩嵐のジャノン|ジャック|岩嵐部隊長)/) {
                    $self->{BattleRanking}{$p_no_name}{$battle_type}{"TotalNamedDamage"}{"Value"} += $damage;

                }
                if($target_name !~ /障壁/) {
                    $self->{BattleRanking}{$p_no_name}{$battle_type}{"TotalNoBarrierDamage"}{"Value"} += $damage;

                }

                if ($self->{BattleRanking}{$p_no_name}{$battle_type}{"MaxDamage"}{"Value"} < $damage) {
                    $self->{BattleRanking}{$p_no_name}{$battle_type}{"MaxDamage"}{"Value"} = $damage;
                    $self->{BattleRanking}{$p_no_name}{$battle_type}{"MaxDamage"}{"BattleNo"} = $battle_no;
                    $self->{BattleRanking}{$p_no_name}{$battle_type}{"MaxDamage"}{"PageNo"} = $page_no;
                    $self->{BattleRanking}{$p_no_name}{$battle_type}{"MaxDamage"}{"Turn"} = $turn;
                    $self->{BattleRanking}{$p_no_name}{$battle_type}{"MaxDamage"}{"ThreadId"} = $thread_id;
                }
            }

            if ($child_node->as_text =~ /(.+?)に (\d+) の反動ダメージ！/) {
                my $target_name = $1;
                $self->{BattleRanking}{$p_no_name}{$battle_type}{"TotalThunderDamage"}{"Value"} += $2;
            }
        }

        if ($child_node =~ /HASH/ && $child_node->attr("name") && $child_node->attr("name") eq "Conf") {
            if ($child_node->as_text =~ /の([HSC]P)が (\d+) 回復！/) {
                my $heal_type = $1;
                my $healToKey = {
                    "HP" => "TotalHpHeal",
                    "SP" => "TotalSpHeal",
                    "CP" => "TotalCpHeal",
                };
                $self->{BattleRanking}{$p_no_name}{$battle_type}{$$healToKey{$1}}{"Value"} += $2;
            }

            if ($child_node->as_text =~ /(.+?)に【(.+?)】を (\d+) 追加した！/) {
                my $target_name = $1;
                my $abnormal_type = $self->{CommonDatas}{ProperName}->GetOrAddId($2);
                if (!($name eq $target_name && "麻痺" eq $2)) { # 自分への麻痺デメリットを除外
                    $self->{BattleRanking}{$p_no_name}{$battle_type}{"TotalAbnormal"}{"Value"} += $3;
                    $self->{BattleRanking}{$p_no_name}{$battle_type}{"TotalAbnormal"}{"Abnormals"}{$abnormal_type} += $3;
                }
            }
        }

        if ($child_node =~ /HASH/ && $child_node->attr("name") && $child_node->attr("name") eq "Summon") {
            if ($child_node->as_text =~ /が現出した！/) {
                $self->{BattleRanking}{$p_no_name}{$battle_type}{"TotalSummon"}{"Value"} += 1;
            }
        }
    }

    return $spellTotalDamage;
}

#-----------------------------------#
#    戦闘開始時・相性の紐づけをリセット
#------------------------------------
#    引数｜
#-----------------------------------#
sub BattleStart{
    my $self = shift;
    my $page_no= shift;

    if ($page_no <= 1) {
        # ページをまたいで詠唱完了することがあるため、レイド戦の2ページ目以降はリセットしない
        $self->{NicknameToPno}  = {};
    }
}

#-----------------------------------#
#    ランキングデータを出力データに追加
#------------------------------------
#    引数｜
#-----------------------------------#
sub OutputRankingData{
    my $self = shift;

    my $ranking_type_name_to_id = {
        "TotalDamage" => 0,
        "TotalBossDamage" => 1,
        "TotalNamedDamage" => 2,
        "TotalThunderDamage" => 3,
        "SpellMaxDamage" => 4,
        "TurnMaxDamage" => 5,
        "TotalHpHeal" => 6,
        "TotalSpHeal" => 7,
        "TotalCpHeal" => 8,
        "SpellMaxHpHeal" => 9,
        "SpellMaxSpHeal" => 10,
        "TotalSummon" => 11,
        "TotalAbnormal" => 12,
        "TotalAction" => 13,
        "TotalCounter" => 14,
        "MaxDamage" => 15,
        "TotalNoBarrierDamage" => 16
    };

    foreach my $p_no_name ( sort { $a cmp $b } keys %{ $self->{BattleRanking} } ) {
        foreach my $battle_type ( sort { $a cmp $b } keys %{ $self->{BattleRanking}{$p_no_name} } ) {

            $self->MakeTurnMaxDamage($self->{BattleRanking}{$p_no_name}{$battle_type}{"TurnMaxDamage"});
            $self->MakeMaxAbnormalType($self->{BattleRanking}{$p_no_name}{$battle_type}{"TotalAbnormal"});

            foreach my $ranking_type_name ( sort { $a cmp $b } keys %{ $self->{BattleRanking}{$p_no_name}{$battle_type} } ) {
                my $ranking_type_id = $$ranking_type_name_to_id{$ranking_type_name};
                my @split_p_no_name = split(/<>/, $p_no_name);
                my $p_no = $split_p_no_name[0];
                my $name = $split_p_no_name[1];
                my $ranking_data = $self->{BattleRanking}{$p_no_name}{$battle_type}{$ranking_type_name};
                $self->{Datas}{BattleRanking}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo},
                                                                    $p_no, $name,
                                                                    $ranking_type_id,
                                                                    $$ranking_data{"Value"},
                                                                    $battle_type, $$ranking_data{"BattleNo"}, $$ranking_data{"PageNo"}, $$ranking_data{"Turn"}, $$ranking_data{"ThreadId"}, $$ranking_data{"AbnormalType"},
                                                                    ) ));
            }
        }
    }
}

#-----------------------------------#
#    ランキングデータを出力データに追加
#------------------------------------
#    引数｜
#-----------------------------------#
sub MakeTurnMaxDamage{
    my $self = shift;
    my $ranking_data = shift;

    foreach my $turn ( sort { $a <=> $b } keys %{ $$ranking_data{"TurnDamages"} } ) {
        if ($$ranking_data{"Value"} < $$ranking_data{"TurnDamages"}{$turn}{"Damage"}) {
            $$ranking_data{"Value"} = $$ranking_data{"TurnDamages"}{$turn}{"Damage"};
            $$ranking_data{"BattleNo"} = $$ranking_data{"TurnDamages"}{$turn}{"BattleNo"};
            $$ranking_data{"PageNo"} = $$ranking_data{"TurnDamages"}{$turn}{"PageNo"};
            $$ranking_data{"Turn"} = $turn;
        }
    }
}

#-----------------------------------#
#    ランキングデータを出力データに追加
#------------------------------------
#    引数｜
#-----------------------------------#
sub MakeMaxAbnormalType{
    my $self = shift;
    my $ranking_data = shift;

    my $max_value = 0;
    foreach my $abnormal_type ( sort { $a <=> $b } keys %{ $$ranking_data{"Abnormals"} } ) {
        if ($max_value < $$ranking_data{"Abnormals"}{$abnormal_type}) {
            $max_value = $$ranking_data{"Abnormals"}{$abnormal_type};
            $$ranking_data{"AbnormalType"} = $abnormal_type;
        }
    }
}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜
#-----------------------------------#
sub Output{
    my $self = shift;

    $self->OutputRankingData();

    foreach my $object ( values %{ $self->{Datas} } ) {
        $object->Output();
    }

    foreach my $object ( values %{ $self->{DataHandlers} } ) {
        $object->Output();
    }

    return;
}
1;
