#######################################
LALG Website Regression Tests.
#######################################

Versions Planned
#########################

v1.11
This first version is a copy of the Drupal 7 Workflow tests, copied to Github repository. No further changes on this branch.

v2.x
Partitioned and Refactored Drupal 7 Tests, including compatible updates, e.g. Unit Tests.

v3.x
Drupal 8 upgrades, incompatible with D7.

Test Structure
#########################

Each Test file contains several related tests, that can be run individually or as a batch.
Tests are divided into:
** Unit Tests.  
	To test relatively small sections of functionality.  Can be run
	Test Files include:
	* Framework.  Widely used functions such as Login, Clean Data.
	* Function Specific.  E.g. CiviRules, or Tokens.  
	
** Workflow Tests
	To test Use Cases commonly used by Membership Admins or End Users.
	Test Files include:
	* Basic - Common functions, Admin and User.  General confidence test.
	* Extended - Functions not covered in Basic, including where we identified 
	    particular problems with standard software. 
	* Extra - Individual functions, included in the above as part of a longer run.
	    May be useful if focussing on a specific point.
	* Old - Tests for discontinued features, notably Pay Later.
	
** Library Files
	There are also library files containing functions called up by the various Tests
	
Dependencies
###########################	

Require installation on client PC of:
    Ruby
	Watir
	Rspec
	Browser Driver(s)
	
To Execute
###########################

** cd to directory containing Test scripts

** Select Domain to test:
	set RspecDomain=xxx					<Where xxx = www, dev, tmp, etc.>

** To execute all tests in a file:
    rspec <Test filename>.rb -f html -o 'results.html' 
	
** To execute individual Tests:
    rspec <Test filename>.rb -e 'Test-nn' -f html -o 'results.html' 	
	
** Notes
	Results filename may be 'anything.html', but by convention always starts with 'result' or 'Result'.
	  These are ignored by the sourcecode version control system.


