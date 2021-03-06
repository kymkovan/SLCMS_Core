<!--- mbc SLCMS CFCs  --->
<!--- &copy; 2012 mort bay communications --->
<!---  --->
<!--- A Module's Controller CFC  --->
<!--- provides the needed information for a module to be incorporated into SLCMS
			this is a cut-down version of the CFC as it is used to initialize the core and we know a lot more about it and more things are hard-coded
			 --->
<!--- Contains:
			getBaseDefinition() - provides the config to SLCMS, CFCs to be stored persistently, etc
			initModule() - initialises the whole kit and kaboodle, inits all the internal CFCs, etc., of the Core
			ReInitAfter() - with an "Action" argument re-initializes all relevant CFC after a core update of some action
			 --->
<!---  --->
<!--- created:  21st Mar 2009 by Kym K, mbcomms --->
<!--- modified: 21st Mar 2009 -  1st Apr 2009 by Kym K, mbcomms: initial work on it --->
<!--- modified:  3rd May 2009 -  6th May 2009 by Kym K, mbcomms: Added User Control CFC for user/roles, etc --->
<!--- modified:  4th Sep 2009 -  4th Sep 2009 by Kym K, mbcomms: Added UserPermissions CFC for user permissions, etc --->
<!--- modified:  6th Sep 2009 -  6th Sep 2009 by Kym K, mbcomms: Added Database_VersionControl CFC for database table management --->
<!--- modified:  3rd Oct 2009 - 30th Oct 2009 by Kym K, mbcomms: V2.2+, portal-capability added --->
<!--- modified: 19th Nov 2009 - 19th Nov 2009 by Kym K, mbcomms: V2.2+, more portal work - changing search init calls to reflect many subSites --->
<!--- modified: 11th Dec 2009 - 27th Dec 2009 by Kym K, mbcomms: V2.2+, now adding DataMgr as a DAL to make the codebase database agnostic, most CFCs now don't need the DSN defined --->
<!--- modified: 24th Jan 2010 - 24th Jan 2010 by Kym K, mbcomms: V2.2+, added ReInitAfter function and renamed CFC to: ModuleController.CFC --->
<!--- modified:  5th Jun 2010 -  5th Jun 2010 by Kym K, mbcomms: V2.2+, added more items to reInitAfter function: database CFC --->
<!--- modified:  3rd Jul 2010 -  3rd Jul 2010 by Kym K, mbcomms: V2.2+, reorganizing the 3rd part libraries like jQuery and DataMgr --->
<!--- modified: 19th Mar 2011 - 19th Mar 2011 by Kym K, mbcomms: V2.2+, added db table stuff to SLCMS_Utility CFC init as its actually doing thinsg now! --->
<!--- modified:  5th May 2011 -  5th May 2011 by Kym K, mbcomms: V2.2+, adding editor paths as used by all sorts of modules now so make them global --->
<!--- modified:  7th Jun 2011 -  8th Jun 2011 by Kym K, mbcomms: V2.2+, added logging functions so we can have consistent logging outside CF's logs --->
<!--- modified:  1st Jan 2012 -  1st Jan 2012 by Kym K, mbcomms: V2.2+, changed the way templates are stored, now we can have the module ones as well and can customize them so the template manager init has changed --->
<!--- modified:  4th Mar 2012 -  4th Mar 2012 by Kym K, mbcomms: V2.2+, changed the way roles are stored, now in application scope directly as core alongside any modules we may have --->
<!--- modified:  9th Apr 2012 -  9th Apr 2012 by Kym K, mbcomms: V3.0, CFWheels version. All SLCMS in own struct under app scope --->

<cfcomponent extends="controller" displayname="Module Controller" hint="Defines and globally sets up what is in the Core" output="False">

	<!--- set up a few quasi-persistant things on the way in. --->
	<cfset variables.theApplicationConfig = StructNew() />	<!--- will carry the SLCMS config struct for a moment whilst everything gets set up --->

