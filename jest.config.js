const { jestConfig } = require('@salesforce/lwc-jest/config');
module.exports = {
    ...jestConfig,
    setupFilesAfterEnv: ['./jest.setup.js'],
    moduleNameMapper: {
        '^@salesforce/apex$': '<rootDir>/rflib/test/jest-mocks/apex',
        '^lightning/navigation$': '<rootDir>/rflib/test/jest-mocks/lightning/navigation',
        '^lightning/platformShowToastEvent$': '<rootDir>/rflib/test/jest-mocks/lightning/platformShowToastEvent'
    }
};
