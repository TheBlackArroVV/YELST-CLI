require "option_parser"
require "http/client"
require "json"

SERVER_URL="https://yelst-backend.herokuapp.com"
CMD = "sh"

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

    response = HTTP::Client.post "#{SERVER_URL}/users/sign_up", headers: nil, form: {email: email, password: password}.to_json

    write_to_token_file(JSON.parse(response.body)["result"].to_s)
    exit
  end

  parser.on "sign_in", "Sign in" do
    puts "Write email"
    print "> "
    email = gets

    puts "Write password"
    print "> "
    password = gets

    response = HTTP::Client.post "#{SERVER_URL}/users/sign_in", headers: nil, form: {email: email, password: password}.to_json

    write_to_token_file(JSON.parse(response.body)["result"].to_s)
    exit
  end

  parser.on "scan", "Scan packages" do
    args = [] of String
    args << "-c" << "pacman -Qq"
    io = IO::Memory.new
    Process.run(CMD, args, shell: true, output: io)
    list = io.to_s.split("\n")

    args = [] of String
    args << "-c" << "cat ~/.yelts_token"
    io = IO::Memory.new
    Process.run(CMD, args, shell: true, output: io)
    token = io.to_s.sub("\n", "")

    headers =  HTTP::Headers.new.add("Authorization", value: "Bearer #{token}")
    response = HTTP::Client.post "#{SERVER_URL}/packages/set_list", headers: headers, form: {list: list, hostname: hostname}.to_json

    puts response.status
    exit
  end

  parser.on "list", "List of saved packages" do
    puts packages
    exit
  end

  parser.on "restore", "Restore packages from list" do
    io = IO::Memory.new
    args = [] of String
    pacman_string = "yay -S "
    list_of_packages = packages.join(" ")
    pacman_string += list_of_packages
    pacman_string += " --noconfirm --needed"
    args << "-c" << pacman_string
    Process.run(CMD, args, shell: true, output: io)
    puts io.to_s
    exit
  end
end

def packages
  args = [] of String
  args << "-c" << "cat ~/.yelts_token"
  io = IO::Memory.new
  Process.run(CMD, args, shell: true, output: io)
  token = io.to_s.sub("\n", "")

  headers =  HTTP::Headers.new.add("Authorization", value: "Bearer #{token}")
  response = HTTP::Client.get "#{SERVER_URL}/packages/get_list", headers: headers, form: {hostname: hostname}.to_json

  JSON.parse(response.body)["result"].to_s.split(" ")
end

def write_to_token_file(text)
  args = [] of String
  token = "echo " + text + " > ~/.yelts_token"
  args << "-c" << token
  Process.run(CMD, args, shell: true)
end

def hostname
  io = IO::Memory.new
  args = [] of String
  args << "-c" << "hostname"
  Process.run(CMD, args, shell: true, output: io)
  io.to_s.sub("\n", "")
end