<cffunction name="getBaseDefinition" output="No" returntype="struct" access="public"
	displayname="get Base Definition"
	hint="sends all the config info to SLCMS on a restart/reconfig/flush"
	>
	
	<!--- the return structure which flags what we have and can use --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with result --->
	<!--- unlike most functions in most CFCs we need no validation here or even any error handling, it just sets up a structure --->
	<!--- first describe this module --->
	<cfset ret.thisModuleBaseInfo = StructNew() />
	<cfset ret.thisModuleBaseInfo.Name = "Core" />
	<cfset ret.thisModuleBaseInfo.Stuff = "Stuff" />	<!--- don't know what we need yet --->
	<!--- with the functions in it that can be called --->
	<cfset ret.thisModuleControllerFunctionList = "ReInitAfter" />
	<cfset ret.thisModuleControllerFunctions = StructNew() />	<!--- list of the function we make available --->
	<cfset ret.thisModuleControllerFunctions.ReInitAfter = StructNew() />
	<cfset ret.thisModuleControllerFunctions.ReInitAfter.name = "ReInitAfter" />
	<cfset ret.thisModuleControllerFunctions.ReInitAfter.argumentList = "Action" />
	<cfset ret.thisModuleControllerFunctions.ReInitAfter.ReturnType = "Structure" />
	<cfset ret.thisModuleControllerFunctions.ReInitAfter.ReturnTypeIsStandardReturnStruct = True />
	<!--- then what CFCs are available --->
	<cfset ret.thisModuleCFCs = StructNew() />

	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<!--- initialize the various thingies, this should only be called after an app scope refresh --->
