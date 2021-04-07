use strict;
use warnings;

use Data::Dumper;
use DBI;
use POSIX qw/strftime mktime/;
use LWP::UserAgent;

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

use lib '/opt/ext_radius/etc';
use radius_options;


# Bring the global hashes into the package scope
our (%RAD_REQUEST, %RAD_REPLY, %RAD_CHECK, %RAD_STATE, %RAD_CONFIG);
our ($dbh, $conn_valid, $somestate, $ua);

use constant { true => 1, false => 0 };

#
# This the remapping of return values
#
use constant {
  RLM_MODULE_REJECT   => 0, # immediately reject the request
  RLM_MODULE_OK       => 2, # the module is OK, continue
  RLM_MODULE_HANDLED  => 3, # the module handled the request, so stop
  RLM_MODULE_INVALID  => 4, # the module considers the request invalid
  RLM_MODULE_USERLOCK => 5, # reject the request (user is locked out)
  RLM_MODULE_NOTFOUND => 6, # user not found
  RLM_MODULE_NOOP     => 7, # module succeeded without doing anything
  RLM_MODULE_UPDATED  => 8, # OK (pairs modified)
  RLM_MODULE_NUMCODES => 9  # How many return codes there are
};

# Same as src/include/log.h
use constant {
  L_AUTH         => 2,  # Authentication message
  L_INFO         => 3,  # Informational message
  L_ERR          => 4,  # Error message
  L_WARN         => 5,  # Warning
  L_PROXY        => 6,  # Proxy messages
  L_ACCT         => 7,  # Accounting messages
  L_DBG          => 16, # Only displayed when debugging is enabled
  L_DBG_WARN     => 17, # Warning only displayed when debugging is enabled
  L_DBG_ERR      => 18, # Error only displayed when debugging is enabled
  L_DBG_WARN_REQ => 19, # Less severe warning only displayed when debugging is enabled
  L_DBG_ERR_REQ  => 20, # Less severe error only displayed when debugging is enabled
};

our $ATTRS_ERR=L_AUTH;
our $DB_ERR=L_ERR;

our $PPPoE_agent=1;
our $IPoE_agent=12;

sub check_db {
  my $attempt=0;
START_OVER:
  if(!defined($dbh)) {
    $dbh = DBI->connect("DBI:mysql:database=$radius_options::DB_NAME;host=$radius_options::DB_HOST", "$radius_options::DB_USER", "$radius_options::DB_PASS",
                      {RaiseError => 0, PrintWarn => 0, PrintError => 0, mysql_enable_utf8 => 1});
    if(!defined($dbh)) {
      return false;
    };
  };
  if($dbh->ping) {
    return true;
  } else {
    $dbh->disconnect;
    $dbh=undef;
    if($attempt > 0) {
      return false;
    } else {
      $attempt++;
      goto START_OVER;
    };
  };
};

sub ip2long {
  return unpack('N', (pack 'C4', split(/\./, shift)));
};

sub ip_private {
  my $ip_long=ip2long(shift);

  if( ($ip_long >= ip2long("10.0.0.0") && $ip_long <= ip2long("10.255.255.255")) ||
      ($ip_long >= ip2long("172.16.0.0") && $ip_long <= ip2long("172.31.255.255")) ||
      ($ip_long >= ip2long("192.168.0.0") && $ip_long <= ip2long("192.168.255.255")) ||
      ($ip_long >= ip2long("100.64.0.0") && $ip_long <= ip2long("100.127.255.255")) ||
      false
  ) {
    return true;
  } else {
    return false;
  };
};

sub scat {
  my %form;
  $form{'login'} = shift;
  $form{'op'} = lc($RAD_REQUEST{'Acct-Status-Type'});
  $form{'ips'} = shift;
  $form{'svc'} = shift;

  my $login=$RAD_REQUEST{'User-Name'};
  $login =~ s/^ //g;
  $login =~ s/ $//g;
  if(!defined($ua)) {
    $ua = LWP::UserAgent->new;
    $ua->timeout($radius_options::SCAT_TIMEOUT);
    $ua->protocols_allowed(['http', 'https']);
  };

  my $ip="";
  if(defined($RAD_REQUEST{'Framed-IP-Address'})) {
    $ip=$RAD_REQUEST{'Framed-IP-Address'};
  };

  $ua->agent("ext-radius/".lc($RAD_REQUEST{'Acct-Status-Type'})." ($login : $ip : ".$form{'login'}." : ".$form{'ips'});

  my $response=$ua->post($radius_options::SCAT_URI, \%form);
  if($response->is_success) {
    return true;
  } else {
    &radiusd::radlog(L_ERR, "SCAT request error: ".$response->message);
    return false;
  };
};

