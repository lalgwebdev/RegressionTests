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

def chkMembership  (memberType: 'Membership', 
					yearOffset: 1)
					
	context	'Check Membership' do
		it 'should find one Membership created' do
			@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{@cid}")
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

def setTags (setPrint: false, setMRequested: false, setReplacement: false)
	@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{@cid}")
	@bAdmin.li(id: 'tab_tag').click
	@bAdmin.div(class: 'contact-tagset').wait_until(&:exists?)
				
	# Print Tag
	tag = @bAdmin.li(class: 'select2-search-choice', text: 'Print Card')
	if tag.exists?
		tag.link(class: 'select2-search-choice-close').click
	end
	if setPrint
		@bAdmin.text_field(label: 'Process Flow').click
		@bAdmin.li(text: 'Print Card').click
	end

	# Membership Requested Tag
	tag = @bAdmin.li(class: 'select2-search-choice', text: 'Membership Requested')
	if tag.exists?
		tag.link(class: 'select2-search-choice-close').click
	end
	if setMRequested
		@bAdmin.text_field(label: 'Process Flow').click
		@bAdmin.li(text: 'Membership Requested').click
	end
	
	# Replacement Request Tag
	tag = @bAdmin.li(class: 'select2-search-choice', text: 'Replacement Request')
	if tag.exists?
		tag.link(class: 'select2-search-choice-close').click
	end
	if setReplacement
		@bAdmin.text_field(label: 'Request Replacement Card').click
		@bAdmin.li(text: 'Replacement Request').click
	end
	$clickCount += 6
end

def chkTags(chkPrint: false, chkMRequested: false, chkReplacement: false)

	context	'Check Tags' do
		it 'should have Print Tag set correctly' do
			@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{@cid}")
			@bAdmin.li(id: 'tab_tag').click	
			@bAdmin.div(class: 'contact-tagset').wait_until(&:exists?)
			tag = @bAdmin.li(class: 'select2-search-choice', text: 'Print Card')
			if chkPrint
				expect(tag).to exist
			else
				expect(tag).not_to exist
			end
		end
		
		it 'should have Membership Requested Tag set correctly' do
			tag = @bAdmin.li(class: 'select2-search-choice', text: 'Membership Requested')
			if chkMRequested
				expect(tag).to exist
			else
				expect(tag).not_to exist
			end
		end
		
		it 'should have Replacement Request Tag set correctly' do
			tag = @bAdmin.li(class: 'select2-search-choice', text: 'Replacement Request')
			if chkReplacement
				expect(tag).to exist
			else
				expect(tag).not_to exist
			end
		end
	end
end

def setUserFields (setMAction: 0)
	@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{@cid}")
	@bAdmin.div(text: 'Latest Membership Action').click
	@bAdmin.text_field.set("#{setMAction}")
	@bAdmin.button(id: '_qf_CustomData_upload').click
end

def chkEmail (numActs: 0)
	context 'Check Email Sent' do
		it 'should have the Email Sent Activity set' do
			@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{@cid}")
			# Check number of Activities
			acts = @bAdmin.li(id: 'tab_activity', visible_text: /Activities/).wait_until(&:exists?)
			expect(acts.text).to match(/#{numActs}/)
			# Check the Email Sent Activity
			@bAdmin.li(id: 'tab_activity').click			 
			tbl = @bAdmin.table(class: 'contact-activity-selector-activity')
			tbl.wait_until(&:exists?)
			row = @bAdmin.element(:css => "table.contact-activity-selector-activity tbody tr:first-of-type")
			row.wait_until(&:exists?)
			act = row.td(class: 'crmf-subject', text: 'LALG Membership Card')
			expect(act).to exist
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
			createContact			
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
				setTags(setMRequested: true)
				setUserFields(setMAction: 2)
				addMembership (@cid)
			} 
			chkMembership
			chkTags(chkPrint: true)
			chkEmail(numActs: 2)
		end
		
		describe 'Step 3: Renew Membership' do
			before(:all) { 
				setTags(setMRequested: true)
				setUserFields(setMAction: 2)
				unitRenewMembership (@cid)
			}		
			chkMembership(yearOffset: 2)
			chkTags(chkPrint: true)
			chkEmail(numActs: 4)
		end
		
		describe 'Step 4: Change Membership' do
			before(:all) { 
				setTags(setMRequested: true)
				setUserFields(setMAction: 2)
				unitChangeMembership (@cid)
			}		
			chkMembership(memberType: 'Printed', yearOffset: 2)
			chkTags(chkPrint: true)
			chkEmail(numActs: 6)
		end
		
		describe 'Step 5: Request Replacement' do
			before(:all) { 
				setUserFields(setMAction: 3)
				setTags(setReplacement: true)
			}		
			chkTags(chkPrint: true)
			chkEmail(numActs: 7)
		end		
		
	end	

	
	####### Test Update HH Membership Details
	describe 'Test-12 Update HH Membership Details' do
		before(:all) { 
			puts 'Test-12 Update HH Membership Details'
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
				unitRenewMembership (@cid)
			}		
			it 'should find Membership Expiry Date in HH Custom Fields updated' do			
				@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{@cid}")
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
				unitChangeMembership (@cid)
			}		
			it 'should find Membership Type details in HH Custom Fields updated' do			
				@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{@cid}")
				hhFields = @bAdmin.element(:css => 'div.Household_Fields div.collapsible-title').wait_until(&:exists?)
				hhFields.click
				type = @bAdmin.div(class: 'crm-custom-data', text: /Printed/)
				expect(type).to exist
			end		
			$clickCount += 1
		end
	end	
	

# Close Test Case Wrapper	
end