<cffunction name="initModule" 
	access="public" output="yes" returntype="any" 
	displayname="Initializer"
	hint="sets up the internal structures for the core SLCMS functions"
	>
	<!--- this function needs.... --->
	<cfargument name="ApplicationConfig" type="struct" required="true" hint="the configuration structure, normally the application.SLCMS.Config struct" />
	<!--- local vars, hard coding for where things are in default installation --->
	<!--- these are the actual folder names, we will add in pre-paths down below --->
	<cfset var theCFCsPath = "CFCs/" />
	<cfset var theGlobalRootPath_Rel = "" />
	<cfset var theDataMgrPath = "DataMgr/" />
	<cfset var theEditorsPath = "Editors/" />
	<cfset var CKEditorFolderName = "FCK_Editor/" />
	<cfset var CKEditorScriptName = "ckeditor.js" />
	<cfset var TinyMCEjqFolderName = "tiny_mce_jq/" />
	<cfset var TinyMCEjqScriptName = "tiny_mce.js" />
	<cfset var TinyMCEStandardFolderName = "TinyMCE/" />
	<cfset var TinyMCEStandardScriptName = "tiny_mce.js" />
	<cfset var the3rdPartyPath = "" />
	<cfset var thejQueryJsPath = "jQuery/jquery.min.js" />
	<cfset var thejQueryUIPath = "jQuery/jquery-ui.full.min.js" />
	<cfset var theHelpAjaxPath = "ajax/" />
	<!--- 
	<cfset var SLCMSGraphicsPath_Rel = "SLCMSstyling/" />
	<cfset var theIconsPath_Rel = "fam/" />
	 --->
	<cfset var databaseRootName =  "" />
	<cfset var databaseSystemName =  "" />
	<cfset var thePortalList = "" />	<!--- will be list of all subsites --->
	<cfset var thisSubSite = "" />	<!--- item from list as we loop --->
	<cfset var thisSubSiteShortName = "" />	<!--- name of folder for particlar subsite as we loop --->
	<!--- create the return structure --->
	<cfset var ret = StructNew() />
	<!--- and load it up with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "Core ModuleController CFC: initModule()" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = StructNew() />	<!--- and no data yet --->

	<cftry>
		<cfset variables.theApplicationConfig = arguments.ApplicationConfig />
		<cfset theCFCsPath = variables.theApplicationConfig.base.SLCMSCoreRelPath & theCFCsPath />
		<cfset theGlobalRootPath_Rel = variables.theApplicationConfig.Base.SLCMSPath_Rel & theGlobalRootPath_Rel />
		<cfset theDataMgrPath = variables.theApplicationConfig.base.SLCMS3rdPartyPath_Abs & theDataMgrPath />
		<cfset theEditorsPath = theGlobalRootPath_Rel & theEditorsPath />
		<cfset CKEditorFolderName = theEditorsPath & CKEditorFolderName />
		<cfset TinyMCEjqFolderName =  theEditorsPath & TinyMCEjqFolderName />
		<cfset TinyMCEStandardFolderName = theEditorsPath & TinyMCEStandardFolderName />
		<cfset theHelpAjaxPath = variables.theApplicationConfig.base.SLCMSHelpBaseRelPath & theHelpAjaxPath />
		<!--- 
		<cfset SLCMSGraphicsRootPath_Rel = theGlobalRootPath_Rel & SLCMSGraphicsPath_Rel />
		<cfset theIconsRootPath_Rel = SLCMSGraphicsRootPath_Rel & theIconsPath_Rel />
		 --->
		<cfset the3rdPartyPath = variables.theApplicationConfig.base.SLCMS3rdPartyPath_Rel />
		<cfset thejQueryJsPath = the3rdPartyPath & thejQueryJsPath />
		<cfset thejQueryUIPath = the3rdPartyPath & thejQueryUIPath />
		<cfset databaseRootName =  variables.theApplicationConfig.DatabaseDetails.TableNaming_Base &  variables.theApplicationConfig.DatabaseDetails.TableNaming_Delimiter & variables.theApplicationConfig.DatabaseDetails.TableNaming_SiteMarker & variables.theApplicationConfig.DatabaseDetails.TableNaming_Delimiter & "0" & variables.theApplicationConfig.DatabaseDetails.TableNaming_Delimiter />
		<cfset databaseSystemName =  variables.theApplicationConfig.DatabaseDetails.TableNaming_Base &  variables.theApplicationConfig.DatabaseDetails.TableNaming_Delimiter & variables.theApplicationConfig.DatabaseDetails.TableNaming_SystemMarker & variables.theApplicationConfig.DatabaseDetails.TableNaming_Delimiter />
	
		<cfif variables.theApplicationConfig.CodingMode>
			<cfoutput>
			core initModule() Started, variables are: <br>
			<cfdump var="#variables#" expand="false">
			</cfoutput>
		</cfif>	
		<!---  first we will load in the utility and security components as they might be needed when the other bits load and initialize --->
		<!--- these are persistent so go into the application scope --->
		<!--- first is DataMgr, the Data Access Layer we use to make the whole SLCMS engine databse agnostic --->
		<cfset application.SLCMS.Core.DataMgr = createObject("component","#variables.theApplicationConfig.base.MapURL##theDataMgrPath#DataMgr").init(datasource="#variables.theApplicationConfig.datasources.CMS#") /><!--- this CFC family manages database access, its the Database Abstraction Layer --->
		<cfif variables.theApplicationConfig.CodingMode>
			<cfoutput>
			core initModule(): DataMgr inited, return is: <br>
			<cfdump var="#application.SLCMS.Core.DataMgr#" expand="false">
			</cfoutput>
		</cfif>
  	<cfinclude template="CoreHardCodedConfig.cfm" >	<!--- this one will puts in the roles bit patterns and similar hard-coded structs --->

		<!--- then the base utilities --->
		<cfset application.SLCMS.Core.SLCMS_Utility = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#SLCMS_Utility") /><!--- this CFC manages common utilities --->
		<cfset ret.Data.UtilityInit = application.SLCMS.Core.SLCMS_Utility.init(StartUpPaths="#variables.theApplicationConfig.StartUp#", dsn="#variables.theApplicationConfig.datasources.CMS#", DatabaseDetails="#variables.theApplicationConfig.DatabaseDetails#") />

		<!--- 
			<cfdump var="#ret.Data.UtilityInit#" expand="false" label="ret.Data.UtilityInit">
			
			<cfabort>
		 --->

		<cfset temps = LogIt(LogType="System_Init", LogString="Core ModuleController Init() after Utility Init()") />
		<!--- and check our version for database updates or whatever and load in the base version config (any version updating will happen transparently, the DAL looks after the db tables, etc) --->
		<cfset application.SLCMS.Core.Versions_Master = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#VersionControl_Master") /><!--- this CFC has persistent date related to maintaining versions, etc. --->
		<cfset ret.Data.Versions_MasterInit = application.SLCMS.Core.Versions_Master.init(Config="#variables.theApplicationConfig#", CFCsPath="#theCFCsPath#", databaseSystemName="#databaseSystemName#") />	<!--- initialise it, this won't update database tables but gets stuff ready --->
		<cfset temps = LogIt(LogType="System_Init", LogString="Core ModuleController Init() after VersionMaster Init()") />
	
		<cfif variables.theApplicationConfig.CodingMode>
			<cfoutput>
			core initModule(): Versions inited, return is: <br>
			<cfdump var="#ret.Data.Versions_MasterInit#" expand="false">
			</cfoutput>
		</cfif>
		<!--- 
		<cfset application.SLCMS.Core.Security = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#Security") /><!--- this CFC manages blog categories and related utilities --->
		<cfset ret.Data.SecurityInit = application.SLCMS.Core.Security.init(DSN="#variables.theApplicationConfig.datasources.CMS#") />	<!--- tell the security engine the DB details to use --->
		 --->
	<!--- 
	<cfdump var="#variables.theApplicationConfig.startup#">
	<cfabort >
	 --->
		<!--- then the non-persistent things that are needed for a once off initialise into application scopes and things --->
		<!--- 
		<cfset variables.Core.Versions_Master = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#VersionControl_Master") /><!--- this CFC has tools related to maintaining versions, etc. --->
		<cfset ret.Data.Versions_MasterInit = variables.Core.Versions_Master.init(dsn="#variables.theApplicationConfig.datasources.CMS#") />	<!--- initialise it, this will update database tables if we need to --->
		 --->
		
		<!--- then set up our global CFCs that are persistent (here they are created in alphabetic oder to help maintenance, no order needed codewise, but the opposite when they are initialized as we need some stuff set b4 other stuff called) --->
		<cfset application.SLCMS.Core.ControllerHelpers_Admin = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#ControllerHelpers_Admin") /><!--- this CFC manages blog categories and related utilities --->
		<cfset application.SLCMS.Core.Control_Blogs = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#Control_Blogs") /><!--- this CFC manages blog categories and related utilities --->
		<cfset application.SLCMS.Core.ContentCFMfunctions = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#ContentCFMfunctions") /><!--- this CFC carries the functions that content.cfm uses, made persistent as called lots of times --->
		<cfset application.SLCMS.Core.Content_DatabaseIO = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#Content_DatabaseIO") /><!--- this CFC manages input/output of content from the database --->
		<cfset application.SLCMS.Core.Content_Search = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#Content_Search") /><!--- this CFC has the various functions related to searching --->
		<cfset application.SLCMS.Core.Forms = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#FormHandling") /><!--- this CFC has functions related to showing, validating and processing form --->
		<cfset application.SLCMS.Core.PageStructure = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#PageStructure") /><!--- this CFC has tools related to the site structure --->
		<cfset application.SLCMS.Core.PortalControl = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#PortalControl") /><!--- this CFC has tools related to the site structure --->
		<cfset application.SLCMS.Core.Templates = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#TemplateManagement") /><!--- this CFC has functions related to Template Management --->
		<cfset application.SLCMS.Core.UserControl = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#UserControl") /><!--- this CFC has tools related to users, their permissions, etc. --->
		<cfset application.SLCMS.Core.UserPermissions = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#UserPermissions") /><!--- this CFC has tools related to users permissions --->
	
		<cfif variables.theApplicationConfig.CodingMode>
			<cfoutput>
			core initModule(): core components loaded. application.SLCMS.Core scope is: <br>
			<cfdump var="#application.SLCMS.Core#" expand="false">
			</cfoutput>
		</cfif>
		<!--- 
		<cfset application.Gallery = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#PhotoGallery") /><!--- this CFC has functions related to the Shop --->
		<cfset application.SLShop = createObject("component","#variables.theApplicationConfig.base.MapURL##theCFCsPath#SLShop") /><!--- this CFC has functions related to the Shop --->
		<cfset ret.Data.mbc_Utility_UtilitiesInit = application.mbc_Utility.Utilities.init(DefStructure="#variables.theApplicationConfig.Utilities#") />	<!--- take the config from the ini files, can be any relevant structure --->
		 --->
	 	<!--- now we have the CFCs we can initialize them and set up other bits as we go, all in the correct order so it all works. --->
		<cfset ret.Data.PortalControlInit = application.SLCMS.Core.PortalControl.init(dsn="#variables.theApplicationConfig.datasources.CMS#", PortalControlTable="#databaseSystemName##variables.theApplicationConfig.DatabaseDetails.PortalControlTable#", PortalParentDocTable="#databaseSystemName##variables.theApplicationConfig.DatabaseDetails.PortalParentDocTable#", PortalURLTable="#databaseSystemName##variables.theApplicationConfig.DatabaseDetails.PortalURLTable#") />	<!--- tell the SiteStructure what DSN and tables to work with and loads up the navigation arrays/structures --->
		<!--- now we have subsites, etc lets fill in a 'few' odd variables, basically all the app scope vars used by core or module code everywhere --->
		<cfset thePortalList = application.SLCMS.Core.PortalControl.GetFullSubSiteIDList() />
		<cfloop list="#thePortalList#" index="thisSubSite">
			<cfset thisSubSiteShortName = application.SLCMS.Core.PortalControl.GetSubSite(subSiteID=thisSubSite).data.SubSiteShortName />
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"] = StructNew() />
			<!--- set up all the paths that we use all the time --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].Paths = StructNew() />
			<!--- load in the paths for the editors to find things --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].Paths.ResourcePaths = StructNew() />
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].Paths.ResourcePaths.ResourceBase = application.SLCMS.Config.Base.SitesBaseRelPath & thisSubSiteShortName & "/" & application.SLCMS.Config.Base.ResourcesBaseRelPath />	<!--- just that, paths to the resources that we use like graphics, documents and files --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].Paths.ResourcePaths.FileResources = application.SLCMS.Config.Base.SitesBaseRelPath & thisSubSiteShortName & "/" & application.SLCMS.Config.Base.ResourcesFileRelPath />	<!--- rel path to this set of files --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].Paths.ResourcePaths.FlashResources = application.SLCMS.Config.Base.SitesBaseRelPath & thisSubSiteShortName & "/" & application.SLCMS.Config.Base.ResourcesFlashRelPath />	<!--- rel path to this set of files --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].Paths.ResourcePaths.ImageResources = application.SLCMS.Config.Base.SitesBaseRelPath & thisSubSiteShortName & "/" & application.SLCMS.Config.Base.ResourcesImageRelPath />	<!--- rel path to this set of files --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].Paths.ResourcePaths.MediaResources = application.SLCMS.Config.Base.SitesBaseRelPath & thisSubSiteShortName & "/" & application.SLCMS.Config.Base.ResourcesMediaRelPath />	<!--- rel path to this set of files --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].Paths.ResourcePaths.FormUploads = application.SLCMS.Config.Base.SitesBaseRelPath & thisSubSiteShortName & "/" & application.SLCMS.Config.Base.ResourcesFormUploadsRelPath />	<!--- rel path to this set of files --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].Paths.ResourceURLs = StructNew() />
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].Paths.ResourceURLs.ResourceBase = application.SLCMS.Config.Base.rootURL & application.SLCMS.Config.Base.SitesBaseRelPath & thisSubSiteShortName & "/" & application.SLCMS.Config.Base.ResourcesBaseRelPath />	<!--- just that, paths to the resources that we use like graphics, documents and files --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].Paths.ResourceURLs.FileResources = application.SLCMS.Config.Base.rootURL & application.SLCMS.Config.Base.SitesBaseRelPath & thisSubSiteShortName & "/" & application.SLCMS.Config.Base.ResourcesFileRelPath />	<!--- rel path to this set of files --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].Paths.ResourceURLs.FlashResources = application.SLCMS.Config.Base.rootURL & application.SLCMS.Config.Base.SitesBaseRelPath & thisSubSiteShortName & "/" & application.SLCMS.Config.Base.ResourcesFlashRelPath />	<!--- rel path to this set of files --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].Paths.ResourceURLs.ImageResources = application.SLCMS.Config.Base.rootURL & application.SLCMS.Config.Base.SitesBaseRelPath & thisSubSiteShortName & "/" & application.SLCMS.Config.Base.ResourcesImageRelPath />	<!--- rel path to this set of files --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].Paths.ResourceURLs.MediaResources = application.SLCMS.Config.Base.rootURL & application.SLCMS.Config.Base.SitesBaseRelPath & thisSubSiteShortName & "/" & application.SLCMS.Config.Base.ResourcesMediaRelPath />	<!--- rel path to this set of files --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].Paths.ResourceURLs.FormUploads = application.SLCMS.Config.Base.rootURL & application.SLCMS.Config.Base.SitesBaseRelPath & thisSubSiteShortName & "/" & application.SLCMS.Config.Base.ResourcesFormUploadsRelPath />	<!--- rel path to this set of files --->
			<!--- now set up forms to use --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].FormDetails = StructNew() />	<!--- just that, details of the forms, field type, size, etc --->
			<!--- and stored queries --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].queries = StructNew() />	<!--- persistent queries --->
			<cfset application.SLCMS.Sites["Site_#thisSubSite#"].queries.templates = StructNew() />	<!--- persistent queries such as the templates --->
		</cfloop>
		<!--- put in odds and sods, part 1, pre initializing --->
		<cfset application.SLCMS.Paths_Common.ThirdPartyPath_Rel = the3rdPartyPath />
		<cfset application.SLCMS.Paths_Common.jQueryJsPath_Rel = thejQueryJsPath />
		<cfset application.SLCMS.Paths_Common.jQueryUIPath_Rel = thejQueryUIPath />
		<cfset application.SLCMS.Paths_Common.HelpAjaxPath_Rel = theHelpAjaxPath />
		<!--- now initialize the rest --->
		<!--- 
		<cfset ret.Data.Control_BlogsInit = application.SLCMS.Core.Control_Blogs.init(dsn="#variables.theApplicationConfig.datasources.CMS#", CategoriesTable="#databaseRootName##variables.theApplicationConfig.DatabaseDetails.BlogCategoryTable#", ControlTable="#databaseRootName##variables.theApplicationConfig.DatabaseDetails.BlogContentControlTable#", BlogsTable="#databaseRootName##variables.theApplicationConfig.DatabaseDetails.BlogBlogsTable#") />	<!--- tell the blog engine the DB details to use --->
		 --->
		<cfset ret.Data.PageStructureInit = application.SLCMS.Core.PageStructure.init(DatabaseDetails="#variables.theApplicationConfig.DatabaseDetails#") />	<!--- tell the SiteStructure what DSN and tables to work with and load up the navigation arrays/structures --->
		<cfset ret.Data.Content_DatabaseIOInit = application.SLCMS.Core.Content_DatabaseIO.init(dsn="#variables.theApplicationConfig.datasources.CMS#", DatabaseDetails="#variables.theApplicationConfig.DatabaseDetails#") />	<!--- tell the Content's Database IO engine what DSN and tables to work with and load up the navigation arrays/structures --->
		<!--- 
		<cfset ret.Data.ContentCFMfunctionsInit = application.SLCMS.Core.ContentCFMfunctions.init(dsn="#variables.theApplicationConfig.datasources.CMS#", PortalControlTable="#databaseSystemName##variables.theApplicationConfig.DatabaseDetails.PortalControlTable#", PortalParentDocTable="#databaseSystemName##variables.theApplicationConfig.DatabaseDetails.PortalParentDocTable#", PortalURLTable="#databaseSystemName##variables.theApplicationConfig.DatabaseDetails.PortalURLTable#") />	<!--- tell the SiteStructure what DSN and tables to work with and loads up the navigation arrays/structures --->
		 --->
		<cfset ret.Data.TemplateManagementInit = application.SLCMS.Core.Templates.init(Config="#variables.theApplicationConfig#") />	<!--- give the template managing engine the config to work out the base paths to the templates. It will work out the rest, its by convention from there on down --->
		<cfset ret.Data.UserControlInit = application.SLCMS.Core.UserControl.init() />	<!--- tell the User controller not much at all, it does its own thing --->
		<cfset ret.Data.UserPermissionsInit = application.SLCMS.Core.UserPermissions.init() />	<!--- tell the permissions controller not much at all, it does its own thing --->
		<cfset ret.Data.FormsInit = application.SLCMS.Core.Forms.init(dsn="#variables.theApplicationConfig.datasources.CMS#") />	<!--- all we need is the datasource as the template engine above did the physical dirty work and found the form templates --->
		<cfif variables.theApplicationConfig.Components.Use_Search>
			
			<cfset ret.Data.Content_SearchInit = application.SLCMS.Core.Content_Search.init(Config="#variables.theApplicationConfig#") />	<!--- give the Search functions the config so it can work out all of the subSites, etc --->
			
			<!--- 
			<cfset ret.Data.Content_SearchInit = application.SLCMS.Core.Content_Search.init(dsn="#variables.theApplicationConfig.datasources.CMS#", SiteName="#databaseRootName##variables.theApplicationConfig.base.theSiteSearchCollectionName#", ContentTable="#databaseRootName##variables.theApplicationConfig.DatabaseDetails.ContentTable#", DocContentControlTable="#databaseRootName##variables.theApplicationConfig.DatabaseDetails.DocContentControlTable#", CollectionsPath="#variables.theApplicationConfig.StartUp.CollectionsRootPath#", DocumentPhysicalPath="#variables.theApplicationConfig.StartUp.SiteBasePath#Resources/Files", DocumentURLPath="#variables.theApplicationConfig.base.rootURL#Resources/Files") />	<!--- tell the Search functions what DSN and tables to work with --->
			 --->
		</cfif>
		<!--- put in odds and sods, part 2 --->
		<cfset application.SLCMS.Sites.Site_0.HomeURL = application.SLCMS.Core.PortalControl.GetPortalHomeURL() />
		<cfset application.SLCMS.Paths_Common.Editors = StructNew() />
		<cfset application.SLCMS.Paths_Common.Editors.contentEditorControllerURL = application.SLCMS.Paths_Admin.AdminBaseURL & "content-editor" />
		<cfset application.SLCMS.Paths_Common.Editors.CKEditorFolder_ABS = application.SLCMS.Paths_Common.RootURL & CKEditorFolderName />
		<cfset application.SLCMS.Paths_Common.Editors.CKEditorScript_ABS = application.SLCMS.Paths_Common.Editors.CKEditorFolder_ABS & CKEditorScriptName />
		<cfset application.SLCMS.Paths_Common.Editors.TinyMCEjqFolder_ABS =  application.SLCMS.Paths_Common.RootURL & TinyMCEjqFolderName />
		<cfset application.SLCMS.Paths_Common.Editors.TinyMCEjqScript_ABS =  application.SLCMS.Paths_Common.Editors.TinyMCEjqFolder_ABS & TinyMCEjqScriptName />
		<cfset application.SLCMS.Paths_Common.Editors.TinyMCEstandardFolder_ABS = application.SLCMS.Paths_Common.RootURL & TinyMCEStandardFolderName />
		<cfset application.SLCMS.Paths_Common.Editors.TinyMCEstandardScript_ABS = application.SLCMS.Paths_Common.Editors.TinyMCEstandardFolder_ABS & TinyMCEStandardScriptName />
		<cfset application.SLCMS.Paths_Common.jQueryJsPath_Abs= application.SLCMS.Paths_Common.RootURL & thejQueryJsPath />
		<cfset application.SLCMS.Paths_Common.jQueryUIPath_Abs = application.SLCMS.Paths_Common.RootURL & thejQueryUIPath />
		<cfset application.SLCMS.Paths_Common.HelpAjaxPath_Abs = application.SLCMS.Paths_Common.RootURL & theHelpAjaxPath />
		<!--- put in odds and sods, part 3 - check the NextIDs are there, only does anything meaningful on first start after an install --->
		<cfset loc.Temp = Nexts_init(DataSource="#variables.theApplicationConfig.datasources.CMS#") />	<!--- tell Nexts that we want to use the database --->
		<cfset loc.Temp = Nexts_ChecknSetNextID(IDname="DocID", IDFormat="NT", flagNeedToUpdateTables=True) />
		<cfset loc.Temp = Nexts_ChecknSetNextID(IDname="ContentID", IDFormat="NT", flagNeedToUpdateTables=True) />
		<cfset loc.Temp = Nexts_ChecknSetNextID(IDname="ModuleID", IDFormat="NT", flagNeedToUpdateTables=True) />
		<cfset loc.Temp = Nexts_ChecknSetNextID(IDname="SubSiteID", IDFormat="NT", flagNeedToUpdateTables=True) />
		<cfset loc.Temp = Nexts_ChecknSetNextID(IDname="SubSiteURLId", IDFormat="NT", flagNeedToUpdateTables=True) />
		<cfset loc.Temp = Nexts_ChecknSetNextID(IDname="UserID", IDFormat="NT", flagNeedToUpdateTables=True) />
		<cfset loc.Temp = Nexts_ChecknSetNextID(IDname="XML_Definition_AllTables", IDFormat="NT", flagNeedToUpdateTables=True) />
		<cfset loc.Temp = Nexts_ChecknSetNextID(IDname="XML_Definition_subSiteZeroTables", IDFormat="NT", flagNeedToUpdateTables=True) />

	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
			<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
			<cfdump var="#cfcatch#">
			<cfrethrow />
		</cfif>
	</cfcatch>
	</cftry>	

	<cfset temps = LogIt(LogType="System_Init", LogString="Core ModuleController Init Finished ****") />
	<cfreturn ret  />
