module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "@typescript-eslint/recommended",
  ],
  parser: "@typescript-eslint/parser",
  ignorePatterns: [
    "/lib/**/*",
  ],
  rules: {
    "quotes": ["error", "double"],
    "max-len": "off",
    "object-curly-spacing": "off",
    "no-trailing-spaces": "off",
    "padded-blocks": "off",
    "require-jsdoc": "off",
    "comma-dangle": "off",
    "@typescript-eslint/no-explicit-any": "off",
  },
};