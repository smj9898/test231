#!/bin/bash -e

patchId=7b2a5857-1e16-4a0d-a82c-62786404c9ff
patchVersion=/var/cgn/info/log/maintenance/patchVersion.log
currTime=$(date +%s)
backupFolder=/var/cgn/info/NDLP_5979/${currTime}
patchLog=/var/cgn/info/log/maintenance/patch_${currTime}.log
verbose=true
applianceVersion=$(rpm -qa | grep ciappliance-DG- | cut -d - -f 3)
$(touch -a /var/cgn/info/log/maintenance/patchVersion.log)
lastPatchId=$(tail -n 1 $patchVersion | awk '{print $1}')

user=$(whoami)
### Functio2s

log () {
    data=$1
    timeStamp=$(date)
    echo $timeStamp - $data >> $patchLog 
    [ "$verbose" == "true" ] && echo $timeStamp - $data
    
}

check_patch_prereq () {
    retVal=1
    log "Enter Patch Pre-requsite Check"
    #User Needs to Define Logic
    beforemd5sumVal=$(md5sum /usr/local/bin/inspectd | awk '{print $1}')
    log "before replace the patch content md5sum : $beforemd5sumVal"
    retVal=$?
    log "running command psql -U cgn cgndb -c \"delete from discovery_oauth_clients where provider='mip';\""
    su - postgres -c "psql -U cgn cgndb -c \"delete from discovery_oauth_clients where provider='mip';\""
    log "Exit Patch Pre-requite Check with return code $retVal"
    #Based on the return value, Execution will proceed or stop.
    return $retVal
}

stop_services () {
    retVal=1
    arg=$1
    log "Enter Stop Services"
    if [ -z $arg ]; then
        log "cgnmgr stop"
        cgnmgr stop 1>>$patchLog 2>&1
        retVal=$?
    else
        for daemon in $(echo  $arg | sed -e 's/,/ /'); do
           log "cgnmgr stop $daemon"
           cgnmgr stop $daemon 1>>$patchLog 2>&1
           retVal=$?
           [ "$retVal" -ne 0 ] && break
         done
    fi
    log "Exit Stop Services with return code $retVal"
    #Based on the return value, Execution will proceed or stop.
    return $retVal
}

create_backup () {
    retVal=1
    mkdir -p ${backupFolder}
    chown --reference=/var/cgn/info/core ${backupFolder}
    log "Enter Create Backup"
    log "Backup Folder : $backupFolder"
    #User Needs to Define Logic
    mv /var/lib/tomcat/webapps/ROOT/WEB-INF/classes/com/cgn/admin/cia/struts/actions/network/ViewCloudSettingsAction* ${backupFolder}/;
    mv /var/lib/tomcat/webapps/ROOT/WEB-INF/lib/cgncloudapi-1.0.0.jar ${backupFolder}/;
    mv /usr/local/bin/mipsvcd ${backupFolder}/;
    retVal=$?
    log "Exit Create Backup with return code $retVal"
    #Based on the return value, Execution will proceed or stop.
    return $retVal
}

deploy_patch () {
    retVal=1
    log "Enter Deploy Patch"
    #User Needs to Define Logic
    cp ./ViewCloudSettingsAction* /var/lib/tomcat/webapps/ROOT/WEB-INF/classes/com/cgn/admin/cia/struts/actions/network/
    cp ./cgncloudapi-1.0.0.jar /var/lib/tomcat/webapps/ROOT/WEB-INF/lib/
    cp ./cgncloudapi-1.0.0.jar /usr/class/discovery/binaries/
    cp ./mipsvcd /usr/local/bin/

    chown --reference=/var/lib/tomcat/webapps/ROOT/WEB-INF/classes/com/cgn/admin/cia/struts/actions/network/ViewMailServerAction.class /var/lib/tomcat/webapps/ROOT/WEB-INF/classes/com/cgn/admin/cia/struts/actions/network/ViewCloudSettingsAction*
    chmod --reference=/var/lib/tomcat/webapps/ROOT/WEB-INF/classes/com/cgn/admin/cia/struts/actions/network/ViewMailServerAction.class /var/lib/tomcat/webapps/ROOT/WEB-INF/classes/com/cgn/admin/cia/struts/actions/network/ViewCloudSettingsAction*
    chown --reference=/var/lib/tomcat/webapps/ROOT/WEB-INF/lib/cgncommon.jar /var/lib/tomcat/webapps/ROOT/WEB-INF/lib/cgncloudapi-1.0.0.jar
    chmod --reference=/var/lib/tomcat/webapps/ROOT/WEB-INF/lib/cgncommon.jar /var/lib/tomcat/webapps/ROOT/WEB-INF/lib/cgncloudapi-1.0.0.jar
    chown --reference=/usr/class/discovery/binaries/cgnmx.jar /usr/class/discovery/binaries/cgncloudapi-1.0.0.jar
    chmod --reference=/usr/class/discovery/binaries/cgnmx.jar /usr/class/discovery/binaries/cgncloudapi-1.0.0.jar
    retVal=$?
    log "Exit Deploy Patch with return code $retVal"
    #Based on the return value, Execution will proceed or stop.
    return $retVal
}

