#!/bin/bash

# Check if a folder was provided as an argument
if [ $# -eq 0 ]
then
    # If no folder was provided, print an error message and exit
    echo "please provide folder location to run ther script as the first argument"
    return
else
    # If a folder was provided, change the current working directory to that folder
    cd $1
fi

echo "adding static testing setup"

############################
# NPM PACKAGES
############################

npx husky-init && npm install prettier lint-staged -D

############################
# HUSKY
############################

npx husky add .husky/pre-commit "npx lint-staged"

mv .husky/pre-commit .husky/pre-commit.bak
sed 's/npm test/npm run validate/g' .husky/pre-commit.bak > .husky/pre-commit
rm .husky/pre-commit.bak

############################
# VALIDATION SCRIPTS
############################

validation_scripts='{ "lint": "eslint src --ext .ts,.tsx", "check-types": "tsc --noEmit", "prettier": "prettier --ignore-path .gitignore \"**/*.+(js|json|ts|tsx)\"", "validate": "npm run lint && npm run check-types && npm test", "format": "npm run prettier -- --write" }'

# Check if the "scripts" key already exists in package.json
if grep -q "scripts" package.json; then
    # If the key already exists, update the existing configuration
    jq ".scripts |= . + $validation_scripts" package.json > package.json.tmp && mv package.json.tmp package.json
else
    # If the key does not exist, add the "scripts" key to the file
    jq ". + { "scripts": $validation_scripts }" package.json > package.json.tmp && mv package.json.tmp package.json
fi

############################
# PRETTIER
############################

echo '{
  "arrowParens": "always",
  "bracketSameLine": false,
  "bracketSpacing": true,
  "embeddedLanguageFormatting": "auto",
  "htmlWhitespaceSensitivity": "css",
  "insertPragma": false,
  "jsxSingleQuote": false,
  "printWidth": 150,
  "proseWrap": "always",
  "quoteProps": "as-needed",
  "requirePragma": false,
  "semi": true,
  "singleQuote": true,
  "tabWidth": 4,
  "trailingComma": "all",
  "useTabs": false,
  "vueIndentScriptAndStyle": false
}' > .prettierrc


############################
# LINT STAGED
############################

lint_staged_config='{ "lint-staged": { "*.{js,jsx,ts,tsx}": "eslint --cache --fix", "*.{js,jsx,ts,tsx,json}": "prettier --write" }'

# Check if the "lint-staged" key already exists in package.json
if grep -q "lint-staged" package.json; then
    # If the key already exists, update the existing configuration
    jq ". + $lint_staged_config }" package.json > package.json.tmp && mv package.json.tmp package.json
else
    # If the key does not exist, add the "lint-staged" key to the file
    jq ". + $lint_staged_config }" package.json > package.json.tmp && mv package.json.tmp package.json
fi

# Check if the "scripts" key already exists in package.json
if grep -q "scripts" package.json; then
    # If the key already exists, update the existing configuration
    jq '.scripts |= . + { "pre-commit": "lint-staged" }' package.json > package.json.tmp && mv package.json.tmp package.json
else
    # If the key does not exist, add the "scripts" key to the file
    jq '. + { "scripts": { "pre-commit": "lint-staged" } }' package.json > package.json.tmp && mv package.json.tmp package.json
fi

