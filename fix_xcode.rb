require 'xcodeproj'
project_path = 'PurityHelp.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

services_group = project.main_group.find_subpath(File.join('PurityHelp', 'Services'), true)

file_path = 'PurityHelp/Services/AutoSyncManager.swift'

# Check if file is already in the project
existing_ref = services_group.files.find { |f| f.path == file_path || f.real_path.to_s.end_with?(file_path) }
unless existing_ref
    # Remove old broken ref if any
    project.main_group.files.each do |f|
        if f.path == 'AutoSyncManager.swift' || f.path == 'PurityHelp/Services/Services/AutoSyncManager.swift'
            f.remove_from_project
        end
    end
    # Create new ref
    file_ref = services_group.new_file(file_path)
    # Add to target
    target.add_file_references([file_ref])
end

project.save
puts "Xcode project updated."
