lappend ::auto_path [file dirname [file dirname [pwd]] ]

puts "Loading IXIA libraries"
package require IxRepository
#source {Z:\Ixia\Workspace\ixia-ixLoad-ixRepository-API\IxRepository.tcl}
set testName "S1S11_MME"
set chassis "172.16.174.134"

puts "Connecting to Serveer..."
IXIA::connect

puts "Loading configuration file: [pwd]/configs/$testName.rxf"
IXIA::loadRepository "[pwd]/configs/$testName.rxf"

# ��������UE
IXIA::configUE UE-R2 -count 1234 -mss 1518
#IXIA::configObjective UE-R2 -objectivetype "Active Subscribers" -objectivevalue 987 -constrainttype TransactionRateConstraint -constraintvalue 4321
IXIA::configObjective HTTPClient1 -constrainttype TransactionRateConstraint -constraintvalue 4321 
# ���������ļ��Ա������ò����Ƿ���ȷ
IXIA::save [file join [pwd] Result/Configs/$testName.rxf]