sub archive_row {
  my $rref=shift;
  my %arch_row=%$rref;


  my $hist_table=strftime("history_%Y%m", localtime());
  $dbh->do("CREATE TABLE IF NOT EXISTS $hist_table LIKE history_template");
  if($dbh->err) {
    return RLM_MODULE_INVALID;
  };

  my $query;

  if($arch_row{'is_error'}) {
    my @lt=localtime();
    $lt[0]=0;
    $lt[1]=0;

    my $error_period=mktime(@lt);

    $query="SELECT COUNT(*) FROM $hist_table WHERE h_login=? AND h_vg_id=? AND h_nas_ip=? AND h_nas_port=? AND h_term_cause=? AND h_error > 0 AND h_error_period=?";
    my $hrows=$dbh->selectall_arrayref($query, {}, ($arch_row{'s_login'}, $arch_row{'s_vg_id'}, $arch_row{'s_nas_ip'}, $arch_row{'s_nas_port'}, $arch_row{'h_term_cause'},
      $error_period
    ));

    if($dbh->err) {
      return RLM_MODULE_INVALID;
    };
    if(scalar(@$hrows) != 1) {
      &radiusd::radlog($DB_ERR, "Query returned wrong number of rows at ".__LINE__);
      return RLM_MODULE_INVALID;
    };

    if(${$hrows}[0][0] == 0) {
      $query="INSERT INTO $hist_table SET";
      $query .= " h_agent=?, h_ip=?, h_mac=?, h_login=?, h_vg_id=?, h_name=?, h_anumber=?, h_nas_ip=?, h_nas_port=?, h_auth=?, h_start=?, h_stop=?, h_coa_reason=?, h_term_cause=?";
      $query .= ",h_speed=?, h_bytes_in=?, h_bytes_out=?, h_pkts_in=?, h_pkts_out=?, h_last_input=?, h_kill=?, h_state=?, h_id=?";
      $query .= ",h_error=1, h_error_period=?";
      $dbh->do($query, {}, ($arch_row{'s_agent'}, $arch_row{'s_ip'}, $arch_row{'s_mac'}, $arch_row{'s_login'}, $arch_row{'s_vg_id'}, $arch_row{'s_name'}, $arch_row{'s_anumber'},
          $arch_row{'s_nas_ip'}, $arch_row{'s_nas_port'}, $arch_row{'s_auth'}, $arch_row{'s_start'}, $arch_row{'s_stop'}, $arch_row{'s_coa_reason'}, $arch_row{'h_term_cause'},
          $arch_row{'s_speed'}, $arch_row{'s_bytes_in'}, $arch_row{'s_bytes_out'}, $arch_row{'s_pkts_in'}, $arch_row{'s_pkts_out'}, $arch_row{'s_last_input'}, $arch_row{'s_kill'},
          $arch_row{'s_state'}, $arch_row{'s_id'},
          $error_period
      ));

      if($dbh->err) {
        return RLM_MODULE_INVALID;
      };
    } else {
      $query="UPDATE $hist_table SET";
      $query .= " h_error=h_error+1";
      $query .= ",h_stop=?";
      $query .= " WHERE h_login=? AND h_vg_id=? AND h_nas_ip=? AND h_nas_port=? AND h_term_cause=? AND h_error > 0 AND h_error_period=?";
      $dbh->do($query, {}, ($arch_row{'s_stop'}, $arch_row{'s_login'}, $arch_row{'s_vg_id'}, $arch_row{'s_nas_ip'}, $arch_row{'s_nas_port'}, $arch_row{'h_term_cause'},
        $error_period
      ));

      if($dbh->err) {
        return RLM_MODULE_INVALID;
      };
    };


  } else {

    $query="INSERT INTO $hist_table SET";
    $query .= " h_agent=?, h_ip=?, h_mac=?, h_login=?, h_vg_id=?, h_name=?, h_anumber=?, h_nas_ip=?, h_nas_port=?, h_auth=?, h_start=?, h_stop=?, h_coa_reason=?, h_term_cause=?";
    $query .= ",h_speed=?, h_bytes_in=?, h_bytes_out=?, h_pkts_in=?, h_pkts_out=?, h_last_input=?, h_kill=?, h_state=?, h_id=?";
    $dbh->do($query, {}, ($arch_row{'s_agent'}, $arch_row{'s_ip'}, $arch_row{'s_mac'}, $arch_row{'s_login'}, $arch_row{'s_vg_id'}, $arch_row{'s_name'}, $arch_row{'s_anumber'},
        $arch_row{'s_nas_ip'}, $arch_row{'s_nas_port'}, $arch_row{'s_auth'}, $arch_row{'s_start'}, $arch_row{'s_stop'}, $arch_row{'s_coa_reason'}, $arch_row{'h_term_cause'},
        $arch_row{'s_speed'}, $arch_row{'s_bytes_in'}, $arch_row{'s_bytes_out'}, $arch_row{'s_pkts_in'}, $arch_row{'s_pkts_out'}, $arch_row{'s_last_input'}, $arch_row{'s_kill'},
        $arch_row{'s_state'}, $arch_row{'s_id'}
    ));

    if($dbh->err) {
      return RLM_MODULE_INVALID;
    };
  };

  return RLM_MODULE_OK;
};

sub get_agent {
  my @CiscoAVPair;
  if(defined($RAD_REQUEST{'Cisco-AVPair'})) {
    if(ref($RAD_REQUEST{'Cisco-AVPair'}) eq "ARRAY") {
      @CiscoAVPair=@{$RAD_REQUEST{'Cisco-AVPair'}};
    } elsif(ref($RAD_REQUEST{'Cisco-AVPair'}) eq "") {
      push(@CiscoAVPair, $RAD_REQUEST{'Cisco-AVPair'});
    };
  };

  my $mac="";
  foreach my $av_pair (@CiscoAVPair) {
    if($av_pair =~ /^client-mac-address=([0-9a-fA-F]{2})[\.:\-]?([0-9a-fA-F]{2})[\.:\-]?([0-9a-fA-F]{2})[\.:\-]?([0-9a-fA-F]{2})[\.:\-]?([0-9a-fA-F]{2})[\.:\-]?([0-9a-fA-F]{2})$/) {
      $mac=lc($1.$2.$3.$4.$5.$6);
      last;
    };
  };
  if(
     exists($RAD_REQUEST{'NAS-Port-Type'}) && $RAD_REQUEST{'NAS-Port-Type'} eq 'Virtual' &&
     exists($RAD_REQUEST{'User-Name'}) &&
     exists($RAD_REQUEST{'NAS-IP-Address'}) &&
     exists($RAD_REQUEST{'NAS-Port'}) &&
     exists($RAD_REQUEST{'NAS-Port-Id'}) &&
     exists($RAD_REQUEST{'Acct-Session-Id'}) &&
     ($RAD_REQUEST{'User-Name'} =~ /^nas-port:/ || $RAD_REQUEST{'User-Name'} =~ /^\d+\.\d+\.\d+\.\d+$/) &&
     $mac eq "" &&
     1
  ) {
     return $IPoE_agent;
  } elsif(
     exists($RAD_REQUEST{'NAS-Port-Type'}) && $RAD_REQUEST{'NAS-Port-Type'} eq 'Virtual' &&
     exists($RAD_REQUEST{'User-Name'}) &&
     exists($RAD_REQUEST{'NAS-IP-Address'}) &&
     exists($RAD_REQUEST{'NAS-Port'}) &&
     exists($RAD_REQUEST{'NAS-Port-Id'}) &&
     exists($RAD_REQUEST{'Acct-Session-Id'}) &&
     $mac ne "" &&
     1
  ) {
     return $PPPoE_agent;
  };

  return -1;
};

