import lwcPlugin from "@lwc/eslint-plugin-lwc";
import salesforceAuraPlugin from "@salesforce/eslint-plugin-aura";

export default [
    {
        ignores: [
            "**/lwc/**/*.css",
            "**/lwc/**/*.html",
            "**/lwc/**/*.json",
            "**/lwc/**/*.svg",
            "**/lwc/**/*.xml",
            ".sfdx"
        ],
        languageOptions: {
            ecmaVersion: 2021,
            sourceType: "module",
            globals: {
                Atomics: "readonly",
                SharedArrayBuffer: "readonly"
            }
        },
        linterOptions: {
            reportUnusedDisableDirectives: true
        },
        plugins: {
            "@lwc": lwcPlugin,
            "@salesforce/aura": salesforceAuraPlugin
        },
        rules: {
            strict: "off",
            "no-unused-expressions": "off",
            "vars-on-top": "off"
        },
        settings: {
            extends: [
                "plugin:@salesforce/eslint-config-lwc/recommended",
                "plugin:@salesforce/eslint-plugin-aura/recommended",
                "plugin:@salesforce/eslint-plugin-aura/locker"
            ]
        }
    }
];
