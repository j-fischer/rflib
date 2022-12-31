const _ = require('lodash');
const semver = require('semver');

const bumpVersion = function(grunt, config) {
    if (config.package.package === "RFLIB" && _.includes(['major'], config.version.nextVersionType)) {
        config.packageFile.version = config.version.nextVersion;
        grunt.file.write('package.json', JSON.stringify(config.packageFile, null, 4));
    }
    
    config.projectFile.packageDirectories[config.packageIndex].versionName = 'ver ' + config.version.nextVersion;
    config.projectFile.packageDirectories[config.packageIndex].versionNumber = config.version.nextVersion + '.NEXT';

    if (config.version.updateDependencies) {
        if (config.package.package === "RFLIB") {
            config.projectFile.packageDirectories[1].dependencies[0].package = config.package.package + '@' + config.version.nextVersion;
            config.projectFile.packageDirectories[2].dependencies[0].package = config.package.package + '@' + config.version.nextVersion;
        }

        if (config.package.package === "RFLIB-FS") {
            config.projectFile.packageDirectories[2].dependencies[1].package = config.package.package + '@' + config.version.nextVersion;
        }
    }
    
    grunt.file.write('sfdx-project.json', JSON.stringify(config.projectFile, null, 4));
}

module.exports = function(grunt) {
    // show elapsed time at the end
    require('time-grunt')(grunt);

    // load all grunt tasks needed for this run
    require('jit-grunt')(grunt);
    grunt.loadNpmTasks('grunt-git');
    
    // build configuration
    var config = {
        projectFile: grunt.file.readJSON('sfdx-project.json'),
        packageFile: grunt.file.readJSON('package.json'),

        alias: grunt.option('alias') || 'rflib',
        
        packageIndex: null,
        package: {},

        version: {
            nextVersion: null,
            updateDependencies: false
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

        rename: {
            bigObjectIndexForPackaging: {
              files: [
                    {src: ['rflib/main/default/objects/rflib_Logs_Archive__b/indexes/rflib_Log_Index.index-meta.xml'], dest: 'rflib/main/default/objects/rflib_Logs_Archive__b/indexes/rflib_Log_Index.indexe-meta.xml'},
                ]
            },
            bigObjectIndexForDeployment: {
                files: [
                    {src: ['rflib/main/default/objects/rflib_Logs_Archive__b/indexes/rflib_Log_Index.indexe-meta.xml'], dest: 'rflib/main/default/objects/rflib_Logs_Archive__b/indexes/rflib_Log_Index.index-meta.xml'},
                ]
            }
        },

        confirm: {
            deleteOrg: {
                options: {
                    question: 'Ready to delete org. Press "y" to continue or any other key to cancel...',
                    input: '_key:y'
                }
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
                                    grunt.log.writeln('Alias already selected: ' + grunt.option('alias'));
                                }

                                return shouldAskForAlias;
                            }
                        }
                    ]
                }
            },

            selectPackage: {
                options: {
                    questions: [
                        {
                            config: 'config.packageIndex',
                            type: 'list',
                            message: 'Select package for the current release process',
                            choices: [
                                {
                                    value: 0,
                                    name: config.projectFile.packageDirectories[0].package
                                },
                                {
                                    value: 1,
                                    name: config.projectFile.packageDirectories[1].package
                                },
                                {
                                    value: 2,
                                    name: config.projectFile.packageDirectories[2].package
                                }
                            ]
                        }
                    ],
                    then: function() {
                        if (!config.package) {
                            grunt.fail.fatal('Failed to set package details');
                        }
                        
                        config.package = _.cloneDeep(config.projectFile.packageDirectories[config.packageIndex]);

                        var packageVersions = _.keys(config.projectFile.packageAliases).filter(function (value) {
                            return value.startsWith(config.package.package + '@');
                        });
                        
                        config.package.latestVersionAlias = packageVersions[packageVersions.length - 1];
                        config.package.configuredVersionNumber = config.package.versionNumber.replace('.NEXT', '');
                        config.package.patch = semver.inc(config.package.configuredVersionNumber, 'patch');
                        config.package.minor = semver.inc(config.package.configuredVersionNumber, 'minor');
                        config.package.major = semver.inc(config.package.configuredVersionNumber, 'major');
                    }
                }
            },

            confirmVersion: {
                options: {
                    questions: [
                        {
                            config: 'config.package.latestVersionConfirmed',
                            type: 'list',
                            message:
                                'Please confirm the current version settings: version number=<%= config.package.configuredVersionNumber %> => version alias=<%= config.package.latestVersionAlias %>',
                            choices: [
                                { name: 'Yes', value: true },
                                { name: 'No', value: false }
                            ]
                        }
                    ],
                    then: function() {
                        if (!config.package.latestVersionAlias) {
                            grunt.fail.fatal('Latest version alias is missing');
                        }
                        if (!config.package.latestVersionConfirmed) {
                            grunt.fail.fatal('Version was not confirmed');
                        }
                    }
                }
            },

            updateDependencies: {
                options: {
                    questions: [
                        {
                            config: 'config.version.updateDependencies',
                            type: 'list',
                            message:
                                'Should the dependencies for the package <%= config.package.package %> be updated to version <%= config.version.nextVersion %> as well?',
                            choices: [
                                { name: 'No', value: false },
                                { name: 'Yes', value: true }
                            ]
                        }
                    ]
                }
            },

            bump: {
                options: {
                    questions: [
                        {
                            config: 'config.version.nextVersion',
                            type: 'list',
                            message: 'Bump version from <%= config.package.configuredVersionNumber %> to:',
                            choices: [
                                {
                                    value: 'build',
                                    name:
                                        'Build:  <%= config.package.configuredVersionNumber %>-? Unstable, betas, and release candidates.'
                                },
                                {
                                    value: 'patch',
                                    name:
                                        'Patch:  <%= config.package.patch %> Backwards-compatible bug fixes.'
                                },
                                {
                                    value: 'minor',
                                    name:
                                        'Minor:  <%= config.package.minor %> Add functionality in a backwards-compatible manner.'
                                },
                                {
                                    value: 'major',
                                    name:
                                        'Major:  <%= config.package.major %> Incompatible API changes.'
                                },
                                {
                                    value: 'custom',
                                    name: 'Custom: ?.?.? Specify version...'
                                }
                            ]
                        },
                        {
                            config: 'config.version.nextVersion',
                            type: 'input',
                            message: 'What specific version would you like',
                            when: function(answers) {
                                return answers['config.version.nextVersion'] === 'custom';
                            },
                            validate: function(value) {
                                var valid = semver.valid(value);
                                return (
                                    !!valid ||
                                    'Must be a valid semver, such as 1.2.3-rc1. See http://semver.org/ for more details.'
                                );
                            }
                        }
                    ],
                    then: function(results) {
                        if (_.includes(['patch', 'minor', 'major'], results['config.version.nextVersion'])) {
                            config.version.nextVersionType = results['config.version.nextVersion'];
                            config.version.nextVersion = config.package[results['config.version.nextVersion']];
                        }
                    }
                }
            }
        },

        gitadd: {
            version: {
                files: {
                    src: ['package.json', 'sfdx-project.json']
                }
            }
        },

        gitcommit: {
            version: {
                options: {
                    message: 'Created new package for <%= config.package.package %>: <%= config.package.configuredVersionNumber %> => <%= config.version.nextVersion %>'
                },
                files: {
                    src: ['package.json', 'sfdx-project.json']
                }
            }

        },

        gittag: {
            version: {
                options: {
                    tag: '<%= config.package.package %>_v<%= config.package.configuredVersionNumber %>',
                    message: '<%= config.package.package %> - Version <%= config.package.configuredVersionNumber %>'
                }
            },
        },

        gitpush: {
            origin: {
                options: {
                    tags: true
                }
            }
        },

        shell: {
            'force-create-org-default': {
                command: 'sfdx force:org:create -f config/project-scratch-def.json -d 30 -a <%= config.alias %> -s '
            },

            'force-create-org-default-preview': {
                command: 'sfdx force:org:create -f config/project-scratch-def-preview.json -d 30 -a <%= config.alias %> -s '
            },

            'force-create-org': {
                command: 'sfdx force:org:create -f config/project-scratch-def.json -d 30 -a <%= config.alias %>'
            },

            'force-create-org-preview': {
                command: 'sfdx force:org:create -f config/project-scratch-def-preview.json -d 30 -a <%= config.alias %>'
            },

            'force-delete-org': {
                command: 'sfdx force:org:delete -u <%= config.alias %> -p'
            },

            'force-assign-permset': {
                command: 'sfdx force:user:permset:assign --permsetname rflib_Ops_Center_Access -u <%= config.alias %>'
            },

            'force-push': {
                command: 'sfdx force:source:push -u <%= config.alias %> -f'
            },

            'force-test': {
                command: 'sfdx force:apex:test:run -l RunAllTestsInOrg -c -r human -u <%= config.alias %>'
            },

            'force-open': {
                command: 'sfdx force:org:open -u <%= config.alias %>'
            },

            'force-create-release-candidate': {
                command:
                    'sfdx force:package:beta:version:create --path <%= config.package.path %> --installationkeybypass --codecoverage --wait 30'
            },

            'force-install-latest': {
                command:
                    'sfdx force:package:beta:install --package <%= config.package.latestVersionAlias %> -u <%= config.alias %> -w 10'
            },

            'force-install-streaming-monitor': {
                command:
                    'sfdx force:package:beta:install --package 04t1t000003Po3QAAS -u <%= config.alias %> -w 10 && ' + 
                    'sfdx force:user:permset:assign -n Streaming_Monitor -u <%= config.alias %>'
            },

            'force-install-bigobject-utility': {
                command:
                    'sfdx force:package:beta:install --package 04t7F000003irldQAA -u <%= config.alias %> -w 10'
            },

            'force-promote': {
                command: 'sfdx force:package:beta:version:promote --package <%= config.package.latestVersionAlias %> --noprompt'
            },

            'force-install-dependencies': {
                command: 'sfdx texei:package:dependencies:install -u <%= config.alias %> --packages <%= config.package.package %>'
            },

            'force-create-qa-user': {
                command: 'sfdx force:user:create -u <%= config.alias %> --setalias qa_user --definitionfile config/qa-user-def.json'
            },

            'force-configure-settings': {
                command: 'sfdx force:apex:execute -u <%= config.alias %> -f scripts/apex/ConfigureCustomSettings.apex'
            },

            'force-create-log-event': {
                command: 'sfdx force:apex:execute -u <%= config.alias %> -f scripts/apex/CreateLogEvent.apex'
            },

            'test-lwc': {
                command: 'npm run test:unit:coverage'
            },

            'lint': {
                command: 'npm run lint'
            }, 

            'force-test-package-install-and-upgrade': {
                command: 
                    'sfdx force:package:beta:install --package 04t3h000004RdLTAA0 -u <%= config.alias %> -w 10 &&' + //RFLIB@2.6.0-1
                    'sfdx force:package:beta:install --package 04t3h000004jpyMAAQ -u <%= config.alias %> -w 10 &&' + //RFLIB-FS@1.0.2-1
                    'sfdx force:package:beta:install --package 04t3h000004jnfBAAQ -u <%= config.alias %> -w 10 &&' + //RFLIB-TF@1.0.1
                    'sfdx force:apex:execute -u <%= config.alias %> -f scripts/apex/CreateLogEvent.apex &&' +
                    'sfdx texei:package:dependencies:install -u <%= config.alias %> --packages <%= config.package.package %> &&' +
                    'sfdx force:package:beta:install --package <%= config.package.latestVersionAlias %> -u <%= config.alias %> -w 10'
            },
        }
    });

    grunt.registerTask('__updateDependencies', 'PRIVATE - Update dependencies in sfdx.project.json file if selected', function() {
        // Since SFDX just updated the project file, we need to refresh it.
        config.projectFile = grunt.file.readJSON('sfdx-project.json');

        if (!config.version.updateDependencies) {
            grunt.log.writeln('No need to update dependencies');
            return;
        }
        
        const packageVersions = _.keys(config.projectFile.packageAliases).filter(function (value) {
            return value.startsWith(config.package.package + '@' + (config.version.nextVersion === 'build' ? '' : config.version.nextVersion));
        });
        
        const newPackageAlias = packageVersions[packageVersions.length - 1];
        if (config.package.package === "RFLIB") {
            config.projectFile.packageDirectories[1].dependencies[0].package = newPackageAlias;
            config.projectFile.packageDirectories[2].dependencies[0].package = newPackageAlias;
        }
    
        if (config.package.package === "RFLIB-FS") {
            config.projectFile.packageDirectories[2].dependencies[1].package = newPackageAlias;
        }

        grunt.file.write('sfdx-project.json', JSON.stringify(config.projectFile, null, 4));
    });

    grunt.registerTask('__bumpVersionAndPackage', 'PRIVATE - Bumping version number and creating beta package version', function() {
        var tasks = ['shell:lint', 'shell:test-lwc', 'shell:force-push', 'shell:force-test'];

        if (grunt.config('config.version.nextVersion') !== 'build') {
            bumpVersion(grunt, config);
        }
        
        tasks.push('shell:force-create-release-candidate');
        tasks.push('__updateDependencies');
        tasks.push('gitadd:version');
        tasks.push('gitcommit:version');

        grunt.task.run(tasks);
    });

    /*
     * Public BUILD TARGETS
     */
    grunt.registerTask('create-scratch', 'Setup default scratch org with either the current or a preview version', function() {
        let tasks = [
            'prompt:alias'
        ];

        if (grunt.option('preview')) {
            tasks.push('shell:force-create-org-default-preview');
        } else {
            tasks.push('shell:force-create-org-default');
        }

        grunt.task.run(tasks.concat([
            'shell:force-push',
            'shell:force-configure-settings',
            'shell:force-create-log-event',
            'shell:force-create-qa-user',
            'shell:force-assign-permset',
            'shell:force-install-streaming-monitor',
            'shell:force-install-bigobject-utility',
            'shell:force-open',
            'shell:force-test',
            'shell:test-lwc'
        ]));
    });

    grunt.registerTask('create-package-scratch', 'Setup scratch org and install all packages', function() {
        let tasks = [
            'prompt:alias',
            'prompt:selectPackage',
            'prompt:confirmVersion'
        ];

        if (grunt.option('preview')) {
            tasks.push('shell:force-create-org-preview');
        } else {
            tasks.push('shell:force-create-org');
        }

        grunt.task.run(tasks.concat([
            'shell:force-install-dependencies',
            'shell:force-install-latest',
            'shell:force-install-streaming-monitor',
            'shell:force-configure-settings',
            'shell:force-create-log-event',
            'shell:force-assign-permset',
            'shell:force-open'
        ]));
    });

    grunt.registerTask('test-package-upgrade', 'Install older versions and then upgrade to the latest package', function() {
        var tasks = [
            'prompt:alias',
            'prompt:selectPackage',
            'prompt:confirmVersion',
            'shell:force-create-org',
            'shell:force-test-package-install-and-upgrade',
            'shell:force-configure-settings',
            'shell:force-create-log-event',
            'shell:force-open',
            'shell:force-test',
            'confirm:deleteOrg',
            'shell:force-delete-org'
        ];

        grunt.task.run(tasks);
    });

    grunt.registerTask('create-package', 'Create a new package version', function() {
        grunt.task.run(['prompt:alias', 'prompt:selectPackage', 'prompt:bump', 'prompt:updateDependencies', '__bumpVersionAndPackage']);
    });

    grunt.registerTask('release', 'Promote the last package version to become a full release', function() {
        var tasks = [
            'prompt:alias',
            'prompt:selectPackage',
            'prompt:confirmVersion',
            'shell:force-create-org',
            'shell:force-install-dependencies',
            'shell:force-install-latest',
            'shell:force-test',
            'shell:test-lwc',
            'shell:force-promote',
            'shell:force-delete-org',
            'gittag:version',
            'gitpush:origin',
        ];

        grunt.task.run(tasks);
    });

    grunt.registerTask('test', 'Run server and client tests', function() {
        var tasks = [
            'prompt:alias'
        ];

        if (!grunt.option('lwc-only')) {
            tasks.push('shell:force-push');
            tasks.push('shell:force-test');
        }
        
        tasks.push('shell:lint');
        tasks.push('shell:test-lwc');
 
        grunt.task.run(tasks);
    });

    grunt.registerTask('create-event', 'Create Log Event in org', function() {
        grunt.task.run(['prompt:alias', 'shell:force-create-log-event']);
    });

    grunt.registerTask('default', ['shell:test-lwc']);
};