# Function to handle authorize
sub authorize {
  # set $RAD_CHECK{'Cleartext-Password'} with valid password, so freeradius will run PAP and CHAP checks

  # For debugging purposes only
  &radiusd::radlog(L_DBG, "Function: ".(caller(0))[3]);
  &log_request_attributes;

  my $agent=&get_agent();

  if($agent < 0) {
    &radiusd::radlog($ATTRS_ERR, "Cannot get agent from attributes:");
    &radiusd::radlog($ATTRS_ERR, "##########");
    &log_request_attributes($ATTRS_ERR);
    &radiusd::radlog($ATTRS_ERR, "##########");
    $RAD_REPLY{'Reply-Message'} = "Reject.Service Error at ".__LINE__;
    return RLM_MODULE_REJECT;
  };

  if(!check_db()) {
    &radiusd::radlog(L_ERR, "PERL ERROR db_check error at ".__LINE__);
    $RAD_CHECK{'Response-Packet-Type'} = 'Do-Not-Respond';
    return RLM_MODULE_HANDLED;
  };

  my $query="SELECT u_password FROM us WHERE TRIM(u_login)=TRIM(?) AND u_agent=? AND u_bill_state < 10";
  my $qres=$dbh->selectall_arrayref($query, {}, ( $RAD_REQUEST{'User-Name'}, $agent));
  if($dbh->err) {
    $RAD_REPLY{'Reply-Message'} = "Reject.Service Error at ".__LINE__;
    &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
    return RLM_MODULE_REJECT;
  };
  if(scalar(@$qres) == 0) {
    #user not found, reject
    &radiusd::radlog(L_DBG, "User not found in DB");
    $RAD_REPLY{'Reply-Message'} = "User not found";
    return RLM_MODULE_REJECT;
  };

  if(scalar(@$qres) > 1) {
    #double login in DB - error!
    &radiusd::radlog(L_ERR, "More than one user found in DB!");
    &radiusd::radlog(L_ERR, "Double user: ".$RAD_REQUEST{'User-Name'});
    $RAD_REPLY{'Reply-Message'} = "Double user";
    return RLM_MODULE_REJECT;
  };

  $RAD_CHECK{'Cleartext-Password'}=${$qres}[0][0];

  return RLM_MODULE_OK;
}

# Function to handle authenticate
sub authenticate {
  # For debugging purposes only
  &radiusd::radlog(L_DBG, "Function: ".(caller(0))[3]);
  &log_request_attributes;

  return RLM_MODULE_OK;
}

