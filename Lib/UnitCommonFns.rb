###############  LALG Membership System - Regression Tests  ##################

# Utilities for Unit Test Regression test scripts to run under Rspec
# Functions called by Test Definitions in UnitTest**.rb

#########################################################################
########################  Shared General Setup Methods  #################
#########################################################################

# Create Individual Contact
# For Unit Testing, uses CiviCRM admin screens
#   Returns - sets @cid to created Contact Id
def createContact
	puts 'Create Individual Contact'
	@bAdmin.goto("#{Domain}/civicrm/contact/add?reset=1&ct=Individual")
	@bAdmin.text_field(id: 'first_name').set('Joe')	
	@bAdmin.text_field(id: 'last_name').set('WatirUser')	
	@bAdmin.button(id: '_qf_Contact_upload_view-top').click	
	@cid = @bAdmin.span(class: 'crm-contact-contact_id').text
	$clickCount += 1
end

# Create Household
# For Unit Testing, uses CiviCRM admin screens
#   Returns - sets @cid to created Contact Id
def createHousehold
	puts 'Create Household Contact'
	@bAdmin.goto("#{Domain}/civicrm/contact/add?reset=1&ct=Household")
	@bAdmin.text_field(id: 'household_name').set('WatirUser Household')	
	@bAdmin.button(id: '_qf_Contact_upload_view-top').click	
	@cid = @bAdmin.span(class: 'crm-contact-contact_id').text
	$clickCount += 1
end

# Delete Contacts
# For Unit Testing
def deleteContacts
	@bAdmin.goto("#{Domain}/civicrm/contact/search?reset=1")
	@bAdmin.text_field(id: 'sort_name').set('WatirUser')
	@bAdmin.button(id: '_qf_Basic_refresh').click
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

# Renew (Change) Membership
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
	@bAdmin.goto("#{Domain}/civicrm/contact/view?reset=1&cid=#{@cid}")
	$clickCount += 4
end

