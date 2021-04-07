CREATE VIEW vgroups AS select us.u_uid AS uid,us.u_vg_id AS vg_id from us;
CREATE VIEW sessionsradius AS
  SELECT
    s_vg_id AS vg_id
   ,s_acct_ses_id as session_id
   ,UNHEX(LPAD(HEX(INET_ATON(s_ip) | 0xFFFF00000000), 32,0)) as assigned_ip
   ,s_mac as sess_ani
  FROM ss
;

CREATE VIEW IF NOT EXISTS rad00120210329 AS
  SELECT
    h_vg_id as vg_id
   ,FROM_UNIXTIME(h_stop) as timeto
   ,FROM_UNIXTIME(h_start) as timefrom
   ,h_mac as ani
   ,UNHEX(LPAD(HEX(INET_ATON(h_ip) | 0xFFFF00000000), 32,0)) as ip
   ,h_bytes_in as cin
   ,h_bytes_out as cout
  FROM history_202103
  WHERE
    h_stop > UNIX_TIMESTAMP('2021-03-29 00:00')
    AND h_stop > 0
    AND h_auth > 0
    AND h_start > 0
    AND h_ip <> ''
;
    
CREATE VIEW auth_hist20210329 AS
  SELECT
    h_vg_id as vg_id
   ,UNHEX(LPAD(HEX(INET_ATON(h_ip) | 0xFFFF00000000), 32,0)) as ip
   ,h_mac as mc
  FROM history_202103
  WHERE
   h_auth > UNIX_TIMESTAMP('2021-03-29 00:00')
   AND h_ip <> ''
;
