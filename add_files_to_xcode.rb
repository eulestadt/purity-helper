require 'xcodeproj'

project_path = 'PurityHelp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'PurityHelp' }

files_to_add = [
  'PurityHelp/Models/JournalEntry.swift',
  'PurityHelp/Models/IfThenPlan.swift',
  'PurityHelp/Services/VigilService.swift',
  'PurityHelp/Services/BibleAPIService.swift',
  'PurityHelp/Views/Vigil/ThresholdView.swift',
  'PurityHelp/Views/Vigil/LogismoiSelectorView.swift',
  'PurityHelp/Views/Vigil/AntirrhetikosView.swift',
  'PurityHelp/Views/Vigil/ReleaseView.swift',
  'PurityHelp/Views/Vigil/VigilContainerView.swift',
  'PurityHelp/Views/Vigil/LitanyView.swift',
  'PurityHelp/Views/Vigil/AudioSanctuaryView.swift',
  'PurityHelp/Views/Vigil/VigilExtendedTabView.swift',
  'PurityHelp/Views/Memorization/AddVerseSearchSheet.swift'
]

# Find the Resources group for the json file
resources_group = project.main_group.find_subpath(File.join('PurityHelp', 'Resources', 'Prayers'), true)
resources_group.set_source_tree('<group>')
resources_group.set_path('Prayers')
json_file = 'PurityHelp/Resources/Prayers/liturgies.json'

files_to_add.each do |file_path|
  # We just add it directly to the root group if it's missing, or the easiest way is to find the right group
  dir_path = File.dirname(file_path)
  group = project.main_group.find_subpath(dir_path, true)
  group.set_source_tree('<group>')
  
  # check if ref exists
  file_ref = group.files.find { |f| f.path == File.basename(file_path) }
  unless file_ref
    file_ref = group.new_file(File.basename(file_path))
    target.add_file_references([file_ref])
    puts "Added #{file_path}"
  else
    puts "Already exists #{file_path}"
  end
end

json_ref = resources_group.files.find { |f| f.path == File.basename(json_file) }
unless json_ref
   json_ref = resources_group.new_file(File.basename(json_file))
   target.resources_build_phase.add_file_reference(json_ref)
   puts "Added resource #{json_file}"
end

project.save
