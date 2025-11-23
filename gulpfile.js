/*
 * Copyright (c) 2024 Johannes Fischer <fischer.jh@gmail.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name "RFLIB", the name of the copyright holder, nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

const gulp = require('gulp');
const git = require('gulp-git');
const gutil = require('gulp-util');
const shell = require('gulp-shell');
const prompt = require('gulp-prompt');
const confirm = require('gulp-confirm');

const fs = require('fs');
const _ = require('lodash');
const semver = require('semver');

const customLabelPath = 'rflib/main/default/labels/CustomLabels.labels-meta.xml';

require('time-require');

const config = {
    projectFile: JSON.parse(fs.readFileSync('sfdx-project.json')),
    packageFile: JSON.parse(fs.readFileSync('package.json')),
    alias: process.argv.includes('--alias') ? process.argv[process.argv.indexOf('--alias') + 1] : 'rflib',
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

// Helper function to bump version
function bumpVersion() {
    if (config.package.package === 'RFLIB' && ['major'].includes(config.version.nextVersionType)) {
        config.packageFile.version = config.version.nextVersion;
        fs.writeFileSync('package.json', JSON.stringify(config.packageFile, null, 2));
    }

    if (config.package.package === 'RFLIB') {
        let customLabel = fs.readFileSync(customLabelPath, 'utf8');
        customLabel = customLabel.replace(/(<value>)([\d.]+)(<\/value>)/, `$1${config.version.nextVersion}$3`);
        fs.writeFileSync(customLabelPath, customLabel);
    }

    config.projectFile.packageDirectories[config.packageIndex].versionName = 'ver ' + config.version.nextVersion;
    config.projectFile.packageDirectories[config.packageIndex].versionNumber = config.version.nextVersion + '.NEXT';

    if (config.version.updateDependencies) {
        if (config.package.package === 'RFLIB') {
            config.projectFile.packageDirectories[1].dependencies[0].package =
                config.package.package + '@' + config.version.nextVersion;
            config.projectFile.packageDirectories[2].dependencies[0].package =
                config.package.package + '@' + config.version.nextVersion;
        }

        if (config.package.package === 'RFLIB-FS') {
            config.projectFile.packageDirectories[2].dependencies[1].package =
                config.package.package + '@' + config.version.nextVersion;
        }
    }

    fs.writeFileSync('sfdx-project.json', JSON.stringify(config.projectFile, null, 2));
}

// Add utility function to get actual package IDs
function getLatestPackageVersionIds() {
    const projectConfig = JSON.parse(fs.readFileSync('sfdx-project.json', 'utf8'));
    const aliases = projectConfig.packageAliases;
    
    // Group by package name (strip version)
    const packageGroups = Object.keys(aliases).reduce((acc, alias) => {
        const id = aliases[alias];
        const match = alias.match(/(.*?)@/);
        if (match) {
            const pkgName = match[1];
            if (!acc[pkgName]) acc[pkgName] = [];
            acc[pkgName].push({ alias, id });
        }
        return acc;
    }, {});

    // Get latest version for each package
    return Object.keys(packageGroups).reduce((acc, pkg) => {
        const versions = packageGroups[pkg];
        const latestVersion = versions.sort((a, b) => {
            const vA = a.alias.split('@')[1].split('.');
            const vB = b.alias.split('@')[1].split('.');
            for (let i = 0; i < vA.length; i++) {
                if (parseInt(vA[i], 10) !== parseInt(vB[i], 10)) {
                    return parseInt(vB[i], 10) - parseInt(vA[i], 10);
                }
            }
            return 0;
        })[0];
        acc[pkg] = latestVersion.id;
        return acc;
    }, {});
}

// Confirm deletion of org with proper cancellation
gulp.task('confirm-deleteOrg', function (done) {
    gulp.src('*').pipe(
        prompt.prompt(
            {
                type: 'list',
                name: 'confirmDeletion',
                message: 'Do you want to delete the org?',
                choices: [
                    { name: 'Yes', value: true },
                    { name: 'No', value: false }
                ]
            },
            function (res) {
                if (res.confirmDeletion) {
                    // Run the delete org task when confirmed
                    gulp.series('shell-force-delete-org')(function(err) {
                        if (err) {
                            gutil.log(gutil.colors.red('Error deleting org:'), err);
                        }
                        done(err);
                    });
                } else {
                    gutil.log(gutil.colors.yellow('Org deletion cancelled by user'));
                    done();
                }
            }
        )
    );
});

// Prompt for alias
gulp.task('prompt-alias', function (done) {
    if (process.argv.includes('--alias')) {
        config.alias = process.argv[process.argv.indexOf('--alias') + 1];
        gutil.log(gutil.colors.blue('Alias already selected: ' + config.alias));
        done();
    } else {
        gulp.src('*').pipe(
            prompt.prompt(
                {
                    type: 'input',
                    name: 'alias',
                    message: 'Please provide the scratch org alias',
                    default: config.alias
                },
                function (res) {
                    config.alias = res.alias;
                    done();
                }
            )
        );
    }
});

// Prompt to select package
gulp.task('prompt-selectPackage', function (done) {
    const choices = config.projectFile.packageDirectories.map((pkgDir, index) => ({
        name: pkgDir.package,
        value: index
    }));

    gulp.src('*').pipe(
        prompt.prompt(
            {
                type: 'list',
                name: 'packageIndex',
                message: 'Select package for the current release process',
                choices: choices
            },
            function (res) {
                config.packageIndex = res.packageIndex;

                if (config.packageIndex === null) {
                    gutil.log(gutil.colors.red('Failed to set package details'));
                    process.exit(1);
                }

                config.package = _.cloneDeep(config.projectFile.packageDirectories[config.packageIndex]);

                const packageVersions = Object.keys(config.projectFile.packageAliases).filter(function (value) {
                    return value.startsWith(config.package.package + '@');
                });

                config.package.latestVersionAlias = packageVersions[packageVersions.length - 1];
                config.package.configuredVersionNumber = config.package.versionNumber.replace('.NEXT', '');
                config.package.patch = semver.inc(config.package.configuredVersionNumber, 'patch');
                config.package.minor = semver.inc(config.package.configuredVersionNumber, 'minor');
                config.package.major = semver.inc(config.package.configuredVersionNumber, 'major');
                done();
            }
        )
    );
});

// Prompt to confirm version
gulp.task('prompt-confirmVersion', function (done) {
    if (!config.package.latestVersionAlias) {
        gutil.log(gutil.colors.red('Latest version alias is missing'));
        process.exit(1);
    }

    gulp.src('*').pipe(
        prompt.prompt(
            {
                type: 'list',
                name: 'latestVersionConfirmed',
                message: `Please confirm the current version settings: version number=${config.package.configuredVersionNumber} => version alias=${config.package.latestVersionAlias}`,
                choices: [
                    { name: 'Yes', value: true },
                    { name: 'No', value: false }
                ]
            },
            function (res) {
                if (!res.latestVersionConfirmed) {
                    gutil.log(gutil.colors.red('Version was not confirmed'));
                    process.exit(1);
                }
                done();
            }
        )
    );
});

// Prompt to update dependencies
gulp.task('prompt-updateDependencies', function (done) {
    gulp.src('*').pipe(
        prompt.prompt(
            {
                type: 'list',
                name: 'updateDependencies',
                message: `Should the dependencies for the package ${config.package.package} be updated to version ${config.version.nextVersion} as well?`,
                choices: [
                    { name: 'No', value: false },
                    { name: 'Yes', value: true }
                ]
            },
            function (res) {
                config.version.updateDependencies = res.updateDependencies;
                done();
            }
        )
    );
});

// Prompt for version bump
gulp.task('prompt-bump', function (done) {
    gulp.src('*').pipe(
        prompt.prompt(
            [
                {
                    type: 'list',
                    name: 'nextVersion',
                    message: `Bump version from ${config.package.configuredVersionNumber} to:`,
                    choices: [
                        {
                            value: 'build',
                            name: `Build:  ${config.package.configuredVersionNumber}-? Unstable, betas, and release candidates.`
                        },
                        {
                            value: 'patch',
                            name: `Patch:  ${config.package.patch} Backwards-compatible bug fixes.`
                        },
                        {
                            value: 'minor',
                            name: `Minor:  ${config.package.minor} Add functionality in a backwards-compatible manner.`
                        },
                        {
                            value: 'major',
                            name: `Major:  ${config.package.major} Incompatible API changes.`
                        },
                        {
                            value: 'custom',
                            name: 'Custom: ?.?.? Specify version...'
                        }
                    ]
                },
                {
                    type: 'input',
                    name: 'nextVersionCustom',
                    message: 'What specific version would you like',
                    when: function (answers) {
                        return answers.nextVersion === 'custom';
                    },
                    validate: function (value) {
                        const valid = semver.valid(value);
                        return (
                            !!valid ||
                            'Must be a valid semver, such as 1.2.3-rc1. See http://semver.org/ for more details.'
                        );
                    }
                }
            ],
            function (res) {
                if (['patch', 'minor', 'major'].includes(res.nextVersion)) {
                    config.version.nextVersionType = res.nextVersion;
                    config.version.nextVersion = config.package[res.nextVersion];
                } else if (res.nextVersion === 'build') {
                    config.version.nextVersionType = 'build';
                    config.version.nextVersion = 'build';
                } else if (res.nextVersion === 'custom') {
                    config.version.nextVersionType = 'custom';
                    config.version.nextVersion = res.nextVersionCustom;
                }
                done();
            }
        )
    );
});

// Update dependencies
gulp.task('updateDependencies', function (done) {
    // Refresh the project file
    config.projectFile = JSON.parse(fs.readFileSync('sfdx-project.json'));

    if (!config.version.updateDependencies) {
        gutil.log(gutil.colors.blue('No need to update dependencies'));
        done();
        return;
    }

    const packageVersions = Object.keys(config.projectFile.packageAliases).filter(function (value) {
        return value.startsWith(
            config.package.package + '@' + (config.version.nextVersion === 'build' ? '' : config.version.nextVersion)
        );
    });

    const newPackageAlias = packageVersions[packageVersions.length - 1];

    if (config.package.package === 'RFLIB') {
        config.projectFile.packageDirectories[1].dependencies[0].package = newPackageAlias;
        config.projectFile.packageDirectories[2].dependencies[0].package = newPackageAlias;
    }

    if (config.package.package === 'RFLIB-FS') {
        config.projectFile.packageDirectories[2].dependencies[1].package = newPackageAlias;
    }

    fs.writeFileSync('sfdx-project.json', JSON.stringify(config.projectFile, null, 4));
    done();
});

// Git add version
gulp.task('gitadd-version', function () {
    return gulp.src(['package.json', 'sfdx-project.json', customLabelPath]).pipe(git.add());
});

// Git commit version
gulp.task('gitcommit-version', function () {
    return gulp
        .src(['package.json', 'sfdx-project.json'])
        .pipe(
            git.commit(
                `Created new package for ${config.package.package}: ${config.package.configuredVersionNumber} => ${config.version.nextVersion}`
            )
        );
});

// Git tag version
gulp.task('gittag-version', function (done) {
    git.tag(
        `${config.package.package}_v${config.package.configuredVersionNumber}`,
        `${config.package.package} - Version ${config.package.configuredVersionNumber}`,
        function (err) {
            if (err) throw err;
            done();
        }
    );
});

// Git push to origin
gulp.task('gitpush-origin', function (done) {
    git.push('origin', 'HEAD', { args: '--tags' }, function (err) {
        if (err) throw err;
        done();
    });
});

gulp.task('evaluate-packages-to-install', function (done) {
    if (process.argv.includes('--omni')) {
        gulp.series('shell-force-install-omnistudio')(done);
    } else {
        done();
    }
    if (process.argv.includes('--pharos')) {
        gulp.series(
            'shell-force-install-pharos', 
            'shell-pharos-post-install'
        )(done);
    } else {
        done();
    }
});

gulp.task('create-scratch-org', function (done) {
    const skipCreation = process.argv.includes('--skip-creation');
    const previewMode = process.argv.includes('--preview');
    const omni = process.argv.includes('--omni');

    if (!skipCreation) {
        let createScratchTaskName = omni
            ? 'shell-force-create-org-with-omni-default'
            : 'shell-force-create-org-default';
        if (previewMode) {
            createScratchTaskName += '-preview';
        }

        gulp.series(createScratchTaskName)(done);
    } else {
        done();
    }
});

// Shell tasks
function shellTask(getCommand, ignoreErrors = false) {
    return function (done) {
        return shell.task(getCommand(), {
            ignoreErrors: ignoreErrors
        })(done);
    };
}

// Define shell tasks with variable injection at runtime

gulp.task(
    'shell-force-create-org-default',
    shellTask(function () {
        return `sf org create scratch -f config/project-scratch-def.json -y 30 -a ${config.alias} --name ${config.alias} --set-default`;
    })
);

gulp.task(
    'shell-force-create-org-default-preview',
    shellTask(function () {
        return `sf org create scratch -f config/project-scratch-def.json -y 30 -a ${config.alias} --name ${config.alias} --set-default --release=preview`;
    })
);

gulp.task(
    'shell-force-create-org-with-omni-default',
    shellTask(function () {
        return `sf org create scratch -f config/omni-scratch-def.json -y 30 -a ${config.alias} --name ${config.alias} --set-default`;
    })
);

gulp.task(
    'shell-force-create-org-with-omni-default-preview',
    shellTask(function () {
        return `sf org create scratch -f config/omni-scratch-def.json -y 30 -a ${config.alias} --name ${config.alias} --set-default --release=preview`;
    })
);

gulp.task(
    'shell-force-create-org',
    shellTask(function () {
        return `sf org create scratch -f config/project-scratch-def.json -y 30 -a ${config.alias} --name ${config.alias}`;
    })
);

gulp.task(
    'shell-force-create-org-preview',
    shellTask(function () {
        return `sf org create scratch -f config/project-scratch-def.json -y 30 -a ${config.alias} --name ${config.alias} --release=preview`;
    })
);

gulp.task(
    'shell-force-delete-org',
    shellTask(function () {
        return `sf org delete scratch -o ${config.alias} -p`;
    })
);

gulp.task(
    'shell-force-assign-permset',
    shellTask(function () {
        return `sf org assign permset --name rflib_Ops_Center_Access --target-org ${config.alias} && sf org assign permset --name rflib_Create_Application_Event --target-org ${config.alias}`;
    }, true)
);

gulp.task(
    'shell-force-push',
    shellTask(function () {
        return `sf project deploy start -o ${config.alias} -c`;
    })
);

gulp.task(
    'shell-force-test',
    shellTask(function () {
        return `sf apex run test -l RunLocalTests -c -r human -o ${config.alias} -w 4 --concise`;
    })
);

gulp.task(
    'shell-force-open',
    shellTask(function () {
        return `sf org open -o ${config.alias}`;
    })
);

gulp.task(
    'shell-force-set-debug-mode',
    shellTask(function () {
        return `sf texei user update -o ${config.alias} --values "UserPreferencesUserDebugModePref=true"`;
    })
);

gulp.task(
    'shell-force-create-release-candidate',
    shellTask(function () {
        return `sf package version create --path ${config.package.path} --installation-key-bypass --code-coverage --wait 30`;
    })
);

gulp.task(
    'shell-force-install-latest',
    shellTask(function () {
        return `sf package install --package ${config.package.latestVersionAlias} -o ${config.alias} -w 10`;
    })
);

gulp.task(
    'shell-force-install-streaming-monitor',
    shellTask(function () {
        return `sf package install --package 04tJ5000000gQFxIAM -o ${config.alias} -w 10 && sf org assign permset --name Streaming_Monitor -o ${config.alias}`;
    }, true)
);

gulp.task(
    'shell-force-install-bigobject-utility',
    shellTask(function () {
        return `sf package install --package 04tGA000005dJQCYA2 -o ${config.alias} -w 10`;
    })
);

gulp.task(
    'shell-force-install-pharos',
    shellTask(function () {
        return `sf package install --package 04tKW000000keZf -o ${config.alias} -w 10`;
    })
);

gulp.task(
    'shell-force-install-pharos-triton',
    shellTask(function () {
        return `sf package install --package 04tbm0000005QbN -o ${config.alias} -w 10`;
    })
);

gulp.task(
    'shell-force-install-omnistudio',
    shellTask(function () {
        return `sf package install --package 04t4W000000YWaz -o ${config.alias} -w 10 --no-prompt && sf org assign permsetlicense --name FinServ_FinancialServicesCloudStandardPsl --name BRERuntime --name OmniStudioRuntime -o ${config.alias} && sf org assign permset --name OmniStudioUser --name BRERuntime -o ${config.alias}`;
    }, true)
);

gulp.task(
    'shell-force-promote',
    shellTask(function () {
        return `sf package version promote --package ${config.package.latestVersionAlias} --no-prompt`;
    })
);

gulp.task(
    'shell-force-install-dependencies',
    shellTask(function () {
        return `sf texei package dependencies install --target-org ${config.alias} --packages ${config.package.package}`;
    })
);

gulp.task(
    'shell-force-create-qa-user',
    shellTask(function () {
        return `sf org create user -o ${config.alias} --set-alias qa_user --definition-file config/qa-user-def.json`;
    })
);

gulp.task(
    'shell-force-configure-settings',
    shellTask(function () {
        return `sf apex run -o ${config.alias} -f scripts/apex/ConfigureCustomSettings.apex`;
    })
);

gulp.task(
    'shell-force-create-log-event',
    shellTask(function () {
        return `sf apex run -o ${config.alias} -f scripts/apex/CreateLogEvent.apex`;
    })
);

gulp.task(
    'shell-force-create-application-event',
    shellTask(function () {
        return `sf apex run -o ${config.alias} -f scripts/apex/CreateApplicationEvent.apex`;
    })
);

gulp.task(
    'shell-pharos-post-install',
    shellTask(function () {
        return `sf apex run -o ${config.alias} -f scripts/apex/RunPharosPostInstallHandler.apex`;
    })
);

gulp.task(
    'shell-test-lwc',
    shellTask(function () {
        return 'npm run test:unit:coverage';
    })
);

gulp.task(
    'shell-lint',
    shellTask(function () {
        return 'npm run lint';
    })
);

gulp.task('shell-force-test-package-install-and-upgrade',
    shellTask(function () {
        const skipBaseInstall = process.argv.includes('--skip-base-install');
        const basePackages = [
            `sf package install --package 04t3h000004RdLTAA0 -o ${config.alias} -w 10 &&` + //RFLIB@2.6.0-1
            `sf package install --package 04t3h000004jpyMAAQ -o ${config.alias} -w 10 &&` + //RFLIB-FS@1.0.2-1
            `sf package install --package 04t3h000004jnfBAAQ -o ${config.alias} -w 10` //RFLIB-TF@1.0.1
        ];

        const upgradeCommands = [
            `sf apex run -o ${config.alias} -f scripts/apex/CreateLogEvent.apex &&` +
            `sf texei package dependencies install -u ${config.alias} --packages ${config.package.package} &&` +
            `sf package install --package ${config.package.latestVersionAlias} -o ${config.alias} -w 10`
        ];

        return skipBaseInstall ? upgradeCommands.join(' && ') : [...basePackages, ...upgradeCommands].join(' && ');
    })
);

// Bump version and package
gulp.task(
    'bumpVersionAndPackage',
    gulp.series(
        'shell-lint',
        'shell-test-lwc',
        'shell-force-push',
        'shell-force-test',
        function (done) {
            if (config.version.nextVersion !== 'build') {
                bumpVersion();
            }
            done();
        },
        'shell-force-create-release-candidate',
        'updateDependencies',
        'gitadd-version',
        'gitcommit-version'
    )
);

// Now, define all public tasks matching your Gruntfile

// Create scratch org task
gulp.task(
    'create-scratch',
    gulp.series(
        'prompt-alias',
        'create-scratch-org',
        'shell-force-set-debug-mode',
        'shell-force-push',
        'shell-force-assign-permset',
        'shell-force-configure-settings',
        'shell-force-create-log-event',
        'shell-force-create-application-event',
        'shell-force-create-qa-user',
        'shell-force-install-streaming-monitor',
        'shell-force-install-bigobject-utility',
        'evaluate-packages-to-install',
        'shell-force-open',
        'shell-force-test',
        'shell-test-lwc'
    )
);

// Create package scratch org and install all packages
gulp.task(
    'create-package-scratch',
    gulp.series(
        'prompt-alias',
        'prompt-selectPackage',
        'prompt-confirmVersion',
        'create-scratch-org',
        'shell-force-install-dependencies',
        'shell-force-install-latest',
        'shell-force-install-streaming-monitor',
        'shell-force-install-bigobject-utility',
        'evaluate-packages-to-install',
        'shell-force-assign-permset',
        'shell-force-configure-settings',
        'shell-force-create-log-event',
        'shell-force-create-application-event',
        'shell-force-create-qa-user',
        'shell-force-open'
    )
);

// Test package upgrade
gulp.task('test-package-upgrade',
    gulp.series(
        'prompt-alias',
        'prompt-selectPackage',
        'prompt-confirmVersion',
        'create-scratch-org',
        'evaluate-packages-to-install',
        'shell-force-test-package-install-and-upgrade',
        'shell-force-configure-settings',
        'shell-force-create-log-event',
        function createApplicationEvent(done) {
            if (config.package.package === 'RFLIB') {
                gulp.series('shell-force-create-application-event')(done);
            } else {
                done();
            }
        },
        function createQAUser(done) {
            if (!process.argv.includes('--skip-base-install')) {
                gulp.series('shell-force-create-qa-user')(done);
            } else {
                done();
            }
        },
        'shell-force-open',
        'shell-force-test',
        'confirm-deleteOrg'
    )
);

// Update existing test-install-all-packages task
gulp.task(
    'test-install-all-packages',
    gulp.series(
        'prompt-alias',
        'create-scratch-org',
        shellTask(function() {
            const packages = getLatestPackageVersionIds();
            const commands = Object.keys(packages)
                .map(pkg => 
                    `sf package install --package ${packages[pkg]} -o ${config.alias} -w 10`
                )
                .join(' && ');
            
            return commands;
        }),
        'shell-force-configure-settings',
        'shell-force-create-log-event',
        'shell-force-create-application-event',
        'shell-force-open'
    )
);

// Create package task
gulp.task(
    'create-package',
    gulp.series(
        'prompt-alias',
        'prompt-selectPackage',
        'prompt-bump',
        'prompt-updateDependencies',
        'bumpVersionAndPackage'
    )
);

// Release task
gulp.task(
    'release',
    gulp.series(
        'prompt-alias',
        'prompt-selectPackage',
        'prompt-confirmVersion',
        'create-scratch-org',
        'shell-force-install-dependencies',
        'shell-force-install-latest',
        'shell-force-test',
        'shell-test-lwc',
        'shell-force-promote',
        'shell-force-delete-org',
        'gittag-version',
        'gitpush-origin'
    )
);

// Test task
gulp.task(
    'test',
    gulp.series(
        'prompt-alias',
        function runTests(done) {
            if (!process.argv.includes('--lwc-only')) {
                gulp.series('shell-force-push', 'shell-force-test')(done);
            } else {
                done();
            }
        },
        'shell-lint',
        'shell-test-lwc'
    )
);

// Create event task
gulp.task('create-event', gulp.series('prompt-alias', 'shell-force-create-log-event'));

// Default task
gulp.task('default', gulp.series('shell-lint', 'shell-test-lwc'));