</cffunction>

<cffunction name="ReInitAfter" output="No" returntype="struct" access="public"
	displayname="Re-Init After"
	hint="re-initialize Core components after some external change"
	>
	<!--- this function needs.... --->
	<cfargument name="Action" type="string" default="" hint="the action that took place, the components that need re-initializing" />

	<!--- now all of the var declarations, first the arguments which need manipulation --->
	<cfset var theAction = trim(arguments.Action) />
	<!--- now vars that will get filled as we go --->
	<cfset var temp1 = False />	<!--- temp/throwaway var --->
	<cfset var tempStruct2 = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorContext = "Core ModuleController CFC: ReInitAfter() Action: #theAction#" />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- and no data yet --->

	<cfset temps = LogIt(LogType="System_Init", LogString="Core ModuleController ReInitAfter() Started") />
	<!--- wrap the whole thing in a try/catch in case something breaks --->
	<cftry>
		<!--- try each action in turn --->
		<cfswitch expression="#theAction#">
			<!--- pick action performed and run the relevant refreshes --->
			<cfcase value="subSite">
				<!--- a changed sub needs to refresh permissions, pages, templates, forms --->
				<cfset temp1 = application.SLCMS.Core.UserPermissions.init() />	<!--- reload the permission now we have the subSites reloaded --->
				<cfif temp1 eq False>
					<cfset ret.error.ErrorCode = BitOr(ret.error.ErrorCode, 2) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "UserPermissions Init Failed.<br>" />
				</cfif>
				<cfset temp1 = application.SLCMS.Core.PageStructure.RefreshSiteStructures() />	<!--- no error return --->
				<cfset temp1 = application.SLCMS.Core.Templates.init(SitesBasePhysicalPath="#variables.theApplicationConfig.StartUp.SiteBasePath##variables.theApplicationConfig.base.SitesBaseRelPath#" , PageTemplatesRelPath="#variables.theApplicationConfig.Base.SLCMSPageTemplatesRelPath#", FormTemplatesRelPath="#variables.theApplicationConfig.Base.SLCMSFormTemplatesRelPath#", DataTemplatesRelPath="#variables.theApplicationConfig.Base.SLCMSDataTemplatesRelPath#") />
				<cfset tempStruct2 = application.SLCMS.Core.Forms.init(dsn="#variables.theApplicationConfig.datasources.CMS#") />
				<cfif tempStruct2.error.errorcode neq 0>
					<cfset ret.error.ErrorCode = BitOr(ret.error.ErrorCode, tempStruct2.error.errorcode) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "FormHandler Init Failed. Error was: #tempStruct2.error.errorText#<br>" />
				</cfif>
				<cfset tempStruct2 = application.SLCMS.Core.Content_DatabaseIO.reInitAfter(Action="subSite") />
				<cfif tempStruct2.error.errorcode neq 0>
					<cfset ret.error.ErrorCode = BitOr(ret.error.ErrorCode, tempStruct2.error.errorcode) />
					<cfset ret.error.ErrorText = ret.error.ErrorText & "Content_DatabaseIO Init Failed. Error was: #tempStruct2.error.errorText#<br>" />
				</cfif>
			</cfcase>
			<cfdefaultcase>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! No Action argument Supplied<br>" />
			</cfdefaultcase>>
		</cfswitch>
		<cfif ret.error.ErrorCode neq 0>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		</cfif>
	<cfcatch type="any">
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
		<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
		<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
		<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
			<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
		</cfif>
		<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
		<cfif application.SLCMS.Config.debug.debugmode>
			<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
			<cfdump var="#cfcatch#">
		</cfif>
	</cfcatch>
	</cftry>

	<cfset temps = LogIt(LogType="System_Init", LogString="Core ModuleController ReInitAfter() Finished ****") />
	<!--- return our data structure --->
	<cfreturn ret  />
