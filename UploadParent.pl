#===================================================================
#    データベースへのアップロード
#-------------------------------------------------------------------
#        (C) 2021 @white_mns
#===================================================================

# モジュール呼び出し    ---------------#
require "./source/Upload.pm";
require "./source/lib/time.pm";

# パッケージの使用宣言    ---------------#
use strict;
use warnings;
require LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;

# 変数の初期化    ---------------#
use FindBin qw($Bin);
use lib "$Bin";
use ConstData_Upload;        #定数呼び出し

my $timeChecker = TimeChecker->new();

# 実行部    ---------------------------#
$timeChecker->CheckTime("start  \t");

&Main;

$timeChecker->CheckTime("end    \t");
$timeChecker->OutputTime();
$timeChecker = undef;

# 宣言部    ---------------------------#

sub Main {
    my $result_no = $ARGV[0];
    my $generate_no = $ARGV[1];
    my $upload = Upload->new();

    if (!defined($result_no) || !defined($generate_no) || $result_no !~ /^[0-9]+$/ || $generate_no !~ /^[0-9]+$/) {
        print "Error:Unusual ResultNo or GenerateNo\n";
        return;
    }

    $result_no = sprintf ("%02d", $result_no);

    $upload->DBConnect();

    $upload->DeleteSameResult("uploaded_checks", $result_no, $generate_no);

    if (ConstData::EXE_DATA) {
        &UploadData($upload, ConstData::EXE_DATA_PROPER_NAME, "proper_names",      "./output/data/proper_name.csv");
        &UploadData($upload, ConstData::EXE_DATA_SPELL,       "spell_data",        "./output/data/spell_data.csv");
        &UploadData($upload, ConstData::EXE_DATA_TUNE_GEM,    "tune_gem_data",     "./output/data/tune_gem_data.csv");

        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_DATA_OBSOLESCENCE, "obsolescences", "./output/data/obsolescence_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_DATA_PK_PKK,       "pk_pkks",       "./output/data/pk_pkk_");
    }
    if (ConstData::EXE_NEW) {
    }
    if (ConstData::EXE_CHARA) {
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_NAME,         "names",         "./output/chara/name_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_PROFILE,      "profiles",      "./output/chara/profile_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_STATUS,       "statuses",      "./output/chara/status_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_EQUIP,        "equips",        "./output/chara/equip_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_ITEM,         "items",         "./output/chara/item_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_CHARA_SPELL,        "spells",        "./output/chara/spell_");
    }
    if (ConstData::EXE_ACTION) {
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_ACTION_TUNING_ABILITY, "tuning_abilities",  "./output/action/tuning_ability_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_ACTION_PARTY_INFO,     "party_infos",       "./output/action/party_info_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_ACTION_PARTY,          "parties",           "./output/action/party_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_ACTION_TEACH_SPELL,    "teach_spells",      "./output/action/teach_spell_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_ACTION_NEXT_BATTLE,    "next_battle_infos", "./output/action/next_battle_info_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_ACTION_RAID_REWARD,    "raid_rewards",      "./output/action/raid_reward_");
    }
    if (ConstData::EXE_BATTLE) {
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_BATTLE_RESULT,        "battle_results",       "./output/battle/battle_result_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_BATTLE_THREAD,        "spell_threads",        "./output/battle/thread_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_BATTLE_THREAD_MEMBER, "spell_thread_members", "./output/battle/thread_member_");
        &UploadResult($upload, $result_no, $generate_no, ConstData::EXE_BATTLE_RANK,          "ranks",                "./output/battle/rank_");
    }
        &UploadResult($upload, $result_no, $generate_no, 1, "uploaded_checks", "./output/etc/uploaded_check_");
    print "result_no:$result_no,generate_no:$generate_no\n";
    return;
}

#-----------------------------------#
#       結果番号に依らないデータをアップロード
#-----------------------------------#
#    引数｜アップロードオブジェクト
#    　　　アップロード定義
#          テーブル名
#          ファイル名
##-----------------------------------#
sub UploadData {
    my ($upload, $is_upload, $table_name, $file_name) = @_;

    if ($is_upload) {
        $upload->DeleteAll($table_name);
        $upload->Upload($file_name, $table_name);
    }
}

#-----------------------------------#
#       更新結果データをアップロード
#-----------------------------------#
#    引数｜アップロードオブジェクト
#    　　　更新番号
#    　　　再更新番号
#    　　　アップロード定義
#          テーブル名
#          ファイル名
##-----------------------------------#
sub UploadResult {
    my ($upload, $result_no, $generate_no, $is_upload, $table_name, $file_name) = @_;

    if($is_upload) {
        $upload->DeleteSameResult($table_name, $result_no, $generate_no);
        $upload->Upload($file_name . $result_no . "_" . $generate_no . ".csv", $table_name);
    }
}
