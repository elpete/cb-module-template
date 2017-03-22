/**
* Create a new standalone ColdBox module.
* Comes complete with testing facilities and ready to publish to ForgeBox.
* This command will create a new directory in the current directory.
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
    property name="system" inject="system@constants";

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
        boolean createGitRepo = true,
        boolean createGitHubRepo = true,
        string gitUsername,
        string location,
        string author,
        string email
    ) {
        arguments.author = arguments.author ?: moduleSettings.author;
        arguments.email = arguments.email ?: moduleSettings.email;
        arguments.gitUsername = arguments.gitUsername ?: moduleSettings.gitUsername;

        if ( ! len( gitUsername ) && isNull( location ) ) {
            return error( "No Git username set.<br/>One of three things needs to happen:<br/><br/>1. A global Git username needs to be set<br/>config set modules.cb-module-template.gitUsername= <br/><br/>2. A `gitUsername` parameter needs to be passed in.<br/><br/>3. A `location` parameter needs to be passed in." );
        }

        arguments.location = arguments.location ?: "#gitUsername#/#moduleName#";

        arguments.directory = fileSystemUtil.resolvePath( arguments.directory );
        if ( ! directoryExists( arguments.directory ) ) {
            directoryCreate( arguments.directory );
        }

        var readme = fileRead( templatePath & "README.md.stub" );
        readme = replaceNoCase( readme, "@@moduleName@@", arguments.moduleName, "all" );
        readme = replaceNoCase( readme, "@@gitUsername@@", arguments.gitUsername, "all" );
        readme = replaceNoCase( readme, "@@author@@", arguments.author, "all" );
        readme = replaceNoCase( readme, "@@description@@", arguments.description, "all" );
        readme = replaceNoCase( readme, "@@location@@", arguments.location, "all" );

        var boxJSON = fileRead( templatePath & "box.json.stub" );
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
        fileDelete( arguments.directory & "/ModuleConfig.cfc.stub" );
        fileDelete( arguments.directory & "/tests/resources/ModuleIntegrationSpec.cfc.stub" );
        fileDelete( arguments.directory & "/tests/specs/integration/SampleIntegrationSpec.cfc.stub" );

        // write templated files
        fileWrite( arguments.directory & "/README.md", readme );
        fileWrite( arguments.directory & "/box.json", boxJSON );
        fileWrite( arguments.directory & "/ModuleConfig.cfc", moduleConfig );
        fileWrite( arguments.directory & "/tests/resources/ModuleIntegrationSpec.cfc", moduleIntegrationSpec );
        fileWrite( arguments.directory & "/tests/specs/integration/SampleIntegrationSpec.cfc", sampleIntegrationSpec );

        command( "install" ).run();

        if ( ! createGitRepo ) {
            finishUp();
            return;
        }

        print.line().boldBlueLine( "Setting up your Git repo...." ).toConsole();

        // This will trap the full java exceptions to work around this annoying behavior:
        // https://luceeserver.atlassian.net/browse/LDEV-454
        var CommandCaller = createObject( 'java', 'com.ortussolutions.commandbox.jgit.CommandCaller' ).init();
        var Git = createObject( 'java', 'org.eclipse.jgit.api.Git' );

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
            return error( "No GitHub Token provided.  Create one at https://github.com/settings/tokens/new.<br />Then set it by runnning the command:<br /><br />config set modules.cb-module-template.githubToken=" );
        }

        cfhttp( url="https://api.github.com/user/repos", method="post", result="githubRequest", throwonerror="true" ) {
            cfhttpparam( type="header", name="Content-Type", value="application/json" );
            cfhttpparam( type="header", name="Authorization", value="token #moduleSettings.githubToken#" );
            cfhttpparam( type="body", value="#serializeJSON( {
                "name" = moduleName,
                "description" = description,
                "homepage" = ""
            } )#" );
        }

        print.magentaLine( "Repo created on Github." ).line().toConsole();

        var response = deserializeJSON( githubRequest.filecontent );

        try {
            var uri = createObject( "java", "org.eclipse.jgit.transport.URIish" ).init( response.ssh_url );
            var remoteAddCommand = local.repo.remoteAdd();
            remoteAddCommand.setName( "origin" )
            remoteAddCommand.setUri( uri );
            CommandCaller.call( remoteAddCommand );

            // set the upstream
            var configConstants = createObject( "java", "org.eclipse.jgit.lib.ConfigConstants" );
            var config = local.repo.getRepository().getConfig();
            config.setString( configConstants.CONFIG_BRANCH_SECTION, "master", "remote", "origin" );
            config.setString( configConstants.CONFIG_BRANCH_SECTION, "local-branch", "merge", "refs/heads/master" );
            config.save();

            // Wrap up system out in a PrintWriter and create a progress monitor to track our clone
            var printWriter = createObject( 'java', 'java.io.PrintWriter' ).init( system.out, true );
            var progressMonitor = createObject( 'java', 'org.eclipse.jgit.lib.TextProgressMonitor' ).init( printWriter );
            var pushCommand = local.repo.push()
                .setRemote( "origin" )
                .add( "master" )
                .setProgressMonitor( progressMonitor );
            CommandCaller.call( pushCommand );
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