# Function to handle post_auth
sub post_auth {
  &radiusd::radlog(L_DBG, "Function: ".(caller(0))[3]);
  &log_request_attributes;

  my $agent=&get_agent();

  if(!check_db()) {
    &radiusd::radlog(L_ERR, "PERL ERROR db_check error at ".__LINE__);
    $RAD_CHECK{'Response-Packet-Type'} = 'Do-Not-Respond';
    return RLM_MODULE_HANDLED;
  };

  my $login=$RAD_REQUEST{'User-Name'};
  my $acct_ses_id=$RAD_REQUEST{'Acct-Session-Id'};
  my $nas_ip=$RAD_REQUEST{'NAS-IP-Address'};
  my $nas_port=$RAD_REQUEST{'NAS-Port-Type'}.":".$RAD_REQUEST{'NAS-Port'}.":".$RAD_REQUEST{'NAS-Port-Id'};
  my @CiscoAVPair;

  if(defined($RAD_REQUEST{'Cisco-AVPair'})) {
    if(ref($RAD_REQUEST{'Cisco-AVPair'}) eq "ARRAY") {
      @CiscoAVPair=@{$RAD_REQUEST{'Cisco-AVPair'}};
    } elsif(ref($RAD_REQUEST{'Cisco-AVPair'}) eq "") {
      push(@CiscoAVPair, $RAD_REQUEST{'Cisco-AVPair'});
    };
  };

  my $mac="";
  foreach my $av_pair (@CiscoAVPair) {
    if($av_pair =~ /^client-mac-address=([0-9a-fA-F]{2})[\.:\-]?([0-9a-fA-F]{2})[\.:\-]?([0-9a-fA-F]{2})[\.:\-]?([0-9a-fA-F]{2})[\.:\-]?([0-9a-fA-F]{2})[\.:\-]?([0-9a-fA-F]{2})$/) {
      $mac=lc($1.$2.$3.$4.$5.$6);
      last;
    };
  };

  if(
     (defined($RAD_CONFIG{'Post-Auth-Type'}) && $RAD_CONFIG{'Post-Auth-Type'} eq "Reject") ||
     defined($RAD_REPLY{'Reply-Message'})
  ) {
    # REJECT call, log reject reason
    # REJECTED by us or CHAP module

    my $fail_message="User rejected, reason unknown";
    if(defined($RAD_REPLY{'Reply-Message'})) {
      $fail_message=$RAD_REPLY{'Reply-Message'};
    } elsif(defined($RAD_REQUEST{'Module-Failure-Message'})) {
      $fail_message=$RAD_REQUEST{'Module-Failure-Message'};
      if($fail_message =~ /password/i) {
        $fail_message = "Bad password";
      };
    };
        
    my $query="SELECT * FROM us WHERE TRIM(u_login)=TRIM(?) AND u_agent=? AND u_bill_state <= 10";
    my $urow=$dbh->selectall_arrayref($query, { Slice=>{} }, ( $RAD_REQUEST{'User-Name'}, $agent));
    if($dbh->err) {
      # problem with DB, no point to continue
      &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
      return RLM_MODULE_NOOP;
    };

    if(scalar(@$urow)) {
      $query="UPDATE us SET u_last_fail=?, u_fail_reason=? WHERE u_vg_id=?";
      $dbh->do($query, {}, time(), $fail_message, ${${$urow}[0]}{'u_vg_id'});
      if($dbh->err) {
        # problem with DB, no point to continue
        &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
        return RLM_MODULE_NOOP;
      };


      if(${${$urow}[0]}{'u_bill_state'} >= 10) {
        #account blocked
        return RLM_MODULE_NOOP;
      };
    };

    my $ip="";
    if(defined($RAD_REQUEST{'Framed-IP-Address'})) {
      $ip=$RAD_REQUEST{'Framed-IP-Address'};
    };

    my %arch_row;
    $arch_row{'s_id'} = 0;
    $arch_row{'s_agent'} = $agent;
    $arch_row{'s_ip'} = $ip;
    $arch_row{'s_mac'} = $mac;
    $arch_row{'s_acct_ses_id'} = $acct_ses_id;
    $arch_row{'s_login'} = $login;
    $arch_row{'s_name'} = scalar(@$urow)?${${$urow}[0]}{'u_name'}:"";
    $arch_row{'s_anumber'} = scalar(@$urow)?${${$urow}[0]}{'u_anumber'}:"";
    $arch_row{'s_vg_id'} = scalar(@$urow)?${${$urow}[0]}{'u_vg_id'}:0;
    $arch_row{'s_nas_ip'} = $nas_ip;
    $arch_row{'s_nas_port'} = $nas_port;
    $arch_row{'s_auth'} = time();
    $arch_row{'s_start'} = 0;
    $arch_row{'s_update'} = 0;
    $arch_row{'s_stop'} = time();
    $arch_row{'s_state'} = -1;
    $arch_row{'s_state_changed'} = 0;
    $arch_row{'s_change_queued'} = 0;
    $arch_row{'s_coa_reason'} = "";
    $arch_row{'s_speed'} = scalar(@$urow)?${${$urow}[0]}{'u_speed'}:0;
    $arch_row{'s_last_input'} = 0;

    $arch_row{'s_bytes_in'} = 0;
    $arch_row{'s_bytes_out'} = 0;
    $arch_row{'s_pkts_in'} = 0;
    $arch_row{'s_pkts_out'} = 0;

    $arch_row{'s_kill'} = 0;

    $arch_row{'h_term_cause'} = $fail_message;
    $arch_row{'is_error'} = 1;

    if(&archive_row(\%arch_row) != RLM_MODULE_OK) {
      &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
      return RLM_MODULE_NOOP;
    };

    return RLM_MODULE_NOOP;
  };

  if($agent < 0) {
    &radiusd::radlog($ATTRS_ERR, "Cannot get agent from attributes:");
    &radiusd::radlog($ATTRS_ERR, "##########");
    &log_request_attributes($ATTRS_ERR);
    &radiusd::radlog($ATTRS_ERR, "##########");
    $RAD_REPLY{'Reply-Message'} = "Reject.Service Error at ".__LINE__;
    return RLM_MODULE_REJECT;
  };


  my $query="SELECT * FROM us WHERE TRIM(u_login)=TRIM(?) AND u_agent=? AND u_bill_state < 10";
  my $qres=$dbh->selectall_arrayref($query, { Slice=>{} }, ( $RAD_REQUEST{'User-Name'}, $agent));
  if($dbh->err) {
    $RAD_REPLY{'Reply-Message'} = "Reject.Service Error at ".__LINE__;
    &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
    return RLM_MODULE_REJECT;
  };
  if(scalar(@$qres) == 0) {
    #user not found, reject
    &radiusd::radlog(L_DBG, "User not found in DB");
    $RAD_REPLY{'Reply-Message'} = "Reject.Service Error at ".__LINE__;
    return RLM_MODULE_REJECT;
  };

  if(scalar(@$qres) > 1) {
    #double login in DB - error!
    &radiusd::radlog(L_ERR, "More than one user found in DB!");
    &radiusd::radlog(L_ERR, "Double user: ".$RAD_REQUEST{'User-Name'});
    $RAD_REPLY{'Reply-Message'} = "Reject.Service Error at ".__LINE__;
    return RLM_MODULE_REJECT;
  };

  my %user_data=%{${$qres}[0]};

  if($user_data{'u_bill_state'} >= 10) {
    #user account is off, reject
    &radiusd::radlog(L_DBG, "User account is off");
    $RAD_REPLY{'Reply-Message'} = "Reject.Service Error at ".__LINE__;
    return RLM_MODULE_REJECT;
  };

  my @CiscoAccountInfo;
  my @ReplyCiscoAVPair;

  foreach my $svc (@radius_options::ADDITIONAL_SERVICES) {
    #push(@CiscoAccountInfo, "N$svc");
    push(@CiscoAccountInfo, "A$svc");
  };

  my $state=0;

  if($user_data{'u_bill_state'} > 0) {
    $state=1;
  };

  foreach my $svc (@radius_options::REDIRECT_SERIVCES) {
    #push(@CiscoAccountInfo, "N$svc");
    push(@CiscoAccountInfo, "VS_$svc");
  };

  push(@CiscoAccountInfo, "VR_$radius_options::THIS");
  push(@CiscoAccountInfo, "Vtime_".time());
  push(@CiscoAccountInfo, "Vstate_".$state);
  push(@CiscoAccountInfo, "Vvg_id_".$user_data{'u_vg_id'});
  push(@CiscoAccountInfo, "Vagent_".$agent);
  push(@CiscoAccountInfo, "Vspeed_".$user_data{'u_speed'});
  push(@CiscoAccountInfo, "Vssvc_".$user_data{'u_scat_svc'});
  push(@CiscoAccountInfo, "Vii_".$radius_options::UPDATE_INTERVAL);

  my $Vslogin=$user_data{'u_anumber'};
  my $u_scat_login=$user_data{'u_scat_login'};
  $u_scat_login =~ s/^ //g;
  $u_scat_login =~ s/ $//g;
  if($u_scat_login ne "") {
    $Vslogin=$u_scat_login;
  };

  $user_data{'u_scat_ips'} =~ s/^ //g;
  $user_data{'u_scat_ips'} =~ s/ $//g;

  push(@CiscoAccountInfo, "Vslogin_".$Vslogin);
  push(@CiscoAccountInfo, "Vsips_".$user_data{'u_scat_ips'});

  if($state == 1) {
    foreach my $svc (@radius_options::REDIRECT_SERIVCES) {
      push(@CiscoAccountInfo, "A$svc");
    };
    my $speed;
    if($user_data{'u_speed'} > $radius_options::REDIRECT_SPEED_MAX) {
      $speed=1024*$radius_options::REDIRECT_SPEED_MAX;
    } else {
      $speed=1024*$user_data{'u_speed'};
    };
    push(@CiscoAccountInfo, "QU;${speed};D;${speed}");
  };

  my $speed=0;
  if($user_data{'u_speed'} > 0 && $state == 0) {
    my $speed=1024*$user_data{'u_speed'};
    push(@CiscoAccountInfo, "QU;${speed};D;${speed}");
  };

  my @inbound_ai=();
  if(defined($RAD_REQUEST{'Cisco-Account-Info'})) {
    if(ref($RAD_REQUEST{'Cisco-Account-Info'}) eq "ARRAY") {
      @inbound_ai=@{$RAD_REQUEST{'Cisco-Account-Info'}};
    } elsif(ref($RAD_REQUEST{'Cisco-Account-Info'}) eq "") {
      push(@inbound_ai, $RAD_REQUEST{'Cisco-Account-Info'});
    };
  };

  foreach my $attr (@inbound_ai) {
    if($attr =~ /^S/) {
      push(@CiscoAccountInfo, $attr);
    };
  };


  #$RAD_REPLY{'Idle-Timeout'} = $radius_options::IDLE_SESSION;
  $RAD_REPLY{'Acct-Interim-Interval'} = $radius_options::UPDATE_INTERVAL;
  push(@ReplyCiscoAVPair, "accounting-list=$radius_options::ACCOUNTING_LIST");

  if($agent == $PPPoE_agent) {
    $RAD_REPLY{'Idle-Timeout'} = $radius_options::IDLE_SESSION;
    $RAD_REPLY{'Service-Type'}='Framed-User';
    $RAD_REPLY{'Framed-Protocol'}='PPP';

    if($user_data{'u_ips'} ne "") {
      my $found=0;
      for my $ip (split(",",$user_data{'u_ips'})) {
        if($ip ne '0.0.0.0' && $ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
          $query="SELECT COUNT(s_id) FROM ss WHERE s_ip=?";
          $qres=$dbh->selectall_arrayref($query, {}, $ip);
          if($dbh->err) {
            $RAD_REPLY{'Reply-Message'} = "Reject.Service Error at ".__LINE__;
            &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
            return RLM_MODULE_REJECT;
          };
          if(scalar(@$qres) != 1) {
            $RAD_REPLY{'Reply-Message'} = "Reject.Service Error at ".__LINE__;
            &radiusd::radlog($DB_ERR, "Query returned wrong number of rows at ".__LINE__);
            return RLM_MODULE_REJECT;
          };
          if(${$qres}[0][0] == 0) {
            $RAD_REPLY{'Framed-IP-Address'}=$ip;
            $found=1;
            last;
          };
        };
      };
      if(! $found) {
        $RAD_REPLY{'Reply-Message'} = "Reject.No free IPs";
        &radiusd::radlog(L_DBG, "No free IP at ".__LINE__);
        return RLM_MODULE_REJECT;
      };
    };
  } else {
    $RAD_REPLY{'Service-Type'}='Outbound-User';
  };

  $RAD_REPLY{'Cisco-Account-Info'} = \@CiscoAccountInfo;
  $RAD_REPLY{'Cisco-AVPair'} = \@ReplyCiscoAVPair;

  $query="INSERT INTO ss SET";
  $query .= " s_agent=?";
  $query .= ",s_ip=?";
  $query .= ",s_mac=?";
  $query .= ",s_acct_ses_id=?";
  $query .= ",s_login=?";
  $query .= ",s_name=?";
  $query .= ",s_anumber=?";
  $query .= ",s_vg_id=?";
  $query .= ",s_nas_ip=?";
  $query .= ",s_nas_port=?";
  $query .= ",s_auth=?";
  $query .= ",s_start=?";
  $query .= ",s_update=?";
  $query .= ",s_state=?";
  $query .= ",s_state_changed=?";
  $query .= ",s_change_queued=?";
  $query .= ",s_coa_reason=?";
  $query .= ",s_speed=?";
  $query .= ",s_bytes_in=?";
  $query .= ",s_bytes_out=?";
  $query .= ",s_pkts_in=?";
  $query .= ",s_pkts_out=?";
  $query .= ",s_last_input=?";
  $query .= ",s_interim_interval=?";
  $query .= ",s_kill=0";
  $query .= ",s_scat_svc=?";

  $dbh->do($query, {}, ($agent, "", $mac, $acct_ses_id, $login,
    $user_data{'u_name'},
    $user_data{'u_anumber'},
    $user_data{'u_vg_id'}, $nas_ip, $nas_port, time(), 0, 0, $state, 0, 0, "", $user_data{'u_speed'}, 0, 0, 0, 0, 0,
    $radius_options::UPDATE_INTERVAL, $user_data{'u_scat_svc'}
  ));
  if($dbh->err) {
    &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
    $RAD_REPLY{'Reply-Message'} = "Reject.Service Error at ".__LINE__;
    return RLM_MODULE_REJECT;
  };

  return RLM_MODULE_OK;
}

