if system("gum confirm \"Lancer la conversion ?\"")
  # Continuer
else
  system("gum style --foreground 3 \"Annulation de l'opération\"")
  exit 0
end
