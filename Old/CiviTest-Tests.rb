###############  LALG Membership System - Regression Tests  ##################

# Regression test scripts to run under Rspec
# To execute:
#    cd to directory containing scripts
#	 set RspecDomain=xxx											<Where xxx = www, dev or tmp>
#    rspec CiviTest.rb -e 'Test Name' -f html -o 'results.html' 
#
# Available tests:
#	 Test-00 Do Nothing
#
#	1x	Utilities
#    Test-11 Admin Login
#	 Test-12 Create User
#    Test-13 Clean Data
#	 Test-14 User Login
#
#	2x	Admin standard operations
#    Test-21 Admin New Member 
#    Test-22 Admin New Member NoEmail
#	 Test-23 Admin Renew Membership
#	 Test-24 Admin Additional Members
#    Test-25 Admin Renew Membership NoEmail
#	 Test-26 Admin New Plain Membership
#
#	3x	End User standard operations
#	 Test-31 User New Member Stripe
#	 Test-33 User Additional Members
#	 Test-34 User Join and Renew
#	 Test-35 User Plain Membership
#
#	4x	Lifecycle tests
#	 Test-41 Admin Membership Cycle
#	 Test-42 User Check Visibility of Fields
#	 Test-43 User Membership Lifecycle
#
#	5x	Special Cases
#	 Test-51 Admin Renew Membership plus Add Member at once
#	 Test-52 User Renew Membership plus Add Member
#	 Test-54 User Renew plus Change Membership Type with Stripe
#
#	9x  Obsolete Cases, kept in case needed again
#	 Test-91 (was 32) User New Member Pay Later [Old]
#	 Test-92 (was 35) User New Member OTM [Old]
#	 Test-93 (was 53) User Renew plus Change Membership Type with Pay Later [Old]
#
#
# Plus e.g.
#	 Test-n			<Runs Test number n>
#    User  			<Runs all User tests>
#    <Omitted>  	<Runs all Tests>
#	 [Short]		<Runs a shortened 'Confidence Level' test set>
#	 [Full]			<Runs additional tests to make up a full test set, omitting repeated operations>
#	 [Old]			<Target functionality discontinued - OTM, Pay Later>
#
# Need to turn off CAPTCHA on user_login and user_register forms
#

################  Compatibility Changes  #####################
# Version 6
#	Run with Stripe set to disable Billing Address
#   Implement 15 Month Renewals (synchronously)
#	Update to Stripe 6.4.2 and Contribution-Transact-Legacy
#	Update to VBO Action to use Payment API.
#
# Version 9 
#   Rework 'Delete Members' search with Data processor
#
# Version (10)
#   Correct Activity numbers for Webform_CiviCRM 7.x-5.2 and later changes
#	Change to Payment screen when Pay Later removed. (No options displayed.)
#	Make Pay Later and OTM Old and unused
#   Use ?payment=test when invoking webform to allow operation on Live without changes to PP
#
# Version (wip)
#	Add Click Count throttling

############# TODO #############
# Verify Emails
# Check Contact created on Create User (with end User Registration?
# Deduplication

puts 'Test File opened'
require 'rspec'
require 'watir'
require './CiviTest-Code.rb'
puts 'Libraries loaded'

