<?php
error_reporting(E_ALL);
ini_set('display_errors',1);
ini_set('display_startup_errors',1);

header("Cache-Control: no-cache, no-store, must-revalidate");
header("Pragma: no-cache");
header("Expires: 0");
  


const R_SUPER="super";
  
$rights_list[R_SUPER]="Супр";

$MAX_SESSION_AGE=36000;

$time=time();
$version="";

if(preg_match("/_devel/", __FILE__)) {
  $version="_devel";
}

require("local".$version.".php");
require($_SERVER['DOCUMENT_ROOT']."/mylib/php/myphplib.php");

function error_exit($error) {
  close_db(FALSE);
  echo JSON_encode(array("error" => $error));
  exit;
};
  
function ok_exit($result) {
  close_db(TRUE);
  echo JSON_encode(array("ok" => $result));
  exit;
};

function hist_tables($from, $to) {
  global $db;
  global $q;

  if($from >= $to) {
    error_exit("Начальная дата больше конечной");
  };

  $query="SHOW TABLES LIKE 'history_%'";
  $tables=return_array($query);

  $ret=Array();

  foreach($tables as $table) {
    if(preg_match('/^history_(\d{4})(\d{2})$/', $table, $m)) {
      $tab_start=mktime(0,0,0, $m[2], 1, $m[1]);
      $tab_end=mktime(0,0,0, $m[2]+1, 1, $m[1]) -1;

      if($tab_start < $to && $tab_end > $from) {
        $ret[] = $table;
      };
    };
  };

  return($ret);
};
  
$json=file_get_contents("php://input");

$q = json_decode($json, true);
if($q === NULL) {
  error_exit("Bad JSON input: $json");
};

if(!isset($q['action'])) {
  error_exit("No action in JSON");
};

$db=mysqli_connect("localhost", $DB_USER, $DB_PASS, $DB_NAME);
if(!$db) {
  error_exit("Db connect error at ".__LINE__);
};

if (!mysqli_set_charset($db, "utf8")) {
  error_exit("UTF-8 set charset error at ".__LINE__);
};

session_name("ext_radius$version");
session_start();

if($q['action'] == 'login') {
  require_p('login');
  require_p('password');

  unset($_SESSION['login']);
  unset($_SESSION['pc']);
  unset($_SESSION['time']);
#error_exit("Boo at ".__LINE__);
  $check_login=$q['login'];

  $query="SELECT * FROM users WHERE user_login=".mq($check_login)." AND user_password=PASSWORD(".mq($q['password']).") AND user_deleted=0";
  $user_row=return_one($query,TRUE,"Неверно указан логин или пароль");

  if($user_row['user_blocked'] != 0) { error_exit("Пользователь заблокирован"); };

  run_query("UPDATE users SET user_last_login=$time WHERE user_id=".mq($user_row['user_id']));

  $_SESSION['login']=$check_login;
  $_SESSION['pc']=$user_row['user_password_count'];
  $_SESSION['time']=time();

  ok_exit("ok");
};

if($q['action'] == 'logout') {

  unset($_SESSION['login']);
  unset($_SESSION['pc']);
  unset($_SESSION['time']);

  ok_exit("ok");
};

if(isset($_SESSION['login']) && isset($_SESSION['pc']) && isset($_SESSION['time']) && (time() - $_SESSION['time']) < $MAX_SESSION_AGE) {
  $check_login=$_SESSION['login'];
  $check_pc=$_SESSION['pc'];
} else {
  error_exit("no_auth");
};

$query="SELECT * FROM users WHERE user_login=".mq($check_login)." AND user_password_count=".mq($check_pc)." AND user_deleted=0";
$user_row=return_one($query,TRUE,"no_auth");
if($user_row['user_blocked'] != 0) { error_exit("Пользователь заблокирован"); };

run_query("UPDATE users SET user_last_activity=$time WHERE user_id=".mq($user_row['user_id']));

$_SESSION['time']=time();
$user_self_id=$user_row['user_id'];
$user_self_login=$user_row['user_login'];
$user_rights=$user_row['user_rights'];
$user_name=$user_row['user_name'];

function has_right($right, $rights_string=NULL) {
  global $user_rights;
  if(!isset($right) || $right===NULL || $right == "") {
    return true;
  };
  if(!isset($rights_string)) {
    $rights_string=$user_rights;
  };
  if(preg_match("/(?:^|,) *super *(?:,|$)/i", $rights_string)) {
    return true;
  };
  if(preg_match("/(?:^|,) *".preg_quote($right, "/")." *(?:,|$)/i", $rights_string)) {
    return true;
  };
  return false;
};

