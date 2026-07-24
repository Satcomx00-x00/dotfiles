# shellcheck shell=sh
# Non-interactive answers to every prompt in home/.chezmoi.toml.tmpl.
#
# Sourced (never executed) by test/render.sh, test/sandbox.sh, install.sh's
# unattended path and CI. Sourcing this file REPLACES the positional parameters
# with the flag list, so callers use it as:
#
#     ( . test/prompts.sh; chezmoi init --apply "$@" )
#
# ── IMPORTANT ────────────────────────────────────────────────────────────────
# chezmoi's --promptString/--promptChoice/--promptBool flags key on the PROMPT
# TEXT, not on the data key. `--promptString name=...` does nothing; the prompt
# reads "Full name", so the flag must be `--promptString "Full name=..."`.
#
# That makes the prompt wording in .chezmoi.toml.tmpl a machine-facing contract.
# It is kept short and stable for exactly that reason, and test/render.sh fails
# loudly (EOF on a prompt) the moment the two files disagree — so this cannot
# rot silently into a broken unattended install.

set -- \
    --promptString "Full name=CI Tester" \
    --promptString "Email=ci@example.com" \
    --promptString "Editor=nvim" \
    --promptChoice "Machine profile=${DOTFILES_TEST_PROFILE:-server}" \
    --promptChoice "Tool tier=${DOTFILES_TEST_TIER:-standard}" \
    --promptChoice "Secrets backend=none" \
    --promptBool "Enable SSH commit signing=false" \
    --promptString "SSH signing key path="
