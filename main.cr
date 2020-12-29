require "option_parser"
require "http/client"
require "json"

OptionParser.parse do |parser|
  parser.on "-v", "--version", "Show version" do
    puts "version 1.0"
    exit
  end

  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end

  parser.on "sign_up", "Sign up" do
    puts "Write email"
    print "> "
    email = gets

    puts "Write password"
    print "> "
    password = gets

    response = HTTP::Client.post "https://yelst-backend.herokuapp.com/users/sign_up", headers: nil, form: {email: email, password: password}.to_json

    cmd = "sh"
    args = [] of String
    token = "echo export YELST_TOKEN=" + JSON.parse(response.body)["result"].to_s + " >> ~/.zshrc"
    args << "-c" << token

    puts args

    Process.run(cmd, args, shell: true)
    exit
  end

  parser.on "sign_in", "Sign in" do
    puts "Write email"
    print "> "
    email = gets

    puts "Write password"
    print "> "
    password = gets

    response = HTTP::Client.post "https://yelst-backend.herokuapp.com/users/sign_in", headers: nil, form: {email: email, password: password}.to_json

    cmd = "sh"
    args = [] of String
    token = "echo export YELST_TOKEN=" + JSON.parse(response.body)["result"].to_s + " >> ~/.zshrc"
    args << "-c" << token

    puts args

    Process.run(cmd, args, shell: true)
    exit
  end

  parser.on "scan", "Scan packages" do
    cmd = "sh"

    args = [] of String
    args << "-c" << "pacman -Qq"
    io = IO::Memory.new
    Process.run(cmd, args, shell: true, output: io)
    list = io.to_s.split("\n")

    args = [] of String
    args << "-c" << "cat ~/.zshrc | grep YELST_TOKEN"
    io = IO::Memory.new
    Process.run(cmd, args, shell: true, output: io)
    token = io.to_s.sub("export YELST_TOKEN=", "").sub("\n", "")

    headers =  HTTP::Headers.new.add("Authorization", value: "Bearer #{token}")
    response = HTTP::Client.post "https://yelst-backend.herokuapp.com/packages/set_list", headers: headers, form: {list: list}.to_json

    puts response.status
    exit
  end

  parser.on "restore", "Restore packages from list" do
    cmd = "sh"
    args = [] of String
    args << "-c" << "cat ~/.zshrc | grep YELST_TOKEN"
    io = IO::Memory.new
    Process.run(cmd, args, shell: true, output: io)
    token = io.to_s.sub("export YELST_TOKEN=", "").sub("\n", "")

    headers =  HTTP::Headers.new.add("Authorization", value: "Bearer #{token}")
    response = HTTP::Client.get "https://yelst-backend.herokuapp.com/get_list", headers: headers
    packages = JSON.parse(response.body)["result"].to_s.split(" ")

    io = IO::Memory.new
    args = [] of String
    pacman_string = "yay -S "
    packages = packages.join(" ")
    pacman_string += packages
    pacman_string += " --noconfirm --needed"
    args << "-c" << pacman_string
    Process.run(cmd, args, shell: true, output: io)
    puts io.to_s
    exit
  end
end
