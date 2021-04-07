package radius_options;

use strict;

#our $UPDATE_INTERVAL=300;
our $UPDATE_INTERVAL=180;

# IOS XE supported maximum or bug. Check for next versions.
our $MAX_POLICE_BPS=1024*262148;

our $THIS="10.0.11.72";

our @ADDITIONAL_SERVICES=qw//;
our @REDIRECT_SERIVCES=qw/NoMoney10 NoMoney400 NoMoney500 NoMoney510/; #defined on NAS

our $REDIRECT_SPEED_MAX=10240;

our $DB_HOST="localhost";
our $DB_NAME="radius";

#radiusd db account
our $DB_USER="radius";
our $DB_PASS="radius";

#CoA daemon db account
our $COA_DB_USER="coa-daemon";
our $COA_DB_PASS="coa-daemon";

#CoA router secret. May differ for each radius host!
our $COA_SECRET="secret";

our $COA_LOG="/var/log/coa_daemon.log";

our $IDLE_SESSION=3600;

our $ACCOUNTING_LIST="EXT_RADIUS"; #defined on NAS aaa

our $RADCLIENT="/usr/bin/radclient";

our $RADIUSD_PID_FILE="/var/run/freeradius/freeradius.pid";

our $STOP_LOG="/var/log/freeradius/stop.log";

# as returned by "ps -o command -p `cat $RADIUSD_PID_FILE`"
our $RADIUSD_BINARY="/usr/sbin/freeradius";

#CoA daemon files
our $PID_FILE="/var/run/coa-daemon.pid";
our $STATE_FILE="/var/run/coa-daemon.state";

our $SCAT_TIMEOUT=4;
our $SCAT_URI="http://10.0.11.110/fdpi_login/ext_radius.php";
