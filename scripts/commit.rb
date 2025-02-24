#!/usr/bin/env ruby

# This script is used to write a conventional commit message.
# It prompts the user to choose the type of commit as specified in the
# conventional commit spec. And then prompts for the summary and detailed
# description of the message and uses the values provided as the summary and
# details of the message.

require 'tty-prompt'

prompt = TTY::Prompt.new

# Check if there are any changes to commit
if `git status -s -uno`.strip.empty?
  if prompt.yes?("Stage all?")
    system("git add .")
  end
end

# Prompt for commit type
type = prompt.select("Choose the type of commit:", ["fix", "feat", "docs", "style", "refactor", "test", "chore", "revert"])

# Prompt for optional scope
scope = prompt.ask("Scope (optional):", default: "")

# Wrap the scope in parentheses if it has a value
scope = "(#{scope})" unless scope.empty?

# Pre-populate the input with the type(scope): so that the user may change it
summary = prompt.ask("Summary of this change:", default: "#{type}#{scope}: ")

# Prompt for detailed description
description = prompt.ask("Details of this change (press Enter to finish):", multiline: true)

# Confirm before committing
if prompt.yes?("Commit changes?")
  # Properly escape the summary and description for the git commit command
  system("git", "commit", "-m", summary, "-m", description)
end