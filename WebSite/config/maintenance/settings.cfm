<!---
	This file is used to configure specific settings for the "maintenance" environment.
	A variable set in this file will override the one in "config/settings.cfm".
	Example: <cfset set(ipExceptions="an.ip.num.ber")>
--->

<!--- include the settings code for SLCMS --->
<cfset $include(template="SLCMS/config/maintenance/settings.cfm") />
