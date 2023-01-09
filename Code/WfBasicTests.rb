###############  LALG Membership System - Regression Tests  ##################
###############             Workflow Tests - Basic          ##################
###############       Minimal set of Confidence Tests       ##################

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
	
	######  Admin Membership Renewal No Email
	describe "Test-25 Admin Renew Membership No Email" do
		before(:all) { 
			puts '*** Test-25 Admin Renew Membership No Email'
			cleanData 
		} 
		
		describe 'Step 1, Join' do
			before(:all) {
				newMember(user: :admin, withEmail: false, payment: :cheque)
			}
			chkRedirect()
			chkHousehold()
			chkIndividual( withEmail: false, contrib: 1, activities: 4, lma: 1)
			chkPrintCards
		end
		describe 'Step 2, Renew' do
			before(:all) {
				changeEndDate(offset: 10, status: 'Renew') 
				renewMembership
			}
			chkRedirect()
			chkIndividual( withEmail: false, contrib: 2, memberStatus: 'Current', 
				endDateOffset: 10, duration: 12, activities: 11, lma: 2)
			chkPrintCards
		end
	end

	#######  Admin Membership Lifecycle
	describe "Test-41 Admin Membership Lifecycle" do
		before(:all) { 
			puts '*** Test-41 Admin Membership Lifecycle'
			cleanData 
		} 	
		
		describe 'Join Membership' do	
			before(:all) {
				newMember(user: :admin, payment: :cheque)
			}
			chkRedirect()
			chkHousehold()
			chkIndividual( activities: 4, lma: 1)
			chkPrintCards
		end
		
		describe 'Replace Membership Card' do	
			before(:all) {
				replaceCard(user: :admin)
			}
			chkRedirect()
			chkIndividual( activities: 7, lma: 3 )
			chkPrintCards
		end
		
		describe 'Renew Membership' do	
			before(:all) {
				chkClicks
				changeEndDate(offset: 10, status: 'Renew') 
				renewMembership(user: :admin, payment: :cheque) 
			}
			chkRedirect()
			chkIndividual( contrib: 2, endDateOffset: 10, duration: 12,
							memberStatus: 'Current', activities: 14, lma: 2 )
			chkPrintCards
		end
		
		describe 'Overdue Membership' do	
			before(:all) {
				changeEndDate(offset: -10, status: 'Overdue') 
				renewMembership(user: :admin, payment: :cheque) 
			}
			chkRedirect()
			chkIndividual( contrib: 3, endDateOffset: -10, duration: 12,
							memberStatus: 'Current', activities: 21, lma: 2 )
			chkPrintCards
		end
		
		describe 'ReJoin Lapsed Membership' do	
			before(:all) {
				changeEndDate(offset: -60, status: 'Lapsed')
				renewMembership(user: :admin, payment: :cheque) 
			}
			chkRedirect()
			chkIndividual( contrib: 4, memberStatus: 'Current', activities: 28, lma: 4 )
			chkPrintCards
		end
	end	

	##############################################################
	#######  Test End User Actions
	
	#######  End User with Plain Membership
	describe "Test-35 User Plain Membership" do
		before(:all) { 
			puts '*** Test-35 User Plain Membership'
			cleanData 
			loginUser	
			newMember(user: :endUser, memberType: :plain, payment: :stripe)
		} 	
		after(:all) { logoutUser }		
		
		chkRedirect(user: :endUser, memberType: 'Membership')
		chkHousehold(user: :endUser, memberType: 'Membership')
		chkIndividual(memberType: 'Membership', activities: 5)
		chkPrintCards
	end

	#######  End User Membership Lifecycle
	describe "Test-43 User Membership Lifecycle" do
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
			chkRedirect(user: :endUser)
			chkHousehold(user: :endUser)
			chkIndividual( activities: 5, lma: 1)
			chkPrintCards
		end
		
		describe 'Replace Membership Card' do	
			before(:all) {
				replaceCard(user: :endUser)
			}
			chkRedirect(user: :endUser)
			chkIndividual(activities: 8, lma: 3 )
			chkPrintCards
		end
		
		describe 'Renew Membership' do	
			before(:all) {
				chkClicks
				changeEndDate(offset: 10, status: 'Renew') 
				renewMembership(user: :endUser, payment: :stripe) 
			}
			chkRedirect(user: :endUser)
			chkIndividual( contrib: 2, endDateOffset: 10, duration: 12,
							memberStatus: 'Current', activities: 16, lma: 2 )
			chkPrintCards
		end
		
		describe 'Overdue Membership' do	
			before(:all) {
				changeEndDate(offset: -10, status: 'Overdue') 
				renewMembership(user: :endUser, payment: :stripe) 
			}
			chkRedirect(user: :endUser)
			chkIndividual( contrib: 3, endDateOffset: -10, duration: 12,
							memberStatus: 'Current', activities: 24, lma: 2 )
			chkPrintCards
		end
		
		describe 'ReJoin Lapsed Membership' do	
			before(:all) {
				changeEndDate(offset: -60, status: 'Lapsed')
				renewMembership(user: :endUser, payment: :stripe) 
			}
			chkRedirect(user: :endUser)
			chkIndividual( contrib: 4, memberStatus: 'Current', activities: 32, lma: 4 )
			chkPrintCards
		end
	end	

	######  End User Renew Membership plus Add Member 
	describe "Test-52 User Renew Membership plus Add Member" do
		before(:all) { 
			puts '*** Test-52 User Renew Membership plus Add Member'
			cleanData 
			loginUser	
		} 
		describe 'Step 1, Join' do
			before(:all) {
				newMember(user: :endUser, payment: :stripe)
			}
			chkRedirect(user: :endUser)
			chkHousehold(user: :endUser)
			chkIndividual(contrib: 1, activities: 5)
			chkPrintCards
		end
		describe 'Step 2, Renew & Add Member' do
			before(:all) {
				changeEndDate(offset: 10, status: 'Renew') 
				renewMembership(user: :endUser, payment: :stripe, additional: 1)
			}
			chkRedirect(user: :endUser)
			chkHousehold(user: :endUser, memberStatus: 'Current', additional: 1)
			chkIndividual( contrib: 2, memberStatus: 'Current', 
				endDateOffset: 10, duration: 12, activities: 15, additional: 1)
			chkIndividual( contrib: 0, memberStatus: 'Current', 
				endDateOffset: 10, duration: 12, activities: 3, additional: 1, chkAddNum: 1)				
			chkPrintCards(additional: 1)
		end
	end	

# Close Test Case Wrapper
end
