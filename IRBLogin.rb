###############  LALG Membership System - Regression Tests  ##################

# Login routine for Interactive session
# To execute:  
#    cd to directory containing tests
#    irb
#    load 'IRBLogin.rb'



require 'watir'

Domain = 'http://tmp.lalg.org.uk'

Watir.default_timeout = 10
@b = Watir::Browser.new :chrome
@b.window.resize_to(1200, 1000)

@b.goto("#{Domain}/user/login")
@b.text_field(id: 'edit-name').set('watir')
@b.text_field(id: 'edit-pass').set('WatirTesting1987!!')
@b.button(id: 'edit-submit').click

