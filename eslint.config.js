import js from "@eslint/js"
import stylistic from "@stylistic/eslint-plugin"
import pluginN from "eslint-plugin-n"
import globals from "globals"

export default [
  {
    ignores: [
      "node_modules/**",
      "app/assets/builds/**",
      "vendor/**",
      "tmp/**",
      "log/**",
      "public/**"
    ]
  },
  js.configs.recommended,
  {
    files: ["**/*.js", "**/*.mjs", "**/*.cjs"],
    plugins: {
      "@stylistic": stylistic,
      n: pluginN
    },
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        ...globals.browser,
        ...globals.es2021,
        ...globals.node
      }
    },
    rules: {
      // Standard JS style rules
      "@stylistic/comma-dangle": ["error", "never"],
      "@stylistic/comma-spacing": ["error", { before: false, after: true }],
      "@stylistic/comma-style": ["error", "last"],
      "@stylistic/dot-location": ["error", "property"],
      "@stylistic/indent": [
        "error",
        2,
        {
          SwitchCase: 1,
          VariableDeclarator: 1,
          outerIIFEBody: 1,
          MemberExpression: 1,
          FunctionDeclaration: { parameters: 1, body: 1 },
          FunctionExpression: { parameters: 1, body: 1 },
          CallExpression: { arguments: 1 },
          ArrayExpression: 1,
          ObjectExpression: 1,
          ImportDeclaration: 1,
          flatTernaryExpressions: false,
          ignoreComments: false,
          ignoredNodes: [
            "TemplateLiteral *",
            "JSXElement",
            "JSXElement > *",
            "JSXAttribute",
            "JSXIdentifier",
            "JSXNamespacedName",
            "JSXMemberExpression",
            "JSXSpreadAttribute",
            "JSXExpressionContainer",
            "JSXOpeningElement",
            "JSXClosingElement",
            "JSXFragment",
            "JSXOpeningFragment",
            "JSXClosingFragment",
            "JSXText",
            "JSXEmptyExpression",
            "JSXSpreadChild"
          ],
          offsetTernaryExpressions: true
        }
      ],
      "@stylistic/key-spacing": [
        "error",
        { beforeColon: false, afterColon: true }
      ],
      "@stylistic/keyword-spacing": ["error", { before: true, after: true }],
      "@stylistic/no-mixed-spaces-and-tabs": "error",
      "@stylistic/no-multi-spaces": ["error", { ignoreEOLComments: false }],
      "@stylistic/no-multiple-empty-lines": [
        "error",
        { max: 1, maxBOF: 0, maxEOF: 0 }
      ],
      "@stylistic/no-trailing-spaces": "error",
      "@stylistic/no-whitespace-before-property": "error",
      "@stylistic/object-curly-spacing": ["error", "always"],
      "@stylistic/operator-linebreak": [
        "error",
        "after",
        { overrides: { "?": "before", ":": "before", "|>": "before" } }
      ],
      "@stylistic/quotes": [
        "error",
        "single",
        { avoidEscape: true, allowTemplateLiterals: "always" }
      ],
      "@stylistic/semi": ["error", "never"],
      "@stylistic/semi-spacing": ["error", { before: false, after: true }],
      "@stylistic/space-before-blocks": ["error", "always"],
      "@stylistic/space-before-function-paren": ["error", "always"],
      "@stylistic/space-infix-ops": "error",
      "@stylistic/space-unary-ops": ["error", { words: true, nonwords: false }],
      "@stylistic/spaced-comment": [
        "error",
        "always",
        {
          line: { markers: ["*package", "!", "/", ",", "="] },
          block: {
            balanced: true,
            markers: ["*package", "!", ",", ":", "::", "flow-include"],
            exceptions: ["*"]
          }
        }
      ],

      // Node.js plugin rules (relaxed for browser environment)
      "n/no-deprecated-api": "error",
      "n/no-extraneous-import": "off",
      "n/no-extraneous-require": "off",
      "n/no-missing-import": "off",
      "n/no-missing-require": "off",
      "n/no-unpublished-bin": "off",
      "n/no-unpublished-import": "off",
      "n/no-unpublished-require": "off",
      "n/no-unsupported-features/es-builtins": "off",
      "n/no-unsupported-features/es-syntax": "off",
      "n/no-unsupported-features/node-builtins": "off",
      "n/process-exit-as-throw": "error",
      "n/hashbang": "off",

      // Core ESLint rules (Standard-like)
      "accessor-pairs": "error",
      "array-callback-return": [
        "error",
        { allowImplicit: false, checkForEach: false }
      ],
      camelcase: [
        "error",
        {
          properties: "never",
          ignoreDestructuring: false,
          ignoreImports: false,
          ignoreGlobals: false
        }
      ],
      "constructor-super": "error",
      "default-case-last": "error",
      "dot-notation": ["error", { allowKeywords: true }],
      eqeqeq: ["error", "always", { null: "ignore" }],
      "new-cap": [
        "error",
        { newIsCap: true, capIsNew: false, properties: true }
      ],
      "no-array-constructor": "error",
      "no-async-promise-executor": "error",
      "no-caller": "error",
      "no-class-assign": "error",
      "no-compare-neg-zero": "error",
      "no-cond-assign": "error",
      "no-const-assign": "error",
      "no-constant-condition": ["error", { checkLoops: false }],
      "no-control-regex": "error",
      "no-debugger": "error",
      "no-delete-var": "error",
      "no-dupe-args": "error",
      "no-dupe-class-members": "error",
      "no-dupe-keys": "error",
      "no-duplicate-case": "error",
      "no-useless-backreference": "error",
      "no-empty": ["error", { allowEmptyCatch: true }],
      "no-empty-character-class": "error",
      "no-empty-pattern": "error",
      "no-eval": "error",
      "no-ex-assign": "error",
      "no-extend-native": "error",
      "no-extra-bind": "error",
      "no-extra-boolean-cast": "error",
      "no-fallthrough": "error",
      "no-func-assign": "error",
      "no-global-assign": "error",
      "no-implied-eval": "error",
      "no-import-assign": "error",
      "no-invalid-regexp": "error",
      "no-irregular-whitespace": "error",
      "no-iterator": "error",
      "no-labels": ["error", { allowLoop: false, allowSwitch: false }],
      "no-lone-blocks": "error",
      "no-loss-of-precision": "error",
      "no-misleading-character-class": "error",
      "no-prototype-builtins": "error",
      "no-useless-catch": "error",
      "no-multi-str": "error",
      "no-new": "error",
      "no-new-func": "error",
      "no-new-object": "error",
      "no-new-symbol": "error",
      "no-new-wrappers": "error",
      "no-obj-calls": "error",
      "no-octal": "error",
      "no-octal-escape": "error",
      "no-proto": "error",
      "no-redeclare": ["error", { builtinGlobals: false }],
      "no-regex-spaces": "error",
      "no-return-assign": ["error", "except-parens"],
      "no-self-assign": ["error", { props: true }],
      "no-self-compare": "error",
      "no-sequences": "error",
      "no-shadow-restricted-names": "error",
      "no-sparse-arrays": "error",
      "no-template-curly-in-string": "error",
      "no-this-before-super": "error",
      "no-throw-literal": "error",
      "no-undef": "error",
      "no-undef-init": "error",
      "no-unexpected-multiline": "error",
      "no-unmodified-loop-condition": "error",
      "no-unneeded-ternary": ["error", { defaultAssignment: false }],
      "no-unreachable": "error",
      "no-unreachable-loop": "error",
      "no-unsafe-finally": "error",
      "no-unsafe-negation": "error",
      "no-unused-expressions": [
        "error",
        {
          allowShortCircuit: true,
          allowTernary: true,
          allowTaggedTemplates: true
        }
      ],
      "no-unused-vars": [
        "error",
        {
          args: "none",
          caughtErrors: "none",
          ignoreRestSiblings: true,
          vars: "all"
        }
      ],
      "no-use-before-define": [
        "error",
        { functions: false, classes: false, variables: false }
      ],
      "no-useless-call": "error",
      "no-useless-computed-key": "error",
      "no-useless-constructor": "error",
      "no-useless-escape": "error",
      "no-useless-rename": "error",
      "no-useless-return": "error",
      "no-void": "error",
      "no-with": "error",
      "object-shorthand": ["error", "properties"],
      "one-var": ["error", { initialized: "never" }],
      "prefer-const": ["error", { destructuring: "all" }],
      "prefer-promise-reject-errors": "error",
      "prefer-regex-literals": ["error", { disallowRedundantWrapping: true }],
      "symbol-description": "error",
      "unicode-bom": ["error", "never"],
      "use-isnan": [
        "error",
        { enforceForSwitchCase: true, enforceForIndexOf: true }
      ],
      "valid-typeof": ["error", { requireStringLiterals: true }],
      yoda: ["error", "never"]
    }
  },
  {
    files: ["**/*.cjs"],
    languageOptions: {
      sourceType: "commonjs"
    }
  }
]
