class Railtie < ::Rails::Railtie
  rake_tasks do
    load "tasks/brakeman_tasks.rake"
  end
end
