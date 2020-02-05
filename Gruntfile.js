module.exports = function(grunt) {
    // load all grunt tasks needed for this run
    require('jit-grunt')(grunt);

    // build configuration
    var config = {
        alias: 'rflib'
    };

    grunt.initConfig({
        config: config,
        env: process.env,

        shell: {
            'force-create-org': {
                command: 'sfdx force:org:create -s -f config/project-scratch-def.json -d 30 -a <%= config.alias %>'
            },

            'force-assign-permset': {
                command:
                    'sfdx force:user:permset:assign --permsetname rflib_Log_Monitor_Access --targetusername <%= config.alias %>'
            },

            'force-push': {
                command: 'sfdx force:source:push -u <%= config.alias %>'
            },

            'force-open': {
                command: 'sfdx force:org:open -u <%= config.alias %>'
            }
        }
    });

    /*
     * BUILD TARGETS
     */
    grunt.registerTask('create-scratch', [
        'shell:force-create-org',
        'shell:force-push',
        'shell:force-assign-permset',
        'shell:force-open'
    ]);
};
