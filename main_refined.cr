require "option_parser"
require "yaml"

CMD = "sh"

OptionParser.parse do |parser|
  parser.on "-v", "--version", "Show version" do
    puts "version 2.0"
    exit
  end

  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end

  parser.on "-i", "--init", "Initialize" do
    puts "This comand will ask you for a installation manager, and will create a config file in .config/yelts/config.yml"
    puts "This file will also contain list of packages to install"

    puts "Write installation manager (e.g. pacman, apt, dnf, yay, brew, etc.)"
    package_manager = gets

    args = [] of String
    args << "-c" << "mkdir -p .config/yelts"

    Process.run(CMD, args, shell: true)

    args = [] of String
    args << "-c" << "touch .config/yelts/config.yml"

    result = Process.run(CMD, args, shell: true)

    File.open(".config/yelts/config.yml", "w") { |f| YAML.dump({package_manager: package_manager, packages: [] of String}, f) }
    exit
  end

  parser.on "-a", "--add", "Add package to install" do
    puts "Write package name"
    package = gets

    config = YAML.parse(File.read(".config/yelts/config.yml"))

    packages = config["packages"].as_a
    packages << YAML::Any.new(package)

    File.open(".config/yelts/config.yml", "w") { |f| YAML.dump(config, f) }
    exit
  end

  parser.on "-r", "--restore", "Restore packages from config file" do
    config = YAML.parse(File.read(".config/yelts/config.yml"))

    package_manager = config["package_manager"].as_s
    packages = config["packages"].as_a

    args = [] of String
    args << "-c" << "#{package_manager} install #{packages.join(" ")}"

    Process.run(CMD, args, shell: true)
    exit
  end
end
