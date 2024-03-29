###############  LALG Membership System - Regression Tests  ##################

# Regression test scripts to run under Rspec
# Functions called by Test Definitions - Workflow specific

########################################################################
############# Global Configuration Constants etc.  #####################
########################################################################

#		Watir.default_timeout = 15

################################################################################
#####################  Business Process Setup Methods  #########################
#  Go through the business process to the point where outcome can be verified
################################################################################

################  Helper Methods  ##################

#  Set up Additional Members
def additionalMembers (b: @bAdmin, noMembers: 1)
	@b = b
	@i = 1
	while @i <= noMembers do
		contact = @i			
		details = @b.details(id: "edit-additional-household-member-#{contact}")
		if details.summary.attribute_value("aria-expanded") == "false"
			details.summary.click
		end
		txt = details.text_field(visible: true, label: 'First Name')
		txt.set('Joe')
		txt = details.text_field(visible: true, label: 'Last Name')
		txt.set("WatirUserAdd#{@i}")
		txt = details.text_field(visible: true, label: 'Email')
		txt.set("watiruser#{@i}@lalg.org.uk")	
		@i += 1
	end
	# No server transactions
end

#  Select and make Payment 
def makePayment (b: @bAdmin, payment: :cheque)
	@b = b
	case payment
	when :cheque
		#Wait for the Payment overlay to vanish, then Click Cheque
		ppLabel = @b.label(text: 'Cheque')
		ppLabel.wait_while(&:obscured?).click
	when :stripe
		# Wait for the Payment overlay to vanish.
		billingItems = @b.table(id: 'wf-crm-billing-items')
		billingItems.wait_while(&:obscured?)
		# If radios exist, click Stripe Test
		ppLabel = @b.label(text: /STRIPE Test/i)		# Case independent
		if (ppLabel.exists?) 
			ppLabel.wait_while(&:obscured?).click	
		end
		# Wait again, then Fill in the Card Details
		cNum = @b.iframe.input(index: 1).wait_until(&:present?)
		cNum.click
		txt = '4000 0082 6000 0000 1230 123JW1 1JW'
		txt.split("").each do |i|
			@b.send_keys(i)
			sleep(0.2)
		end
	when :free
		# Just click Submit 
		total = @b.element(css: "tr#wf-crm-billing-total td:nth-child(2)")
		total.wait_while(&:obscured?)
		expect(total.text).to eq("£ 0.00")
	end	
	sleep(1)
	here = @b.url
	@b.button(id: 'edit-actions-submit').click
	# Wait until payment completed
	Watir::Wait.until { @b.url != here }
	$clickCount += 1
end	

################  Called from Test Spec   #####################

# Admin creates new Member, or End User signs up
# Requires to be logged in as Admin or End User
def newMember(	user: 			:admin, 
				withEmail: 		true, 
				memberType:		:printed,		# :printed, :plain, :none
				clearPrefs:		false,
				payment: 		:cheque, 
				additional:		0)
	puts 'Do New Member: Email- ' + withEmail.to_s + '  Payment- ' + payment.to_s + '  User- ' + user.to_s

	# Select browser to use
	if user == :admin
		@b = @bAdmin
		wf = 'admindetails'
	else 
		@b = @bUser
		wf = 'userdetails'
	end

	#Fill in the details of Contact, Household and Membership
	# May already be on that page in some tests
	if !(@b.url.include? 'userdetails') && !(@b.url.include? 'admindetails')
		@b.goto("#{Domain}/#{wf}")
	end#
	
	# Fiddle to get the jQuery that fills in Household Name to fire at the right time.
	if user != :admin
		@b.text_field(id: /contact-1-contact-last-name/).click
	else
		@b.text_field(id: /contact-1-contact-first-name/).set('Joe')
		@b.text_field(id: /contact-1-contact-last-name/).set('WatirUser')
	end 
	
	if withEmail
		@b.text_field(id: /contact-1-email-email/).set('watiruser@lalg.org.uk')
	end
	@timenow = Time.now.strftime("%H%M")
	@b.text_field(id: /contact-1-address-street-address/).set("#{@timenow} Watir Street")
	@b.text_field(id: /contact-1-address-city/).set('Testtown')
	@b.text_field(id: /contact-1-address-postal-code/).set('JW1 1JW')
	if memberType != :none
		# Select Membership Type
		if user == :admin
			if memberType == :printed
				@b.select_list(id: /membership-1-membership-membership-type-id/).select(/Printed/)
			else
				@b.select_list(id: /membership-1-membership-membership-type-id/).select('Membership')
			end
		else
			if memberType == :printed
				@b.radio(id: /membership-1-membership-membership-type-id-8/).set
			else
				@b.radio(id: /membership-1-membership-membership-type-id-7/).set
			end
		end
	end
	if clearPrefs 
		@b.checkbox(class: 'lalg-memb-emailoptions', label: /Information/).clear
		@b.checkbox(class: 'lalg-memb-emailoptions', label: /Newsletter/).clear
	end
	# Next Page
	@b.button(id: 'edit-actions-wizard-next').click
	# Additional Members
	additionalMembers(b: @b, noMembers: additional)
	# Next Page / Submit
	if memberType == :none
		@b.button(id: 'edit-actions-submit').click
	else
		@b.button(id: 'edit-actions-wizard-next').click
		# Make Payment
		makePayment(payment: payment, b: @b)
	end
	$clickCount += 3
