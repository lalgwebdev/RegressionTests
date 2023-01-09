###############  LALG Membership System - Regression Tests  ##################
###############             Workflow Tests - Extended       ##################
#####  Extensions to Basic Tests to give full set of Confidence Tests  #######

puts 'Test File opened *** D8 version ***'
require 'rspec'
require 'watir'
require './CommonFns.rb'
require './CommonWfFns.rb'
puts 'Libraries loaded'

################################################################################
####################  Test Case Specifications  ################################
################################################################################

describe "Test Case Wrapper #{Time.now.strftime("%Y-%m-%d %H:%M")}" do
	
	before(:all) { loginAdmin }
	after(:all) {if defined?(@bAdmin) then @bAdmin.close end}
	
	############################################################
	#######  Test Admin New Member Variants
	
	#######  Admin Without Email
	describe "Test-22 Admin New Member NoEmail" do
		before(:all) { 
			puts '*** Test-22 Admin New Member No Email'
			cleanData 
			newMember(user: :admin, withEmail: false, payment: :cheque)
		} 
		chkRedirect()
		chkHousehold()
		chkIndividual(withEmail: false, activities: 4, lma: 1)
		chkPrintCards
	end

	#######  Admin Additional Members
	describe "Test-24 Admin Additional Members" do
		before(:all) { 
			puts '*** Test-24 Admin Additional Members'
			cleanData 
			newMember(user: :admin, payment: :cheque, additional: 5)
		} 
		chkRedirect()
		chkHousehold(additional: 5)
		chkIndividual(activities: 4, additional: 5, lma: 1)
		chkPrintCards(additional: 5)
	end
	
	######  Admin Plain Membership 
	describe "Test-26 Admin Plain Membership" do
		before(:all) { 
			puts '*** Test-26 Admin Plain Membership'
			cleanData 
			newMember(user: :admin, memberType: :plain, payment: :cheque)
		} 
		chkRedirect()
		chkHousehold(memberType: 'Membership') 
		chkIndividual(activities: 4, memberType: 'Membership', lma: 1)
		chkPrintCards
	end
	
	#######  Admin STRIPE Payment, Without Email
	describe "Test-27 Admin STRIPE Payment, Without Email" do
		before(:all) { 
			puts '*** Test-27 Admin STRIPE Payment, Without Email'
			cleanData 
			newMember(user: :admin, withEmail: false, payment: :stripe)
		} 
		chkRedirect()
		chkHousehold()
		chkIndividual(withEmail: false, activities: 4, lma: 1)
		chkPrintCards
	end	

	######  Admin Delete Member and Next/Previous
	describe "Test-45 Admin Delete Member and Next/Previous" do
		before(:all) { 
			puts '*** Test-45 Admin Delete Member and Next/Previous'
			cleanData 
		} 
		
		describe 'Step 1, Join, plus 2 Additional Members' do
			before(:all) {
				newMember(user: :admin, memberType: :none, additional: 4)
			}
			chkRedirect()
			chkHousehold(mShips: 0, additional: 4)
			chkIndividual( contrib: 0, mShips: 0, activities: 0, additional: 4, lma: 1)
		end
		
		describe 'Step 2, Do Edits, Set Deletions' do
			before(:all) {
				findJoe
				# Edit Joe
				@bAdmin.text_field(id: /civicrm-1-contact-1-phone-phone/).set('01234-123456')
				#Next Page
				@bAdmin.button(id: 'edit-actions-wizard-next').click
				# Delete first Additional Member
				@bAdmin.div(class: 'webform-custom-options-button', data_option_value: 'delete1').click
				# Edit second Additional Member
				@bAdmin.text_field(id: /civicrm-4-contact-1-phone-phone/).set('01234-123456')
				@bAdmin.text_field(id: /civicrm-4-contact-1-email-email/).clear
				# Edit fourth Additional Member
				@bAdmin.text_field(id: /civicrm-6-contact-1-phone-phone/).set('01234-123456')
				@bAdmin.text_field(id: /civicrm-6-contact-1-email-email/).clear
				$clickCount += 1	
			}
		
			it "should have disabled first Additional Member" do
				expect(@bAdmin.div(class: 'webform-custom-options-button', data_option_value: 'delete1').text).to match(/Restore/) 
				expect(@bAdmin.text_field(id: /civicrm-3-contact-1-phone-phone/).attribute_value('readonly')).to be_truthy
			end
		end
		
		describe 'Step 3, Do Previous/Next, Check Changes' do		
			before(:all) {	
				@bAdmin.button(id: 'edit-actions-wizard-prev').click
				@bAdmin.text_field(id: /civicrm-1-contact-1-phone-phone/).wait_until(&:visible?)
				@bAdmin.button(id: 'edit-actions-wizard-next').click
				$clickCount += 2
			}
			
			it 'should have four Additional Members in correct order' do
				@bAdmin.text_field(id: /civicrm-3-contact-1-contact-last-name/).wait_until(&:visible?)
				expect(@bAdmin.text_field(id: /civicrm-3-contact-1-contact-last-name/).value).to eq('WatirUserAdd1')
				expect(@bAdmin.text_field(id: /civicrm-4-contact-1-contact-last-name/).value).to eq('WatirUserAdd2')
				expect(@bAdmin.text_field(id: /civicrm-5-contact-1-contact-last-name/).value).to eq('WatirUserAdd3')
				expect(@bAdmin.text_field(id: /civicrm-6-contact-1-contact-last-name/).value).to eq('WatirUserAdd4')
			end
			
			it 'should still have first Additional Member deletion in place' do
				expect(@bAdmin.div(class: 'webform-custom-options-button', data_option_value: 'delete1').text).to match(/Restore/) 
				expect(@bAdmin.text_field(id: /civicrm-3-contact-1-phone-phone/).attribute_value('readonly')).to be_truthy
			end
			
			it 'should still have edits in place' do
				expect(@bAdmin.text_field(id: /civicrm-4-contact-1-phone-phone/).value).to eq('01234-123456')
				expect(@bAdmin.text_field(id: /civicrm-4-contact-1-email-email/).text).to be_empty
			end
		end
		
		describe 'Step 4, Make further Changes and Submit' do		
			before(:all) {	
				#Restore first Additional Member
				@bAdmin.div(class: 'webform-custom-options-button', data_option_value: 'delete1').click
				# Delete third Additional Member
				@bAdmin.div(class: 'webform-custom-options-button', data_option_value: 'delete3').click
				#Reverse edits on fourth Additional Member
				@bAdmin.text_field(id: /civicrm-6-contact-1-phone-phone/).clear
				@bAdmin.text_field(id: /civicrm-6-contact-1-email-email/).set('junk@junk.com')
				# Submit Form
				@bAdmin.button(id: 'edit-actions-submit').click
				$clickCount += 1
			}
			
			chkIndividual( contrib: 0, mShips: 0, activities: 0, additional: 3, lma: 1)
			context 'Check Delete & Edits' do
				it "should have edited Contact 1 Phone correctly" do
					sTab = @bAdmin.li(id: 'tab_summary').wait_until(&:exists?)
					sTab.click
					Watir::Wait.until { @bAdmin.execute_script("return jQuery.active") == 0}		#Wait for AJAX to finish
					homePhone = @bAdmin.div(text: 'Home Phone').following_sibling.text
					expect(homePhone).to eq('01234-123456')
				end 
				it "should not have deleted Additional Member 1" do
					@bAdmin.goto("#{Domain}/civicrm/contact/search/?reset=1")
					@bAdmin.text_field(id: 'sort_name').set('WatirUserAdd')
					@bAdmin.button(id: /_qf_Basic_refresh/i).click	
					rows = @bAdmin.elements(:css => "div.crm-search-results tbody tr")
					expect(rows.length).to eq 3
					tbody = @bAdmin.element(:css => "div.crm-search-results tbody")
					expect(tbody.text).to match(/WatirUserAdd1/)
					$clickCount += 1
				end
				
				it "should have deleted Additional Member 3" do
					tbody = @bAdmin.element(:css => "div.crm-search-results tbody")
					expect(tbody.text).not_to match(/WatirUserAdd3/)
				end
				
				it "should have edited Additional Member 2 Phone and Email correctly" do
					@bAdmin.element(:css => "div.crm-search-results tbody").link(visible_text: /WatirUserAdd2/).click
					expect(@bAdmin.div(class: 'crm-summary-display_name', text: /WatirUserAdd2/)).to exist
					homePhone = @bAdmin.div(text: 'Home Phone').following_sibling.text
					expect(homePhone).to eq('01234-123456')
					email = @bAdmin.div(text: 'Email').parent.div(class: 'crm-content') 
					expect(email.text).to be_empty
					$clickCount += 1
				end
				
				it "should have edited Additional Member 4 Phone and Email correctly" do
					@bAdmin.goto("#{Domain}/civicrm/contact/search/?reset=1")
					@bAdmin.text_field(id: 'sort_name').set('WatirUserAdd4')
					@bAdmin.button(id: /_qf_Basic_refresh/i).click	
					rows = @bAdmin.elements(:css => "div.crm-search-results tbody tr")		
					@bAdmin.element(:css => "div.crm-search-results tbody").link(visible_text: /WatirUserAdd4/).click
					phone = @bAdmin.div(text: 'Phone').parent.div(class: 'crm-content')
					expect(phone.text).to be_empty
					email = @bAdmin.div(text: 'Home Email').following_sibling.text
					expect(email).to eq('junk@junk.com')
					$clickCount += 2
				end
			end
		end
	end
	
	######  Admin Renew Membership plus Add Member at once
	describe "Test-51 Admin Renew Membership plus Add Member at once" do
		before(:all) { 
			puts '*** Test-51 Admin Renew Membership plus Add Member at once'
			cleanData 
		} 
		describe 'Step 1, Join' do
			before(:all) {
				newMember(user: :admin, payment: :cheque)
			}
			chkRedirect()
			chkHousehold()
			chkIndividual( contrib: 1, activities: 4, lma: 1)
			chkPrintCards
		end
		describe 'Step 2, Renew & Add Member' do
			before(:all) {
				changeEndDate(offset: 10, status: 'Renew') 
				renewMembership(additional: 1)
			}
			chkRedirect()
			chkHousehold( memberStatus: 'Current', additional: 1)
			chkIndividual( contrib: 2, memberStatus: 'Current', 
				endDateOffset: 10, duration: 12, activities: 11, additional: 1, lma: 2)
			chkIndividual( contrib: 0, memberStatus: 'Current', 
				endDateOffset: 10, duration: 12, activities: 3, additional: 1, lma: 2, chkAddNum: 1)				
			chkPrintCards(additional: 1)
		end
	end

	##############################################################
	#######  Test End User Actions
		
	#######  End User Additional Members
	describe "Test-33 User Additional Members" do
		before(:all) { 
			puts '*** Test-33 User Additional Members'
			cleanData 
			loginUser	
			newMember(user: :endUser, payment: :stripe, additional: 5)
		} 
		after(:all) { logoutUser }			
		
		chkRedirect(user: :endUser)
		chkHousehold(user: :endUser, additional: 5)
		chkIndividual( activities: 10, additional: 5)
		chkPrintCards(additional: 5)
	end
	
	#######  End User Page Field Visibility 
	describe "Test-42 User Field Visibility" do
		before(:all) { 
			puts '*** Test-42 User Visibility'
			cleanData 
			loginUser	
		} 	
		after(:all) { logoutUser }		

		describe 'No Membership' do	
			chkVisible(membType: true, otm: false, replace: false)
		end
		
		describe 'Current Membership' do	
			before(:all) { newMember(user: :endUser, payment: :stripe) }
			chkVisible(membType: false, otm: false, replace: true)
		end
		
		describe 'Renew Membership' do	
			before(:all) { changeEndDate(offset: 10, status: 'Renew') }
			chkVisible(membType: true, otm: false, replace: false)
		end
		
		describe 'Overdue Membership' do	
			before(:all) { changeEndDate(offset: -10, status: 'Overdue') }
			chkVisible(membType: true, otm: false, replace: false)
		end
		
		describe 'Lapsed Membership' do	
			before(:all) { changeEndDate(offset: -60, status: 'Lapsed') }
			chkVisible(membType: true, otm: false, replace: false)
		end
	end

	#######  End User Default Mail Preferences
	describe "Test-44 Default Mail Preferences" do
		before(:all) { 
			puts '*** Test-44 Default Mail Preferences'
			cleanData 
			loginUser	
			@bUser.goto("#{Domain}/userdetails")	
		} 	
		after(:all) { logoutUser }
		
		describe 'No Membership selected' do	
			chkMailPrefs(info: false, newsletter: false)
		end
		describe 'Membership with Printed Newsletter selected' do	
			before(:all) {
				@bUser.radio(id: /membership-1-membership-membership-type-id-8/).set
			}
			chkMailPrefs(info: true, newsletter: false)
		end		
		describe 'Plain Membership selected' do	
			before(:all) {
				@bUser.checkbox(class: 'lalg-memb-emailoptions', label: /Information/).clear
				@bUser.radio(id: /membership-1-membership-membership-type-id-7/).set
			}
			chkMailPrefs(info: true, newsletter: true)
		end		
		describe 'Check no defaults if already a member' do
			before (:all) {
				# Create Membership and move to Renewal Period
				newMember(user: :endUser, memberType: :plain, clearPrefs: true, payment: :stripe)
				changeEndDate(offset: 10, status: 'Renew')
				@bUser.goto("#{Domain}/userdetails")
				@bUser.radio(id: /membership-1-membership-membership-type-id-7/).set
			}
			chkMailPrefs(info: false, newsletter: false)
		end
		$clickCount += 2
	end
	
	######  End User Delete Member
	describe "Test-46 User Delete Member" do
		before(:all) { 
			puts '*** Test-46 User Delete Member'
			cleanData 
			loginUser	
		} 
		
		describe 'Step 1, Join, plus 2 Additional Members' do
			before(:all) {
				newMember(user: :admin, additional: 2)
			}
			chkRedirect()
			chkHousehold(additional: 2)
			chkIndividual( contrib: 1, activities: 4, additional: 2, lma: 1)
			chkPrintCards(additional: 2)
		end
		
		describe 'Step 2, User deletes Additional Member' do
			before(:all) {	
				@bUser.goto("#{Domain}/userdetails")	
				@bUser.button(id: 'edit-actions-wizard-next').click
				# Delete both Additional Members
				@bUser.div(class: 'webform-custom-options-button', data_option_value: 'delete1').click
				@bUser.div(class: 'webform-custom-options-button', data_option_value: 'delete2').click
				#Restore first Additional Member
				@bUser.div(class: 'webform-custom-options-button', data_option_value: 'delete1').click
			}	
			it "should have disabled second Additional Member" do
				expect(@bUser.div(class: 'webform-custom-options-button', data_option_value: 'delete2').text).to match(/Restore/) 
				expect(@bUser.text_field(id: /civicrm-4-contact-1-email-email/).attribute_value('readonly')).to be_truthy
			end
			it "should delete second Additional member when submitted" do
				# Submit Form
				@bUser.button(id: 'edit-actions-submit').click
				# Count Members
				@bAdmin.goto("#{Domain}/civicrm/contact/search/?reset=1")
				@bAdmin.text_field(id: 'sort_name').set('WatirUserAdd')
				@bAdmin.button(id: /_qf_Basic_refresh/i).click	
				rows = @bAdmin.elements(:css => "div.crm-search-results tbody tr")
				expect(rows.length).to eq 1
				tbody = @bAdmin.element(:css => "div.crm-search-results tbody")
				expect(tbody.text).to match(/WatirUserAdd1/)
				$clickCount += 3
			end
		end
	end	
	
	
	######  End User Renew Membership plus Change Membership Type with Stripe
	describe "Test-54 User Renew plus Change Membership Type with Stripe" do
		before(:all) { 
			puts '*** Test-54 User Renew plus Change Membership Type with Stripe'
			cleanData 
			loginUser	
		} 
		describe 'Step 1, Join' do
			before(:all) {
				newMember(user: :endUser, memberType: :printed, payment: :stripe)
			}
			chkRedirect(user: :endUser)
			chkHousehold(user: :endUser)
			chkIndividual(contrib: 1, activities: 5, lma: 1)
			chkPrintCards
		end
		describe 'Step 2, Renew & Change Membership Type' do
			before(:all) {
				changeEndDate(offset: 10, status: 'Renew') 
				renewMembership(user: :endUser, memberType: :membership, payment: :stripe)
			}
			chkRedirect(user: :endUser, memberType: 'Membership')
			chkHousehold(user: :endUser, memberType: 'Membership', memberStatus: 'Current')
			chkIndividual( contrib: 2, memberStatus: 'Current', 
				endDateOffset: 10, memberType: 'Membership', duration: 12, activities: 15, lma: 2)
			chkPrintCards
		end
	end	

# Close Test Case Wrapper
end
