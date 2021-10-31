###############  LALG Membership System - Regression Tests  ##################
###############             Workflow Tests - Extended       ##################
#####  Extensions to Basic Tests to give full set of Confidence Tests  #######

puts 'Test File opened'
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
		chkHousehold()
		chkIndividual(withEmail: false, activities: 3, lma: 1)
		chkPrintCards
	end

	#######  Admin Additional Members
	describe "Test-24 Admin Additional Members" do
		before(:all) { 
			puts '*** Test-24 Admin Additional Members'
			cleanData 
			newMember(user: :admin, payment: :cheque, additional: 5)
		} 
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
		chkHousehold(memberType: 'Membership') 
		chkIndividual(activities: 4, memberType: 'Membership', lma: 1)
		chkPrintCards
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
				endDateOffset: 10, duration: 12, activities: 10, additional: 1, lma: 2)
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
				@bUser.radio(id: /membership-1-membership-membership-type-id-2/).set
			}
			chkMailPrefs(info: true, newsletter: false)
		end		
		describe 'Plain Membership selected' do	
			before(:all) {
				@bUser.checkbox(class: 'lalg-wf-emailoptions', label: /Information/).clear
				@bUser.radio(id: /membership-1-membership-membership-type-id-1/).set
			}
			chkMailPrefs(info: true, newsletter: true)
		end		
		describe 'Check no defaults if already a member' do
			before (:all) {
				# Create Membership and move to Renewal Period
				newMember(user: :endUser, memberType: :plain, clearPrefs: true, payment: :stripe)
				changeEndDate(offset: 10, status: 'Renew')
				@bUser.goto("#{Domain}/userdetails")
				@bUser.radio(id: /membership-1-membership-membership-type-id-1/).set
			}
			chkMailPrefs(info: false, newsletter: false)
		end
		$clickCount += 2
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
			chkHousehold(user: :endUser)
			chkIndividual(contrib: 1, activities: 5, lma: 1)
			chkPrintCards
		end
		describe 'Step 2, Renew & Change Membership Type' do
			before(:all) {
				changeEndDate(offset: 10, status: 'Renew') 
				renewMembership(user: :endUser, memberType: :membership, payment: :stripe)
			}
			chkHousehold(user: :endUser, memberType: 'Membership', memberStatus: 'Current')
			chkIndividual( contrib: 2, memberStatus: 'Current', 
				endDateOffset: 10, memberType: 'Membership', duration: 12, activities: 14, lma: 2)
			chkPrintCards
		end
	end	

# Close Test Case Wrapper
end
