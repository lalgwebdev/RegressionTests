 ###############  LALG Membership System - Regression Tests  ##################
###############             Unit Tests - Common             ##################

puts 'Test File opened'
require 'rspec'
require 'watir'
require '../Lib/CommonFns.rb'
require '../Lib/UnitCommonFns.rb'
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
	
	####### Test Update HH Membership Details
	describe 'Test-11 Update HH Membership Details' do
		before(:all) { 
			puts 'Test-11 Update HH Membership Details'
			deleteContacts
			createHousehold			
		} 
		describe 'Step 1: Check Household' do
			it 'should find that Household exists' do
				@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{@cid}")	
				name = @bAdmin.div(class: 'crm-summary-display_name', visible_text: /WatirUser Household/)
				expect(name).to exist
			end
		end
		
		describe 'Step 2: Add Membership' do
			before(:all) { 
				addMembership (@cid)
			} 
			it 'should find Membership details in HH Custom Fields' do
				@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{@cid}")
				hhFields = @bAdmin.element(:css => 'div.Household_Fields div.collapsible-title').wait_until(&:exists?)
				hhFields.click
				type = @bAdmin.div(class: 'crm-custom-data', text: /Membership/)
				expect(type).to exist
				expectedYear = Date.today.year + 1
				endDate = @bAdmin.div(class: 'crm-custom-data', text: /#{expectedYear}/)
				expect(endDate).to exist
			end
		end
	end	

# Close Test Case Wrapper	
end