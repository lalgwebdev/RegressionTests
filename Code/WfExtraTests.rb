###############  LALG Membership System - Regression Tests  ##################
###############             Workflow Tests - Extra          ##################
######  Odd tests now subsumed in Confidence Tests, but still usable   #######

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
				endDateOffset: 10, duration: 12, activities: 10, lma: 2)
			chkPrintCards
		end
	end
		
	##############################################################
	#######  Test End User Actions

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
		chkIndividual( activities: 5)
		chkPrintCards
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
			chkIndividual(activities: 5, lma: 1)
			chkPrintCards
		end
		
		describe 'Renew Membership' do	
			before(:all) {
				changeEndDate(offset: 10, status: 'Renew') 
				renewMembership(user: :endUser, payment: :stripe) 
			}
			chkIndividual( contrib: 2, endDateOffset: 10, duration: 12,
							memberStatus: 'Current', activities: 12, lma: 2 )
			chkPrintCards
		end
	end

# Close Test Case Wrapper
end
