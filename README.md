# JIRA cloud
JIRA cloud
This article describes how to make Jira cloud work with opsview’s servicedesk module
The Output_Jirasd.pm file goes into /opt/opsview/servicedeskconnector/lib/Opsview/Notifications/Output/Jirasd.pm

 

    While the Input_Jirasd.pm file goes into /opt/opsview/servicedeskconnector/lib/Opsview/Notifications/Intput/Jirasd.pm   

     

The permissions should match the files currently in there which is -rw-r-----. 1 root opsview
 
You already have the jirasd.yml file, so the one you have configured with the correct credentials should work as below
root@mgeu20:~# cat /opt/opsview/servicedeskconnector/etc/config.d/jirasd.yml 
jirasd:
  connection:
    url: https://bankrau-team-dtydh4en.atlassian.net/
    user: xetok50162@bankrau.com
    password: ATATT3xFfGxxxxxxxxxbZcNDQB5HMv9N_xxxxxxxxxxxxxxxxdy-p3x3uKL7BhN14FhweXI7Mve-iWGjVKAPmqc2Bg=C7EA48DB
    disable_ssl_verify_hostname: 0
    use_rest_api: 1
  issue_defaults:
    project: "FML"
    type_id: "10003" 

 

And then restart the component as below as you have made changes:-

/opt/opsview/watchdog/bin/opsview-monit restart opsview-servicedeskconnector


You can then fire a manual test notification as below and it should fire successfully:

sudo -iu opsview /opt/opsview/coreutils/utils/test_notifications serviceproblem /opt/opsview/monitoringscripts/notifications/opsview_notifications jirasd


Then you can check the backend DB:- 


mysql> use notifications;
Database changed
mysql> select * FROM spool;
---
| 59 | 2025-03-13 20:28:20 | jirasd | {
  NAGIOS_CONTACTEMAIL           => "opsview\@example.com",
  NAGIOS_CONTACTNAME            => "admin",
  NAGIOS_HOSTADDRESS            => "10.11.12.13",
  NAGIOS_HOSTALIAS              => "temp host 1",
  NAGIOS_HOSTATTEMPT            => 1,
  NAGIOS_HOSTDURATION           => "20m",
  NAGIOS_HOSTNAME               => "host1",
  NAGIOS_HOSTOUTPUT             => "Test host failure",
  NAGIOS_HOSTSTATE              => "DOWN",
  NAGIOS_LASTHOSTCHECK          => 1234567891,
  NAGIOS_LASTHOSTDOWN           => 0,
  NAGIOS_LASTHOSTSTATECHANGE    => 0,
  NAGIOS_LASTHOSTUP             => 1234567890,
  NAGIOS_LASTSERVICECHECK       => 1234567889,
  NAGIOS_LASTSERVICESTATECHANGE => 1234567889,
  NAGIOS_LONGDATETIME           => "Dec 1 2009",
  NAGIOS_LONGHOSTOUTPUT         => "More data returned from Nagios\nWhich could be over\nmultiple lines",
  NAGIOS_LONGSERVICEOUTPUT      => "Many moons ago, in a galaxy\nfar, far away\nlived... Luke Skywaker!",
  NAGIOS_MAXHOSTATTEMPTS        => 2,
  NAGIOS_MAXSERVICEATTEMPTS     => 3,
  NAGIOS_NOTIFICATIONNUMBER     => 1,
  NAGIOS_NOTIFICATIONTYPE       => "PROBLEM",
  NAGIOS_SERVICEATTEMPT         => 2,
  NAGIOS_SERVICEDESC            => "Test service",
  NAGIOS_SERVICEDURATION        => "15m",
  NAGIOS_SERVICEOUTPUT          => "Service failure! Abort! Abort!",
  NAGIOS_SERVICESTATE           => "CRITICAL",
  NAGIOS_TIMET                  => 1234567895,
} | 2025-03-13 20:28:21 |       0 | active | 2025-03-13 20:28:21 |                                                                       |             |
+----+---------------------+--------+------------------------------------------------------------------------------+---------------------+---------+--------+---------------------+-----------------------------------------------------------------------+-------------+
30 rows in set (0.00 sec)


You can also tail the logs and it will show you the below:-


Mar 14 10:22:16 mgeu20 opsview_notifyd: [main::catch_signals:194] [WARN] Received kill signal - gracefully shutting down
Mar 14 10:22:18 mgeu20 opsview_notifyd: [PAR::_run_member_from_par:49] [INFO] Starting
Mar 14 10:22:23 mgeu20 opsview_notifyd: [PAR::_run_member_from_par:95] [INFO] Got 1741947742.693924 to read
Mar 14 10:22:23 mgeu20 opsview_notifyd: [PAR::_run_member_from_par:131] [DEBUG] Inserted data: <opsview><notification><create_time>1741947742</create_time><status_time>1234567889</status_time><module>jirasd</module><input_data><![CDATA[{#012  NAGIOS_CONTACTEMAIL           => "opsview\@example.com",#012  NAGIOS_CONTACTNAME            => "admin",#012  NAGIOS_HOSTADDRESS            => "10.11.12.13",#012  NAGIOS_HOSTALIAS              => "temp host 1",#012  NAGIOS_HOSTATTEMPT            => 1,#012  NAGIOS_HOSTDURATION           => "20m",#012  NAGIOS_HOSTNAME               => "host1",#012  NAGIOS_HOSTOUTPUT             => "Test host failure",#012  NAGIOS_HOSTSTATE              => "DOWN",#012  NAGIOS_LASTHOSTCHECK          => 1234567891,#012  NAGIOS_LASTHOSTDOWN           => 0,#012  NAGIOS_LASTHOSTSTATECHANGE    => 0,#012  NAGIOS_LASTHOSTUP             => 1234567890,#012  NAGIOS_LASTSERVICECHECK       => 1234567889,#012  NAGIOS_LASTSERVICESTATECHANGE => 1234567889,#012  NAGIOS_LONGDATETIME           => "Dec 1 2009",#012  NAGIOS_LONGHOSTOUTPUT         => "More data returned from Nagios\nWhich could be over\nmultiple lines",#012  NAGIOS_LONGSERVICEOUTPUT      => "Many moons ago, in a galaxy\nfar, far away\nlived... Luke Skywaker!",#012  NAGIOS_MAXHOSTATTEMPTS        => 2,#012  NAGIOS_MAXSERVICEATTEMPTS     => 3,#012  NAGIOS_NOTIFICATIONNUMBER     => 1,#012  NAGIOS_NOTIFICATIONTYPE       => "PROBLEM",#012  NAGIOS_SERVICEATTEMPT         => 2,#012  NAGIOS_SERVICEDESC            => "Test service",#012  NAGIOS_SERVICEDURATION        => "15m",#012  NAGIOS_SERVICEOUTPUT          => "Service failure! Abort! Abort!",#012  NAGIOS_SERVICESTATE           => "CRITICAL",#012  NAGIOS_TIMET                  => 1234567895,#012}]]></input_data></notification></opsview>
Mar 14 10:22:23 mgeu20 opsview_notifyd: [PAR::_run_member_from_par:149] [INFO] Processing message id 97
Mar 14 10:22:25 mgeu20 opsview_notifyd: [PAR::_run_member_from_par:166] [INFO] Processed message id 97



