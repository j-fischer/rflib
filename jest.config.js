const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');
const setupFilesAfterEnv = jestConfig.setupFilesAfterEnv || [];
setupFilesAfterEnv.push('<rootDir>/jest-sa11y-setup.js');
module.exports = {
    ...jestConfig,
    setupFilesAfterEnv: ['./jest.setup.js'],
    moduleNameMapper: {
        '^@salesforce/apex$': '<rootDir>/rflib/test/jest-mocks/apex',
        '^lightning/navigation$': '<rootDir>/rflib/test/jest-mocks/lightning/navigation',
        '^lightning/platformShowToastEvent$': '<rootDir>/rflib/test/jest-mocks/lightning/platformShowToastEvent'
    }
};
