###############  LALG Membership System - Regression Tests  ##################

# Utilities for Unit Test Regression test scripts to run under Rspec
# Functions called by Test Definitions in UnitTest**.rb

########################################################################
############# Global Configuration Constants etc.  #####################
########################################################################

DOWNLOADS = "C:/Users/#{ENV['USERNAME']}/Downloads"

#########################################################################
########################  Shared General Setup Methods  #################
#########################################################################

# Create Individual Contact
# For Unit Testing, uses CiviCRM admin screens
#   Returns - the created Contact Id 
def createContact (noEmail: false)
	puts 'Create Individual Contact'
	@bAdmin.goto("#{Domain}/civicrm/contact/add?reset=1&ct=Individual")
	@bAdmin.text_field(id: 'first_name').set('Joe')	
	@bAdmin.text_field(id: 'last_name').set('WatirUser')
	if (noEmail)
		#Skip
	else
		@bAdmin.text_field(id: 'email_1_email').set('watiruser@lalg.org.uk')
	end
	@bAdmin.button(id: '_qf_Contact_upload_view-top').click	
	cid = @bAdmin.span(class: 'crm-contact-contact_id').text
	$clickCount += 1
	return cid
end

# Create Household
# For Unit Testing, uses CiviCRM admin screens
#   Returns - the created Household Contact Id 
def createHousehold
	puts 'Create Household Contact'
	@bAdmin.goto("#{Domain}/civicrm/contact/add?reset=1&ct=Household")
	@bAdmin.text_field(id: 'household_name').set('WatirUser Household')	
	@bAdmin.button(id: '_qf_Contact_upload_view-top').click	
	hhid = @bAdmin.span(class: 'crm-contact-contact_id').text
	$clickCount += 1
	return hhid
end

# Add (new) Relationship and Household to Contact
# For Unit Testing, uses CiviCRM admin screens
# Returns - new Household Id
def addHouseholdToContact (cid)
	# Create the Household
	hhid = createHousehold
	# Go to Add Relationship Page
	@bAdmin.goto("#{Domain}/civicrm/contact/view/rel?reset=1&action=add&cid=#{cid}")
	lnk = @bAdmin.link(class: 'select2-choice').wait_until(&:present?)
	lnk.click
	@bAdmin.div(class: 'select2-result-label', text: 'Member of').click
	@bAdmin.send_keys(:tab, :tab, 'watir')
	@bAdmin.div(class: 'crm-select2-row-label', text: 'WatirUser Household').click
#	sleep(1)
	@bAdmin.button(id: '_qf_Relationship_upload-bottom').click
	$clickCount += 3
	return hhid
end

# Delete Contacts
# For Unit Testing
def deleteContacts
	@bAdmin.goto("#{Domain}/civicrm/contact/search?reset=1")
	@bAdmin.text_field(id: 'sort_name').set('WatirUser')
	@bAdmin.button(id: '_qf_Basic_refresh-bottom').click
	# Check if any exist
	resultMT = @bAdmin.div(class: 'crm-results-block-empty')
	if (resultMT.exists?) 
		# Skip if none
	else
		# Select all
		@bAdmin.radio(value: 'ts_all').click
		# Select and click the Delete action
		@bAdmin.send_keys(:tab, :enter)
		@bAdmin.div(class: 'select2-result-label', text: 'Delete contacts').click
		# Confirm
		@bAdmin.button(id: '_qf_Delete_done').click
	end
	$clickCount += 3
end

# Add Membership to Contact
# For Unit Testing
def addMembership (cid)
	@bAdmin.goto("#{Domain}/civicrm/member/add?reset=1&action=add&context=standalone&cid=#{cid}")
	@bAdmin.select_list(id: 'membership_type_id_1').select('Membership')
	@bAdmin.checkbox(id: 'record_contribution').clear
	@bAdmin.button(id: '_qf_Membership_upload-bottom').click
	$clickCount += 2
end

# Renew Membership
# For Unit Testing
def unitRenewMembership (cid)
	@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{cid}&selectedChild=member")
	btn = @bAdmin.element(:css => 'div#memberships tbody tr td span.btn-slide')
	btn.click
	@bAdmin.link(text: 'Renew').click
	@bAdmin.div(id: 'help').click		#Clear the Date Picker
	@bAdmin.checkbox(id: 'record_contribution').clear
	@bAdmin.button(id: '_qf_MembershipRenewal_upload-top').click
	#Wait for jQuery/AJAX to finish
	Watir::Wait.until { @bAdmin.execute_script("return jQuery.active") == 0}
	# Make sure Contact screen is properly refreshed
	@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{cid}")
	$clickCount += 4
end

# Change Membership
# For Unit Testing
def unitChangeMembership (cid)
	@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{cid}&selectedChild=member")
	btn = @bAdmin.element(:css => 'div#memberships tbody tr td span.btn-slide')
	btn.click
	@bAdmin.link(class: 'action-item', text: 'Edit').click
	@bAdmin.select_list(id: 'membership_type_id_1').select('8')
	@bAdmin.button(visible_text: 'Save').click
	#Wait for jQuery/AJAX to finish
	Watir::Wait.until { @bAdmin.execute_script("return jQuery.active") == 0}
	# Make sure Contact screen is properly refreshed
	@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{cid}")
	$clickCount += 4
end

def setTags (cid, setPrint: false, setMRequested: false, setReplacement: false)
	@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{cid}")
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


def setUserFields (cid, setMAction: 0)
	@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{cid}")
	@bAdmin.div(text: 'Latest Membership Action').click
	@bAdmin.text_field.set("#{setMAction}")
	@bAdmin.button(id: '_qf_CustomData_upload').click
end

########################################################################
########################  Shared Checking Methods  #####################
#########################################################################

shared_examples "chkTags" do |chkPrint: false, chkMRequested: false, chkReplacement: false|

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

def chkDownload (dirBefore, minSize: 2000)
	context 'Check Download' do
		it 'should have downloaded a plausible PDF file' do
			dirAfter = Dir.glob("#{DOWNLOADS}/*.pdf")
			expect(dirAfter.length).to eq(dirBefore.length + 1) 
			
			dirAfter.each do |fname|
				if dirBefore.include? fname
					next
				else
					expect(File.size(fname)).to be > minSize
					break
				end 
			end
		end 
	end 
end
