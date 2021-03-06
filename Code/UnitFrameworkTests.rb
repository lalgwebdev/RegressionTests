###############  LALG Membership System - Regression Tests  ##################
###############             Unit Tests - Common             ##################

puts 'Test File opened'
require 'rspec'
require 'watir'
require './CommonFns.rb'
puts 'Libraries loaded'

################################################################################
####################  Test Case Specifications  ################################
################################################################################

####### Just Test the Framework - Do Nothing
describe 'Test-00 Do Nothing' do
	before(:all) {
		puts 'Test-00 Do Nothing'
	}
	
	it 'should succeed' do
		ARGV.each do|a|
			puts "Argument: #{a}"
		end
	end
end


describe "Test Case Wrapper #{Time.now.strftime("%Y-%m-%d %H:%M")}" do
	
	before(:all) { loginAdmin }
	after(:all) {if defined?(@bAdmin) then @bAdmin.close end}
	
	#########################################################
	#######  Utility Routine Tests
	
	####### Test Admin Login
	describe 'Test-11 Admin Login' do
		before(:all) {
			puts 'Test-11 Admin Login'
		}

		it 'should have correct Page Title' do
			expect(@bAdmin.title).to match(/watir|My Profile/)
		end
	end
	
	####### Test Create User
	describe 'Test-12 Create User' do
		before(:all) { 
			puts 'Test-12 Create User'
			deleteUsers
			createUser 
		} 
		
		it 'should find that WatirUser exists' do
			@bAdmin.goto("#{Domain}/admin/people")	
			@bAdmin.text_field(id: 'edit-user').set('watirUser')
			@bAdmin.button(id: 'edit-submit-user-admin-people').click
			user = @bAdmin.link(text: /watirUser/i).wait_until(&:exists?)
			expect(user).to exist
		end
	end

	####### Test Clean Data
	describe 'Test-13 Clean Data' do
		before(:all) { 
			puts 'Test-13 Clean Data'
			cleanData 
		} 
		
		it 'should find no Contact data to clean next time' do
			@bAdmin.goto("#{Domain}/civicrm/dataprocessor_contact_search/delete_members?reset=1")
			@bAdmin.text_field(id: 'name_value').set('WatirUser')
			@bAdmin.button(name: '_qf_Basic_refresh').click
			results = @bAdmin.div(class: 'crm-results-block', text: /No results/)
			expect(results).to exist
		end
		it 'should find no User data' do
			@bAdmin.goto("#{Domain}/admin/people")	
			@bAdmin.text_field(id: 'edit-user').set('watirUser')
			@bAdmin.button(id: 'edit-submit-user-admin-people').click
			@bAdmin.wait_until { |b| (b.tbody.text.downcase.include?('watiruser')) || (b.tbody.text.include?('No people'))  }
			row = @bAdmin.tbody.tr(text: /No people/)
			expect(row).to exist
		end
	end
	
	##############################################################
	#######  Test End User Actions
	describe 'User Actions' do

		####### Test End User Login
		describe 'Test-14 User Login' do
			before(:all) { 
				puts '*** Test-14 User Login'
				cleanData
				loginUser	
			} 	
			after(:all) { logoutUser }			
			
			it 'should have correct Page Title' do
				expect(@bUser.title).to match(/watirUser|My Profile/)
			end
		end	
	end

# Close Test Case Wrapper
end
