###############  LALG Membership System - Regression Tests  ##################
###############             Workflow Tests - Extra          ##################

puts 'Test File opened'
require 'rspec'
require 'watir'
require '../Lib/CommonFns.rb'
require '../Lib/WorkflowFns.rb'
puts 'Libraries loaded'

################################################################################
####################  Test Case Specifications  ################################
################################################################################

describe "Test Case Wrapper #{Time.now.strftime("%Y-%m-%d %H:%M")}" do
	
	before(:all) { loginAdmin }
	after(:all) {if defined?(@bAdmin) then @bAdmin.close end}

	############################################################
	#######  Test Admin New Member Variants
		
	######  End User Pay Later
	describe "Test-91 User New Member Pay Later" do
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
	
	#######  End User with Online Temporary Membership
	describe "Test-92 User New Member OTM" do
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
	end

	######  End User Renew Membership plus Change Membership Type with Pay Later
	describe "Test-93 User Renew plus Change Membership Type with Pay Later" do
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

# Close Test Case Wrapper
end
