const { task } = require('grunt');

module.exports = function(grunt) {
    // load all grunt tasks needed for this run
    require('jit-grunt')(grunt);
    var semver = require('semver');

    // build configuration
    var projectFile = grunt.file.readJSON('sfdx-project.json');
    var config = {
        projectFile: projectFile,

        alias: grunt.option('alias') || 'rflib',
        packageAlias: projectFile.packageDirectories[0].package,

        version: {
            configuredVersionNumber: projectFile.packageDirectories[0].versionNumber.replace('.NEXT', ''),
            latestVersionAlias: Object.keys(projectFile.packageAliases)[
                Object.keys(projectFile.packageAliases).length - 1
            ]
        },

        sfdx: {
            org: {
                create: {
                    parameters: ''
                }
            }
        }
    };

    grunt.initConfig({
        config: config,
        env: process.env,

        bump: {
            options: {
                files: ['package.json', 'sfdx-project.json'],
                updateConfigs: [],
                commit: true,
                commitMessage: 'Created package for version v%VERSION%',
                commitFiles: ['package.json', 'sfdx-project.json'],
                createTag: false,
                tagName: 'v%VERSION%',
                tagMessage: 'Version %VERSION%',
                push: true,
                pushTo: 'origin',
                gitDescribeOptions: '--tags --always --abbrev=1 --dirty=-d',
                globalReplace: true,
                prereleaseName: false,
                regExp: /(['|"]?version[\w]*['|"]?[ ]*:[ ]*['|"]?[\w\s]*)(\d+\.\d+\.\d+(-\.\d+)?(-\d+)?)([\d|A-a|.|-]*['|"]?)/
            }
        },

        semver: {
            options: {
                files: [
                    {
                        src: 'package.json',
                        dest: 'package.json.out'
                    },
                    {
                        src: 'sfdx-project.json',
                        dest: 'sfdx-project.json.out'
                    }
                ]
            }
        },

        prompt: {
            alias: {
                options: {
                    questions: [
                        {
                            config: 'config.alias',
                            type: 'input',
                            message: 'Please provide the scratch org alias',
                            default: config.alias,
                            when: function() {
                                let shouldAskForAlias = !grunt.option('alias');

                                if (!shouldAskForAlias) {
                                    grunt.log.writeln('Alias already selected: <%= config.alias %>');
                                }

                                return shouldAskForAlias;
                            }
                        }
                    ]
                }
            },

            confirmVersion: {
                options: {
                    questions: [
                        {
                            config: 'config.version.latestVersionConfirmed',
                            type: 'list',
                            message:
                                'Please confirm the current version settings: version number=<%= config.version.configuredVersionNumber %> => version alias=<%= config.version.latestVersionAlias %>',
                            default: false,
                            choices: [
                                { name: 'Yes', value: true },
                                { name: 'No', value: false }
                            ]
                        }
                    ],
                    then: function() {
                        if (!config.version.latestVersionConfirmed) {
                            grunt.fail.fatal('Version was not confirmed');
                        }
                    }
                }
            },

            bump: {
                options: {
                    questions: [
                        {
                            config: 'bump.options.versionType',
                            type: 'list',
                            message: 'Bump version from ' + '<%= config.version.configuredVersionNumber %>' + ' to:',
                            choices: [
                                {
                                    value: 'build',
                                    name:
                                        'Build:  ' +
                                        (config.version.configuredVersionNumber + '-?') +
                                        ' Unstable, betas, and release candidates.'
                                },
                                {
                                    value: 'patch',
                                    name:
                                        'Patch:  ' +
                                        semver.inc(config.version.configuredVersionNumber, 'patch') +
                                        ' Backwards-compatible bug fixes.'
                                },
                                {
                                    value: 'minor',
                                    name:
                                        'Minor:  ' +
                                        semver.inc(config.version.configuredVersionNumber, 'minor') +
                                        ' Add functionality in a backwards-compatible manner.'
                                },
                                {
                                    value: 'major',
                                    name:
                                        'Major:  ' +
                                        semver.inc(config.version.configuredVersionNumber, 'major') +
                                        ' Incompatible API changes.'
                                },
                                {
                                    value: 'custom',
                                    name: 'Custom: ?.?.? Specify version...'
                                }
                            ]
                        },
                        {
                            config: 'bump.options.setVersion',
                            type: 'input',
                            message: 'What specific version would you like',
                            when: function(answers) {
                                return answers['bump.options.versionType'] === 'custom';
                            },
                            validate: function(value) {
                                var valid = semver.valid(value);
                                return (
                                    !!valid ||
                                    'Must be a valid semver, such as 1.2.3-rc1. See http://semver.org/ for more details.'
                                );
                            }
                        }
                    ]
                }
            }
        },

        shell: {
            'force-create-org': {
                command: 'sfdx force:org:create -f config/project-scratch-def.json -d 30 -a <%= config.alias %> <%= config.sfdx.org.create.parameters %>'
            },

            'force-delete-org': {
                command: 'sfdx force:org:delete -u <%= config.alias %> -p'
            },

            'force-assign-permset': {
                command: 'sfdx force:user:permset:assign --permsetname rflib_Ops_Center - <%= config.alias %>'
            },

            'force-push': {
                command: 'sfdx force:source:push -u <%= config.alias %>'
            },

            'force-test': {
                command: 'sfdx force:apex:test:run -l RunAllTestsInOrg -c -r human -u <%= config.alias %>'
            },

            'force-open': {
                command: 'sfdx force:org:open -u <%= config.alias %>'
            },

            'force-create-release-candidate': {
                command:
                    'sfdx force:package:version:create --path force-app --package RFLIB --installationkeybypass --releasenotesurl https://github.com/j-fischer/rflib/blob/master/CHANGELOG.md --postinstallurl https://github.com/j-fischer/rflib#how-tos --wait 10'
            },

            'force-install-latest': {
                command:
                    'sfdx force:package:install --package <%= config.version.latestVersionAlias %> -u <%= config.alias %> -w 10'
            },

            'force-promote': {
                command: 'sfdx force:package:version:promote --package <%= config.version.latestVersionAlias %> -w 10'
            }
        }
    });

    grunt.registerTask('bumpVersionAndPackage', 'Bumping version number if needed', function() {
        var tasks = ['shell:force-push', 'shell:force-test'];

        if (grunt.config('bump.options.versionType') !== 'build') {
            tasks.push('bump:bump-only');
        }

        tasks.push('shell:force-create-release-candidate');
        tasks.push('bump:commit-only');

        grunt.task.run(tasks);
    });

    /*
     * BUILD TARGETS
     */
    grunt.registerTask('create-scratch', 'Setup default scratch org', function() {
        grunt.config('config.sfdx.org.create.parameters', '');
        
        grunt.task.run([
            'prompt:alias',
            'shell:force-create-org',
            'shell:force-push',
            'shell:force-assign-permset',
            'shell:force-test',
            'shell:force-open'
        ]);
    });

    grunt.registerTask('create-package', 'Create a new package version', function() {
        grunt.task.run(['prompt:alias', 'prompt:bump', 'bumpVersionAndPackage']);
    });

    grunt.registerTask('release', 'Promote the last package version to become a full release', function() {
        grunt.config('bump.version', config.version.configuredVersionNumber);
        grunt.config('bump.options.commit', false);
        grunt.config('bump.options.createTag', true);
        grunt.config('bump.options.push', 'tag');

        var tasks = [
            'prompt:alias',
            'prompt:confirmVersion',
            'shell:force-create-org',
            'shell:force-install-latest',
            'shell:force-test',
            'shell:force-promote',
            'shell:force-delete-org',
            'bump:commit-only'
        ];

        grunt.task.run(tasks);
    });
};
