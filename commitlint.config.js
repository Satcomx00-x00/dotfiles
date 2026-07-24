// Conventional Commits (decision #22). Used by CI; the local equivalent is the
// conventional-pre-commit hook in .pre-commit-config.yaml.
//
// No changelog generation and no release automation — the convention exists to
// make `git log --oneline` readable, not to drive a pipeline.
module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "header-max-length": [2, "always", 100],
    "body-max-line-length": [1, "always", 100],
    "scope-enum": [
      1,
      "always",
      [
        "shell", "zsh", "bash", "prompt", "theme", "nvim", "zellij",
        "git", "ssh", "mise", "tools", "secrets", "ci", "docs",
        "install", "portable", "test", "claude", "deps",
      ],
    ],
  },
};