end

# Goes to the Drupal Admin Details form for Joe
def findJoe()
	@bAdmin.goto("#{Domain}/find-contacts")
	@bAdmin.text_field(id: "edit-display-name").set('WatirUser')	
	@bAdmin.button(id: 'edit-submit-find-contacts').click	
	# Goto Admin Details for Joe
	@bAdmin.link(text: 'Joe WatirUser').click
	$clickCount += 1
end

# Renews Membership
# Requires Clean Data, Created New Member
def renewMembership(user: :admin, 
					memberType: :printed, 
					payment: :cheque, 
					additional: 0)
	puts 'Do Renew Membership'
	if user == :admin
		# Find Contact
		# @bAdmin.goto("#{Domain}/find-contacts")
		# @bAdmin.text_field(id: "edit-display-name").set('WatirUser')	
		# @bAdmin.button(id: 'edit-submit-find-contacts').click	
		# # Goto Admin Details for Joe
		# @bAdmin.link(text: /WatirUser/i).click
		findJoe
		# Select Membership and continue
		if memberType == :printed
			@bAdmin.select_list(id: /membership-1-membership-membership-type-id/).select(/Printed/)
		else
			@bAdmin.select_list(id: /membership-1-membership-membership-type-id/).select('Membership')
		end
		# Next Page
		@bAdmin.button(id: 'edit-actions-wizard-next').click		# Additional Members
		additionalMembers(b: @bAdmin, noMembers: additional)
		# Next Page
		@bAdmin.button(id: 'edit-actions-wizard-next').click
		# Make Payment
		makePayment(b: @bAdmin, payment: payment)	
		$clickCount += 4
	else
		# Go to User Details page
		@bUser.goto("#{Domain}/userdetails?payment=test")
		# Select Membership and continue
		if memberType == :printed
			@bUser.radio(id: /membership-1-membership-membership-type-id-8/).set
		else
			@bUser.radio(id: /membership-1-membership-membership-type-id-7/).set
		end
		# Next Page
		@bUser.button(id: 'edit-actions-wizard-next').click		
		# Additional Members
		additionalMembers(b: @bUser, noMembers: additional)
		# Next Page
		@bUser.button(id: 'edit-actions-wizard-next').click
		# Make Payment
		makePayment(b: @bUser, payment: payment)	
		$clickCount += 3
	end
end

# Replace Card
# Requires to be logged in as User, with New Member Created
def replaceCard ( user: :admin)
	#Select Browser and Webform to use
	if user == :admin
		@b = @bAdmin
		
		# Find User and goto details page
		@b.goto("#{Domain}/find-contacts")
		@b.text_field(id: "edit-display-name").set('WatirUser')	
		@b.button(id: 'edit-submit-find-contacts').click	
		# Goto Admin Details for Joe
		@b.link(text: /WatirUser/i).click
	else 
		@b = @bUser
		#Go to Details Page
		@b.goto("#{Domain}/userdetails")
	end

	# Set one Replacement Card and continue
	@b.checkbox(class: 'lalg-memb-replace-tag', index: 0).set(true)
	@b.button(id: 'edit-actions-wizard-next').click
	@b.button(id: 'edit-actions-submit').click
	$clickCount += 4  	#Average of 3 and 5
end