################################################################################
####################  Test Case Specifications  ################################
################################################################################
# Test definitions - define business process to run, and verification to apply

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
		
		it 'should have a Logout entry on the menu' do
			@bAdmin.li(id: 'menu-5618-1').click
			menu = @bAdmin.link(text: /Logout/)
			expect(menu).to exist
		end
	end
	
	####### Test Create User
	describe 'Test-12 Create User' do
		before(:all) { 
			puts 'Test-12 Create User'
			cleanData
			createUser 
		} 
		
		it 'should find that WatirUser exists' do
			@bAdmin.goto("#{Domain}/admin/people")	
			@bAdmin.text_field(id: 'edit-name').set('watirUser')
			@bAdmin.button(id: 'edit-submit-admin-views-user').click
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
			@bAdmin.text_field(id: 'edit-name').set('watirUser')
			@bAdmin.button(id: 'edit-submit-admin-views-user').click
			@bAdmin.wait_until { |b| (b.tbody.text.downcase.include?('watiruser')) || (b.tbody.text.include?('No users'))  }
			row = @bAdmin.tbody.tr(text: /No users/)
			expect(row).to exist
		end
	end

	############################################################
	#######  Test Admin New Member Variants
	describe 'Admin New Member' do
	
	#######  Admin With Email
		describe "Test-21 Admin New Member Email" do
			before(:all) { 
				puts '*** Test-21 Admin New Member Email'
				cleanData 
				newMember(user: :admin, payment: :cheque)
			} 
			chkHousehold() 
			chkIndividual(activities: 4, lma: 1)
			chkPrintCards
		end
		
		#######  Admin Without Email
		describe "Test-22 [Full] Admin New Member NoEmail" do
			before(:all) { 
				puts '*** Test-22 Admin New Member No Email'
				cleanData 
				newMember(user: :admin, withEmail: false, payment: :cheque)
			} 
			chkHousehold()
			chkIndividual(withEmail: false, activities: 3, lma: 1)
			chkPrintCards
		end

		######  Admin Membership Renewal
		describe "Test-23 Admin Renew Membership" do
			before(:all) { 
				puts '*** Test-23 Admin Renew Membership'
				cleanData 
			} 
			
			describe 'Step 1' do
				before(:all) {
					newMember(user: :admin, payment: :cheque)
				}
				chkHousehold()
				chkIndividual( contrib: 1, activities: 4, lma: 1)
				chkPrintCards
			end
			describe 'Step 2' do
				before(:all) {
					changeEndDate(offset: 10, status: 'Renew') 
					renewMembership
				}
				chkIndividual( contrib: 2, memberStatus: 'Current', 
					endDateOffset: 10, duration: 15, activities: 10, lma: 2)
				chkPrintCards
			end
		end
		
		#######  Admin Additional Members
		describe "Test-24 [Full] Admin Additional Members" do
			before(:all) { 
				puts '*** Test-24 Admin Additional Members'
				cleanData 
				newMember(user: :admin, payment: :cheque, additional: 5)
			} 
			chkHousehold(additional: 5)
			chkIndividual(activities: 4, additional: 5, lma: 1)
			chkPrintCards(additional: 5)
		end
	end
	
	######  Admin Membership Renewal No Email
		describe "Test-25 [Short] Admin Renew Membership No Email" do
			before(:all) { 
				puts '*** Test-25 Admin Renew Membership No Email'
				cleanData 
			} 
			
			describe 'Step 1, Join' do
				before(:all) {
					newMember(user: :admin, withEmail: false, payment: :cheque)
				}
				chkHousehold()
				chkIndividual( withEmail: false, contrib: 1, activities: 3, lma: 1)
				chkPrintCards
			end
			describe 'Step 2, Renew' do
				before(:all) {
					changeEndDate(offset: 10, status: 'Renew') 
					renewMembership
				}
				chkIndividual( withEmail: false, contrib: 2, memberStatus: 'Current', 
					endDateOffset: 10, duration: 15, activities: 8, lma: 2)
				chkPrintCards
			end
		end
	
		describe "Test-26 Admin Plain Membership" do
			before(:all) { 
				puts '*** Test-26 [Full] Admin Plain Membership'
				cleanData 
				newMember(user: :admin, memberType: :plain, payment: :cheque)
			} 
			chkHousehold(memberType: 'Membership') 
			chkIndividual(activities: 4, memberType: 'Membership', lma: 1)
			chkPrintCards
		end
	
	#######  Admin Membership Lifecycle
	describe "Test-41 [Short] Admin Membership Lifecycle" do
		before(:all) { 
			puts '*** Test-41 Admin Membership Lifecycle'
			cleanData 
		} 	
		
		describe 'Join Membership' do	
			before(:all) {
				newMember(user: :admin, payment: :cheque)
			}
			chkHousehold()
			chkIndividual( activities: 4, lma: 1)
			chkPrintCards
		end
		
		describe 'Replace Membership Card' do	
			before(:all) {
				replaceCard(user: :admin)
			}
			chkIndividual( activities: 6, lma: 3 )
			chkPrintCards
		end
		
		describe 'Renew Membership' do	
			before(:all) {
				chkClicks
				changeEndDate(offset: 10, status: 'Renew') 
				renewMembership(user: :admin, payment: :cheque) 
			}
			chkIndividual( contrib: 2, endDateOffset: 10, duration: 15,
							memberStatus: 'Current', activities: 12, lma: 2 )
			chkPrintCards
		end
		
		describe 'Overdue Membership' do	
			before(:all) {
				changeEndDate(offset: -10, status: 'Overdue') 
				renewMembership(user: :admin, payment: :cheque) 
			}
			chkIndividual( contrib: 3, endDateOffset: -10, duration: 15,
							memberStatus: 'Current', activities: 18, lma: 2 )
			chkPrintCards
		end
		
		describe 'ReJoin Lapsed Membership' do	
			before(:all) {
				changeEndDate(offset: -60, status: 'Lapsed')
				renewMembership(user: :admin, payment: :cheque) 
			}
			chkIndividual( contrib: 4, memberStatus: 'Current', activities: 24, lma: 4 )
			chkPrintCards
		end
	end	

	######  Admin Renew Membership plus Add Member at once
		describe "Test-51 [Full] Admin Renew Membership plus Add Member at once" do
			before(:all) { 
				puts '*** Test-51 Admin Renew Membership plus Add Member at once'
				cleanData 
			} 
			describe 'Step 1, Join' do
				before(:all) {
					newMember(user: :admin, payment: :cheque)
				}
				chkHousehold()
				chkIndividual( contrib: 1, activities: 4, lma: 1)
				chkPrintCards
			end
			describe 'Step 2, Renew & Add Member' do
				before(:all) {
					changeEndDate(offset: 10, status: 'Renew') 
					renewMembership(additional: 1)
				}
				chkHousehold( memberStatus: 'Current', additional: 1)
				chkIndividual( contrib: 2, memberStatus: 'Current', 
					endDateOffset: 10, duration: 15, activities: 10, additional: 1, lma: 2)
				chkIndividual( contrib: 0, memberStatus: 'Current', 
					endDateOffset: 10, duration: 15, activities: 3, additional: 1, lma: 2, chkAddNum: 1)				
				chkPrintCards(additional: 1)
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
			
			it 'should have a Logout entry on the menu' do
				@bUser.li(id: 'menu-5618-1').click
				menu = @bUser.link(text: /Logout/)
				expect(menu).to exist
			end
		end	
	
		#######  End User with STRIPE
		describe "Test-31 User New Member Stripe" do
			before(:all) { 
				puts '*** Test-31 User New Member Stripe'
				cleanData 
				loginUser	
				newMember(user: :endUser, payment: :stripe)
			} 	
			after(:all) { logoutUser }		
			
			chkHousehold(user: :endUser)
			chkIndividual( activities: 4)
			chkPrintCards
		end
		
		######  End User Pay Later
		describe "Test-91 [Old] User New Member Pay Later" do
			before(:all) { 
				puts '*** Test-91 User New Member Pay Later'
				cleanData
				loginUser	
				newMember(user: :endUser, payment: :payLater)
			} 	
			after(:all) { logoutUser }			
			
			chkHousehold(user: :endUser, mShips: 0, memberStatus: 'Pending')
			chkIndividual( mShips: 0, memberStatus: 'Pending', activities: 3)
			chkReceivePayments
			chkIndividual( mShips: 1, activities: 6)	
			chkPrintCards
		end
		
		#######  End User Additional Members
		describe "Test-33 [Full] User Additional Members" do
			before(:all) { 
				puts '*** Test-33 User Additional Members'
				cleanData 
				loginUser	
				newMember(user: :endUser, payment: :stripe, additional: 5)
			} 
			after(:all) { logoutUser }			
			
			chkHousehold(user: :endUser, additional: 5)
			chkIndividual( activities: 9, additional: 5)
			chkPrintCards(additional: 5)
		end
		
		#######  End User Join and Renew 
		describe "Test-34 User Join and Renew" do
			before(:all) { 
				puts '*** Test-34 User Join and Renew'
				cleanData 
				loginUser	
				} 	
			after(:all) { logoutUser }		
			
			describe 'Join Membership' do	
				before(:all) {
					newMember(user: :endUser, payment: :stripe)
				}
				chkHousehold(user: :endUser)
				chkIndividual(activities: 4, lma: 1)
				chkPrintCards
			end
			
			describe 'Renew Membership' do	
				before(:all) {
					changeEndDate(offset: 10, status: 'Renew') 
					renewMembership(user: :endUser, payment: :stripe) 
				}
				chkIndividual( contrib: 2, endDateOffset: 10, duration: 15,
								memberStatus: 'Current', activities: 11, lma: 2 )
				chkPrintCards
			end
		end
		
		#######  End User with Plain Membership
		describe "Test-35 [Short] User Plain Membership" do
			before(:all) { 
				puts '*** Test-35 User Plain Membership'
				cleanData 
				loginUser	
				newMember(user: :endUser, memberType: :plain, payment: :stripe)
			} 	
			after(:all) { logoutUser }		
			
			chkHousehold(user: :endUser, memberType: 'Membership')
			chkIndividual(memberType: 'Membership', activities: 4)
			chkPrintCards
		end

		
		#######  End User with Online Temporary Membership
		describe "Test-92 [Old] User New Member OTM" do
			before(:all) { 
				puts '*** Test-92 User New Member OTM'
				cleanData 
				loginUser	
				newMember(user: :endUser, payment: :free, memberType: :otm)
			} 	
			after(:all) { logoutUser }		
			
			chkHousehold(user: :endUser, memberType: 'Online')
			chkIndividual( memberType: 'Online', contrib: 0, activities: 3)
			chkPrintCards(noCard: true)
