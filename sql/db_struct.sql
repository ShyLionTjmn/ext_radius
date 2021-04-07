SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `auth_hist20210407` (
  `vg_id` tinyint NOT NULL,
  `ip` tinyint NOT NULL,
  `mc` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `history_202103` (
  `h_agent` int(11) NOT NULL,
  `h_ip` varchar(128) NOT NULL,
  `h_mac` varchar(128) NOT NULL,
  `h_login` varchar(128) NOT NULL,
  `h_vg_id` int(11) NOT NULL,
  `h_name` varchar(255) NOT NULL,
  `h_anumber` varchar(128) NOT NULL,
  `h_nas_ip` varchar(128) NOT NULL,
  `h_nas_port` varchar(128) NOT NULL,
  `h_start` bigint(20) unsigned NOT NULL,
  `h_stop` bigint(20) unsigned NOT NULL,
  `h_coa_reason` varchar(256) NOT NULL,
  `h_term_cause` varchar(256) NOT NULL,
  `h_speed` bigint(20) unsigned NOT NULL COMMENT 'kBit/s',
  `h_bytes_in` bigint(20) unsigned NOT NULL,
  `h_bytes_out` bigint(20) unsigned NOT NULL,
  `h_pkts_in` bigint(20) unsigned NOT NULL,
  `h_pkts_out` bigint(20) unsigned NOT NULL,
  `h_last_input` bigint(20) unsigned NOT NULL,
  `h_auth` bigint(20) unsigned NOT NULL,
  `h_kill` int(11) NOT NULL,
  `h_state` int(11) NOT NULL,
  `h_id` bigint(20) unsigned NOT NULL,
  `h_error` int(10) unsigned NOT NULL DEFAULT 0,
  `h_error_period` bigint(20) unsigned NOT NULL DEFAULT 0,
  KEY `k_vg_id` (`h_vg_id`),
  KEY `k_ip` (`h_ip`),
  KEY `k_start` (`h_start`),
  KEY `k_stop` (`h_stop`),
  KEY `h_error_period` (`h_error_period`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `history_202104` (
  `h_agent` int(11) NOT NULL,
  `h_ip` varchar(128) NOT NULL,
  `h_mac` varchar(128) NOT NULL,
  `h_login` varchar(128) NOT NULL,
  `h_vg_id` int(11) NOT NULL,
  `h_name` varchar(255) NOT NULL,
  `h_anumber` varchar(128) NOT NULL,
  `h_nas_ip` varchar(128) NOT NULL,
  `h_nas_port` varchar(128) NOT NULL,
  `h_start` bigint(20) unsigned NOT NULL,
  `h_stop` bigint(20) unsigned NOT NULL,
  `h_coa_reason` varchar(256) NOT NULL,
  `h_term_cause` varchar(256) NOT NULL,
  `h_speed` bigint(20) unsigned NOT NULL COMMENT 'kBit/s',
  `h_bytes_in` bigint(20) unsigned NOT NULL,
  `h_bytes_out` bigint(20) unsigned NOT NULL,
  `h_pkts_in` bigint(20) unsigned NOT NULL,
  `h_pkts_out` bigint(20) unsigned NOT NULL,
  `h_last_input` bigint(20) unsigned NOT NULL,
  `h_auth` bigint(20) unsigned NOT NULL,
  `h_kill` int(11) NOT NULL,
  `h_state` int(11) NOT NULL,
  `h_id` bigint(20) unsigned NOT NULL,
  `h_error` int(10) unsigned NOT NULL DEFAULT 0,
  `h_error_period` bigint(20) unsigned NOT NULL DEFAULT 0,
  KEY `k_vg_id` (`h_vg_id`),
  KEY `k_ip` (`h_ip`),
  KEY `k_start` (`h_start`),
  KEY `k_stop` (`h_stop`),
  KEY `h_error_period` (`h_error_period`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `history_template` (
  `h_agent` int(11) NOT NULL,
  `h_ip` varchar(128) NOT NULL,
  `h_mac` varchar(128) NOT NULL,
  `h_login` varchar(128) NOT NULL,
  `h_vg_id` int(11) NOT NULL,
  `h_name` varchar(255) NOT NULL,
  `h_anumber` varchar(128) NOT NULL,
  `h_nas_ip` varchar(128) NOT NULL,
  `h_nas_port` varchar(128) NOT NULL,
  `h_start` bigint(20) unsigned NOT NULL,
  `h_stop` bigint(20) unsigned NOT NULL,
  `h_coa_reason` varchar(256) NOT NULL,
  `h_term_cause` varchar(256) NOT NULL,
  `h_speed` bigint(20) unsigned NOT NULL COMMENT 'kBit/s',
  `h_bytes_in` bigint(20) unsigned NOT NULL,
  `h_bytes_out` bigint(20) unsigned NOT NULL,
  `h_pkts_in` bigint(20) unsigned NOT NULL,
  `h_pkts_out` bigint(20) unsigned NOT NULL,
  `h_last_input` bigint(20) unsigned NOT NULL,
  `h_auth` bigint(20) unsigned NOT NULL,
  `h_kill` int(11) NOT NULL,
  `h_state` int(11) NOT NULL,
  `h_id` bigint(20) unsigned NOT NULL,
  `h_error` int(10) unsigned NOT NULL DEFAULT 0,
  `h_error_period` bigint(20) unsigned NOT NULL DEFAULT 0,
  KEY `k_vg_id` (`h_vg_id`),
  KEY `k_ip` (`h_ip`),
  KEY `k_start` (`h_start`),
  KEY `k_stop` (`h_stop`),
  KEY `h_error_period` (`h_error_period`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `rad00120210407` (
  `vg_id` tinyint NOT NULL,
  `timeto` tinyint NOT NULL,
  `timefrom` tinyint NOT NULL,
  `ani` tinyint NOT NULL,
  `ip` tinyint NOT NULL,
  `cin` tinyint NOT NULL,
  `cout` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `sessionsradius` (
  `vg_id` tinyint NOT NULL,
  `session_id` tinyint NOT NULL,
  `assigned_ip` tinyint NOT NULL,
  `sess_ani` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ss` (
  `s_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `s_agent` int(11) NOT NULL,
  `s_ip` varchar(128) NOT NULL,
  `s_mac` varchar(128) NOT NULL,
  `s_acct_ses_id` varchar(128) NOT NULL,
  `s_login` varchar(128) NOT NULL,
  `s_name` varchar(255) NOT NULL,
  `s_anumber` varchar(128) NOT NULL,
  `s_vg_id` int(11) NOT NULL,
  `s_nas_ip` varchar(128) NOT NULL,
  `s_nas_port` varchar(128) NOT NULL,
  `s_auth` bigint(20) unsigned NOT NULL,
  `s_start` bigint(20) unsigned NOT NULL,
  `s_update` bigint(20) unsigned NOT NULL,
  `s_state` int(11) NOT NULL COMMENT '0 - normal access, 1 - redirect on, -1 - adopted unknown service',
  `s_state_changed` bigint(20) unsigned NOT NULL,
  `s_change_queued` bigint(20) unsigned NOT NULL,
  `s_coa_reason` varchar(256) NOT NULL,
  `s_speed` bigint(20) unsigned NOT NULL COMMENT 'kBit/s',
  `s_bytes_in` bigint(20) unsigned NOT NULL,
  `s_bytes_out` bigint(20) unsigned NOT NULL,
  `s_pkts_in` bigint(20) unsigned NOT NULL,
  `s_pkts_out` bigint(20) unsigned NOT NULL,
  `s_last_input` bigint(20) unsigned NOT NULL,
  `s_kill` bigint(20) unsigned NOT NULL DEFAULT 0,
  `s_interim_interval` int(11) NOT NULL,
  `s_scat_svc` varchar(256) NOT NULL DEFAULT '',
  PRIMARY KEY (`s_id`),
  UNIQUE KEY `uk_ses_id_nas_ip` (`s_acct_ses_id`,`s_nas_ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `us` (
  `u_vg_id` int(11) NOT NULL,
  `u_login` varchar(128) NOT NULL,
  `u_password` varchar(128) NOT NULL,
  `u_agent` int(11) NOT NULL,
  `u_speed` bigint(20) unsigned NOT NULL COMMENT 'kBit/s',
  `u_name` varchar(255) NOT NULL,
  `u_address` varchar(255) NOT NULL,
  `u_anumber` varchar(128) NOT NULL,
  `u_ips` varchar(255) NOT NULL,
  `u_scat_ips` varchar(255) NOT NULL,
  `u_scat_login` varchar(255) NOT NULL,
  `u_bill_state` int(11) NOT NULL,
  `u_added` bigint(20) unsigned NOT NULL,
  `u_updated` bigint(20) unsigned NOT NULL,
  `u_local` int(10) unsigned NOT NULL DEFAULT 0,
  `u_last_start` bigint(20) unsigned NOT NULL DEFAULT 0,
  `u_last_stop` bigint(20) unsigned NOT NULL DEFAULT 0,
  `u_last_fail` bigint(20) unsigned NOT NULL DEFAULT 0,
  `u_fail_reason` varchar(255) NOT NULL DEFAULT '',
  `u_scat_svc` varchar(256) NOT NULL DEFAULT '',
  `u_uid` int(11) NOT NULL DEFAULT 0,
  UNIQUE KEY `uk_vg_id` (`u_vg_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `user_login` varchar(128) NOT NULL,
  `user_password` varchar(256) NOT NULL,
  `user_password_count` int(11) NOT NULL,
  `user_rights` varchar(1024) NOT NULL,
  `user_name` varchar(256) NOT NULL,
  `user_last_login` bigint(20) NOT NULL,
  `user_last_activity` bigint(20) NOT NULL,
  `user_blocked` int(11) NOT NULL,
  `user_block_reason` varchar(256) NOT NULL,
  `user_deleted` bigint(20) NOT NULL,
  `ts` bigint(20) NOT NULL,
  UNIQUE KEY `user_id` (`user_id`),
  UNIQUE KEY `uk_user_login` (`user_deleted`,`user_login`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `vgroups` (
  `uid` tinyint NOT NULL,
  `vg_id` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;
/*!50001 DROP TABLE IF EXISTS `auth_hist20210407`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`importer`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `auth_hist20210407` AS select `history_202104`.`h_vg_id` AS `vg_id`,unhex(lpad(hex(inet_aton(`history_202104`.`h_ip`) | 0xffff00000000),32,0)) AS `ip`,`history_202104`.`h_mac` AS `mc` from `history_202104` where `history_202104`.`h_auth` > 1617735600 and `history_202104`.`h_ip` <> '' */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP TABLE IF EXISTS `rad00120210407`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`importer`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `rad00120210407` AS select `history_202104`.`h_vg_id` AS `vg_id`,from_unixtime(`history_202104`.`h_stop`) AS `timeto`,from_unixtime(`history_202104`.`h_start`) AS `timefrom`,`history_202104`.`h_mac` AS `ani`,unhex(lpad(hex(inet_aton(`history_202104`.`h_ip`) | 0xffff00000000),32,0)) AS `ip`,`history_202104`.`h_bytes_in` AS `cin`,`history_202104`.`h_bytes_out` AS `cout` from `history_202104` where `history_202104`.`h_stop` > 1617735600 and `history_202104`.`h_stop` > 0 and `history_202104`.`h_auth` > 0 and `history_202104`.`h_start` > 0 and `history_202104`.`h_ip` <> '' */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP TABLE IF EXISTS `sessionsradius`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`lion`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `sessionsradius` AS select `ss`.`s_vg_id` AS `vg_id`,`ss`.`s_acct_ses_id` AS `session_id`,unhex(lpad(hex(inet_aton(`ss`.`s_ip`) | 0xffff00000000),32,0)) AS `assigned_ip`,`ss`.`s_mac` AS `sess_ani` from `ss` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP TABLE IF EXISTS `vgroups`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`lion`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vgroups` AS select `us`.`u_uid` AS `uid`,`us`.`u_vg_id` AS `vg_id` from `us` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
