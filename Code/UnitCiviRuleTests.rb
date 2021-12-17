 ###############  LALG Membership System - Regression Tests  ##################
###############             Unit Tests - Common             ##################

puts 'Test File opened'
require 'rspec'
require 'watir'
require './CommonFns.rb'
require './CommonUnitFns.rb'
puts 'Libraries loaded'

################################################################################
################  Support Functions for these Tests  ###########################
################################################################################

def chkMembership  (cid, memberType: 'Membership', 
					yearOffset: 1)
					
	context	'Check Membership' do
		it 'should find one Membership created' do
puts cid
puts "#{Domain}/civicrm/contact/view?reset=1&cid=#{cid}"
			@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{cid}")
			mShips = @bAdmin.li(id: 'tab_member', visible_text: /Memberships/).wait_until(&:exists?)
			expect(mShips.text).to match(/1/)
			mShips.click
		end
		it 'should be the correct Type' do
			mType = @bAdmin.element(:css => 'td.crm-membership-membership_type').wait_until(&:exists?)
			if memberType == 'Membership'
				expect(mType.text).to include(memberType)
				expect(mType.text).not_to include('Printed')
			else
				expect(mType.text).to include(memberType)
			end
		end
		it 'should find correct Expiry Date' do			
			newEndDate = @bAdmin.element(:css => 'td.crm-membership-end_date').wait_until(&:exists?)
			expectedYear = Date.today.year + yearOffset
			expect(newEndDate.text).to match(/#{expectedYear}/)
		end	
		$clickCount += 2
	end
end

def chkActivity (cid, numActs: 0, activity: :membershipActivity)
	context 'Check Email Sent' do
		it 'should have the Expected Activity set' do
			@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{cid}")
			# Check number of Activities
			acts = @bAdmin.li(id: 'tab_activity', visible_text: /Activities/).wait_until(&:exists?)
			expect(acts.text).to match(/#{numActs}/)
			# Check the most recent Activity
			@bAdmin.li(id: 'tab_activity').click			 
			tbl = @bAdmin.table(class: 'contact-activity-selector-activity')
			tbl.wait_until(&:exists?)
			row = @bAdmin.element(:css => "table.contact-activity-selector-activity tbody tr:first-of-type")
			row.wait_until(&:exists?)
			if (activity == :membershipActivity)
				subject = row.td(class: 'crmf-subject', text: 'LALG Membership Card')
				expect(subject).to exist
			else
				actType = row.element(:css => "td:first-of-type")
				expect(actType.text).to include('Postal Reminder')
			end
		end
	end
end

################################################################################
####################  Test Case Specifications  ################################
################################################################################

describe "Test Case Wrapper #{Time.now.strftime("%Y-%m-%d %H:%M")}" do

	before(:all) { loginAdmin }
	after(:all) {if defined?(@bAdmin) then @bAdmin.close end}
	
	####### Test Process Membership Addition/Changes
	describe 'Test-11 Process Membership Addition/Changes' do
		before(:all) { 
			puts 'Test-11 Process Membership Addition/Changes'
			deleteContacts
			@cid = createContact			
		} 
		describe 'Step 1: Check Contact' do
			it 'should find that Contact exists' do
				@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{@cid}")	
				name = @bAdmin.div(class: 'crm-summary-display_name')
				expect(name.text).to match('Joe WatirUser')
			end
			$clickCount += 1
		end
		
		describe 'Step 2: Add Membership' do
			before(:all) { 
				setTags(@cid, setMRequested: true)
				setUserFields(@cid, setMAction: 2)
				addMembership (@cid)
			} 
puts @cid			
			chkMembership(@cid)
			chkTags(@cid, chkPrint: true)
			chkActivity(@cid, numActs: 2)
		end
		
		describe 'Step 3: Renew Membership' do
			before(:all) { 
				setTags(@cid, setMRequested: true)
				setUserFields(@cid, setMAction: 2)
				unitRenewMembership (@cid)
			}		
			chkMembership(@cid, yearOffset: 2)
			chkTags(@cid, chkPrint: true)
			chkActivity(@cid, numActs: 4)
		end
		
		describe 'Step 4: Change Membership' do
			before(:all) { 
				setTags(@cid, setMRequested: true)
				setUserFields(@cid, setMAction: 2)
				unitChangeMembership (@cid)
			}		
			chkMembership(@cid, memberType: 'Printed', yearOffset: 2)
			chkTags(@cid, chkPrint: true)
			chkActivity(@cid, numActs: 6)
		end
		
		describe 'Step 5: Request Replacement' do
			before(:all) { 
				setUserFields(@cid, setMAction: 3)
				setTags(@cid, setReplacement: true)
			}		
			chkTags(@cid, chkPrint: true)
			chkActivity(@cid, numActs: 7)
		end		
		
	end	

	
	####### Test Update HH Membership Details
	describe 'Test-12 Update HH Membership Details' do
		before(:all) { 
			puts 'Test-12 Update HH Membership Details'
			deleteContacts
			@hhid = createHousehold			
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
				addMembership (@hhid)
			} 
			it 'should find Membership details in HH Custom Fields' do
				@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{@hhid}")
				hhFields = @bAdmin.element(:css => 'div.Household_Fields div.collapsible-title').wait_until(&:exists?)
				hhFields.click
				type = @bAdmin.div(class: 'crm-custom-data', text: 'Membership')
				expect(type).to exist
				expectedYear = Date.today.year + 1
				endDate = @bAdmin.div(class: 'crm-custom-data', text: /#{expectedYear}/)
				expect(endDate).to exist
			end
			$clickCount += 1
		end
		
		describe 'Step 3: Renew Membership' do
			before(:all) { 
				unitRenewMembership (@hhid)
			}		
			it 'should find Membership Expiry Date in HH Custom Fields updated' do			
				@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{@hhid}")
				hhFields = @bAdmin.element(:css => 'div.Household_Fields div.collapsible-title').wait_until(&:exists?)
				hhFields.click
				expectedYear = Date.today.year + 2
				endDate = @bAdmin.div(class: 'crm-custom-data', text: /#{expectedYear}/)
				expect(endDate).to exist
			end	
			$clickCount += 1
		end
		
		describe 'Step 4: Change Membership' do
			before(:all) { 
				unitChangeMembership (@hhid)
			}		
			it 'should find Membership Type details in HH Custom Fields updated' do			
				@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{@hhid}")
				hhFields = @bAdmin.element(:css => 'div.Household_Fields div.collapsible-title').wait_until(&:exists?)
				hhFields.click
				type = @bAdmin.div(class: 'crm-custom-data', text: /Printed/)
				expect(type).to exist
			end		
			$clickCount += 1
		end
	end	
	
	####### Test Postal Reminder if Email Scheduled Reminder fails
	describe 'Test-13 Postal Reminder if Email Scheduled Reminder fails' do
		before(:all) { 
			puts 'Test-13 Postal Reminder if Email Scheduled Reminder fails'
			deleteContacts
			@cid = createContact(noEmail: true)
			addMembership (@cid)
			changeEndDate(@cid, offset: 29, status: 'Renewal', cid: @cid)
			# Run the Scheduled Job
			@bAdmin.goto("#{Domain}/civicrm/admin/job?action=view&id=9&reset=1")
			@bAdmin.button(id: '_qf_Job_submit-top').click
			@bAdmin.h1(class: 'page-title', text: /Settings - Scheduled Jobs/).wait_until(&:exists?)
		} 
		chkActivity(@cid, numActs: 3, activity: :postalReminder)
	end
	

# Close Test Case Wrapper	
end