</cffunction>

<cffunction name="LogIt" output="No" returntype="struct" access="Private"
	displayname="Log It"
	hint="Local Function to log info to standard log space via application.SLCMS.Core.SLCMS_Utility.WriteLog_Core(), minimizes log code in individual functions"
	>
	<cfargument name="LogType" type="string" default="" hint="The log to write to" />
	<cfargument name="LogString" type="string" default="" hint="The string to write to the log" />

	<cfset var theLogType = trim(arguments.LogType) />
	<cfset var theLogString = trim(arguments.LogString) />
	<cfset var temps = StructNew() />	<!--- temp/throwaway structure --->
	<!--- then the standard return structure, not compulsory but a good standard if nothing else specified --->
	<cfset var ret = StructNew() />	<!--- this is the return to the caller --->
	<!--- load up the return structure with a clean, empty result --->
	<cfset ret.error = StructNew() />
	<cfset ret.error.ErrorCode = 0 />
	<cfset ret.error.ErrorText = "" />
	<cfset ret.error.ErrorContext = "Core ModuleController CFC: LogIt()" />
	<cfset ret.error.ErrorExtra = "" />
	<cfset ret.Data = "" />	<!--- no data --->

		<!--- validation --->
	<cfif theLogType neq "">
		<cftry>
			<cfset temps = application.SLCMS.Core.SLCMS_Utility.WriteLog_Core(LogType="#theLogType#", LogString="#theLogString#") />
			<cfif temps.error.errorcode neq 0>
				<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 2) />
				<cfset ret.error.ErrorText = ret.error.ErrorText & "Log Write Failed. Error was: #temps.error.ErrorText#<br>" />
			</cfif>
		<cfcatch type="any">
			<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 128) />
			<cfset ret.error.ErrorText = ret.error.ErrorContext & ' Trapped. Site: #application.SLCMS.Config.base.SiteName#, error message was: #cfcatch.message#, error detail was: #cfcatch.detail#' />
			<cfset ret.error.ErrorExtra =  cfcatch.TagContext />
			<cfif isArray(ret.error.ErrorExtra) and StructKeyExists(ret.error.ErrorExtra[1], "Raw_Trace")>
				<cfset ret.error.ErrorText = ret.error.ErrorText & ", Line: #ListLast(cfcatch.TagContext[1].Raw_Trace, '#server.mbc_utility.serverconfig.OSPathDelim#')#" />
			</cfif>
			<cflog text='#ret.error.ErrorText# - ret.error.ErrorCode: #ret.error.ErrorCode# - Time: #DateFormat(Now(),"YYYYMMDD")#-#TimeFormat(now(),"HH:mm:ss")#'  file="#Application.SLCMS.Logging.theSiteLogName#" type="Error" application = "yes">
			<cfif application.SLCMS.Config.debug.debugmode>
				<cfoutput>#ret.error.ErrorContext#</cfoutput> Trapped - error dump:<br>
				<cfdump var="#cfcatch#">
			</cfif>
		</cfcatch>
		</cftry>
	<cfelse>	<!--- this is the error code --->
		<cfset ret.error.ErrorCode =  BitOr(ret.error.ErrorCode, 1) />
		<cfset ret.error.ErrorText = ret.error.ErrorText & "Oops! Unknown Log<br>" />
	</cfif>

	<cfreturn ret  />
</cffunction>

</cfcomponent>