function require_right($right, $rights_string=NULL) {
  if(!has_right($right, $rights_string)){
    error_exit("У вас нет прав $right на совершение операции.");
  };
};

if($q['action'] == 'user_check') {
  ok_exit(Array("user_self_id" => $user_self_id,
    "user_rights" => $user_rights, "user_name" => $user_name, "user_login" => $check_login
  ));
} else if($q['action'] == 'list_sessions') {
  $ret=Array();

  $ret['ss'] = return_query("SELECT ss.*, IFNULL((SELECT u_address FROM us WHERE u_vg_id=s_vg_id), '') as u_address FROM ss", "s_id");

  ok_exit($ret);
} else if($q['action'] == 'kill_session') {
  require_p('s_id', '/^\d+$/');

  $query="UPDATE ss SET s_kill=".mq($user_self_id)." WHERE s_id=".mq($q['s_id']);

  run_query($query);

  ok_exit("done");
} else if($q['action'] == 'list_accounts') {
  $ret=Array();

  $ret['us'] = return_query("SELECT * FROM us WHERE u_bill_state <= 10", "u_vg_id");

  ok_exit($ret);
} else if($q['action'] == 'search_journal') {
  require_p('query');
  require_p('limit', '/^\d+$/');
  require_p('from', '/^\d+$/');
  require_p('to', '/^\d+$/');
  $ret=Array();

  $hist_tables=hist_tables($q['from'], $q['to']);

  $mac="";

  if(preg_match("/([0-9a-fA-F]{2})[:\-\.]?([0-9a-fA-F]{2})[:\-\.]?([0-9a-fA-F]{2})[:\-\.]?([0-9a-fA-F]{2})[:\-\.]?([0-9a-fA-F]{2})[:\-\.]?([0-9a-fA-F]{2})/", $q['query'], $m)) {
    $mac=strtolower($m[1].$m[2].$m[3].$m[4].$m[5].$m[6]);
  };

  if(count($hist_tables)) {
    $func=function($t) {
      global $q;
      global $mac;
      $rq="SELECT $t.*, IFNULL(us.u_address, '') as u_address, '$t' as h_table FROM $t LEFT JOIN us ON us.u_vg_id=$t.h_vg_id WHERE ";
      $rq .= "(";
      #$rq .= "(h_auth >= ".mq($q['from'])." AND h_auth <= ".mq($q['to']).") OR";
      $rq .= " (h_start >= ".mq($q['from'])." AND h_start <= ".mq($q['to']).") OR";
      $rq .= " (h_stop >= ".mq($q['from'])." AND h_stop <= ".mq($q['to']).")";
      $rq .= ")";

      $rq .= " AND (";
      $rq .= " FALSE";
      if(trim($q['query']) != "") {
        $rq .= " OR h_ip=".mq(trim($q['query']));
      };
      if($mac != "") {
        $rq .= " OR h_mac=".mq($mac);
      };
      $rq .= " OR h_login LIKE ".mq("%".$q['query']."%");
      $rq .= " OR h_name LIKE ".mq("%".$q['query']."%");
      $rq .= " OR h_anumber LIKE ".mq("%".$q['query']."%");
      $rq .= " OR h_coa_reason LIKE ".mq("%".$q['query']."%");
      $rq .= " OR h_term_cause LIKE ".mq("%".$q['query']."%");
      $rq .= " OR u_address LIKE ".mq("%".$q['query']."%");
      $rq .= ")";

      return $rq;
    };

    $query = "SELECT COUNT(*) FROM ( ".join(" UNION ALL ", array_map($func, $hist_tables)).") u";

    $total_matched=return_single($query, TRUE);

    $query = "SELECT * FROM ( ".join(" UNION ALL ", array_map($func, $hist_tables)).") u ORDER BY h_auth DESC LIMIT ".$q['limit'];
    $ret['es']=return_query($query);
    $ret['found']=$total_matched;
    $ret['query']=$query;

  } else {
    $ret['es']=Array();
    $ret['found']=0;
    $ret['query']="";
  };

  ok_exit($ret);
};

error_exit("Unknown action: ".$q['action']);

?>