#			chkVisible(membType: false, otm: false, replace: false)
		end
		
		#######  End User Page Field Visibility 
		describe "Test-42 [Full] User Field Visibility" do
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

		#######  End User Membership Lifecycle
		describe "Test-43 [Short] User Membership Lifecycle" do
			before(:all) { 
				puts '*** Test-43 User Membership Lifecycle'
				cleanData 
				loginUser	
				} 	
			after(:all) { logoutUser }		
			
			describe 'Join Membership' do	
				before(:all) {
					newMember(user: :endUser, payment: :stripe)
				}
				chkHousehold(user: :endUser)
				chkIndividual( activities: 4, lma: 1)
				chkPrintCards
			end
			
			describe 'Replace Membership Card' do	
				before(:all) {
					replaceCard(user: :endUser)
				}
				chkIndividual(activities: 6, lma: 3 )
				chkPrintCards
			end
			
			describe 'Renew Membership' do	
				before(:all) {
					chkClicks
					changeEndDate(offset: 10, status: 'Renew') 
					renewMembership(user: :endUser, payment: :stripe) 
				}
				chkIndividual( contrib: 2, endDateOffset: 10, duration: 15,
								memberStatus: 'Current', activities: 12, lma: 2 )
				chkPrintCards
			end
			
			describe 'Overdue Membership' do	
				before(:all) {
					changeEndDate(offset: -10, status: 'Overdue') 
					renewMembership(user: :endUser, payment: :stripe) 
				}
				chkIndividual( contrib: 3, endDateOffset: -10, duration: 15,
								memberStatus: 'Current', activities: 18, lma: 2 )
				chkPrintCards
			end
			
			describe 'ReJoin Lapsed Membership' do	
				before(:all) {
					changeEndDate(offset: -60, status: 'Lapsed')
					renewMembership(user: :endUser, payment: :stripe) 
				}
				chkIndividual( contrib: 4, memberStatus: 'Current', activities: 24, lma: 4 )
				chkPrintCards
			end
		end	

		######  End User Renew Membership plus Add Member with Pay Later
		describe "Test-52 [Short] User Renew Membership plus Add Member" do
			before(:all) { 
				puts '*** Test-52 User Renew Membership plus Add Member'
				cleanData 
				loginUser	
			} 
			describe 'Step 1, Join' do
				before(:all) {
					newMember(user: :endUser, payment: :stripe)
				}
				chkHousehold(user: :endUser)
				chkIndividual(contrib: 1, activities: 4)
				chkPrintCards
			end
			describe 'Step 2, Renew & Add Member' do
				before(:all) {
					changeEndDate(offset: 10, status: 'Renew') 
					renewMembership(user: :endUser, payment: :stripe, additional: 1)
				}
				chkHousehold(user: :endUser, memberStatus: 'Current', additional: 1)
				chkIndividual( contrib: 2, memberStatus: 'Current', 
					endDateOffset: 10, duration: 15, activities: 12, additional: 1)
				chkIndividual( contrib: 0, memberStatus: 'Current', 
					endDateOffset: 10, duration: 15, activities: 3, additional: 1, chkAddNum: 1)				
				chkPrintCards(additional: 1)
			end
		end	

		######  End User Renew Membership plus Change Membership Type with Stripe
		describe "Test-54 [Full] User Renew plus Change Membership Type with Stripe" do
			before(:all) { 
				puts '*** Test-54 User Renew plus Change Membership Type with Stripe'
				cleanData 
				loginUser	
			} 
			describe 'Step 1, Join' do
				before(:all) {
					newMember(user: :endUser, memberType: :printed, payment: :stripe)
				}
				chkHousehold(user: :endUser)
				chkIndividual(contrib: 1, activities: 4, lma: 1)
				chkPrintCards
			end
			describe 'Step 2, Renew & Change Membership Type' do
				before(:all) {
					changeEndDate(offset: 10, status: 'Renew') 
					renewMembership(user: :endUser, memberType: :membership, payment: :stripe)
				}
				chkHousehold(user: :endUser, memberType: 'Membership', memberStatus: 'Current')
				chkIndividual( contrib: 2, memberStatus: 'Current', 
					endDateOffset: 10, memberType: 'Membership', duration: 15, activities: 12, lma: 2)
				chkPrintCards
			end
		end	

		######  End User Renew Membership plus Change Membership Type with Pay Later
		describe "Test-93 [Old] User Renew plus Change Membership Type with Pay Later" do
			before(:all) { 
				puts '*** Test-93 User Renew plus Change Membership Type with Pay Later'
				cleanData 
				loginUser	
			} 
			describe 'Step 1, Join' do
				before(:all) {
					newMember(user: :endUser, memberType: :printed, payment: :stripe)
				}
				chkHousehold(user: :endUser)
				chkIndividual(contrib: 1, activities: 4, lma: 1)
				chkPrintCards
			end
			describe 'Step 2, Renew & Change Membership Type' do
				before(:all) {
					changeEndDate(offset: 10, status: 'Renew') 
					renewMembership(user: :endUser, memberType: :membership, payment: :payLater)
				}
				chkReceivePayments
				chkHousehold(user: :endUser, memberType: 'Membership', memberStatus: 'Current')
				chkIndividual( contrib: 2, memberStatus: 'Current', 
					endDateOffset: 10, memberType: 'Membership', duration: 15, activities: 14, lma: 2)
				chkPrintCards
			end
		end	

	end

# Close Test Case Wrapper
end
