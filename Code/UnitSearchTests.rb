###############  LALG Membership System - Regression Tests  ##################
###############             Unit Tests - Searches             ##################

puts 'Test File opened'
require 'rspec'
require 'watir'
require './CommonFns.rb'
require './CommonUnitFns.rb'
require './CommonWfFns.rb'
puts 'Libraries loaded'

################################################################################
################  Support Functions for these Tests  ###########################
################################################################################



################################################################################
####################  Test Case Specifications  ################################
################################################################################

describe "Test Case Wrapper #{Time.now.strftime("%Y-%m-%d %H:%M")}" do

	before(:all) { loginAdmin }
	after(:all) {if defined?(@bAdmin) then @bAdmin.close end}
	
	####### Test Print Membership Cards
	describe 'Test-11 Print Membership Cards' do
		before(:all) { 
			puts 'Test-11 Print Membership Cards'
			deleteContacts
			createContact	
			setTags(setPrint: true)
			setUserFields(setMAction: 2)
			addMembership (@cid)			
		} 
		
		chkPrintCards
	end	
end
