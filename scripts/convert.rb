#!/usr/bin/env/ruby

require 'optparse'
require 'fileutils'
require 'shellwords'

# Vérifie si gum est installé
unless system("gum --version > /dev/null 2>&1")
  abort "Erreur : 'gum' n'est pas installé. Installez-le avec : brew install gum (macOS) ou voir https://github.com/charmbracelet/gum#installation"
end

# Options par défaut
options = {
  directory: Dir.pwd,
  extension: ".txt",
  backup: false,
  verbose: false,
  force: false
}

# Parsing des arguments
opt_parser = OptionParser.new do |opts|
  opts.banner = "Conversion US-ASCII vers UTF-8 avec gum\nUsage: #{File.basename(__FILE__)} [options]"

  opts.on("-d", "--directory DIR", "Dossier à traiter") { |dir| options[:directory] = dir }
  opts.on("-e", "--extension EXT", "Extension des fichiers") { |ext| options[:extension] = ext }
  opts.on("-b", "--backup", "Créer des backups") { options[:backup] = true }
  opts.on("-v", "--verbose", "Mode verbeux") { options[:verbose] = true }
  opts.on("-f", "--force", "Forcer la conversion") { options[:force] = true }
  opts.on("-h", "--help", "Affiche l'aide") do
    puts opts
    exit
  end
end

opt_parser.parse!

# Mode interactif uniquement si aucune option n'est fournie
if ARGV.empty? && options.all? { |k, v| v == false || v == Dir.pwd || v == ".txt" }
  system("gum style --border double --padding \"1 2\" --margin 1 \"Conversion US-ASCII vers UTF-8\"")
  
  options[:directory] = `gum input --prompt "📁 Dossier à traiter (défaut: #{Dir.pwd}): " --placeholder "#{Dir.pwd}"`.chomp
  options[:directory] = Dir.pwd if options[:directory].empty?

  options[:extension] = `gum input --prompt "📝 Extension des fichiers (défaut: .txt): " --placeholder ".txt"`.chomp
  options[:extension] = ".txt" if options[:extension].empty?

  selected_options = `gum choose --no-limit "Backup des fichiers" "Mode verbeux" "Forcer la conversion"`.chomp.split("\n")
  options[:backup] = selected_options.include?("Backup des fichiers")
  options[:verbose] = selected_options.include?("Mode verbeux")
  options[:force] = selected_options.include?("Forcer la conversion")
end

# Vérifie si le dossier existe
unless Dir.exist?(options[:directory])
  system("gum style --foreground 1 \"✖ Erreur: Le dossier '#{options[:directory]}' n'existe pas\"")
  exit 1
end

# Initialisation des compteurs
converted = 0
errors = 0
skipped = 0

# Affiche les paramètres
params = [
  "Dossier: #{options[:directory]}",
  "Extension: #{options[:extension]}",
  "Backup: #{options[:backup] ? 'Oui' : 'Non'}",
  "Verbose: #{options[:verbose] ? 'Oui' : 'Non'}",
  "Force: #{options[:force] ? 'Oui' : 'Non'}"
].map { |s| "\"#{s}\"" }.join(" ")
system("gum spin --title \"Préparation...\" -- sleep 1")
system("gum style --border normal --padding \"0 1\" #{params}")

# Demande de confirmation avec code de retour
if system("gum confirm \"Lancer la conversion ?\"")
  # Continuer
else
  system("gum style --foreground 3 \"Annulation de l'opération\"")
  exit 0
end

# Parcours des fichiers
Dir.glob(File.join(options[:directory], "*#{options[:extension]}")).each do |file|
  if options[:verbose]
    system("gum spin --title \"Traitement de #{File.basename(file)}...\" -- sleep 0.5")
  end
  
  begin
    if options[:verbose]
      current_encoding = File.read(file, 10).encoding
      IO.popen("gum format", "w") { |io| io.puts "➤ #{File.basename(file)} (encodage: #{current_encoding})" }
    end

    # Backup
    if options[:backup]
      FileUtils.cp(file, "#{file}.bak")
      if options[:verbose]
        IO.popen("gum style --foreground 2", "w") { |io| io.puts "✓ Backup créé: #{File.basename(file)}.bak" } # Vert pour succès
      end
    end

    # Lecture et conversion
    content = File.read(file, encoding: "US-ASCII")
    
    if content.encoding == Encoding::UTF_8 && !options[:force]
      IO.popen("gum style --foreground 3", "w") { |io| io.puts "↷ Déjà en UTF-8, sauté" } if options[:verbose] # Jaune pour avertissement
      skipped += 1
      next
    end

    File.open(file, "w:UTF-8") { |f| f.write(content.encode("UTF-8")) }
    IO.popen("gum style --foreground 2", "w") { |io| io.puts "✓ Converti avec succès: #{File.basename(file)}" } # Vert pour succès
    converted += 1
  rescue Encoding::UndefinedConversionError => e
    errors += 1
    if options[:force]
      IO.popen("gum style --foreground 3", "w") { |io| io.puts "⚠ Forcé malgré erreur: #{e.message}" } # Jaune pour avertissement
    else
      IO.popen("gum style --foreground 1", "w") { |io| io.puts "✖ Erreur de conversion: #{e.message}" } # Rouge pour erreur
    end
  rescue StandardError => e
    errors += 1
    IO.popen("gum style --foreground 1", "w") { |io| io.puts "✖ Erreur: #{e.message}" } # Rouge pour erreur
  end
end

# Résumé final
summary_items = [
  "📊 Résultat",
  "✓ Convertis: #{converted}",
  (skipped > 0 ? "↷ Sautés: #{skipped}" : nil),
  (errors > 0 ? "✖ Erreurs: #{errors}" : nil),
  "✅ Conversion terminée !"
].compact.map { |s| "\"#{s}\"" }.join(" ")
system("gum style --border double --padding \"1 2\" --margin 1 #{summary_items}")

# Message final si erreurs
if errors > 0 && !options[:force]
  system("gum style --foreground 4 \"ℹ Utilisez --force pour ignorer les erreurs\"")
end