start_services () {
    retVal=1
    arg=$1
    log "Enter Start Services"
    if [ -z $arg ]; then
        log "cgnmgr start"
        cgnmgr start 1>>$patchLog 2>&1
        retVal=$?
    else
        for daemon in $(echo  $arg | sed -e 's/,/ /'); do
           log "cgnmgr start $daemon"
           cgnmgr start $daemon 1>>$patchLog 2>&1
           retVal=$?
           [ "$retVal" -ne 0 ] && break
         done
    fi
    log "Exit Start Services with return code $retVal"
    #Based on the return value, Execution will proceed or stop.
    return $retVal
}

restart_services () {
    retVal=1
    log "Enter Restart All Services"
    log "cgnmgr restart" 
    cgnmgr restart 1>>$patchLog 2>&1
    retVal=$?
    log "Exit Retart All Services with return code $retVal"
    #Based on the return value, Execution will proceed or stop.
    return $retVal
}

verify_patch () {
    retVal=1
    log "Enter Verify Patch"
    #User Needs to Define Logic
    aftermd5sumVal=$(md5sum /usr/local/bin/inspectd | awk '{print $1}')

    log "after replace the patch content md5sum : $aftermd5sumVal"
    retVal=$?
    log "Exit Verify Patch with return code $retVal"
    #Based on the return value, Execution will proceed or stop.
    return $retVal
}

rollback_patch () {
    retVal=1
    log "Enter Rollback Patch"
    #User Needs to Define Logic
    cp ${backupFolder}/pbed   /usr/local/bin
    cp ${backupFolder}/inspectd   /usr/local/bin
 
    chown --reference=/usr/local/bin/mipd          /usr/local/lbin/pbed
    chown --reference=/usr/local/bin/mipd          /usr/local/lbin/inspectd

    retVal=$?
    log "Exit Rollback Patch with return code $retVal"
    #Based on the return value, Execution will proceed or stop.
    return $retVal
}

update_patch_history () {
    retVal=1
    log "Enter Update Patch History"
    grep -q $patchId $patchVersion 1>/dev/nul 2>/dev/nul && log "PatchId is already present" || { echo -n "$patchId -> "; date; }  >> $patchVersion
    retVal=$?
    log "Exit Update Patch History with return code $retVal"
    #Based on the return value, Execution will proceed or stop.
    return $retVal
}

end () {
    [ "$1" -eq 0 ] && { log "Patch Update Successful"; } || { log "Patch Update Failed with Errors"; }
    exit $1
}

system_restore () {
    functionsToCall=$1
    [ -z $functionsToCall ] && functionsToCall=restart_services || functionsToCall=${functionsToCall},restart_services
    log "Restoring the system ... "
    for fname in `echo $functionsToCall | sed -e 's/,/ /g'`; do
        $fname
        [ "$?" -ne 0 ] && { log "RESTORATION FAILED"; end 1; }
    done   
    end 1
}
###############################################
log "Start Patch Update"
[ "$user" == "root" ] || { log "Current user is $user. Need to log in as root.";end 1; } 
log "Detailed progess of patch deployment are in $patchLog"
check_patch_prereq

if [ "$?" -eq 0 ]; then
    #User needs to define which services to stop
    stop_services 
    if [ "$?" -eq 0 ]; then
       create_backup
       if [ "$?" -eq 0 ]; then
          deploy_patch
          if [ "$?" -eq 0 ]; then
            #User needs to define which services to start
             start_services
             if [ "$?" -eq 0 ]; then
                verify_patch
                if [ "$?" -eq 0 ]; then
                   update_patch_history 
                   end 0
                else
                   system_restore rollback_patch
                fi
             else
                system_restore rollback_patch
             fi
          else
             system_restore rollback_patch
          fi
       else
          system_restore
       fi
    else
       end 1
    fi
else
    end 1
fi


