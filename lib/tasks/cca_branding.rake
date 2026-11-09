namespace :cca do
  namespace :branding do
    desc 'Apply Community branding (name, logos, URLs) to InstallationConfig, overriding existing values'
    task apply: :environment do
      Cca::Branding.apply!
      puts "Community branding applied: #{Cca::Branding::KEYS.join(', ')}"
    end
  end
end
