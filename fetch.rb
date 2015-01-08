#!/usr/bin/env ruby

require 'mechanize'
require 'pp'

# https://www.sunnyportal.com/Templates/Start.aspx?ReturnUrl=%2f - login page
# form post to Start.aspx?ReturnUrl=%2f
# field - ctl00$ContentPlaceHolder1$Logincontrol1$txtUserName
# field - ctl00$ContentPlaceHolder1$Logincontrol1$txtPassword
# submit

# Get:
# https://www.sunnyportal.com/Dashboard?_=1420748111334 - JSON of what we want...
# Done approx every 5-10 seconds on website.

if ! [2, 3].include? ARGV.length
  puts "Usage: #{__FILE__} username password [delay]\n"
  puts "username - User used on sunnyportal.com website.\n"
  puts "password - Password to go with the Username above.\n"
  puts "delay - Delay in seconds between retrievals. Defaults to 10 seconds.\n"
  exit 1
end

login_user = ARGV[0]
login_pass = ARGV[1]
delay = 10
if ARGV.length == 3
  delay = ARGV[2].to_i
end
raise 'delay variable must be numeric, between 0 and 60.' unless delay > 0 and delay <= 60

mechanize = Mechanize.new { |agent|
  agent.user_agent_alias = 'Mac Safari'
}

puts "Logging in...\n"
login_page = mechanize.get('https://www.sunnyportal.com/Templates/Start.aspx?ReturnUrl=%2f')
login_result = login_page.form_with(:id => 'aspnetForm') do |login_form|
  login_form['ctl00$ContentPlaceHolder1$Logincontrol1$txtUserName'] = login_user
  login_form['ctl00$ContentPlaceHolder1$Logincontrol1$txtPassword'] = login_pass
  login_form['ctl00$ContentPlaceHolder1$Logincontrol1$LoginBtn'] = 'Login'
end.submit
# Check login was successful.
expected_success_uri = 'https://www.sunnyportal.com/FixedPages/Dashboard.aspx'
if login_result.uri.to_s == expected_success_uri
  puts "Login complete.\n"
else
  puts "Login failed, we did not get sent to the expected page.\n"
  puts "Expected: #{expected_success_uri}\n"
  puts "Actual: #{login_result.uri}\n"
  exit 1
end

at_exit {
  puts "Logging out.\n"
  logout_result = mechanize.get('https://www.sunnyportal.com/Templates/Logout.aspx')
  puts "Logout complete.\n"
}

puts "Output statistics every #{delay} seconds. Press Ctrl+C to exit any time.\n"
while true do
  print 'Requesting JSON... '
  json_result = mechanize.get("https://www.sunnyportal.com/Dashboard?_=#{Time.now.strftime('%s%L')}")
  puts "Done.\n\n"
  json_data = JSON.parse(json_result.body)
  #pp json_data
  puts "Timestamp: #{json_data['Timestamp']}\n"
  puts "Current PV Output (Watts): #{json_data['PV']}\n"
  puts "\nSleeping for #{delay} seconds.\n"
  sleep delay
end
