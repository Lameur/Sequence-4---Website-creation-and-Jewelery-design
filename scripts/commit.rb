#!/usr/bin/env ruby

# This script is used to write a conventional commit message.
# It prompts the user to choose the type of commit as specified in the
# conventional commit spec. And then prompts for the summary and detailed
# description of the message and uses the values provided as the summary and
# details of the message.

require 'shellwords'  # Pour échapper les chaînes correctement

# Appels directs à gum
def run_gum(cmd)
  `gum #{cmd}`.chomp
end

# Fonction pour gérer le staging des modifications
def stage_changes
  # Vérifie s'il y a des changements non staged
  unstaged = `git status -s -uno`.lines.map(&:chomp)
  return if unstaged.empty?  # Rien à faire s'il n'y a pas de changements

  # Propose des options pour le staging
  options = ["Tout ajouter (git add .)", "Sélectionner des fichiers"]
  choice = run_gum("choose \"#{options.join('" "')}\" --header \"Modifications à mettre en staging :\"")

  if choice == options[0]  # "Tout ajouter"
    system("git add .")
  elsif choice == options[1]  # "Sélectionner des fichiers"
    files = unstaged.map { |line| line.split[1] }  # Extrait les noms de fichiers
    selected = run_gum("choose --no-limit \"#{files.join('" "')}\" --header \"Sélectionnez les fichiers :\"").split
    system("git add #{selected.map { |f| Shellwords.shellescape(f) }.join(' ')}") unless selected.empty?
  end
end

# Logique principale
stage_changes  # Appelle la fonction pour gérer le staging

types = %w[fix feat docs style refactor test chore revert].join(" ")
type = run_gum("choose #{types}")
scope = run_gum('input --placeholder "scope"')

scope = "(#{scope})" unless scope.empty?

summary = run_gum("input --value \"#{type}#{scope}: \" --placeholder \"Summary of this change\"")
description = run_gum('write --placeholder "Details of this change"')

# Validation et commit
if system("gum confirm \"Commit changes?\"")
  system("git commit -m #{Shellwords.shellescape(summary)} -m #{Shellwords.shellescape(description)}")
end