################################################################################
####################  Process Verification Shared Examples  ####################
################################################################################
# Verify results of business process

######  Check redirect after payment etc.
#
def chkRedirect (user: :admin, memberType: 'Printed')
	context 'Check Redirect' do 
		if (user == :admin)			
			it "should return to the Find Contacts screen" do
				@bAdmin.text_field(id: 'edit-id').wait_until(&:present?)	
				expect(@bAdmin.title).to include('Find Contacts')
			end
		else
			it "should show the Thank You screen" do		
				@bUser.wait_until { |a| a.title =~ /Thank You/ }
				expect(@bUser.text).to include("Thank You")
				expect(@bUser.div(class: 'lalg-view-thank-you').text).to include(memberType)
				if (memberType != 'Printed')
					expect(@bUser.div(class: 'lalg-view-thank-you').text).not_to include('Printed')
				end
			end
		end
	end
end

######  Check Household Details  (Actual Tests follow)
#
def chkHousehold (	user: :admin, 
					mShips: 1, 
					memberType: 'Printed', 
					memberStatus: 'New',
					additional: 0)				# Additional Members
					
	context 'Check Household' do 
	
		it 'correct number should appear in Find Contacts' do
			@bAdmin.goto("#{Domain}/find-contacts")
			@bAdmin.text_field(id: 'edit-display-name').set('watiruser')
			@bAdmin.button(id: 'edit-submit-find-contacts').click
			tbl = @bAdmin.table(class: 'sticky-enabled').wait_until(&:present?)
			rows = @bAdmin.elements(:css => "table.sticky-enabled tbody tr")
			expect(rows.length).to eq 1	+ additional	
		end

		it "should appear twice in CiviCRM Contacts Search" do
			@bAdmin.goto("#{Domain}/civicrm/contact/search/?reset=1")
			@bAdmin.text_field(id: 'sort_name').set('WatirUser')
			@bAdmin.button(id: /_qf_Basic_refresh/i).click	
			rows = @bAdmin.elements(:css => "div.crm-search-results tbody tr")
			expect(rows.length).to eq 2	+ additional	
		end
		  
		it "should have Household Summary fields set correctly" do
			# Go to Household summary page
			@bAdmin.element(:css => "div.crm-search-results tbody").link(visible_text: /Household/).click
			expect(@bAdmin.div(text: 'Contact Type').following_sibling(text: 'Household')).to exist
			expect(@bAdmin.div(text: 'Home Address').following_sibling(text: /#{@timenow} Watir Street/)).to exist
		end 
		
		it 'should have no Household Contribution set' do 
			expect(@bAdmin.li(id: 'tab_contribute', visible_text: 'Contributions 0')).to exist
		end
		
		it 'should have one Household Membership' do
			if mShips > 0
				mTab = @bAdmin.li(id: 'tab_member', visible_text: /Memberships/).wait_until(&:exists?)
				expect(mTab).to exist
				expect(mTab.text).to match(/#{mShips}/)
				mTab.click
				Watir::Wait.until { @bAdmin.execute_script("return jQuery.active") == 0}		#Wait for AJAX to finish
				mType = @bAdmin.element(:css => 'td.crm-membership-membership_type').wait_until(&:exists?)
				if memberType == 'Membership'
					expect(mType.text).to eq(memberType)
				else
					expect(mType.text).to include(memberType)
				end
				mStatus = @bAdmin.element(:css => 'td.crm-membership-status').wait_until(&:exists?)
				expect(mStatus.text).to eq(memberStatus)
			end
		end
		$clickCount += 6
	end
end

######  Check Individual Details
def chkIndividual (	withEmail: true, 
					activities: 3, 
					contrib: 1, 
					mShips: 1, 					# Number of Memberships:  0 => don't check
					memberType: 'Printed', 
					memberStatus: 'New',
					endDateOffset: -1,			# Default End Date is one year from yesterday
					duration: 12,				# Default Membership duration is 12 months.
					additional: 0,				# Additional Members
					chkAddNum: false,			# Check the Additional Member number, not Contact 1
					lma: 0)						# Latest Membership Action:  0 => don't check
					
	context 'Check Individual' do 
		it 'should have one Individual Contact, plus Additional Members' do
			@bAdmin.goto("#{Domain}/civicrm/contact/search/?reset=1")
			@bAdmin.text_field(id: 'sort_name').set('WatirUser')
			@bAdmin.button(id: /_qf_Basic_refresh/i).click	
			rows = @bAdmin.elements(:css => "div.crm-search-results tbody tr")
			expect(rows.length).to eq 2	+ additional
			if chkAddNum
				@bAdmin.element(:css => "div.crm-search-results tbody").link(visible_text: /WatirUserAdd#{chkAddNum}/i).click
			else
				@bAdmin.element(:css => "div.crm-search-results tbody").link(visible_text: /WatirUser, Joe/i).click
			end
		end
		
		it "should have Individual Summary fields set correctly" do
			expect(@bAdmin.div(text: 'Contact Type').following_sibling(text: 'Individual')).to exist
			expect(@bAdmin.div(text: 'Home Address').following_sibling(text: /#{@timenow} Watir Street/)).to exist
			expect(@bAdmin.div(text: 'Billing Address')).not_to exist
			if withEmail
				if chkAddNum
					expect(@bAdmin.div(text: 'Home Email').following_sibling(text: /watiruser#{chkAddNum}@lalg.org.uk/i)).to exist
				else	
					expect(@bAdmin.div(text: 'Home Email').following_sibling(text: /watiruser@lalg.org.uk/i)).to exist
				end
			else
				expect(@bAdmin.div(text: 'Home Email')).not_to exist
			end
			if lma > 0 
				expect(@bAdmin.div(text: 'Latest Membership Action').following_sibling.text).to eq(lma.to_s)
			end
		end 
		
		it 'should have correct number of Individual Contribution set' do 
			contribTab = @bAdmin.li(id: 'tab_contribute', visible_text: /Contributions/).wait_until(&:exists?)
			# Count rows rather than using the number in the tab, because 
			#   this does not include test-mode contributions.
			contribTab.click
			Watir::Wait.until { @bAdmin.execute_script("return jQuery.active") == 0}		#Wait for AJAX to finish
			if contrib == 0
				msg = @bAdmin.div(class: 'messages', visible_text: /No contributions/).wait_until(&:exists?)
				expect(msg).to exist
			else
				table = @bAdmin.tbody(:css => "div.crm-contact-contribute-contributions tbody").wait_until(&:exists?)
				rows = @bAdmin.elements(:css => "div.crm-contact-contribute-contributions tbody tr")
				expect(rows.length).to eq contrib
			end
		end	
		
		it 'should have one Individual Membership' do
			if mShips > 0
				mTab = @bAdmin.li(id: 'tab_member', visible_text: /Memberships/).wait_until(&:exists?)
				expect(mTab.text).to match(/#{mShips}/)
				mTab.click
				Watir::Wait.until { @bAdmin.execute_script("return jQuery.active") == 0}		#Wait for AJAX to finish
				mType = @bAdmin.element(:css => 'td.crm-membership-membership_type').wait_until(&:exists?)
				if memberType == 'Membership'
					expect(mType.text).to include(memberType)
					expect(mType.text).not_to include('Printed')
				else
					expect(mType.text).to include(memberType)
				end
				mStatus = @bAdmin.element(:css => 'td.crm-membership-status').wait_until(&:exists?)
				expect(mStatus.text).to eq(memberStatus)
			end
		end
		
		it 'should have the correct End Date' do
			if mShips > 0
				newEndDateTxt = @bAdmin.element(:css => 'td.crm-membership-end_date').wait_until(&:exists?)
				newEndDate = (Date.parse newEndDateTxt.text)
				oldEndDate = Date.today + endDateOffset
				expect(newEndDate).to eq(oldEndDate >> duration)		# Expected Period One Year.
			end
		end 
		
		it 'should have correct number of Individual Activities set' do 
			acts = @bAdmin.li(id: 'tab_activity', visible_text: /Activities/).wait_until(&:exists?)
			expect(acts.text).to match(/#{activities}/)
		end
		$clickCount += 5
	end	
end

# Check that Print Cards is set, and clears OK
def chkPrintCards (additional: 0, noCard: false)

	context 'Check Card Printing' do 
		if(!noCard)
			it 'should appear once/n-times in the Print Cards screen' do
				# Go to Print Cards
				@bAdmin.goto("#{Domain}/civicrm/contact/search/custom?csid=20&reset=1&force=1")
				results = @bAdmin.elements(css: 'div.crm-search-results tbody tr', text: /WatirUser/i)
				expect(results.length).to eq 1 + additional			
			end

			it 'should generate Membership Card PDF correctly' do
				results = @bAdmin.elements(css: 'div.crm-search-results tbody tr', text: /WatirUser/i)
				expect(results.length).to eq 1 + additional			
				
				# Find the Action drop-down
				tasks = @bAdmin.div(css: 'div.crm-search-tasks tbody div.select2-container').wait_until(&:exists?)
				expect(tasks).to exist
				# Select the WatirUser rows
				results.each { |row| row.checkbox(class: 'select-row').set(true) }					
				# Wait for Action frop-down to become enabled
				Watir::Wait.until {!tasks.class_name.include?('select2-container-disabled') }
				expect(tasks.class_name).not_to include('select2-container-disabled')				
				# Select and click the link
				lnk = tasks.link(class: 'select2-choice')
				expect(lnk).to exist
				lnk.click
				@bAdmin.send_keys(:enter)
								
				# Wait for CKEditor panel to load
				boldIcon = @bAdmin.link(class: 'cke_button__bold').wait_until(&:present?)
				expect(boldIcon).to exist
				# Wait for Template to load
				@bAdmin.iframe.body(text: /LALG/).wait_until(&:present?)
				expect(@bAdmin.iframe.body.text).to match(/LALG/)
				# Print  the PDF
				print = @bAdmin.button(text: 'Download and clear flags').wait_until(&:present?)
				print.click
			end
			$clickCount += 3
		end
		
		it 'should then be no Watir flags set' do
			@bAdmin.goto("#{Domain}/civicrm/contact/search/custom?csid=20&reset=1&force=1")
			
			Watir::Wait.until {
				@bAdmin.div(class: 'messages').present? ||
				@bAdmin.tr(css: 'div.crm-search-results tbody tr').present?			
			}
			
			resultsBlock = @bAdmin.div(class: 'crm-results-block')
			if (resultsBlock.div(class: 'messages').present?)
				expect(resultsBlock.div(class: 'messages').text).to include('None found')
			else 
				expect(@bAdmin.elements(css: 'div.crm-search-results tbody tr', text: /WatirUser/i).length).to eq(0)
			end
		end
		$clickCount += 1
	end
end

# Check Visibility on User Form
def chkVisible(membType: true, otm: true, replace: false)
	before (:all) {
		puts 'Check Visibility'
		@bUser.goto("#{Domain}/userdetails")
	}
	it 'should show Membership Type Required correctly' do
		field = @bUser.fieldset(class: 'lalg-memb-membership-type-wrapper').present?
		expect(field).to eq(membType)
	end	
	it 'should show OTM Membership correctly' do
		field = @bUser.input(label: /Online/).present?
		expect(field).to eq(otm)
	end	
	it 'should show Replacement Card correctly' do
		field = @bUser.input(class: 'lalg-memb-replace-tag').present?
		expect(field).to eq(replace)
	end
	$clickCount += 1
end

# Check Mail Preferences
def chkMailPrefs(info: false, newsletter: false)
	# Assumes already on the UserDetails form
	before (:all) {
		puts 'Check Mail Preferences'
	}
	it 'should show Info preference correctly' do
		field = @bUser.checkbox(class: 'lalg-memb-emailoptions', label: /Information/)
		expect(field.checked?).to eq(info)
	end
	it 'should show Newsletter preference correctly' do
		field = @bUser.checkbox(class: 'lalg-memb-emailoptions', label: /Newsletter/)
		expect(field.checked?).to eq(newsletter)
	end
end

# Check all Memberships updated as expected
def chkMemberships (expDate:, status:)
	@bAdmin.goto("#{Domain}/civicrm/member/search?reset=1")
	@bAdmin.text_field(id: 'sort_name').set('watiruser')
	@bAdmin.button(id: '_qf_Search_refresh').click
	@rows = @bAdmin.elements(:css => "div.crm-search-results tbody tr")

	@rows.each { |row| 
		mDate = row.td(class: 'crm-membership-end_date').wait_until(&:exists?)
#		expect(Date.parse(mDate.text)).to eq(Date.parse(expDate))
		expect(Date.parse(mDate.text)).to eq(Date.parse('01/01/2020'))
		mStatus = row.td(class: 'crm-membership-status').wait_until(&:exists?)
		expect(mStatus.text).to include(status)
	}
	$clickCount += 2
end


