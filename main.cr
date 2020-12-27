require "option_parser"

OptionParser.parse do |parser|
  parser.on "-v", "--version", "Show version" do
    puts "version 1.0"
    exit
  end

  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end

  parser.on "scan", "Scan packages" do
    cmd = "sh"
    args = [] of String
    args << "-c" << "pacman -Qq"
    io = IO::Memory.new
    Process.run(cmd, args, shell: true, output: io)
    puts io.to_s
    exit
  end

  parser.on "restore", "Restore packages from list" do
    cmd = "sh"
    packages = ["cowsay", "ponysay"]
    io = IO::Memory.new
    args = [] of String
    pacman_string = "sudo pacman -S "
    packages.each do |package|
      pacman_string += "#{package} "
    end
    pacman_string += "--noconfirm"
    args << "-c" << pacman_string
    Process.run(cmd, args, shell: true, output: io)
    puts io.to_s
    exit
  end
end
