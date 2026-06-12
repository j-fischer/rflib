const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');
const setupFilesAfterEnv = jestConfig.setupFilesAfterEnv || [];

setupFilesAfterEnv.push('<rootDir>/jest-sa11y-setup.js');
const newConfig = {
    ...jestConfig,
    setupFilesAfterEnv: ['./jest.setup.js'],
    // Playwright E2E specs are run by "npm run test:e2e", not Jest
    testPathIgnorePatterns: [...(jestConfig.testPathIgnorePatterns || []), '<rootDir>/e2e/'],
    moduleNameMapper: {
        '^@salesforce/apex$': '<rootDir>/rflib/test/jest-mocks/apex',
        '^lightning/navigation$': '<rootDir>/rflib/test/jest-mocks/lightning/navigation',
        '^lightning/platformShowToastEvent$': '<rootDir>/rflib/test/jest-mocks/lightning/platformShowToastEvent'
    }
};
newConfig.collectCoverageFrom.push('dist/**/*.js');

module.exports = newConfig;
