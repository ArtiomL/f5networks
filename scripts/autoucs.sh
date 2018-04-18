# Auto Copy UCS from another machine
# V1.1 By ValentineG 2017-07-16

# We need to use SCP so first create an PKI trust, Execute "ssh-keygen" on recieving f5 without paraphrase,
# save it to /root/.ssh/f5AutoUCS and copy public key(/root/.ssh/f5AutoUCS.pub) to the F5 from which you wish to pull the config
# use the comand : ssh <F5 USER>@<F5 HOSTNAME> 'cat /root/.ssh/f5AutoUCS.pub' >> ~/.ssh/authorized_keys

function fun_LOG () {
 if [ $? -eq 0 ] ; then
  echo `date +"%B %d %H:%M:%S"` $1 was successful ! >> /var/tmp/scripts/autoUCS.log
 else
  echo `date +"%B %d %H:%M:%S"` $1 failed ! >> /var/tmp/scripts/autoUCS.log
  exit $2
 fi
}

echo `date +"%B %d %H:%M:%S"` Starting f5 UCS config sync >> /var/tmp/scripts/autoUCS.log

_hostname=`uname -n`
_now=`date +"%d_%m_%Y"`

# enter the username here:
_user='root'

# enter the MGMT IPs of local and remote F5s
_remoteF5=$1

_localF5=$(tmsh list /sys management-ip one-line | awk -F'[ /]' '{print $3}')

# UCS Location
_ucsLoc='/var/tmp/scripts'


#Create the UCS on remote device and download it to local device via SCP
_sshOut=$(ssh -i /root/.ssh/f5AutoUCS $_user@$_remoteF5 <<- EOF
 tmsh save sys ucs $_ucsLoc/f5AutoUCS-$_now
 scp -i /root/.ssh/f5AutoUCS $_ucsLoc/f5AutoUCS-$_now.ucs $_user@$_localF5:$_ucsLoc/f5AutoUCS-$_now.ucs
 rm -rf $_ucsLoc/f5AutoUCS-$_now.ucs
EOF)

fun_LOG "Connection to $_remoteF5 " 1
echo "$_sshOut" | grep "is saved"
fun_LOG "Grabbing the UCS from $_remoteF5" 1

#extract the UCS in order to import local base config file
mkdir $_ucsLoc/UCS
mv $_ucsLoc/f5AutoUCS-$_now.ucs $_ucsLoc/UCS/
cd $_ucsLoc/UCS
gzip -dc f5AutoUCS-$_now.ucs | tar xvpf -
rm -f f5AutoUCS-$_now.ucs

fun_LOG "UCS extract" 2

# Make desired changes to bigip.conf
#ex -sc '%s/x.x.x.y/x.x.x.z/g|x' config/bigip.conf

# Import base config file to new UCS
cp /config/bigip_base.conf config/bigip_base.conf

# Compress back the configuration to a new UCS and clean the files
tar cvf - * | gzip -c > $_ucsLoc/f5AutoUCS-$_now.ucs

fun_LOG "new UCS compression", 3

# Cleanup
cd ..
rm -rf $_ucsLoc/UCS

_loadOut=$(tmsh load sys ucs $_ucsLoc/f5AutoUCS-$_now.ucs no-license no-platform-check)
echo $_loadOut | grep "is loaded."
fun_LOG "UCS Load", 4

# Return hostname to before running 
tmsh modify sys global-settings hostname temp.temp
tmsh modify sys global-settings hostname $_hostname
