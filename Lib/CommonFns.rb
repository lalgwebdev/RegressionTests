###############  LALG Membership System - Regression Tests  ##################

# Utilities for Unit Test Regression test scripts to run under Rspec
# Functions called by Test Definitions in Test**.rb

########################################################################
############# Global Configuration Constants etc.  #####################
########################################################################

# Select Domain
domain = ENV['RspecDomain']
if domain.nil?
	Domain = 'https://d8memb.lalg.org.uk'
else
	Domain = "https://#{domain}.lalg.org.uk"
end
puts 'Running on Domain: ' + Domain

# Throttling routine to pause every so many Clicks
$clickCount = 0
def chkClicks
	while $clickCount > 30
		puts 'Pausing for Clicks: ' + $clickCount.to_s
		sleep(60)
		$clickCount -= 60
	end
end

#########################################################################
########################  Shared General Setup Methods  #################
#########################################################################

# Open a Browser and Login as Admin
def loginAdmin
	if !defined?(@bAdmin)
		if ENV['RspecBrowser'] == 'firefox'
			@bAdmin = Watir::Browser.new :firefox
		else
			@bAdmin = Watir::Browser.new :chrome
		end
		@bAdmin.window.resize_to(1200, 1000)
	end
	@bAdmin.goto("#{Domain}/user/login")
	# If Cookie Banner showing, then dismiss it
	sleep(1)
	cookie = @bAdmin.div(class: 'eu-cookie-compliance-banner')
	if (cookie.exists?) 
		@bAdmin.button(class: 'agree-button').click
	end
	if @bAdmin.title =~ /Log in|Login|My LALG|User account/ 
		@bAdmin.text_field(id: 'edit-name').set('watir')
		@bAdmin.text_field(id: 'edit-pass').set('WatirTesting1987!!')
		@bAdmin.button(id: 'edit-submit').click
	end
	# Set count at start of run
	$clickCount = 3
end

# Open a Browser and Login as End User
def loginUser
	createUser
	if !defined?(@bUser)
		@bUser = Watir::Browser.new :chrome
		@bUser.window.move_to(600, 0)
		@bUser.window.resize_to(1200, 1000)
	end
	@bUser.goto("#{Domain}/user/login")
	# If Cookie Banner showing, then dismiss it
	sleep(1)
	cookie = @bUser.div(class: 'eu-cookie-compliance-banner')
	if (cookie.exists?) 
		@bUser.button(class: 'agree-button').click
	end
	if @bUser.title =~ /Log in|Login|My LALG|User account/ 
		@bUser.text_field(id: 'edit-name').set('watirUser')
		@bUser.text_field(id: 'edit-pass').set('WatirUserTesting%%')
		@bUser.button(id: 'edit-submit').click
	end
	$clickCount += 3
end	

# Logout End User
def logoutUser
	@bUser.goto("#{Domain}/user/logout")
	@bUser.close
	$clickCount += 1
end

# Create End User
def createUser
	puts 'Create End User'
	@bAdmin.goto("#{Domain}/admin/people/create")
	@bAdmin.text_field(id: 'edit-name').set('watirUser')
	@bAdmin.text_field(id: 'edit-mail').set('watiruser@lalg.org.uk')
	@bAdmin.text_field(id: 'edit-pass-pass1').set('WatirUserTesting%%')
	@bAdmin.text_field(id: 'edit-pass-pass2').set('WatirUserTesting%%')
	@bAdmin.checkbox(label: 'watir tests').set
	@bAdmin.text_field(id: 'first_name').set('Joe')	
	@bAdmin.text_field(id: 'last_name').set('WatirUser')
	@bAdmin.text_field(id: 'postal_code-Primary').set('JW1 1JW')
	@bAdmin.button(id: 'edit-submit').click	
	$clickCount += 2
end

# Delete End User
def deleteUser
	# Go to Drupal Users and find WatirUser
	@bAdmin.goto("#{Domain}/admin/people")	
	@bAdmin.text_field(id: 'edit-user').set('watirUser')
	@bAdmin.button(id: 'edit-submit-user-admin-people').click
	@bAdmin.wait_until { |b| (b.tbody.text.downcase.include?('watiruser')) || (b.tbody.text.include?('No people'))  }
	if (@bAdmin.tbody.text.downcase.include?('watiruser'))
		# Delete User
		row = @bAdmin.tbody.tr(text: /watirUser/i)
		row.checkbox(class: 'form-checkbox').set
		@bAdmin.select_list(id: 'edit-action').select 'user_cancel_user_action'
		@bAdmin.button(id: 'edit-submit').click
		@bAdmin.h1(text: /Are you sure/).wait_until(&:exists?)
		btn = @bAdmin.button(id: 'edit-submit').wait_until(&:exists?)
		sleep(1)
		btn.click
		@bAdmin.wait_until { |b| b.title =~ /People/ }
	end
	$clickCount += 4
end


# Clean out Test Data
# Requires to be logged in as Admin
def cleanData
	puts'Do Clean Data'
	# Check Clicks at start of each test
	chkClicks
	# Goto Delete Members search
	@bAdmin.goto("#{Domain}/civicrm/dataprocessor_contact_search/delete_members?reset=1")
	# Search for all Watir test Contacts
	@bAdmin.text_field(id: 'name_value').set('WatirUser')
	@bAdmin.button(name: '_qf_Basic_refresh').click
	# Check if any exist
	results = @bAdmin.div(class: 'crm-results-block', text: /No results/)
	if (results.exists?) 
		# Skip if none
	else
		# Select all
		@bAdmin.radio(value: 'ts_all').click
		# Select and click the Delete action
		@bAdmin.send_keys(:tab, :enter)
		@bAdmin.send_keys(:enter)
		# Confirm
		@bAdmin.button(id: '_qf_LalgDeleteMembers_done').click
	end
	$clickCount += 4
	
	# Delete Drupal User
	deleteUser
end


