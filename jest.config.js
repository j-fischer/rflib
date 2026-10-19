const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');
const setupFilesAfterEnv = jestConfig.setupFilesAfterEnv || [];

setupFilesAfterEnv.push('<rootDir>/jest-sa11y-setup.js');
const newConfig = {
    ...jestConfig,
    setupFilesAfterEnv: ['./jest.setup.js'],
    // Playwright E2E specs are run by "npm run test:e2e", not Jest. Git worktrees under .claude/ hold
    // other branches' copies of every test, which would otherwise run (and fail) alongside this checkout's.
    testPathIgnorePatterns: [...(jestConfig.testPathIgnorePatterns || []), '<rootDir>/e2e/', '<rootDir>/.claude/'],
    moduleNameMapper: {
        '^@salesforce/apex$': '<rootDir>/rflib/test/jest-mocks/apex',
        '^lightning/navigation$': '<rootDir>/rflib/test/jest-mocks/lightning/navigation',
        '^lightning/platformShowToastEvent$': '<rootDir>/rflib/test/jest-mocks/lightning/platformShowToastEvent'
    }
};
newConfig.collectCoverageFrom.push('dist/**/*.js');

module.exports = newConfig;
