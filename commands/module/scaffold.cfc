/**
* Create a new standalone ColdBox module.
* Comes complete with testing facilities and ready to publish to ForgeBox.
* This command will create the module in the current directory so make sure you 
* create the folder you want to hold the module and "cd" into it. 
* When you're ready to publish, just bump your package to publish your first 1.0.0!
* 
* {code:bash}
* bump --major
* {code}
*
* You can set global defaults for gitUsername, author, and email in the module settings.
* Then you don't need to pass those parameters in to `module scaffold`.
*
* {code:bash}
* config set modules.cb-module-template.gitUsername=elpete
* config set modules.cb-module-template.author="Eric Peterson"
* config set modules.cb-module-template.email=eric@elpete.com
* {code}
*
* The `location` argument is derived from "#gitUsername#/#moduleName#".
* Passing in a location overrides this convention.
*
* You can automate the creating of a GitHub repo by setting a GitHub Personal Access Token.
*
* {code:bash}
* config set modules.cb-module-template.githubToken=YOUR-TOKEN-HERE
* {code}
*
* With this token set, a repo will be created in GitHub, the local repository pushed, and GitHub set as the upstream repo.
* The personal access token create needs the full "repo" scope to work.
*/
component {

    property name="moduleSettings" inject="commandbox:moduleSettings:cb-module-template";
    property name="OAuthService" inject="OAuthService@cbgithub";
    property name="ConfigService" inject="ConfigService";
    property name="log" inject="logbox:logger:{this}";
    property name="system" inject="system@constants";
    property name="wirebox" inject="wirebox";

    variables.templatePath = "/cb-module-template/template/";

    /**
    * @moduleName Name of the new ColdBox module to scaffold.
    * @description A short description of the module.
    * @directory Directory to create the module in.
    * @createGitRepo Create a git repo and an initial commit.
    * @createGitHubRepo Create a repo on GitHub.
    * @gitUsername GitHub username where repo will be located.
    * @location The location value for the box.json.
    * @author The name of the author of the module.
    * @email The email of the author of the module.
    */
    function run(
        required string moduleName,
        required string description,
        string directory = "",
        string gitUsername,
        string location,
        string author,
        string email,
        boolean createGitHubRepo = true,
        boolean createGitRepo = true,
        boolean useIntegrationTesting = true
    ) {
        arguments.author = arguments.author ?: moduleSettings.author;
        arguments.email = arguments.email ?: moduleSettings.email;
        arguments.gitUsername = arguments.gitUsername ?: moduleSettings.gitUsername;

        if ( ! len( gitUsername ) && isNull( location ) ) {
        	
            print.boldRedLine( "No Git username set." )
            	.line()
            	.boldRedLine( "One of three things needs to happen:" )
            	.boldRedLine( "1. A global Git username needs to be set" )
            	.boldRedLine( "2. A `gitUsername` parameter needs to be passed in." )
            	.boldRedLine( "3. A `location` parameter needs to be passed in." )
            	.line()
            	.boldYellowline( "We can go ahead and setup your GitHub token if you provide us with your Github username." )
            	.boldYellowline( "I you want to set a `location` instead, just leave empty or press Ctrl+c to quit" )
            	.line();
            	
            var gitHubUsername = ask( 'GitHub Username: ' );
            if( !gitHubUsername.len() ) {
            	print.line( 'Ok, exiting.  Come back later when you have set up your location or have your GitHub credentials ready.' );
            	return;	
            }

            ConfigService.setSetting(
                name = "modules.cb-module-template.gitUsername",
                value = gitHubUsername
            );
			arguments.gitUsername = gitHubUsername;

        }

        arguments.location = arguments.location ?: "#gitUsername#/#moduleName#";

        arguments.directory = fileSystemUtil.resolvePath( arguments.directory );
        if ( ! directoryExists( arguments.directory ) ) {
            directoryCreate( arguments.directory );
        }

        print.line().boldCyanLine( "Copying template over...." ).toConsole();

        var readme = fileRead( templatePath & "README.md.stub" );
        readme = replaceNoCase( readme, "@@moduleName@@", arguments.moduleName, "all" );
        readme = replaceNoCase( readme, "@@gitUsername@@", arguments.gitUsername, "all" );
        readme = replaceNoCase( readme, "@@author@@", arguments.author, "all" );
        readme = replaceNoCase( readme, "@@description@@", arguments.description, "all" );
        readme = replaceNoCase( readme, "@@location@@", arguments.location, "all" );

        if ( useIntegrationTesting ) {
            var boxJSON = fileRead( templatePath & "box-integration.json.stub" );
        }
        else {
            var boxJSON = fileRead( templatePath & "box.json.stub" );
        }
        boxJSON = replaceNoCase( boxJSON, "@@moduleName@@", arguments.moduleName, "all" );
        boxJSON = replaceNoCase( boxJSON, "@@gitUsername@@", arguments.gitUsername, "all" );
        boxJSON = replaceNoCase( boxJSON, "@@author@@", arguments.author, "all" );
        boxJSON = replaceNoCase( boxJSON, "@@description@@", arguments.description, "all" );
        boxJSON = replaceNoCase( boxJSON, "@@location@@", arguments.location, "all" );

        var moduleConfig = fileRead( templatePath & "ModuleConfig.cfc.stub" );
        moduleConfig = replaceNoCase( moduleConfig, "@@moduleName@@", arguments.moduleName, "all" );
        moduleConfig = replaceNoCase( moduleConfig, "@@gitUsername@@", arguments.gitUsername, "all" );
        moduleConfig = replaceNoCase( moduleConfig, "@@author@@", arguments.author, "all" );
        moduleConfig = replaceNoCase( moduleConfig, "@@description@@", arguments.description, "all" );
        moduleConfig = replaceNoCase( moduleConfig, "@@location@@", arguments.location, "all" );

        var moduleIntegrationSpec = fileRead( templatePath & "tests/resources/ModuleIntegrationSpec.cfc.stub" );
        moduleIntegrationSpec = replaceNoCase( moduleIntegrationSpec, "@@moduleName@@", arguments.moduleName, "all" );
        moduleIntegrationSpec = replaceNoCase( moduleIntegrationSpec, "@@gitUsername@@", arguments.gitUsername, "all" );
        moduleIntegrationSpec = replaceNoCase( moduleIntegrationSpec, "@@author@@", arguments.author, "all" );
        moduleIntegrationSpec = replaceNoCase( moduleIntegrationSpec, "@@description@@", arguments.description, "all" );
        moduleIntegrationSpec = replaceNoCase( moduleIntegrationSpec, "@@location@@", arguments.location, "all" );

        var sampleIntegrationSpec = fileRead( templatePath & "tests/specs/integration/sampleIntegrationSpec.cfc.stub" );
        sampleIntegrationSpec = replaceNoCase( sampleIntegrationSpec, "@@moduleName@@", arguments.moduleName, "all" );
        sampleIntegrationSpec = replaceNoCase( sampleIntegrationSpec, "@@gitUsername@@", arguments.gitUsername, "all" );
        sampleIntegrationSpec = replaceNoCase( sampleIntegrationSpec, "@@author@@", arguments.author, "all" );
        sampleIntegrationSpec = replaceNoCase( sampleIntegrationSpec, "@@description@@", arguments.description, "all" );
        sampleIntegrationSpec = replaceNoCase( sampleIntegrationSpec, "@@location@@", arguments.location, "all" );

        // copy over the template
        directoryCopy( templatePath, arguments.directory, true );

        // clean out stubs
        fileDelete( arguments.directory & "/README.md.stub" );
        fileDelete( arguments.directory & "/box.json.stub" );
        fileDelete( arguments.directory & "/box-integration.json.stub" );
        fileDelete( arguments.directory & "/ModuleConfig.cfc.stub" );
        fileDelete( arguments.directory & "/tests/resources/ModuleIntegrationSpec.cfc.stub" );
        fileDelete( arguments.directory & "/tests/specs/integration/SampleIntegrationSpec.cfc.stub" );

        // write templated files
        fileWrite( arguments.directory & "/README.md", readme );
        fileWrite( arguments.directory & "/box.json", boxJSON );
        fileWrite( arguments.directory & "/ModuleConfig.cfc", moduleConfig );
        fileWrite( arguments.directory & "/tests/resources/ModuleIntegrationSpec.cfc", moduleIntegrationSpec );
        fileWrite( arguments.directory & "/tests/specs/integration/SampleIntegrationSpec.cfc", sampleIntegrationSpec );

        if ( ! useIntegrationTesting ) {
            directoryDelete( arguments.directory & "/tests/resources", true );
            directoryDelete( arguments.directory & "/tests/specs/integration", true );
        }
        
        print.line().boldGreeneLine( "Module created in [#arguments.directory#]" ).toConsole();

        print.line().boldWhiteLine( "Installing dependencies...." ).toConsole();

        command( "install" ).run();

        if ( ! createGitRepo ) {
            finishUp();
            return;
        }

        print.boldBlueLine( "Setting up your Git repo...." ).toConsole();

        // This will trap the full java exceptions to work around this annoying behavior:
        // https://luceeserver.atlassian.net/browse/LDEV-454
        var CommandCaller = createObject( "java", "com.ortussolutions.commandbox.jgit.CommandCaller" ).init();
        var Git = createObject( "java", "org.eclipse.jgit.api.Git" );

        try {
            // Have to use reflection here since `init` tries to call the constructor
            var method = Git.getClass().getDeclaredMethod("init", []);
            var initCommand = method.invoke(Git, javacast("null", ""));
            // can't use CommandCaller since it expects a `GitCommand` and `InitCommand` does not inherit from there
            // local.repo = CommandCaller.call( initCommand );
            var jDirectory = createObject( "java", "java.io.File" ).init( arguments.directory );
            local.repo = initCommand
                .setDirectory( jDirectory )
                .call();

            var addCommand = local.repo.add().addFilePattern( "." );
            CommandCaller.call( addCommand );

            var commitCommand = local.repo.commit()
                .setMessage( "Initial commit" )
                .setAuthor( arguments.author, arguments.email );
            CommandCaller.call( commitCommand );
        }
        catch ( any var e ) {
            // If the exception came from the Java call, this exception won't be null
            var theRealJavaException = CommandCaller.getException();
            
            // If it's null, that just means some other CFML code must have blown chunks above.
            if( isNull( theRealJavaException ) ) {
                throw( message="Error Cloning Git repository", detail="#e.message#",  type="ModuleScaffoldException");
            } else {
                var deepMessage = '';
                // Start at the top level and work around way down to the root cause.
                do {
                    deepMessage &= '#theRealJavaException.toString()# #chr( 10 )#';
                    theRealJavaException = theRealJavaException.getCause()
                } while( !isNull( theRealJavaException ) )
                
                throw( message="Error Cloning Git repository", detail="#deepMessage#",  type="ModuleScaffoldException");
            }
        }

        print.blueLine( "Git repo initialized with an initial commit." ).toConsole();

        if ( ! createGitHubRepo ) {
            finishUp();
            return;
        }

        print.line().boldMagentaLine( "Creating GitHub repo...." ).toConsole();
        
        if ( ! len( moduleSettings.githubToken ) ) {
            print.line().line( "I couldn't find a GitHub token for you.  Let's create one now!" );
            var username = ask( message = "GitHub Username: ", defaultResponse = arguments.gitUsername );
            var password = ask( message = "GitHub Password: ", mask = "*" );
            var token = "";
            var otp = "";

            var loop = true;
            while ( loop ) {
                try {
                    loop = false;
                    token = OAuthService.createToken(
                        note = "cb-module-template",
                        scopes = [ "read:org", "user:email", "repo", "write:repo_hook" ],
                        username = username,
                        password = password,
                        oneTimePassword = otp
                    );
                }
                catch ( TwoFactorAuthRequired e ) {
                    loop = true;
                    otp = ask( "Two-factor Authentication Code: " );
                }
                catch( TokenAlreadyExists e ) {
                    loop = true;
                    print.line().redLine( "Whoops!  Looks like you've created a token for cb-module-template in the past." ).toConsole();
                    var response = ask( message = "Would you like us to delete that token and create a new one? (y/n) ", defaultResponse = "y" );
                    
                    if ( lcase( response ) == 'n') {
                        print.line( "Okay.  We won't be able to create your GitHub repository then." );
                        finishUp();
                        return;
                    }

                    var tokens = OAuthService.getAll(
                        username = username,
                        password = password,
                        oneTimePassword = otp
                    );

                    var existingToken = tokens.filter( function( token ) {
                        return token.getNote() == "cb-module-template";
                    } );

                    if ( ! arrayIsEmpty( existingToken ) ) {
                        existingToken[ 1 ].delete(
                            username = username,
                            password = password,
                            oneTimePassword = otp
                        );
                    }
                }
                catch ( BadCredentials e ) {
                    print.boldRedLine( "Bad credentials.  Please try again." ).line().toConsole();
                    username = ask( message = "GitHub Username: ", defaultResponse = arguments.gitUsername );
                    password = ask( message = "GitHub Password: ", mask = "*" );
                    loop = true;
                }
            }

            print.blackOnWhiteLine( "Token created!." ).line();

            ConfigService.setSetting(
                name = "modules.cb-module-template.githubToken",
                value = token.getToken()
            );

            moduleSettings.githubToken = token.getToken();
        }

        try {
            var githubRepo = wirebox.getInstance( "Repository@cbgithub" );
            githubRepo.setOwner( gitUsername );
            githubRepo.setName( moduleName );
            githubRepo.setDescription( description );
            githubRepo.save( token = moduleSettings.githubToken );
        }
        catch ( APIError e ) {
            var msg = deserializeJSON( e.message );
            return error( message = msg.message, detail = msg.errors.map( function( err ) {
                return err.message;
            } ).toList("\n") );
        }

        print.boldMagentaLine( "Repo created on Github." ).line().toConsole();

        // Turn on Travis CI
        if ( ! len( moduleSettings.travisToken ) ) {
            print.line().line( "I couldn't find a Travis token for you.  Creating one from your GitHub token now." ).toConsole();
            cfhttp( url="https://api.travis-ci.org/auth/github", method="POST", result="local.token", throwonerror="true" ) {
                // "MyClient/1.0.0" is used because Travis is bonkers with anything else
                cfhttpparam( type="header", name="User-Agent", value="MyClient/1.0.0" );
                cfhttpparam( type="header", name="Accept", value="application/vnd.travis-ci.2+json" );
                cfhttpparam( type="header", name="Content-Type", value="application/json" );
                cfhttpparam( type="body", value=serializeJSON( {"github_token" = "#moduleSettings.githubToken#"} ) );
            }

            ConfigService.setSetting(
                name = "modules.cb-module-template.travisToken",
                value = deserializeJSON( token.filecontent ).access_token
            );

            moduleSettings.travisToken = deserializeJSON( token.filecontent ).access_token;

            // refresh module settings
            moduleSettings = wirebox.getInstance( dsl = "commandbox:moduleSettings:cb-module-template" );
            print.blackOnWhiteLine( "Token created!." ).line().toConsole();
        }

        print.greenLine( "Syncing GitHub repos with Travis...." ).toConsole();
        cfhttp( url="https://api.travis-ci.org/users/sync", method="POST", result="local.syncTravis" ) {
            cfhttpparam( type="header", name="Authorization", value="token #moduleSettings.travisToken#" );
            // "MyClient/1.0.0" is used because Travis is bonkers with anything else
            cfhttpparam( type="header", name="User-Agent", value="MyClient/1.0.0" );
            cfhttpparam( type="header", name="Accept", value="application/vnd.travis-ci.2+json" );
        }

        var tries = 1;
        var travisRepoId = 0;
        var numTries = 60;
        print.text( "Please wait while Travis CI syncs with you GitHub account. " )
        	.toConsole();
        while ( tries <= numTries ) {
            try {
                cfhttp( url="https://api.travis-ci.org/repos/#gitUsername#/#moduleName#", result="local.travisRepo", throwonerror="true" ) {
                    cfhttpparam( type="header", name="Authorization", value="token #moduleSettings.travisToken#" );
                    // "MyClient/1.0.0" is used because Travis is bonkers with anything else
                    cfhttpparam( type="header", name="User-Agent", value="MyClient/1.0.0" );
                    cfhttpparam( type="header", name="Accept", value="application/vnd.travis-ci.2+json" );
                }

                travisRepoId = deserializeJSON( travisRepo.filecontent ).repo.id;
                
               	log.info( 'Found travisRepoID: #travisRepoId#' );
               	
                break;    
            }
            catch ( any e ) {
               	log.info( 'Error getting travisRepoID: #e.message#' );
               	
				// Is sync still running?
				cfhttp( url="https://api.travis-ci.org/users", method="GET", result="local.syncIsDone" ) {
					cfhttpparam( type="header", name="Authorization", value="token #moduleSettings.travisToken#" );
					// "MyClient/1.0.0" is used because Travis is bonkers with anything else
					cfhttpparam( type="header", name="User-Agent", value="MyClient/1.0.0" );
					cfhttpparam( type="header", name="Accept", value="application/vnd.travis-ci.2+json" );
				}
            	
               	  log.info( 'Travis is_syncing: #deserializeJSON( syncIsDone.filecontent )[ "user" ][ "is_syncing" ] ?: "N/A"#' );
                	
            	  // Run another!!
            	  if ( ! deserializeJSON( syncIsDone.filecontent )[ "user" ][ "is_syncing" ] ) {
		            	
					cfhttp( url="https://api.travis-ci.org/users/sync", method="POST", result="local.syncTravis" ) {
					    cfhttpparam( type="header", name="Authorization", value="token #moduleSettings.travisToken#" );
					    // "MyClient/1.0.0" is used because Travis is bonkers with anything else
					    cfhttpparam( type="header", name="User-Agent", value="MyClient/1.0.0" );
					    cfhttpparam( type="header", name="Accept", value="application/vnd.travis-ci.2+json" );
					}
					
	                print.text( "+ " )
	                	.toConsole();
				  } else {
				  	
	                print.text( ". " )
	                	.toConsole();
	                	
				  }
		            	
                sleep( 1000 );
                tries++;    
            }
        }
		
		// End the dots
		print.line();
		
        if ( tries > numTries || travisRepoId == 0 ) {
            print.boldRed( "Whoops! " )
                .redLine( "We never got a response back from the API to turn on yTravis builds.  You may need to handle that manually.  Sorry!")
                .line()
                .toConsole();
        }
        else {
            sleep( 2000 );
        	tries = 0;
        	print.text( "Please wait while we activate your repo in Travis CI. " )
        		.toConsole();
            try {
            	tries++;
                cfhttp( url="https://api.travis-ci.org/hooks", method="PUT", result="local.turnOnHooks", throwonerror="true" ) {
                    cfhttpparam( type="header", name="Authorization", value="token #moduleSettings.travisToken#" );
                    // "MyClient/1.0.0" is used because Travis is bonkers with anything else
                    cfhttpparam( type="header", name="User-Agent", value="MyClient/1.0.0" );
                    cfhttpparam( type="header", name="Accept", value="application/vnd.travis-ci.2+json" );
                    cfhttpparam( type="header", name="Content-Type", value="application/json" );
                    cfhttpparam( type="body", value=serializeJSON( {
                        "hook" = {
                            "id" = travisRepoId,
                            "active" = true
                        }
                    } ) );
                }

                print
                	.line()
                	.boldGreenLine( "Builds turned on in Travis." ).line().toConsole();
            }
            catch ( any e ) {
                log.info( "Travis Repo Id: #travisRepoId ?: 'N/A'#" );
                log.error( "Exception thrown trying to activate Travis CI", e.message );
				
				if( tries <= 30 ) {
					sleep( 1000 );
	                print.text( ". " )
	                	.toConsole();
	                	
					retry;
				}

                print.line()
                	.boldRed( "Whoops! " )
                    .redLine( "There was some trouble turning on the Travis builds.  You may need to handle that manually.  Sorry!")
                    .line()
                    .toConsole();
            }
        }
		
        try {
        // Using HTTPS URL so the GitHub Oauth token will work without complaining about not knowing the github.com host.
            var uri = createObject( "java", "org.eclipse.jgit.transport.URIish" )
                .init( "https://github.com/#githubRepo.getFullName()#.git" );
                
            print.yellowLine( "Pushing module to https://github.com/#githubRepo.getFullName()#.git" ).line().toConsole();
            
            var remoteAddCommand = local.repo.remoteAdd();
            remoteAddCommand.setName( "origin" )
            remoteAddCommand.setUri( uri );
            CommandCaller.call( remoteAddCommand );

            // set the upstream
            var configConstants = createObject( "java", "org.eclipse.jgit.lib.ConfigConstants" );
            var config = local.repo.getRepository().getConfig();
            config.setString( configConstants.CONFIG_BRANCH_SECTION, "master", "remote", "origin" );
            config.setString( configConstants.CONFIG_BRANCH_SECTION, "master", "merge", "refs/heads/master" );
            config.save();

            // Wrap up system out in a PrintWriter and create a progress monitor to track our clone
            var printWriter = createObject( "java", "java.io.PrintWriter" ).init( system.out, true );
            var progressMonitor = createObject( "java", "org.eclipse.jgit.lib.TextProgressMonitor" ).init( printWriter );
            var credentialsProvider = createObject( "java", "org.eclipse.jgit.transport.UsernamePasswordCredentialsProvider" )
            .init( moduleSettings.githubToken, "" );

            var pushCommand = local.repo.push()
                .setRemote( "origin" )
                .add( "master" )
                .setProgressMonitor( progressMonitor )
                .setCredentialsProvider( credentialsProvider );

            CommandCaller.call( pushCommand );

            // Now that the initial push is done, let's set the default URL for the origin remote back to the SSH format
            config.unsetSection("remote", "origin");
            config.save();

            var uri = createObject( "java", "org.eclipse.jgit.transport.URIish" )
                .init( githubRepo.getSshUrl() );
                            
            var remoteAddCommand = local.repo.remoteAdd();
            remoteAddCommand.setName( "origin" )
            remoteAddCommand.setUri( uri );
            CommandCaller.call( remoteAddCommand );
        }
        catch ( any var e ) {
            // If the exception came from the Java call, this exception won't be null
            var theRealJavaException = CommandCaller.getException();
            
            // If it's null, that just means some other CFML code must have blown chunks above.
            if( isNull( theRealJavaException ) ) {
                throw( message="Error Cloning Git repository", detail="#e.message#",  type="ModuleScaffoldException");
            } else {
                var deepMessage = '';
                // Start at the top level and work around way down to the root cause.
                do {
                    deepMessage &= '#theRealJavaException.toString()# #chr( 10 )#';
                    theRealJavaException = theRealJavaException.getCause()
                } while( !isNull( theRealJavaException ) )
                
                throw( message="Error Cloning Git repository", detail="#deepMessage#",  type="ModuleScaffoldException");
            }
        }

        print.line().line()
            .magentaLine( "GitHub set up as origin and module pushed." ).toConsole();

        finishUp();
    }

    function finishUp() {
        print.line();
        print.boldYellowLine( "Module Scaffolded!" );
        print.line();
        print.cyan( "When you're ready to publish to ForgeBox, run " );
        print.boldUnderscoredWhite( "bump --major" );
        print.cyan( " to publish your first 1.0.0!" );
        print.line();
        print.line();
    }
    
}