# Function to handle preacct
sub preacct {
  return RLM_MODULE_OK;
}

# Function to handle accounting
sub accounting {
  &radiusd::radlog(L_DBG, "Function: ".(caller(0))[3]);
  &log_request_attributes;


  if(!check_db()) {
    &radiusd::radlog(L_ERR, "PERL ERROR db_check error at ".__LINE__);
    return RLM_MODULE_INVALID;
  };

  if(defined($RAD_REQUEST{'Cisco-AVPair'})) {
    #ignore subsessions accounting
    if(ref($RAD_REQUEST{'Cisco-AVPair'}) eq "ARRAY") {
      if(scalar(grep { $_ =~ /^parent-session-id=/ } @{$RAD_REQUEST{'Cisco-AVPair'}})) {
        return RLM_MODULE_OK;
      };
    } elsif(ref($RAD_REQUEST{'Cisco-AVPair'}) eq "") {
      if($RAD_REQUEST{'Cisco-AVPair'} =~ /^parent-session-id=/) {
        return RLM_MODULE_OK;
      };
    };
  };

  my $octets_in=0;
  if(defined($RAD_REQUEST{'Acct-Input-Octets'})) {
    $octets_in=$RAD_REQUEST{'Acct-Input-Octets'};
    if(defined($RAD_REQUEST{'Acct-Input-Gigawords'})) {
      $octets_in += $RAD_REQUEST{'Acct-Input-Gigawords'}*4294967296;
    };
  };

  my $octets_out=0;
  if(defined($RAD_REQUEST{'Acct-Output-Octets'})) {
    $octets_out=$RAD_REQUEST{'Acct-Output-Octets'};
    if(defined($RAD_REQUEST{'Acct-Output-Gigawords'})) {
      $octets_out += $RAD_REQUEST{'Acct-Output-Gigawords'}*4294967296;
    };
  };

  if(($RAD_REQUEST{'Acct-Status-Type'} eq "Interim-Update" || $RAD_REQUEST{'Acct-Status-Type'} eq "Stop") &&
     (!defined($RAD_REQUEST{'Acct-Input-Octets'}) || !defined($RAD_REQUEST{'Acct-Output-Octets'}) ||
      !defined($RAD_REQUEST{'Acct-Input-Packets'}) || !defined($RAD_REQUEST{'Acct-Output-Packets'}) ||
      false
     )
  ) {
    &radiusd::radlog(L_ERR, "PERL ERROR: incomplete request at ".__LINE__);
    return RLM_MODULE_INVALID;
  };
  if($RAD_REQUEST{'Acct-Status-Type'} eq "Stop" &&
     !defined($RAD_REQUEST{'Acct-Terminate-Cause'})
  ) {
    &radiusd::radlog(L_ERR, "PERL ERROR: incomplete request at ".__LINE__);
    return RLM_MODULE_INVALID;
  };

  my @CiscoAVPair=();
  my @CiscoAccountInfo=();

  my $nas_port=$RAD_REQUEST{'NAS-Port-Type'}.":".$RAD_REQUEST{'NAS-Port'}.":".$RAD_REQUEST{'NAS-Port-Id'};

  my $login=$RAD_REQUEST{'User-Name'};
  my $acct_ses_id=$RAD_REQUEST{'Acct-Session-Id'};
  my $nas_ip=$RAD_REQUEST{'NAS-IP-Address'};
  my $ip="";
  if(defined($RAD_REQUEST{'Framed-IP-Address'})) {
    $ip=$RAD_REQUEST{'Framed-IP-Address'};
  };

  if(defined($RAD_REQUEST{'Cisco-Account-Info'})) {
    if(ref($RAD_REQUEST{'Cisco-Account-Info'}) eq "ARRAY") {
      @CiscoAccountInfo=@{$RAD_REQUEST{'Cisco-Account-Info'}};
    } elsif(ref($RAD_REQUEST{'Cisco-Account-Info'}) eq "") {
      push(@CiscoAccountInfo, $RAD_REQUEST{'Cisco-Account-Info'});
    };
  };

  if(defined($RAD_REQUEST{'Cisco-AVPair'})) {
    if(ref($RAD_REQUEST{'Cisco-AVPair'}) eq "ARRAY") {
      @CiscoAVPair=@{$RAD_REQUEST{'Cisco-AVPair'}};
    } elsif(ref($RAD_REQUEST{'Cisco-AVPair'}) eq "") {
      push(@CiscoAVPair, $RAD_REQUEST{'Cisco-AVPair'});
    };
  };

  my $Vvg_id=0;
  my $Vstate=-1;
  my $Vspeed=0;
  my $Vslogin="";
  my $Vsips="";
  my $Vssvc="";
  my $Vii=$radius_options::UPDATE_INTERVAL;

  my $agent=0;

  foreach my $attr (@CiscoAccountInfo) {
    if( $attr =~ /^Vvg_id_(\d+)$/ ) {
      $Vvg_id = $1;
    } elsif( $attr =~ /^Vstate_(\d+)$/ ) {
      $Vstate = $1;
    } elsif( $attr =~ /^Vspeed_(\d+)$/ ) {
      $Vspeed = $1;
    } elsif( $attr =~ /^Vagent_(-?\d+)$/ ) {
      $agent = $1;
    } elsif( $attr =~ /^Vii_(\d+)$/ ) {
      $Vii = $1;
    } elsif( $attr =~ /^Vslogin_(.+)$/ ) {
      $Vslogin = $1;
    } elsif( $attr =~ /^Vsips_(.+)$/ ) {
      $Vsips = $1;
    } elsif( $attr =~ /^Vssvc_(.+)$/ ) {
      $Vssvc = $1;
    };
  };

  my $mac="";
  foreach my $av_pair (@CiscoAVPair) {
    if($av_pair =~ /^client-mac-address=([0-9a-fA-F]{2})[\.:\-]?([0-9a-fA-F]{2})[\.:\-]?([0-9a-fA-F]{2})[\.:\-]?([0-9a-fA-F]{2})[\.:\-]?([0-9a-fA-F]{2})[\.:\-]?([0-9a-fA-F]{2})$/) {
      $mac=lc($1.$2.$3.$4.$5.$6);
      last;
    };
  };

  my $query="SELECT * FROM ss WHERE s_acct_ses_id=? AND s_nas_ip=?";
  my $srow=$dbh->selectall_arrayref($query, { Slice => {} }, ($RAD_REQUEST{'Acct-Session-Id'}, $RAD_REQUEST{'NAS-IP-Address'}));
  if($dbh->err) {
    &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
    return RLM_MODULE_INVALID;
  };

  if(scalar(@$srow) > 1) {
    &radiusd::radlog(L_ERR, "Double session records. Weird.");
    return RLM_MODULE_INVALID;
  };

  $query="SELECT * FROM us WHERE u_vg_id=? AND u_bill_state < 10";
  my $urow=$dbh->selectall_arrayref($query, { Slice => {} }, ($Vvg_id));
  if($dbh->err) {
    &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
    return RLM_MODULE_INVALID;
  };

  if($RAD_REQUEST{'Acct-Status-Type'} eq "Start") {
    my $ses_start=time();
    if(defined($RAD_REQUEST{'Acct-Delay-Time'})) {
      $ses_start -= $RAD_REQUEST{'Acct-Delay-Time'};
    };

    if(scalar(@$srow) > 0) {

      $query="UPDATE ss SET";
      $query .= " s_ip=?";
      $query .= ",s_mac=?";
      $query .= ",s_start=?";
      $query .= ",s_update=?";

      $query .= " WHERE s_id=?";
  
      $dbh->do($query, {}, ($ip, $mac,
        $ses_start, $ses_start,
        ${${$srow}[0]}{'s_id'}
      ));
      if($dbh->err) {
        &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
        return RLM_MODULE_INVALID;
      };
    } else {

      $query="INSERT INTO ss SET";
      $query .= " s_agent=?";
      $query .= ",s_ip=?";
      $query .= ",s_mac=?";
      $query .= ",s_acct_ses_id=?";
      $query .= ",s_login=?";
      $query .= ",s_name=?";
      $query .= ",s_anumber=?";
      $query .= ",s_vg_id=?";
      $query .= ",s_nas_ip=?";
      $query .= ",s_nas_port=?";
      $query .= ",s_auth=?";
      $query .= ",s_start=?";
      $query .= ",s_update=?";
      $query .= ",s_state=?";
      $query .= ",s_state_changed=?";
      $query .= ",s_change_queued=?";
      $query .= ",s_coa_reason=?";
      $query .= ",s_speed=?";
      $query .= ",s_bytes_in=?";
      $query .= ",s_bytes_out=?";
      $query .= ",s_pkts_in=?";
      $query .= ",s_pkts_out=?";
      $query .= ",s_last_input=?";
      $query .= ",s_interim_interval=?";
      $query .= ",s_kill=0";
      $query .= ",s_scat_svc=?";
  
      $dbh->do($query, {}, ($agent, $ip, $mac, $acct_ses_id, $login,
        scalar(@$urow)?${${$urow}[0]}{'u_name'}:"",
        scalar(@$urow)?${${$urow}[0]}{'u_anumber'}:"",
        $Vvg_id, $nas_ip, $nas_port, $ses_start, $ses_start, $ses_start, $Vstate, 0, 0, "", $Vspeed, 0, 0, 0, 0, $ses_start,
        $Vii, $Vssvc
      ));
      if($dbh->err) {
        &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
        return RLM_MODULE_INVALID;
      };
    };
  } elsif($RAD_REQUEST{'Acct-Status-Type'} eq "Interim-Update") {
    my $ses_update=time();
    if(defined($RAD_REQUEST{'Acct-Delay-Time'})) {
      $ses_update -= $RAD_REQUEST{'Acct-Delay-Time'};
    };

    if(scalar(@$srow)) {
      $query="UPDATE ss SET";
      $query .= " s_ip=?";
      $query .= ",s_mac=?";
      $query .= ",s_update=?";
      $query .= ",s_bytes_in=?";
      $query .= ",s_bytes_out=?";
      $query .= ",s_pkts_in=?";
      $query .= ",s_pkts_out=?";
      $query .= ",s_last_input=?";

      $query .= " WHERE s_id=?";

      $dbh->do($query, {}, ( $ip, $mac,
        $ses_update,  $octets_in, $octets_out, $RAD_REQUEST{'Acct-Input-Packets'}, $RAD_REQUEST{'Acct-Output-Packets'},
        ($RAD_REQUEST{'Acct-Input-Packets'} > ${${$srow}[0]}{'s_pkts_in'}) ? $ses_update : ${${$srow}[0]}{'s_last_input'},
        ${${$srow}[0]}{'s_id'}
      ));
      if($dbh->err) {
        &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
        return RLM_MODULE_INVALID;
      };
    } else {
      my $ses_start=0;
      if(defined($RAD_REQUEST{'Acct-Session-Time'})) {
        $ses_start=time()-$RAD_REQUEST{'Acct-Session-Time'};
        if(defined($RAD_REQUEST{'Acct-Delay-Time'})) {
          $ses_start -= $RAD_REQUEST{'Acct-Delay-Time'};
        };
      };

      $query="INSERT INTO ss SET";
      $query .= " s_agent=?";
      $query .= ",s_ip=?";
      $query .= ",s_mac=?";
      $query .= ",s_acct_ses_id=?";
      $query .= ",s_login=?";
      $query .= ",s_name=?";
      $query .= ",s_anumber=?";
      $query .= ",s_vg_id=?";
      $query .= ",s_nas_ip=?";
      $query .= ",s_nas_port=?";
      $query .= ",s_auth=?";
      $query .= ",s_start=?";
      $query .= ",s_update=?";
      $query .= ",s_state=?";
      $query .= ",s_state_changed=?";
      $query .= ",s_change_queued=?";
      $query .= ",s_coa_reason=?";
      $query .= ",s_speed=?";
      $query .= ",s_bytes_in=?";
      $query .= ",s_bytes_out=?";
      $query .= ",s_pkts_in=?";
      $query .= ",s_pkts_out=?";
      $query .= ",s_last_input=?";
      $query .= ",s_interim_interval=?";
      $query .= ",s_kill=0";
      $query .= ",s_scat_svc=?";

      $dbh->do($query, {}, ($agent, $ip, $mac, $acct_ses_id, $login,
        scalar(@$urow)?${${$urow}[0]}{'u_name'}:"",
        scalar(@$urow)?${${$urow}[0]}{'u_anumber'}:"",
        $Vvg_id, $nas_ip, $nas_port, $ses_start, $ses_start, $ses_update, $Vstate, 0, 0, "Adopted update. No data.", $Vspeed,
        $octets_in, $octets_out, $RAD_REQUEST{'Acct-Input-Packets'}, $RAD_REQUEST{'Acct-Output-Packets'},
        $ses_update, $Vii, $Vssvc
      ));
      if($dbh->err) {
        &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
        return RLM_MODULE_INVALID;
      };
    };
  } elsif($RAD_REQUEST{'Acct-Status-Type'} eq "Stop") {
    if(defined($radius_options::STOP_LOG) &&
       ($Vvg_id == 0 || $agent == 0) &&
       1
    ) {
      my $stop_log;
      if(open($stop_log, ">>", $radius_options::STOP_LOG)) {
        print($stop_log scalar(localtime())."\n");
        print($stop_log Dumper(\%RAD_REQUEST));
        close($stop_log);
      };
    };

    my $ses_stop=time();
    if(defined($RAD_REQUEST{'Acct-Delay-Time'})) {
      $ses_stop -= $RAD_REQUEST{'Acct-Delay-Time'};
    };

    my %arch_row;

    if(scalar(@$srow)) {
      %arch_row = %{${$srow}[0]};
      $arch_row{'s_update'} = $ses_stop;
      $arch_row{'s_last_input'} = ($RAD_REQUEST{'Acct-Input-Packets'} > ${${$srow}[0]}{'s_pkts_in'}) ? $ses_stop : ${${$srow}[0]}{'s_last_input'},

      $dbh->do("DELETE FROM ss WHERE s_id=?", {}, (${${$srow}[0]}{'s_id'}));
      if($dbh->err) {
        &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
        return RLM_MODULE_INVALID;
      };

    } else {
      my $ses_start=1;
      if(defined($RAD_REQUEST{'Acct-Session-Time'})) {
        $ses_start=time()-$RAD_REQUEST{'Acct-Session-Time'};
        if(defined($RAD_REQUEST{'Acct-Delay-Time'})) {
          $ses_start -= $RAD_REQUEST{'Acct-Delay-Time'};
        };
      };
      $arch_row{'s_id'} = 0;
      $arch_row{'s_agent'} = $agent;
      $arch_row{'s_ip'} = $ip;
      $arch_row{'s_mac'} = $mac;
      $arch_row{'s_acct_ses_id'} = $acct_ses_id;
      $arch_row{'s_login'} = $login;
      $arch_row{'s_name'} = scalar(@$urow)?${${$urow}[0]}{'u_name'}:"";
      $arch_row{'s_anumber'} = scalar(@$urow)?${${$urow}[0]}{'u_anumber'}:"";
      $arch_row{'s_vg_id'} = $Vvg_id;
      $arch_row{'s_nas_ip'} = $nas_ip;
      $arch_row{'s_nas_port'} = $nas_port;
      $arch_row{'s_auth'} = $ses_start;
      $arch_row{'s_start'} = $ses_start;
      $arch_row{'s_update'} = $ses_stop;
      $arch_row{'s_state'} = $Vstate;
      $arch_row{'s_state_changed'} = 0;
      $arch_row{'s_change_queued'} = 0;
      $arch_row{'s_coa_reason'} = "Adopted stop, no data";
      $arch_row{'s_speed'} = $Vspeed;
      $arch_row{'s_last_input'} = $ses_stop;
      $arch_row{'s_kill'} = 0;
      $arch_row{'s_scat_svc'} = $Vssvc;
    };

    $arch_row{'s_bytes_in'} = $octets_in;
    $arch_row{'s_bytes_out'} = $octets_out;
    $arch_row{'s_pkts_in'} = $RAD_REQUEST{'Acct-Input-Packets'};
    $arch_row{'s_pkts_out'} = $RAD_REQUEST{'Acct-Output-Packets'};

    $arch_row{'h_term_cause'} = $RAD_REQUEST{'Acct-Terminate-Cause'};
    $arch_row{'s_stop'} = $ses_stop;

    $arch_row{'is_error'} = 0;

    if(&archive_row(\%arch_row) != RLM_MODULE_OK) {
      &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
      return RLM_MODULE_INVALID;
    };

  } else {
    &radiusd::radlog(L_ERR, "Bad acct request ".$RAD_REQUEST{'Acct-Status-Type'}." at ".__LINE__);
    return RLM_MODULE_INVALID;
  };

  if(($RAD_REQUEST{'Acct-Status-Type'} eq "Start" ||
      $RAD_REQUEST{'Acct-Status-Type'} eq "Stop"
     ) &&
     $Vslogin ne ""
  ) {
    my $ips="";
    if($Vsips ne "") {
      $ips = $Vsips;
      if($Vsips =~ /^ *[;,\/]/) {
        $ips = $ip.$ips;
      };
    } else {
      $ips=$ip;
    };

    if($ips ne "") {
      if(! &scat($Vslogin."_".$acct_ses_id, $ips, $Vssvc)) {
        return RLM_MODULE_INVALID;
      };
    };

    if(scalar(@$urow)) {
      if($RAD_REQUEST{'Acct-Status-Type'} eq "Start") {
        $query="UPDATE us SET u_last_start=? WHERE u_vg_id=?";
      } else {
        $query="UPDATE us SET u_last_stop=? WHERE u_vg_id=?";
      };
      $dbh->do($query, {}, (time(), $Vvg_id));
      if($dbh->err) {
        &radiusd::radlog($DB_ERR, "DB error at ".__LINE__.": ".$dbh->errstr);
        return RLM_MODULE_INVALID;
      };
    };
  };

  return RLM_MODULE_OK;
}

# Function to handle checksimul
sub checksimul {
  return RLM_MODULE_OK;
}

# Function to handle pre_proxy
sub pre_proxy {
  return RLM_MODULE_OK;
}

# Function to handle post_proxy
sub post_proxy {
  return RLM_MODULE_OK;
}

# Function to handle xlat
sub xlat {
}

# Function to handle detach
sub detach {
}

sub log_request_attributes {
  my $level=shift;
  if(!defined($level)) { $level=L_DBG; };
  # This shouldn't be done in production environments!
  # This is only meant for debugging!
  for (keys %RAD_REQUEST) {
    &radiusd::radlog($level, "\t$_ = $RAD_REQUEST{$_}");
  }
}

