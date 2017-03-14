/**
* Create a new standalone ColdBox module.
* Comes complete with testing facilities and ready to publish to ForgeBox.
* This command will create a new directory in the current directory.
* When you're ready to publish, run `bump --major` to publish your first 1.0.0!
*/
component {

    property name="moduleSettings" inject="commandbox:moduleSettings:cb-module-template";
    property name="system" inject="system@constants";

    variables.templatePath = "/cb-module-template/template/";

    /**
    * @moduleName Name of the new ColdBox module to scaffold.
    * @description A short description of the module.  Used in the box.json and in the README.
    * @directory Directory to create the module in. Defaults to the current directory
    * @createGitRepo If true, creates a git repo and an initial commit. Default: true.
    * @createGitHubRepo If true, uses the GitHub API to create a new repo named "#moduleName#" for the user.  Requires a GitHub Personal Access Token to be set in the config: `config set modules.cb-module-template.githubToken=PERSONAL_ACCESS_TOKEN`.  Personal Access Tokens can be generated at https://github.com/settings/tokens/new.
    * @gitUsername GitHub (or similar) username where repo will be located.  Can be set globally in the module config: `config set modules.cb-module-template.gitUsername=elpete`
    * @location The location value for the box.json.  If left empty, defaults to "#gitUsername#/#moduleName#".
    * @author The name of the author of the module.  Can be set globally in the module config settings: `config set modules.cb-module-template.author="Eric Peterson"`
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

        arguments.directory = fileSystemUtil.resolvePath( arguments.directory ) & "/#arguments.moduleName#";
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

        command( "cd #moduleName#" ).run();
        command( "install" ).run();

        if ( ! createGitRepo ) {
            finishUp();
            return;
        }

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
            local.repo = initCommand.call()
            // command( "!git init" ).run();

            var addCommand = local.repo.add().addFilePattern( "." );
            CommandCaller.call( addCommand );
            // command( "!git add ." ).run();

            var commitCommand = local.repo.commit()
                .setMessage( "Initial commit" )
                .setAuthor( arguments.author, arguments.email );
            CommandCaller.call( commitCommand );
            // command( '!git commit -m "Initial commit"' ).run();    
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

        if ( ! createGitHubRepo ) {
            finishUp();
            return;
        }
        
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

        var response = deserializeJSON( githubRequest.filecontent );

        try {
            var uri = createObject( "java", "org.eclipse.jgit.transport.URIish" ).init( response.ssh_url );
            var remoteAddCommand = local.repo.remoteAdd();
            remoteAddCommand.setName( "origin" )
            remoteAddCommand.setUri( uri );
            CommandCaller.call( remoteAddCommand );
            // command( "!git remote add origin #response.ssh_url#" ).run();

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
            // command( "!git push -u origin master" ).run();
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